resource "kubernetes_secret_v1" "cert_manager_sa_token" {
  depends_on = [helm_release.this]

  count = var.vault_pki_issuer != null ? 1 : 0
  metadata {
    name      = "cert-manager-sa-token"
    namespace = kubernetes_namespace_v1.this.metadata[0].name
    annotations = {
      "kubernetes.io/service-account.name" = "cert-manager"
    }
    labels = merge(local.labels, { component = "vault-cert" })
  }
  type = "kubernetes.io/service-account-token"
}

resource "kubernetes_manifest" "vault_pki_issuer" {
  count = var.vault_pki_issuer != null ? 1 : 0

  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"

    metadata = {
      name   = var.vault_pki_issuer.issuer_name
      labels = merge(local.labels, { component = "vault-cert" })
    }

    spec = {
      vault = {
        server   = var.vault_pki_issuer.server
        path     = var.vault_pki_issuer.sign_path
        caBundle = var.vault_pki_issuer.ca_file
        auth = {
          kubernetes = {
            role = vault_kubernetes_auth_backend_role.this[0].role_name
            secretRef = {
              name = kubernetes_secret_v1.cert_manager_sa_token[0].metadata[0].name
              key  = "token"
            }
          }
        }
      }
    }
  }
}
