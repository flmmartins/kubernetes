locals {
  defaut_cert_issuer_name = "apps-tamrieltower-local"
}

resource "vault_kubernetes_auth_backend_role" "cert-manager" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "cert-manager"
  bound_service_account_names      = ["cert-manager"]
  bound_service_account_namespaces = ["cert-manager"]
  token_max_ttl                    = 1440 #24H
  token_policies                   = [vault_policy.issuer-apps-tamrieltower-local.name]
}

resource "helm_release" "cert-manager" {
  name             = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true
  repository       = "https://charts.jetstack.io"
  version          = var.cert_manager_version
  chart            = "cert-manager"
  values = [
    <<-EOF
    crds:
      enabled: true
    replicaCount: 2
    podLabels:
      component: cert-manager
      part-of: certificates
    podDisruptionBudget:
      enabled: true
      minAvailable: 1
    affinity:
      podAntiAffinity:
        preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 100
          podAffinityTerm:
            labelSelector:
              matchExpressions:
              - key: component
                operator: In
                values:
                - cert-manager
            topologyKey: kubernetes.io/hostname
    ingressShim:
      defaultIssuerName: ${local.defaut_cert_issuer_name}
      defaultIssuerKind: ClusterIssuer
      defaultIssuerGroup: cert-manager.io
  EOF
  ]
}

resource "kubernetes_secret_v1" "cert-manager-sa-token" {
  metadata {
    name      = "cert-manager-sa-token"
    namespace = helm_release.cert-manager.metadata[0].namespace
    annotations = {
      "kubernetes.io/service-account.name" = "cert-manager"
    }
    labels = {
      part-of   = "certificates"
      component = "service-account"
    }
  }
  type = "kubernetes.io/service-account-token"
}

data "kubernetes_config_map" "vault_ca" {
  metadata {
    name      = "kube-root-ca.crt"
    namespace = helm_release.cert-manager.metadata[0].namespace
  }
}

resource "kubernetes_manifest" "cert-manager-issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"

    metadata = {
      name = local.defaut_cert_issuer_name
      labels = {
        part-of   = "certificates"
        component = "issuer"
      }
    }

    spec = {
      vault = {
        server   = var.vault_address_internal
        path     = "${vault_mount.pki-apps-root.path}/sign/${vault_pki_secret_backend_role.apps-tamrieltower-local.name}"
        caBundle = base64encode(data.kubernetes_config_map.vault_ca.data["ca.crt"])
        auth = {
          kubernetes = {
            role = vault_kubernetes_auth_backend_role.cert-manager.role_name
            secretRef = {
              name = kubernetes_secret_v1.cert-manager-sa-token.metadata[0].name
              key  = "token"
            }
          }
        }
      }
    }
  }
}
