locals {
  velero_dashboard = {
    title = "Velero"
    uid   = "velero-custom"
    panels = [
      {
        title       = "Last Backup Status by Schedule"
        type        = "table"
        query       = "velero_backup_last_status"
        keep_fields = ["schedule", "Value"]
      },
      {
        title = "Hours Since Last Successful Backup"
        type  = "timeseries"
        query = "(time() - velero_backup_last_successful_timestamp) / 3600"
      },
      {
        title = "Backup Attempts vs Success vs Failure"
        type  = "timeseries"
        query = "sum(rate(velero_backup_attempt_total[1h])) by (schedule) or sum(rate(velero_backup_success_total[1h])) by (schedule) or sum(rate(velero_backup_failure_total[1h])) by (schedule)"
      },
      {
        title = "Backup Location Status"
        type  = "stat"
        query = "velero_backup_location_status_gauge"
      },
      {
        title = "Total Existing Backups"
        type  = "stat"
        query = "sum(velero_backup_total)"
      },
      {
        title = "Backup Items Errors"
        type  = "timeseries"
        query = "sum(rate(velero_backup_items_errors[1h])) by (schedule)"
      },
      {
        title = "Partial Failures / Warnings"
        type  = "timeseries"
        query = "sum(rate(velero_backup_partial_failure_total[1h])) by (schedule) or sum(rate(velero_backup_warning_total[1h])) by (schedule)"
      }
    ]
  }

  velero_dashboard_json = {
    title         = local.velero_dashboard.title
    uid           = local.velero_dashboard.uid
    timezone      = "browser"
    schemaVersion = 39
    version       = 1
    refresh       = "30s"
    time          = { from = "now-7d", to = "now" }
    panels = [
      for idx, p in local.velero_dashboard.panels : merge(
        {
          id         = idx + 1
          title      = p.title
          type       = p.type
          gridPos    = { h = 8, w = 12, x = (idx % 2) * 12, y = floor(idx / 2) * 8 }
          datasource = { type = "prometheus", uid = "Prometheus" }
          targets = [{
            expr    = p.query
            format  = p.type == "table" ? "table" : "time_series"
            instant = p.type == "table" ? true : false
            refId   = "A"
          }]
          fieldConfig = { defaults = {}, overrides = [] }
        },
        lookup(p, "keep_fields", null) != null ? {
          transformations = [{
            id = "organize"
            options = {
              excludeByName = {
                Time     = true, __name__ = true, container = true
                endpoint = true, instance = true, job = true, namespace = true, pod = true
              }
              includeByName = { for f in p.keep_fields : f => true }
            }
          }]
        } : {}
      )
    ]
  }
}

resource "kubernetes_config_map_v1" "velero_grafana_dashboard" {
  count = var.enable_metrics ? 1 : 0

  metadata {
    name      = "${local.name}-grafana-dashboard"
    namespace = kubernetes_namespace_v1.this.metadata[0].name
    labels = merge(local.labels, {
      component         = "grafana-dashboard"
      grafana_dashboard = "1"
    })
  }

  data = {
    "velero.json" = jsonencode(local.velero_dashboard_json)
  }
}
