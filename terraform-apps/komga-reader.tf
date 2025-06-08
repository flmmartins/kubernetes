locals {
  komga_app_name = "komga-reader"
  komga_port     = 25600
  komga_url      = "reader.${var.apps_domain}"
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
    
    storage_class_name = "persistent"
  }
}

resource "kubernetes_persistent_volume_claim_v1" "komga_data" {
  metadata {
    name = "komga-data"
    namespace = kubernetes_namespace_v1.komga.metadata[0].name
    labels = merge(local.komga_common_labels, {
      component = "data"
    })
  }

  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = "50Gi"
      }
    }
    volume_name        = kubernetes_persistent_volume_v1.ebooks_comics.metadata[0].name
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
        container {
          name  = "komga"
          image = "gotson/komga:${var.komga_image_version}"

          security_context {
            run_as_user     = var.storage_user_uid
            run_as_group    = var.storage_user_uid
            run_as_non_root = true
          }

          port {
            container_port = local.komga_port
          }

          volume_mount {
            name       = "config"
            mount_path = "/config"
          }

          volume_mount {
            name       = "data"
            mount_path = "/books"
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
    name        = local.komga_app_name
    namespace   = kubernetes_namespace_v1.komga.metadata[0].name
    annotations = {
      "kubernetes.io/tls-acme"      = "true"
      "cert-manager.io/common-name" = local.komga_url
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
          path      = "/"
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
      secret_name = "${local.komga_app_name}-tls"  # must match a TLS secret in the same namespace
    }
  }
}