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

  vault_pki_issuer = {
    ca_file   = base64encode(var.internal_ca_certificate)
    server    = module.vault-install.kubernetes_svc
    sign_path = module.vault.pki_sign_path
    policy    = module.vault.pki_policy
  }
}

