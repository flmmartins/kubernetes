resource "helm_release" "metrics-server" {
  name             = "metrics-server"
  namespace        = "metrics-server"
  repository       = "https://kubernetes-sigs.github.io/metrics-server"
  create_namespace = true
  version          = "3.13.0"
  chart            = "metrics-server"
}
