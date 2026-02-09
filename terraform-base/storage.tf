locals {
  csi_driver_nfs_labels = {
    part-of = "truenas"
  }
}

module "csi-driver-nfs" {
  count = var.enable_csi_nfs == true ? 1 : 0

  source = "../modules/csi-driver-nfs"

  labels = local.csi_driver_nfs_labels
  server = var.nfs.ip
  folder = var.nfs.folder
}
