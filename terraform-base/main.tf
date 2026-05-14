locals {
  vault_url = "vault.${var.private_domain}"
  csi_driver_nfs_labels = {
    part-of = "truenas"
  }
}

module "csi-driver-nfs" {
  count = var.enable_csi_nfs == true ? 1 : 0

  source = "../modules/csi-driver-nfs"

  labels = local.csi_driver_nfs_labels
  server = var.nfs_ip
  folder = var.nfs_folder
}

module "cert-manager" {
  source = "../modules/cert-manager"

  default_cert_issuer = "letsencrypt-issuer"

  letsencrypt_issuer = {
    issuer_name = "letsencrypt-issuer"
    dns_provider_vault_password = {
      vault_address = var.vault_address_internal
      secret_path   = format("%s/cloudflare-api-token", var.onepassword_vault_path)
    }
    dns_provider = {
      name   = "cloudflare"
      e-mail = var.cloudflare_email
    }
  }

  uploaded_ca_issuer = {
    certificate_cert = var.internal_ca_certificate
    certificate_key  = var.internal_ca_key
  }
}

resource "kubernetes_priority_class_v1" "priority_class_critical" {
  metadata {
    name = var.priority_class
  }

  value          = 900000000
  global_default = false
  description    = "Critical infrastructure pods"
}

module "metrics-server" {
  source = "../modules/metrics-server"
}

module "onepassword" {
  depends_on = [module.metrics-server]

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
  certificate_issuer         = module.cert-manager.uploaded_ca_issuer

  url = local.vault_url
  gateway = {
    name                    = var.gateway.name
    namespace               = var.gateway.namespace
    internal_ca_certificate = var.internal_ca_certificate
  }

  security_context = {
    user_id  = var.vault_user_id
    group_id = var.vault_group_id
  }

  persistent_storage_class_name = module.csi-driver-nfs[0].persistent_storage_class
  priority_class                = var.priority_class
}

module "vault" {
  source = "../modules/hashicorp-vault-configure"

  onepassword_connect = {
    token = var.onepassword_connect_token
    host  = module.onepassword.kubernetes_svc
  }

  address = module.vault-install.kubernetes_svc

  pki = {
    root_ca           = var.vault_apps_cert_pembundle
    path              = "pki/apps/root"
    role_name         = "apps-tamrieltower-local"
    vault_internal_ca = base64encode(var.internal_ca_certificate)
    certmanager_sa = {
      namespace = module.cert-manager.namespace
      name      = module.cert-manager.service_account_name
      secret    = module.cert-manager.service_account_secret_name
    }
  }
}

module "gateway-api" {
  source       = "../modules/gateway-api"
  uses_metallb = true
  istio_ip     = var.istio_ip
  gateway_certificates = [
    {
      hostname       = "*.${var.private_domain}"
      cluster_issuer = module.vault.vault_pki_issuer
    },
    {
      hostname       = "*.${var.public_domain}"
      cluster_issuer = module.cert-manager.letsencrypt_issuer
    }
  ]
  tcp_routes = [
    {
      name      = "plex-tcp"
      port      = 32400
      namespace = "plex"
    },
  ]
}
