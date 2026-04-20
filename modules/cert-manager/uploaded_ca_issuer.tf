# Run into the bug https://github.com/hashicorp/terraform-provider-kubernetes/issues/2833
# Workaround was to add data_wo_revision

resource "kubernetes_secret_v1" "uploaded_ca" {
  count = var.uploaded_ca_issuer != null ? 1 : 0
  metadata {
    name      = "${var.uploaded_ca_issuer.issuer_name}-ca"
    namespace = kubernetes_namespace_v1.this.metadata[0].name
    labels    = merge(local.labels, { component = "self-signed-cert" })
  }

  type = "kubernetes.io/tls"

  data_wo = {
    "tls.crt" = var.uploaded_ca_issuer.certificate_cert
    "tls.key" = var.uploaded_ca_issuer.certificate_key
  }

  data_wo_revision = 1
}

resource "kubernetes_manifest" "uploaded_ca_issuer" {
  depends_on = [helm_release.this]
  count      = var.uploaded_ca_issuer != null ? 1 : 0

  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name   = var.uploaded_ca_issuer.issuer_name
      labels = merge(local.labels, { component = "self-signed-cert" })
    }
    spec = {
      ca = {
        secretName = kubernetes_secret_v1.uploaded_ca[0].metadata[0].name
      }
    }
  }
}
