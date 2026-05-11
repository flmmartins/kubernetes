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

}

resource "kubernetes_namespace_v1" "metallb" {
  count = var.uses_metallb == true ? 1 : 0
  metadata {
    name = "metallb"
    labels = {
      "kubernetes.io/enforce"            = "privileged"
      "pod-security.kubernetes.io/audit" = "privileged"
      "pod-security.kubernetes.io/warn"  = "privileged"
    }
  }
}

resource "helm_release" "metallb" {
  count = var.uses_metallb == true ? 1 : 0

  name       = "metallb"
  namespace  = kubernetes_namespace_v1.metallb[0].metadata[0].name
  repository = "https://metallb.github.io/metallb"
  version    = var.metallb_chart_version
  chart      = "metallb"
  values = [
    <<-EOF
    controller:
      additionalLabels: ${jsonencode(merge(local.labels, { "component" = "loadbalancer" }))}
      resources:
        requests:
          memory: ${var.controller_memory_request}
          cpu: ${var.controller_cpu_request}
        limits:
          memory: ${var.controller_memory_limit}
          cpu: ${var.controller_cpu_limit}
    speaker:
      resources:
        requests:
          memory: ${var.speaker_memory_request}
          cpu: ${var.speaker_cpu_request}
        limits:
          memory: ${var.speaker_memory_limit}
          cpu: ${var.speaker_cpu_limit}
    EOF
  ]
}

resource "kubernetes_namespace_v1" "istio" {
  metadata {
    name   = "istio-system"
    labels = local.labels
  }
}

resource "helm_release" "istio-base" {
  name       = "istio-base"
  namespace  = kubernetes_namespace_v1.istio.metadata[0].name
  repository = "https://istio-release.storage.googleapis.com/charts"
  version    = var.istio_chart_version
  chart      = "base"
}

resource "helm_release" "istiod" {
  depends_on = [helm_release.istio-base]
  name       = "istiod"
  namespace  = kubernetes_namespace_v1.istio.metadata[0].name
  repository = "https://istio-release.storage.googleapis.com/charts"
  version    = var.istio_chart_version
  chart      = "istiod"
  values = [<<-EOT
    ###############################
    # ISTIO D
    ###############################
    autoscaleMin: 2
    autoscaleMax: 4
    podLabels: ${jsonencode(merge(local.labels, { "component" = "istiod" }))}
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

resource "kubernetes_manifest" "istio_ip_address_pool" {
  count = var.uses_metallb == true ? 1 : 0

  manifest = {
    apiVersion = "metallb.io/v1beta1"
    kind       = "IPAddressPool"
    metadata = {
      name      = "istio"
      namespace = kubernetes_namespace_v1.metallb[0].metadata[0].name
      labels    = local.labels
    }
    spec = {
      addresses  = ["${var.istio_ip}/32"]
      autoAssign = true
    }
  }
}

resource "kubernetes_manifest" "istio_l2_advertisement" {
  count = var.uses_metallb == true ? 1 : 0

  manifest = {
    apiVersion = "metallb.io/v1beta1"
    kind       = "L2Advertisement"
    metadata = {
      name      = "istio"
      namespace = kubernetes_namespace_v1.metallb[0].metadata[0].name
      labels    = local.labels
    }
    spec = {
      ipAddressPools = [kubernetes_manifest.istio_ip_address_pool[0].manifest.metadata.name]
    }
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
  }

  data = {
    deployment = <<-YAML
      spec:
        template:
          spec:
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
      labels = {
        component = "gateway"
        part-of   = "istio"
      }
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
