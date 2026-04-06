locals {
  seaweedfs_s3api_url = "s3api.${var.private_domain}"
  seaweedfs_admin_url = "seaweedfs.${var.private_domain}"
}

module "seaweedfs" {
  source = "../modules/seaweedfs"

  buckets = [
    {
      name       = "terraform"
      objectLock = true
      ttl        = "90d"
    },
    {
      name = "velero"
      ttl  = "30d"
    }
  ]

  vault_password = {
    vault_address          = var.vault_address_internal
    vault_csi_ca_cert_path = var.vault_csi_ca_cert_path
    secret_path            = format("%s/seaweedfs", var.onepassword_vault_path)
  }

  security_context = {
    user_id  = var.objstore_credentials.user_id
    group_id = var.objstore_credentials.group_id
  }

  s3api_url = local.seaweedfs_s3api_url
  s3api_ingress_annotations = {
    "nginx.ingress.kubernetes.io/proxy-body-size" = "50m"
    "kubernetes.io/tls-acme"                      = "true"
    "cert-manager.io/cluster-issuer"              = var.private_cert_issuer
    "cert-manager.io/common-name"                 = local.seaweedfs_s3api_url
    "cert-manager.io/dns-names"                   = local.seaweedfs_s3api_url
  }
  admin_ui_url = local.seaweedfs_admin_url
  admin_ui_ingress_annotations = {
    "kubernetes.io/tls-acme"         = "true"
    "cert-manager.io/cluster-issuer" = var.private_cert_issuer
    "cert-manager.io/common-name"    = local.seaweedfs_admin_url
    "cert-manager.io/dns-names"      = local.seaweedfs_admin_url
  }
  persistent_storage_class_name = var.persistent_storage_class
}
