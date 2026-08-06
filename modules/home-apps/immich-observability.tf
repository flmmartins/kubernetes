locals {
  immich_dashboard = {
    title = "Immich"
    uid   = "immich-custom"
    panels = [
      {
        title       = "HTTP Request Rate"
        type        = "timeseries"
        query       = "sum(rate(http_server_request_count_total[5m])) by (http_route)"
        keep_fields = null
      },
      {
        title       = "HTTP Response Success Rate"
        type        = "timeseries"
        query       = "sum(rate(http_server_response_success_count_total[5m])) / sum(rate(http_server_response_count_total[5m]))"
        keep_fields = null
      },
      {
        title       = "HTTP Request Duration p99 (ms)"
        type        = "timeseries"
        query       = "histogram_quantile(0.99, sum(rate(http_server_duration_bucket[5m])) by (le, http_route))"
        keep_fields = null
      },
      {
        title       = "Active Users"
        type        = "stat"
        query       = "immich_users_total"
        keep_fields = null
      },
      {
        title       = "Process CPU Utilization"
        type        = "timeseries"
        query       = "process_cpu_utilization"
        keep_fields = null
      },
      {
        title       = "Process Memory Usage (bytes)"
        type        = "timeseries"
        query       = "process_memory_usage"
        keep_fields = null
      },
      {
        title       = "System CPU Utilization"
        type        = "timeseries"
        query       = "system_cpu_utilization"
        keep_fields = null
      },
      {
        title       = "System Memory Utilization"
        type        = "timeseries"
        query       = "system_memory_utilization"
        keep_fields = null
      },
      {
        title       = "Database Query Duration p99 (ms)"
        type        = "timeseries"
        query       = "histogram_quantile(0.99, sum(rate(immich_asset_repository_create_duration_bucket[5m])) by (le))"
        keep_fields = null
      },
      {
        title       = "Job Queue Activity"
        type        = "timeseries"
        query       = "sum(rate(immich_job_repository_queue_duration_count[5m])) by (job_repository_queue_duration_status)"
        keep_fields = null
      }
    ]
  }

  immich_dashboard_json = {
    title         = local.immich_dashboard.title
    uid           = local.immich_dashboard.uid
    timezone      = "browser"
    schemaVersion = 39
    version       = 1
    refresh       = "30s"
    time = {
      from = "now-6h"
      to   = "now"
    }
    panels = [
      for idx, p in local.immich_dashboard.panels : {
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
            expr  = p.query
            refId = "A"
          }
        ]
        fieldConfig = {
          defaults  = {}
          overrides = []
        }
      }
    ]
  }
}

resource "kubernetes_config_map_v1" "immich_grafana_dashboard" {
  count = var.enable_metrics != null && var.photos_nfs_share != null ? 1 : 0

  metadata {
    name      = "${local.immich_app_name}-grafana-dashboard"
    namespace = kubernetes_namespace_v1.immich[0].metadata[0].name
    labels = merge(local.immich_app_labels, {
      component         = "grafana-dashboard"
      grafana_dashboard = "1"
    })
  }

  data = {
    "immich.json" = jsonencode(local.immich_dashboard_json)
  }
}
