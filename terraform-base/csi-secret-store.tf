resource "helm_release" "csi-secrets-store" {
  name       = "csi-secrets-store"
  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  version    = var.csi_secret_store_chart_version
  chart      = "secrets-store-csi-driver"
  set {
    name  = "syncSecret.enabled"
    value = true
  }
}