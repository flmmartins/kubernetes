locals {
  komga_app_name = "komga-reader"
  komga_port     = 25600
  komga_url      = "reader.${var.public_domain}"
  komga_share    = "ebooks-comics"
  komga_common_labels = {
    part-of = "reader"
  }
  komga_app_labels = merge(local.komga_common_labels, {
    app       = local.komga_app_name
    component = "app"
  })
}

resource "kubernetes_namespace_v1" "komga" {
  metadata {
    name = local.komga_app_name
  }
}

resource "kubernetes_persistent_volume_claim_v1" "komga_config" {
  metadata {
    name      = "komga-config"
    namespace = kubernetes_namespace_v1.komga.metadata[0].name
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
  metadata {
    name      = "komga-data"
    namespace = kubernetes_namespace_v1.komga.metadata[0].name
    labels = merge(local.komga_common_labels, {
      component = "data"
    })
  }

  spec {
    access_modes = [var.existing_nfs_share[local.komga_share].access_mode]
    resources {
      requests = {
        storage = var.existing_nfs_share[local.komga_share].size
      }
    }
    volume_name        = kubernetes_persistent_volume_v1.data_volumes[local.komga_share].metadata[0].name
    storage_class_name = kubernetes_storage_class_v1.manual.metadata[0].name
  }
}

resource "kubernetes_deployment_v1" "komga" {
  metadata {
    name      = local.komga_app_name
    namespace = kubernetes_namespace_v1.komga.metadata[0].name
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
          run_as_user            = var.existing_nfs_share[local.komga_share].user_uid
          run_as_group           = var.existing_nfs_share[local.komga_share].group_uid
          fs_group               = var.existing_nfs_share[local.komga_share].group_uid
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
            claim_name = kubernetes_persistent_volume_claim_v1.komga_config.metadata[0].name
          }
        }

        volume {
          name = "data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.komga_data.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "komga" {
  metadata {
    name      = local.komga_app_name
    namespace = kubernetes_namespace_v1.komga.metadata[0].name
    labels = merge(local.komga_common_labels, {
      component = "service"
    })
  }

  spec {
    selector = kubernetes_deployment_v1.komga.metadata[0].labels

    port {
      port        = 80
      target_port = local.komga_port
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_ingress_v1" "komga" {
  metadata {
    name      = local.komga_app_name
    namespace = kubernetes_namespace_v1.komga.metadata[0].name
    annotations = {
      "kubernetes.io/tls-acme"      = "true"
      "cert-manager.io/common-name" = local.komga_url
      "cert-manager.io/dns-names"   = local.komga_url
    }
    labels = merge(local.komga_common_labels, {
      component = "ingress"
    })
  }

  spec {
    rule {
      host = local.komga_url

      http {
        path {
          path = "/"
          backend {
            service {
              name = kubernetes_service_v1.komga.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }

    tls {
      hosts       = [local.komga_url]
      secret_name = "${local.komga_app_name}-tls" # must match a TLS secret in the same namespace
    }
  }
}