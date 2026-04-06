locals {
  vault_url = "vault.${var.private_domain}"
}

module "onepassword" {
  depends_on = [helm_release.metrics-server]

  source                  = "../modules/1password-connect"
  credentials_json_base64 = var.onepassword_credentials_json_base64
}

module "csi-secret-store" {
  source = "../modules/csi-secret-store"
}

module "vault-install" {
  depends_on = [module.csi-secret-store]
  source     = "../modules/hashicorp-vault-install"

  install_onepassword_plugin = true

  url = local.vault_url
  ingress_annotations = {
    "kubernetes.io/tls-acme"                       = "true"
    "cert-manager.io/cluster-issuer"               = var.private_cert_issuer
    "cert-manager.io/common-name"                  = local.vault_url
    "cert-manager.io/dns-names"                    = local.vault_url
    "nginx.ingress.kubernetes.io/backend-protocol" = "HTTPS"
  }

  security_context = {
    user_id  = var.vault_user_id
    group_id = var.vault_group_id
  }

  persistent_storage_class_name = module.csi-driver-nfs[0].persistent_storage_class
}


module "vault" {
  source = "../modules/hashicorp-vault-configure"

  onepassword_connect = {
    token = var.onepassword_connect_token
    host  = module.onepassword.kubernetes_svc
  }

  address = module.vault-install.kubernetes_svc

  pki = {
    ca_pembundle = var.vault_apps_cert_pembundle
    path         = "pki/apps/root"
    role_name    = "apps-tamrieltower-local"
  }
}
