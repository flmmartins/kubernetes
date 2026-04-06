
module "velero" {
  source = "../modules/velero"

  snapshots_enabled = false
  backup_storage_locations = [
    {
      name = "talos-truenas"
      config = {
        region = "seaweedfs"
        s3Url  = module.seaweedfs.s3_kubernetes_svc
      }
    }
  ]

  vault_password = {
    vault_address          = var.vault_address_internal
    vault_csi_ca_cert_path = var.vault_csi_ca_cert_path
    secret_path            = format("%s/velero", var.onepassword_vault_path)
  }
}
