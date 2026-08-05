data "http" "grafana_dashboard" {
  count = var.enable_metrics ? 1 : 0

  url = "https://grafana.com/api/dashboards/20842/revisions/latest/download"
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
        { title = "Cert Manager", id = null }
      )
    )
  }
}

resource "kubernetes_manifest" "cert_manager_alerts" {
  count = var.enable_metrics ? 1 : 0

  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "PrometheusRule"
    metadata = {
      name      = "cert-manager-alerts"
      namespace = kubernetes_namespace_v1.this.metadata[0].name
      labels    = merge(local.labels, { component = "alerts" })
    }
    spec = {
      groups = [
        {
          name = "cert-manager"
          rules = [
            {
              alert = "CertificateExpired"
              expr  = "certmanager_certificate_expiration_timestamp_seconds - time() < 0"
              for   = "5m"
              labels = {
                severity = "critical"
              }
              annotations = {
                summary     = "Certificate {{ $labels.name }} in {{ $labels.exported_namespace }} has expired"
                description = "Certificate {{ $labels.name }} (issuer {{ $labels.issuer_name }}) expired {{ $value | humanizeDuration }} ago."
              }
            },
            {
              alert = "CertificateExpiringSoon"
              expr  = "(certmanager_certificate_expiration_timestamp_seconds - time()) / 86400 < 14"
              for   = "1h"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary     = "Certificate {{ $labels.name }} in {{ $labels.exported_namespace }} expires within 14 days"
                description = "Certificate {{ $labels.name }} (issuer {{ $labels.issuer_name }}) expires in {{ $value | humanize }} days."
              }
            },
            {
              alert = "CertificateNotReady"
              expr  = "certmanager_certificate_ready_status{condition=\"False\"} == 1"
              for   = "15m"
              labels = {
                severity = "critical"
              }
              annotations = {
                summary     = "Certificate {{ $labels.name }} in {{ $labels.exported_namespace }} is not ready"
                description = "Certificate {{ $labels.name }} (issuer {{ $labels.issuer_name }}) has been in a non-Ready state for over 15 minutes — renewal or issuance is likely failing."
              }
            }
          ]
        }
      ]
    }
  }
}
