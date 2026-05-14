# From Client => Gateway = Client PKI cert is exchanged
# From Gateway => Vault = BackendTLSPolicy with vault internal certificates are used

# BackendTLS Policy requires the CA to be in configmap
resource "kubernetes_config_map_v1" "vault_internal_ca" {
  count = var.gateway != null ? 1 : 0

  metadata {
    name      = "vault-internal-ca"
    namespace = kubernetes_namespace_v1.this.metadata[0].name
  }

  data = {
    "ca.crt" = var.gateway.internal_ca_certificate
  }

}

# This tells the gateway to use TLS when connecting to the backend
resource "kubernetes_manifest" "backendtlspolicy_vault" {
  count = var.gateway != null ? 1 : 0

  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1alpha3"
    kind       = "BackendTLSPolicy"
    metadata = {
      name      = local.name
      namespace = kubernetes_namespace_v1.this.metadata[0].name
      labels    = merge(local.labels, { component = "backendtlspolicy" })
    }
    spec = {
      targetRefs = [
        {
          group = ""
          kind  = "Service"
          name  = local.vault_service
        }
      ]
      validation = {
        caCertificateRefs = [
          {
            group = ""
            kind  = "ConfigMap"
            name  = kubernetes_config_map_v1.vault_internal_ca[0].metadata[0].name
          }
        ]
        hostname = var.url
      }
    }
  }
}

resource "kubernetes_manifest" "httproute_vault" {
  count = var.gateway != null ? 1 : 0

  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = local.name
      namespace = kubernetes_namespace_v1.this.metadata[0].name
      labels    = merge(local.labels, { component = "httproute" })
    }
    spec = {
      parentRefs = [
        {
          name      = var.gateway.name
          namespace = var.gateway.namespace
        }
      ]
      hostnames = [var.url]
      rules = [
        {
          backendRefs = [
            {
              name = local.vault_service
              port = 8200
            }
          ]
        }
      ]
    }
  }
}
