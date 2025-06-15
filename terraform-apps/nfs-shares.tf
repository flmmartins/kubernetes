# Necessary to create because otherwise apps would try to use dynamic provisioning
resource "kubernetes_storage_class_v1" "manual" {
  metadata {
    name = "manual"
  }

  storage_provisioner    = "kubernetes.io/no-provisioner"
  volume_binding_mode    = "WaitForFirstConsumer"
  reclaim_policy         = "Retain"
  allow_volume_expansion = true
}

resource "kubernetes_persistent_volume_v1" "data_volumes" {
  for_each = var.existing_nfs_share
  metadata {
    name = each.key
  }

  spec {
    capacity = {
      storage = each.value.size
    }

    access_modes = [each.value.access_mode]

    persistent_volume_reclaim_policy = "Retain"
    storage_class_name               = kubernetes_storage_class_v1.manual.metadata[0].name

    persistent_volume_source {
      csi {
        driver        = "nfs.csi.k8s.io"
        volume_handle = each.key
        volume_attributes = {
          server = var.nfs_ip
          share  = each.value.path
        }
      }
    }
  }
}