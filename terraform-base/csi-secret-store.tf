resource "helm_release" "csi-secrets-store" {
  name       = "csi-secrets-store"
  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  version    = var.csi_secret_store_chart_version
  chart      = "secrets-store-csi-driver"

  values = [
    <<-EOF
    syncSecret:
      enabled: true
    linux:
      driver:
        resources:
          limits:
            cpu: 150m
            memory: 128Mi
          requests:
            cpu: 25m
            memory: 64Mi
      registrar:
        resources:
          limits:
            cpu: 50m
            memory: 64Mi
          requests:
            cpu: 5m
            memory: 16Mi
      livenessProbe:
        resources:
          limits:
            cpu: 50m
            memory: 32Mi
          requests:
            cpu: 5m
            memory: 16Mi
        EOF
  ]
}