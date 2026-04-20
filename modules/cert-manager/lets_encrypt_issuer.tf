# TODO: Test passing password later
resource "kubernetes_secret_v1" "dns_provider" {
  count = var.letsencrypt_issuer.dns_provider_vault_password == null ? 1 : 0

  metadata {
    name      = local.dns_provider_secret
    namespace = kubernetes_namespace_v1.this.metadata[0].name
    labels    = merge(local.labels, { component = "letsencrypt-cert" })
  }

  data_wo = {
    password = var.letsencrypt_issuer.dns_provider.api_token
  }
}

resource "vault_policy" "dns_provider" {
  count = var.letsencrypt_issuer.dns_provider_vault_password != null ? 1 : 0

  name   = local.dns_provider_secret
  policy = <<EOT
path "${var.letsencrypt_issuer.dns_provider_vault_password.secret_path}" { capabilities = ["read"] }
EOT
}

resource "kubernetes_manifest" "dns_provider" {
  count = var.letsencrypt_issuer.dns_provider_vault_password != null ? 1 : 0
  manifest = {
    apiVersion = "secrets-store.csi.x-k8s.io/v1"
    kind       = "SecretProviderClass"

    metadata = {
      name      = local.dns_provider_secret
      namespace = kubernetes_namespace_v1.this.metadata[0].name
      labels    = merge(local.labels, { component = "letsencrypt-cert" })
    }

    spec = {
      provider = "vault"
      parameters = {
        roleName        = vault_kubernetes_auth_backend_role.this[0].role_name
        vaultAddress    = var.letsencrypt_issuer.dns_provider_vault_password.vault_address
        vaultCACertPath = var.letsencrypt_issuer.dns_provider_vault_password.vault_csi_ca_cert_path
        objects         = <<EOT
- objectName: ${local.dns_provider_secret}
  secretPath: ${var.letsencrypt_issuer.dns_provider_vault_password.secret_path}
  secretKey: ${var.letsencrypt_issuer.dns_provider_vault_password.password_field}
        EOT
      }
      # Will become the following K8s secret
      secretObjects = [{
        secretName = local.dns_provider_secret
        type       = "Opaque"
        data = [{
          objectName = local.dns_provider_secret
          key        = "password"
        }]
      }]
    }
  }
}

resource "kubernetes_manifest" "letsencrypt_issuer" {
  depends_on = [
    helm_release.this,
    kubernetes_secret_v1.dns_provider,
    kubernetes_manifest.dns_provider,
  ]

  count = var.letsencrypt_issuer != null ? 1 : 0

  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name   = var.letsencrypt_issuer.issuer_name
      labels = merge(local.labels, { component = "letsencrypt-cert" })
    }
    spec = {
      acme = {
        server = "https://acme-v02.api.letsencrypt.org/directory"
        email  = var.letsencrypt_issuer.dns_provider.e-mail
        privateKeySecretRef = {
          name = "letsencrypt-dns-account-key"
        }
        solvers = [{
          dns01 = {
            "${var.letsencrypt_issuer.dns_provider.name}" = {
              # Watch out - this can be either api key or token
              apiTokenSecretRef = {
                name = local.dns_provider_secret
                key  = "password"
              }
            }
          }
        }]
      }
    }
  }
}
