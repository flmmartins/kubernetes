locals {
  default_cert_issuer_name = "letsencrypt-issuer"
  cloudflare_secret_name   = "cloudflare-api-token"
  cloudflare_secret_key    = "password"
}

resource "vault_policy" "cloudflare_api_token" {
  name   = local.cloudflare_secret_name
  policy = <<EOT
path "op/vaults/+/items/${local.cloudflare_secret_name}" {
  capabilities = ["read"]
}
EOT
}

resource "kubernetes_namespace_v1" "cert-manager" {
  metadata {
    name = "cert-manager"
  }
}

resource "vault_kubernetes_auth_backend_role" "cert-manager" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "cert-manager"
  bound_service_account_names      = ["cert-manager"]
  bound_service_account_namespaces = ["cert-manager"]
  token_max_ttl                    = 1440 #24H
  token_policies                   = [vault_policy.issuer-apps-tamrieltower-local.name, vault_policy.cloudflare_api_token.name]
}

resource "helm_release" "cert-manager" {
  name       = "cert-manager"
  namespace  = kubernetes_namespace_v1.cert-manager.metadata[0].name
  repository = "https://charts.jetstack.io"
  version    = var.cert_manager_version
  chart      = "cert-manager"
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
    resources:
      requests:
        memory: 25Mi
        cpu: 5m
      limits:
        memory: 100Mi
        cpu: 20m
    ingressShim:
      defaultIssuerName: ${local.default_cert_issuer_name}
      defaultIssuerKind: ClusterIssuer
      defaultIssuerGroup: cert-manager.io
    webhook:
      resources:
        requests:
          memory: 25Mi
          cpu: 5m
        limits:
          memory: 100Mi
          cpu: 20m
    cainjector:
      resources:
        requests:
          memory: 25Mi
          cpu: 5m
        limits:
          memory: 100Mi
          cpu: 20m
    # Volumes are defined only so CSI Secret Driver can run
    volumeMounts:
      - name: csi-secret-driver-for-cloudflare-token
        mountPath: '/mnt/secrets-store'
        readOnly: true
    volumes:
      - name: csi-secret-driver-for-cloudflare-token
        csi:
          driver: 'secrets-store.csi.k8s.io'
          readOnly: true
          volumeAttributes:
            secretProviderClass: ${kubernetes_manifest.cloudflare-api-token.manifest.metadata.name}
  EOF
  ]
}

resource "kubernetes_secret_v1" "cert-manager-sa-token" {
  metadata {
    name      = "cert-manager-sa-token"
    namespace = kubernetes_namespace_v1.cert-manager.metadata[0].name
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

data "kubernetes_config_map_v1" "vault_ca" {
  metadata {
    name      = "kube-root-ca.crt"
    namespace = kubernetes_namespace_v1.cert-manager.metadata[0].name
  }
}

resource "kubernetes_manifest" "private_issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"

    metadata = {
      name = var.private_cert_issuer
      labels = {
        part-of   = "certificates"
        component = "issuer"
      }
    }

    spec = {
      vault = {
        server   = var.vault_address_internal
        path     = "${vault_mount.pki-apps-root.path}/sign/${vault_pki_secret_backend_role.apps-tamrieltower-local.name}"
        caBundle = base64encode(data.kubernetes_config_map_v1.vault_ca.data["ca.crt"])
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

resource "kubernetes_manifest" "cloudflare-api-token" {
  depends_on = [helm_release.vault]
  manifest = {
    apiVersion = "secrets-store.csi.x-k8s.io/v1"
    kind       = "SecretProviderClass"

    metadata = {
      name      = local.cloudflare_secret_name
      namespace = kubernetes_namespace_v1.cert-manager.metadata[0].name
    }

    spec = {
      provider = "vault"
      parameters = {
        roleName        = vault_kubernetes_auth_backend_role.cert-manager.role_name
        vaultAddress    = var.vault_address_internal
        vaultCACertPath = "${local.vault_csi_cert_mounth_path}/vault.ca"
        objects         = <<EOT
- objectName: ${local.cloudflare_secret_name}
  secretPath: ${var.onepassword_vault_path}/items/${local.cloudflare_secret_name}
  secretKey: ${local.cloudflare_secret_key}
        EOT
      }
      # Will become the following K8s secret
      secretObjects = [{
        secretName = local.cloudflare_secret_name
        type       = "Opaque"
        data = [{
          objectName = local.cloudflare_secret_name
          key        = local.cloudflare_secret_key
        }]
      }]
    }
  }
}

resource "kubernetes_manifest" "letsencrypt_issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"

    metadata = {
      name = local.default_cert_issuer_name
      labels = {
        part-of   = "certificates"
        component = "issuer"
      }
    }

    spec = {
      acme = {
        server = "https://acme-v02.api.letsencrypt.org/directory"
        email  = var.cloudflare_email
        privateKeySecretRef = {
          name = "letsencrypt-dns-account-key"
        }
        solvers = [{
          dns01 = {
            cloudflare = {
              # Watch out - this can be either api key or token
              apiTokenSecretRef = {
                name = local.cloudflare_secret_name
                key  = local.cloudflare_secret_key
              }
            }
          }
        }]
      }
    }
  }
}