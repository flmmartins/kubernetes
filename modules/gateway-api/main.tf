locals {
  name = "1password-connect"
  labels = {
    part-of = "loadbalancer"
  }
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
      additionalLabels: ${jsonencode(local.labels)}
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
