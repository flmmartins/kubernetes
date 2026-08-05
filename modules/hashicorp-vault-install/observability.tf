data "http" "grafana_dashboard" {
  count = var.enable_metrics ? 1 : 0

  url = "https://grafana.com/api/dashboards/25314/revisions/latest/download"
}

resource "kubernetes_config_map_v1" "grafana_dashboard" {
  count = var.enable_metrics ? 1 : 0

  metadata {
    name      = "${local.name}-grafana-dashboard"
    namespace = kubernetes_namespace_v1.this.metadata[0].name
    labels = merge(local.labels, {
      component         = "observability"
      grafana_dashboard = "1"
    })
  }

  data = {
    "${local.name}-overview.json" = jsonencode(
      merge(
        jsondecode(replace(data.http.grafana_dashboard[0].response_body, "$${DS_PROMETHEUS}", "Prometheus")),
        { title = "Hashicorp Vault", id = null }
      )
    )
  }
}
