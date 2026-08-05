terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

locals {
  labels = {
    part-of = "loadbalancer"
  }
  gateway_certificates = { for idx, cert in var.gateway_certificates : idx => cert }
  gateway_api_dashboard = {
    title = "Gateway API"
    uid   = "gateway-api-custom"
    panels = [
      {
        title       = "Gateways Programmed"
        type        = "stat"
        query       = "count(gatewayapi_gateway_status{type=\"Programmed\"} == 1)"
        keep_fields = null
      },
      {
        title       = "Gateway Status Conditions"
        type        = "table"
        query       = "gatewayapi_gateway_status"
        keep_fields = ["name", "namespace", "type", "Value"]
      },
      {
        title       = "GatewayClass Status"
        type        = "table"
        query       = "gatewayapi_gatewayclass_status"
        keep_fields = ["name", "type", "Value"]
      },
      {
        title       = "HTTPRoute Attachments"
        type        = "table"
        query       = "gatewayapi_httproute_status_parent_info"
        keep_fields = ["name", "namespace", "controller_name", "parent_name", "parent_namespace"]
      },
      {
        title       = "Attached Routes per Listener"
        type        = "table"
        query       = "gatewayapi_gateway_status_listener_attached_routes"
        keep_fields = ["name", "namespace", "listener_name", "Value"]
      }
    ]
  }

  gateway_api_dashboard_json = {
    title         = local.gateway_api_dashboard.title
    uid           = local.gateway_api_dashboard.uid
    timezone      = "browser"
    schemaVersion = 39
    version       = 1
    refresh       = "30s"
    time = {
      from = "now-6h"
      to   = "now"
    }
    panels = [
      for idx, p in local.gateway_api_dashboard.panels : merge(
        {
          id    = idx + 1
          title = p.title
          type  = p.type
          gridPos = {
            h = 8
            w = 12
            x = (idx % 2) * 12
            y = floor(idx / 2) * 8
          }
          datasource = {
            type = "prometheus"
            uid  = "Prometheus"
          }
          targets = [
            {
              expr    = p.query
              format  = p.type == "table" ? "table" : "time_series"
              instant = p.type == "table" ? true : false
              refId   = "A"
            }
          ]
          fieldConfig = {
            defaults  = {}
            overrides = []
          }
        },
        p.keep_fields != null ? {
          transformations = [
            {
              id = "organize"
              options = {
                excludeByName = {
                  Time      = true
                  __name__  = true
                  container = true
                  endpoint  = true
                  instance  = true
                  job       = true
                  pod       = true
                  service   = true
                  namespace = contains(p.keep_fields, "namespace") ? false : true
                }
                includeByName = {
                  for f in p.keep_fields : f => true
                }
              }
            }
          ]
        } : {}
      )
    ]
  }
}

resource "terraform_data" "gateway_crds" {
  triggers_replace = {
    version = var.gateway_crds_version
  }
  provisioner "local-exec" {
    command = <<EOT
      kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd/experimental?ref=${var.gateway_crds_version}" | kubectl apply --server-side -f -
    EOT
  }
}

resource "kubernetes_namespace_v1" "gateway" {
  metadata {
    name = "gateway"
    labels = merge(local.labels, {
      "pod-security.kubernetes.io/enforce" = "baseline"
    })
  }
}

resource "kubernetes_manifest" "gateway_certificates" {
  for_each = local.gateway_certificates

  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = replace(replace(each.value.hostname, "*", "start"), ".", "-")
      namespace = kubernetes_namespace_v1.gateway.metadata[0].name
      labels    = merge(local.labels, { component = "certificates" })
    }
    spec = {
      commonName = each.value.hostname
      secretName = replace(replace(each.value.hostname, "*", "start"), ".", "-")
      issuerRef = {
        name  = each.value.cluster_issuer
        kind  = "ClusterIssuer"
        group = "cert-manager.io"
      }
      dnsNames = [each.value.hostname]
    }
  }
}

