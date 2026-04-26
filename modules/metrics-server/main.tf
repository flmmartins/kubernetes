variable "chart_version" {
  description = "Metric Server Chart Version"
  default     = "3.13.0"
}

resource "helm_release" "this" {
  name             = "metrics-server"
  namespace        = "metrics-server"
  repository       = "https://kubernetes-sigs.github.io/metrics-server"
  create_namespace = true
  version          = var.chart_version
  chart            = "metrics-server"
}
