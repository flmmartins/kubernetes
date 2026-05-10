locals {
  komga_app_name = "komga-reader"
  komga_port     = 25600
  komga_url      = "reader.${var.domain}"
  komga_common_labels = {
    part-of = "reader"
  }
  komga_app_labels = merge(local.komga_common_labels, {
    app       = local.komga_app_name
    component = "app"
  })
}

resource "kubernetes_namespace_v1" "komga" {
  count = var.ebooks_comics_nfs_share != null ? 1 : 0

  metadata {
    name = local.komga_app_name
  }
}

resource "kubernetes_persistent_volume_claim_v1" "komga_config" {
  count = var.ebooks_comics_nfs_share != null ? 1 : 0

  metadata {
    name      = "komga-config"
    namespace = kubernetes_namespace_v1.komga[0].metadata[0].name
    labels = merge(local.komga_common_labels, {
      component = "config"
    })
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = "5Gi"
      }
    }

    storage_class_name = var.persistent_storage_class
  }
}

resource "kubernetes_persistent_volume_claim_v1" "komga_data" {
  count = var.ebooks_comics_nfs_share != null ? 1 : 0

  metadata {
    name      = "komga-data"
    namespace = kubernetes_namespace_v1.komga[0].metadata[0].name
    labels = merge(local.komga_common_labels, {
      component = "data"
    })
  }

  spec {
    access_modes = [var.ebooks_comics_nfs_share.access_mode]
    resources {
      requests = {
        storage = var.ebooks_comics_nfs_share.size
      }
    }
    volume_name        = kubernetes_persistent_volume_v1.data_volumes["ebooks-comics"].metadata[0].name
    storage_class_name = kubernetes_storage_class_v1.manual.metadata[0].name
  }
}

resource "kubernetes_deployment_v1" "komga" {
  count = var.ebooks_comics_nfs_share != null ? 1 : 0

  metadata {
    name      = local.komga_app_name
    namespace = kubernetes_namespace_v1.komga[0].metadata[0].name
    labels    = local.komga_app_labels
  }

  spec {
    replicas = 1

    selector {
      match_labels = local.komga_app_labels
    }

    template {
      metadata {
        labels = local.komga_app_labels
      }

      spec {
        security_context {
          run_as_non_root        = true
          run_as_user            = var.ebooks_comics_nfs_share.user_id
          run_as_group           = var.ebooks_comics_nfs_share.group_id
          fs_group               = var.ebooks_comics_nfs_share.group_id
          fs_group_change_policy = "OnRootMismatch" #Only applicable to dynamic
        }
        container {
          name  = local.komga_app_name
          image = "gotson/komga:${var.komga_image_version}"
          env {
            name  = "KOMGA_DATABASE_CHECKLOCALFILESYSTEM"
            value = "FALSE"
          }
          env {
            name  = "KOMGA_TASKSDB_CHECKLOCALFILESYSTEM"
            value = "FALSE"
          }

          port {
            container_port = local.komga_port
          }

          resources {
            requests = {
              memory = "500Mi"
              cpu    = "200m"
            }
            limits = {
              memory = "500Mi"
              cpu    = "200m"
            }
          }

          volume_mount {
            name       = "config"
            mount_path = "/config"
          }

          volume_mount {
            name       = "data"
            mount_path = "/books"
            read_only  = true
          }
        }

        volume {
          name = "config"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.komga_config[0].metadata[0].name
          }
        }

        volume {
          name = "data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.komga_data[0].metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "komga" {
  count = var.ebooks_comics_nfs_share != null ? 1 : 0

  metadata {
    name      = local.komga_app_name
    namespace = kubernetes_namespace_v1.komga[0].metadata[0].name
    labels = merge(local.komga_common_labels, {
      component = "service"
    })
  }

  spec {
    selector = kubernetes_deployment_v1.komga[0].metadata[0].labels

    port {
      port        = 80
      target_port = local.komga_port
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_manifest" "komga-http-route" {
  count = var.ebooks_comics_nfs_share != null ? 1 : 0

  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"

    metadata = {
      name      = local.komga_app_name
      namespace = kubernetes_namespace_v1.komga[0].metadata[0].name
    }

    spec = {
      parentRefs = [
        {
          name      = var.gateway.name
          namespace = var.gateway.namespace
        }
      ]

      hostnames = [
        local.komga_url
      ]

      rules = [
        {
          matches = [
            {
              path = {
                type  = "PathPrefix"
                value = "/"
              }
            }
          ]

          backendRefs = [
            {
              name = kubernetes_service_v1.komga[0].metadata[0].name
              port = 80
            }
          ]
        }
      ]
    }
  }
}
