resource "vault_kubernetes_auth_backend_role" "pki-issuer" {
  count = var.pki != null ? 1 : 0

  role_name                        = "pki-issuer"
  bound_service_account_names      = [var.pki.certmanager_sa.name]
  bound_service_account_namespaces = [var.pki.certmanager_sa.namespace]
  token_max_ttl                    = 1440 #24H
  token_policies                   = [vault_policy.pki[0].name]
}

resource "kubernetes_manifest" "pki_issuer" {
  count = var.pki != null ? 1 : 0

  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"

    metadata = {
      name   = "vault-issuer"
      labels = merge(local.labels, { component = "cert-manager-issuer" })
    }

    spec = {
      vault = {
        server   = var.address
        path     = "${vault_mount.pki[0].path}/sign/${vault_pki_secret_backend_role.pki[0].name}"
        caBundle = var.pki.vault_internal_ca
        # In order to cert manager to communicate with vault internally we need ca
        auth = {
          kubernetes = {
            role = vault_kubernetes_auth_backend_role.pki-issuer[0].role_name
            secretRef = {
              name = var.pki.certmanager_sa.secret
              key  = "token"
            }
          }
        }
      }
    }
  }
}
