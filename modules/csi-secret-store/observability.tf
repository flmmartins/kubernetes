locals {
  csi_secrets_store_dashboard = {
    title = "CSI Secrets Store"
    uid   = "csi-secrets-store-custom"
    panels = [
      {
        title = "Node Publish Rate (mounts/sec)"
        type  = "timeseries"
        query = "sum(rate(node_publish_total[5m]))"
      },
      {
        title = "Rotation Reconcile Rate"
        type  = "timeseries"
        query = "sum(rate(rotation_reconcile_total[5m]))"
      },
      {
        title = "Rotation Reconcile p99 Duration"
        type  = "timeseries"
        query = "histogram_quantile(0.99, sum(rate(rotation_reconcile_duration_sec_bucket[5m])) by (le))"
      },
      {
        title = "Controller Reconcile Errors"
        type  = "timeseries"
        query = "sum(rate(controller_runtime_reconcile_errors_total[5m])) by (controller)"
      },
      {
        title = "Workqueue Depth"
        type  = "timeseries"
        query = "sum(workqueue_depth) by (name)"
      }
    ]
  }

  csi_secrets_store_dashboard_json = {
    title         = local.csi_secrets_store_dashboard.title
    uid           = local.csi_secrets_store_dashboard.uid
    timezone      = "browser"
    schemaVersion = 39
    version       = 1
    refresh       = "30s"
    time = {
      from = "now-6h"
      to   = "now"
    }
    panels = [
      for idx, p in local.csi_secrets_store_dashboard.panels : {
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

resource "kubernetes_manifest" "secrets_store_csi_podmonitor" {
  count = var.enable_metrics ? 1 : 0
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "PodMonitor"

    metadata = {
      name      = local.name
      namespace = helm_release.this.namespace
      labels    = merge(local.labels, { "component" = "observability" })
    }

    spec = {
      namespaceSelector = {
        matchNames = ["kube-system"]
      }
      selector = {
        matchLabels = {
          "app.kubernetes.io/name" = local.name
        }
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

resource "kubernetes_config_map_v1" "grafana_dashboard" {
  count = var.enable_metrics ? 1 : 0
  metadata {
    name      = "${local.name}-grafana-dashboard"
    namespace = helm_release.this.namespace
    labels = merge(local.labels, {
      component         = "observability"
      grafana_dashboard = "1"
    })
  }

  data = {
    "${local.name}.json" = jsonencode(local.csi_secrets_store_dashboard_json)
  }
}

