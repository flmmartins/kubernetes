resource "helm_release" "this" {
  name       = "csi-secrets-store"
  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  version    = var.chart_version
  chart      = "secrets-store-csi-driver"
  values = [
    <<-EOF
    syncSecret:
      enabled: true
    enableSecretRotation: true
    rotationPollInterval: "2m"
    linux:
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