resource "kubernetes_config_map_v1" "gateway" {
  metadata {
    name      = "gateway"
    namespace = kubernetes_namespace_v1.gateway.metadata[0].name
    labels    = merge(local.labels, { component = "gateway" })
  }

  data = {
    deployment = <<-YAML
      spec:
        template:
          spec:
            %{~if var.priority_class != null~}
            priorityClassName: ${var.priority_class}
            %{~endif~}
            securityContext:
              seccompProfile:
                type: RuntimeDefault
            containers:
            - name: istio-proxy
              resources:
                requests:
                  cpu: ${var.gateway_resources_requests_cpu}
                  memory: ${var.gateway_resources_requests_memory}
                limits:
                  cpu: ${var.gateway_resources_limits_cpu}
                  memory: ${var.gateway_resources_limits_memory}
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
                        - gateway
                    topologyKey: kubernetes.io/hostname
    YAML

    horizontalPodAutoscaler = <<-YAML
      spec:
        minReplicas: 2
        maxReplicas: 4
        metrics:
        - type: Resource
          resource:
            name: cpu
            target:
              type: Utilization
              averageUtilization: 80
    YAML
  }
}

resource "kubernetes_manifest" "gateway" {
  depends_on = [helm_release.istiod]
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "Gateway"
    metadata = {
      name      = "gateway"
      namespace = kubernetes_namespace_v1.gateway.metadata[0].name
      labels    = merge(local.labels, { component = "gateway" })
      annotations = {
        "metallb.universe.tf/address-pool" = kubernetes_manifest.istio_ip_address_pool[0].manifest.metadata.name
      }
    }
    spec = {
      gatewayClassName = "istio"
      infrastructure = {
        parametersRef = {
          group = ""
          name  = kubernetes_config_map_v1.gateway.metadata[0].name
          kind  = "ConfigMap"
        }
      }
      allowedListeners = {
        namespaces = { from = "All" }
      }
      listeners = concat(
        [
          for idx, cert in local.gateway_certificates : {
            name          = "https-${replace(replace(cert.hostname, "*", "start"), ".", "-")}"
            port          = 443
            protocol      = "HTTPS"
            hostname      = cert.hostname
            allowedRoutes = { namespaces = { from = "All" } }
            tls = {
              mode = "Terminate"
              certificateRefs = [{
                name  = kubernetes_manifest.gateway_certificates[idx].manifest.metadata.name
                kind  = "Secret"
                group = ""
              }]
            }
          }
        ],
        [
          for route in var.tcp_routes : {
            name     = route.name
            port     = route.port
            protocol = "TCP"
            allowedRoutes = {
              namespaces = route.namespace != null ? {
                from = "Selector"
                selector = {
                  matchLabels = {
                    "kubernetes.io/metadata.name" = route.namespace
                  }
                }
                } : {
                from     = "All",
                selector = null # terraform requires objects with same attributes
              }
            }
          }
        ]
      )
    }
  }
}

resource "kubernetes_pod_disruption_budget_v1" "gateway" {
  depends_on = [kubernetes_manifest.gateway]

  metadata {
    name      = "gateway"
    namespace = kubernetes_namespace_v1.gateway.metadata[0].name
    labels    = merge(local.labels, { component = "gateway" })
  }

  spec {
    min_available = 1

    selector {
      match_labels = {
        "gateway.networking.k8s.io/gateway-name" = "gateway"
      }
    }
  }
}

resource "kubernetes_config_map_v1" "gateway_api_grafana_dashboard" {
  metadata {
    name      = "gateway-api-grafana-dashboard"
    namespace = kubernetes_namespace_v1.gateway.metadata[0].name
    labels = merge(local.labels, {
      component         = "observability"
      grafana_dashboard = "1"
    })
  }

  data = {
    "gateway-api.json" = jsonencode(local.gateway_api_dashboard_json)
  }
}
