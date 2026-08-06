
locals {
  istio_dashboards = var.enable_metrics ? {
    mesh         = { id = "7639", title = "Istio Mesh" }
    service      = { id = "7636", title = "Istio Service" }
    workload     = { id = "7630", title = "Istio Workload" }
    controlplane = { id = "7645", title = "Istio Control Plane" }
  } : {}
}

resource "kubernetes_namespace_v1" "istio" {
  metadata {
    name   = "istio-system"
    labels = local.labels
  }
}

resource "helm_release" "istio-base" {
  name        = "istio-base"
  namespace   = kubernetes_namespace_v1.istio.metadata[0].name
  repository  = "https://istio-release.storage.googleapis.com/charts"
  version     = var.istio_chart_version
  chart       = "base"
  max_history = 10
}

resource "helm_release" "istiod" {
  depends_on  = [helm_release.istio-base]
  name        = "istiod"
  namespace   = kubernetes_namespace_v1.istio.metadata[0].name
  repository  = "https://istio-release.storage.googleapis.com/charts"
  version     = var.istio_chart_version
  chart       = "istiod"
  max_history = 10
  values = [<<-EOT
    ###############################
    # ISTIO D
    ###############################
    autoscaleMin: 2
    autoscaleMax: 4
    podLabels: ${jsonencode(merge(local.labels, { "component" = "istiod" }))}
    %{~if var.priority_class != null~}
    priorityClassName: ${var.priority_class}
    %{~endif~}
    resources:
      requests:
        cpu: ${var.istiod_resources_requests_cpu}
        memory: ${var.istiod_resources_requests_memory}
      limits:
        cpu: ${var.istiod_resources_limits_cpu}
        memory: ${var.istiod_resources_limits_memory}
    affinity:
      podAntiAffinity:
        preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 100
          podAffinityTerm:
            labelSelector:
              matchExpressions:
              - key: component
                operator: In
                values:
                - istiod
            topologyKey: kubernetes.io/hostname
    env:
      PILOT_ENABLE_ALPHA_GATEWAY_API: "true" # Enable TCP Route
      PILOT_ENABLE_GATEWAY_API_GAMMA_API: "true" # Enable TCP Route
  EOT
  ]
}

resource "kubernetes_manifest" "istiod_servicemonitor" {
  count = var.enable_metrics ? 1 : 0

  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "istiod"
      namespace = kubernetes_namespace_v1.istio.metadata[0].name
      labels    = merge(local.labels, { component = "istiod-monitor" })
    }
    spec = {
      jobLabel = "istio"
      selector = {
        matchLabels = { "istio" = "pilot" }
      }
      namespaceSelector = {
        matchNames = [kubernetes_namespace_v1.istio.metadata[0].name]
      }
      endpoints = [
        {
          port     = "http-monitoring"
          interval = "30s"
          path     = "/metrics"
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "istio_proxy_podmonitor" {
  count = var.enable_metrics ? 1 : 0

  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "PodMonitor"
    metadata = {
      name      = "istio-proxy"
      namespace = kubernetes_namespace_v1.istio.metadata[0].name
      labels    = merge(local.labels, { component = "observability" })
    }
    spec = {
      jobLabel = "envoy-stats"
      selector = {
        matchExpressions = [
          {
            key      = "istio-prometheus-ignore"
            operator = "DoesNotExist"
          }
        ]
      }
      namespaceSelector = { any = true }
      podMetricsEndpoints = [
        {
          portNumber = 15090
          path       = "/stats/prometheus"
          interval   = "30s"
          relabelings = [
            {
              action       = "keep"
              sourceLabels = ["__meta_kubernetes_pod_container_name"]
              regex        = "istio-proxy"
            }
          ]
        }
      ]
    }
  }
}

data "http" "istio_grafana_dashboard" {
  for_each = local.istio_dashboards

  url = "https://grafana.com/api/dashboards/${each.value.id}/revisions/latest/download"
}

resource "kubernetes_config_map_v1" "istio_grafana_dashboard" {
  for_each = local.istio_dashboards

  metadata {
    name      = "istio-${each.key}-grafana-dashboard"
    namespace = kubernetes_namespace_v1.istio.metadata[0].name
    labels = merge(local.labels, {
      component         = "observability"
      grafana_dashboard = "1"
    })
  }

  data = {
    "istio-${each.key}.json" = jsonencode(
      merge(
        jsondecode(replace(data.http.istio_grafana_dashboard[each.key].response_body, "$${DS_PROMETHEUS}", "Prometheus")),
        { title = each.value.title, id = null }
      )
    )
  }
}

