locals {
  plex_dashboard = {
    title = "Plex"
    uid   = "plex-exporter-custom"
    panels = [
      {
        title       = "Stream Type Over Time"
        type        = "timeseries"
        query       = "sum(plex_plays_active) by (stream_type)"
        keep_fields = null
      },
      {
        title       = "Transcode Type Over Time"
        type        = "timeseries"
        query       = "sum(plex_plays_active) by (transcode_type)"
        keep_fields = null
      },
      {
        title       = "Active Transcode Sessions"
        type        = "timeseries"
        query       = "plex_active_transcode_sessions"
        keep_fields = null
      },
      {
        title       = "Client Location (LAN vs WAN)"
        type        = "timeseries"
        query       = "sum(plex_plays_active) by (location)"
        keep_fields = null
      },
      {
        title       = "Session Bandwidth (kbps)"
        type        = "timeseries"
        query       = "plex_session_bandwidth_kbps"
        keep_fields = null
      },
      {
        title       = "Session Bitrate (kbps)"
        type        = "timeseries"
        query       = "plex_session_bitrate_kbps"
        keep_fields = null
      },
      {
        title       = "HTTP Retries (network flakiness to Plex API)"
        type        = "timeseries"
        query       = "rate(plex_http_retries_total[5m])"
        keep_fields = null
      },
      {
        title       = "HTTP Reachability"
        type        = "timeseries"
        query       = "plex_http_reachable"
        keep_fields = null
      },
      {
        title       = "Session Poll Reachability"
        type        = "timeseries"
        query       = "plex_session_poll_reachable"
        keep_fields = null
      },
      {
        title       = "Exporter Errors by Type"
        type        = "timeseries"
        query       = "sum(rate(plex_exporter_errors_total[5m])) by (type)"
        keep_fields = null
      },
      {
        title       = "Library Item Counts"
        type        = "table"
        query       = "plex_library_items"
        keep_fields = ["library", "content_type", "Value"]
      },
      {
        title       = "Library Storage Used (bytes)"
        type        = "table"
        query       = "plex_library_storage_bytes"
        keep_fields = ["library", "Value"]
      }
    ]
  }

  plex_dashboard_json = {
    title         = local.plex_dashboard.title
    uid           = local.plex_dashboard.uid
    timezone      = "browser"
    schemaVersion = 39
    version       = 1
    refresh       = "30s"
    time = {
      from = "now-6h"
      to   = "now"
    }
    panels = [
      for idx, p in local.plex_dashboard.panels : merge(
        {
          id    = idx + 1
          title = p.title
          type  = p.type
          gridPos = {
            h = 8
            w = 12
            x = (idx % 2) * 12
            y = floor(idx / 2) * 8
          }
          datasource = {
            type = "prometheus"
            uid  = "Prometheus"
          }
          targets = [
            {
              expr    = p.query
              format  = p.type == "table" ? "table" : "time_series"
              instant = p.type == "table" ? true : false
              refId   = "A"
            }
          ]
          fieldConfig = {
            defaults  = {}
            overrides = []
          }
        },
        p.keep_fields != null ? {
          transformations = [
            {
              id = "organize"
              options = {
                excludeByName = {
                  Time      = true
                  __name__  = true
                  container = true
                  endpoint  = true
                  instance  = true
                  job       = true
                  pod       = true
                  namespace = true
                }
                includeByName = {
                  for f in p.keep_fields : f => true
                }
              }
            }
          ]
        } : {}
      )
    ]
  }
}

resource "vault_policy" "plex" {
  count = var.plex_vault_token != null ? 1 : 0

  name   = local.plex_app_name
  policy = <<EOT
path "${var.plex_vault_token.secret_path}" { capabilities = ["read"] }
EOT
}

resource "vault_kubernetes_auth_backend_role" "plex" {
  count = var.plex_vault_token != null ? 1 : 0

  role_name                        = local.plex_app_name
  bound_service_account_names      = ["${local.plex_app_name}-plex-media-server"]
  bound_service_account_namespaces = [kubernetes_namespace_v1.plex[0].metadata[0].name]
  token_max_ttl                    = 1440 #24H
  token_policies                   = [vault_policy.plex[0].name]
}

resource "kubernetes_manifest" "plex_token" {
  count = var.plex_vault_token != null ? 1 : 0

  manifest = {
    apiVersion = "secrets-store.csi.x-k8s.io/v1"
    kind       = "SecretProviderClass"

    metadata = {
      name      = "plex-token"
      namespace = kubernetes_namespace_v1.plex[0].metadata[0].name
      labels    = merge(local.plex_common_labels, { component = "credentials" })
    }

    spec = {
      provider = "vault"
      parameters = {
        roleName        = vault_kubernetes_auth_backend_role.plex[0].role_name
        vaultAddress    = var.plex_vault_token.vault_address
        vaultCACertPath = var.plex_vault_token.vault_csi_ca_cert_path
        objects         = <<EOT
- objectName: plex-token
  secretPath: ${var.plex_vault_token.secret_path}
  secretKey: ${var.plex_vault_token.token_field}
        EOT
      }
      secretObjects = [{
        secretName = "plex-token"
        type       = "Opaque"
        data = [{
          objectName = "plex-token"
          key        = "token"
        }]
      }]
    }
  }
}

resource "kubernetes_manifest" "plex_podmonitor" {
  count = var.enable_metrics != null && length(local.plex_shares) != null ? 1 : 0

  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "PodMonitor"
    metadata = {
      name      = local.plex_app_name
      namespace = kubernetes_namespace_v1.plex[0].metadata[0].name
      labels    = merge(local.plex_common_labels, { component = "plex-exporter-monitor" })
    }
    spec = {
      selector = {
        matchLabels = local.plex_common_labels
      }
      podMetricsEndpoints = [
        {
          port     = "metrics"
          path     = "/metrics"
          interval = "30s"
        }
      ]
    }
  }
}

resource "kubernetes_config_map_v1" "plex_grafana_dashboard" {
  count = var.enable_metrics != null && length(local.plex_shares) != null ? 1 : 0

  metadata {
    name      = "${local.plex_app_name}-grafana-dashboard"
    namespace = kubernetes_namespace_v1.plex[0].metadata[0].name
    labels = merge(local.plex_common_labels, {
      component         = "grafana-dashboard"
      grafana_dashboard = "1"
    })
  }

  data = {
    "plex.json" = jsonencode(local.plex_dashboard_json)
  }
}
