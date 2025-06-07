resource "helm_release" "metrics-server" {
  name             = "metrics-server"
  namespace        = "metrics-server"
  repository       = "https://kubernetes-sigs.github.io/metrics-server"
  create_namespace = true
  version          = var.metric_server_chart_version
  chart            = "metrics-server"
}