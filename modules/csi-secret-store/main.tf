terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
    }
  }
}

locals {
  name = "secrets-store-csi-driver"
  labels = {
    part-of = "secrets"
  }
}

resource "helm_release" "this" {
  name        = local.name
  namespace   = "kube-system"
  repository  = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  version     = var.chart_version
  chart       = "secrets-store-csi-driver"
  max_history = 10
  values = [
    <<-EOF
    syncSecret:
      enabled: true
    enableSecretRotation: true
    rotationPollInterval: "2m"
    commonLabels: ${jsonencode(merge(local.labels, { "component" = "csi" }))}
    linux:
      %{~if var.priority_class != null~}
      priorityClassName: ${var.priority_class}
      %{~endif~}
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
              - matchExpressions:
                  - key: node-role.kubernetes.io/control-plane
                    operator: DoesNotExist
      driver:
        resources:
          limits:
            cpu: ${var.csi_driver_limit_cpu}
            memory: ${var.csi_driver_limit_memory}
          requests:
            cpu: ${var.csi_driver_request_cpu}
            memory: ${var.csi_driver_request_memory}
      registrar:
        resources:
          limits:
            cpu: ${var.csi_registrar_limit_cpu}
            memory: ${var.csi_registrar_limit_memory}
          requests:
            cpu: ${var.csi_registrar_request_cpu}
            memory: ${var.csi_registrar_request_memory}
      livenessProbe:
        resources:
          limits:
            cpu: ${var.csi_liveness_probe_limit_cpu}
            memory: ${var.csi_liveness_probe_limit_memory}
          requests:
            cpu: ${var.csi_liveness_probe_request_cpu}
            memory: ${var.csi_liveness_probe_request_memory}
    EOF
  ]
}
