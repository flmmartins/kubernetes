# Necessary to create because otherwise apps would try to use dynamic provisioning
resource "kubernetes_storage_class_v1" "manual" {
  metadata {
    name   = "manual"
  }

  storage_provisioner = "kubernetes.io/no-provisioner"
  volume_binding_mode = "WaitForFirstConsumer"
  reclaim_policy      = "Retain"
}

resource "kubernetes_persistent_volume_v1" "ebooks_comics" {
  metadata {
    name = var.nfs_share_ebooks_comics_vol_name
  }

  spec {
    capacity = {
      storage = "50Gi"
    }

    access_modes = ["ReadWriteMany"]

    persistent_volume_reclaim_policy = "Retain"
    storage_class_name               = kubernetes_storage_class_v1.manual.metadata[0].name

    persistent_volume_source {
      csi {
        driver       = "nfs.csi.k8s.io"
        volume_handle = var.nfs_share_ebooks_comics_vol_name
        volume_attributes = {
          server = var.nfs_ip
          share  = var.nfs_share_ebooks_comics
        }
      }
    }
  }
}