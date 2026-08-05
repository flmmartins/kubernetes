resource "kubernetes_namespace_v1" "metallb" {
  count = var.uses_metallb ? 1 : 0
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
  count = var.uses_metallb ? 1 : 0

  name        = "metallb"
  namespace   = kubernetes_namespace_v1.metallb[0].metadata[0].name
  repository  = "https://metallb.github.io/metallb"
  version     = var.metallb_chart_version
  chart       = "metallb"
  max_history = 10
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
      %{~if var.priority_class != null~}
      priorityClassName: ${var.priority_class}
      %{~endif~}
    speaker:
      tolerations: []   # remove the control-plane toleration
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
              - matchExpressions:
                  - key: node-role.kubernetes.io/control-plane
                    operator: DoesNotExist
      resources:
        requests:
          memory: ${var.speaker_memory_request}
          cpu: ${var.speaker_cpu_request}
        limits:
          memory: ${var.speaker_memory_limit}
          cpu: ${var.speaker_cpu_limit}
      %{~if var.priority_class != null~}
      priorityClassName: ${var.priority_class}
      %{~endif~}
    %{~if var.enable_metrics~}
    prometheus:
      podMonitor:
        enabled: ${var.enable_metrics}
        additionalLabels: ${jsonencode(merge(local.labels, { "component" = "loadbalancer" }))}
      rbacPrometheus: true
      serviceAccount: ${var.prometheus_service_account}
      namespace: ${var.prometheus_namespace}
      prometheusRule:
        enabled: ${var.enable_metrics}
    %{~endif~}
    EOF
  ]
}

resource "kubernetes_manifest" "istio_ip_address_pool" {
  count = var.uses_metallb ? 1 : 0

  manifest = {
    apiVersion = "metallb.io/v1beta1"
    kind       = "IPAddressPool"
    metadata = {
      name      = "istio"
      namespace = kubernetes_namespace_v1.metallb[0].metadata[0].name
      labels    = merge(local.labels, { "component" = "ip" })
    }
    spec = {
      addresses  = ["${var.istio_ip}/32"]
      autoAssign = true
    }
  }
}

resource "kubernetes_manifest" "istio_l2_advertisement" {
  count = var.uses_metallb ? 1 : 0

  manifest = {
    apiVersion = "metallb.io/v1beta1"
    kind       = "L2Advertisement"
    metadata = {
      name      = "istio"
      namespace = kubernetes_namespace_v1.metallb[0].metadata[0].name
      labels    = merge(local.labels, { "component" = "ip" })
    }
    spec = {
      ipAddressPools = [kubernetes_manifest.istio_ip_address_pool[0].manifest.metadata.name]
    }
  }
}
