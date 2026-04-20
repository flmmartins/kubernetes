terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    vault = {
      source = "hashicorp/vault"
    }
  }
}

locals {
  name = "cert-manager"
  labels = {
    part-of = "certificates"
  }
  dns_provider_secret = "${var.letsencrypt_issuer.dns_provider.name}-api-token"
  dns_policies        = var.letsencrypt_issuer.dns_provider_vault_password != null ? [vault_policy.dns_provider[0].name] : []
  pki_policies        = var.vault_pki_issuer != null ? [var.vault_pki_issuer.policy] : []
  vault_policies      = concat(local.dns_policies, local.pki_policies)
}

resource "vault_kubernetes_auth_backend_role" "this" {
  count = length(local.vault_policies) > 0 ? 1 : 0

  role_name                        = local.name
  bound_service_account_names      = ["cert-manager"]
  bound_service_account_namespaces = [kubernetes_namespace_v1.this.metadata[0].name]
  token_max_ttl                    = 1440 #24H
  token_policies                   = local.vault_policies
}

resource "kubernetes_namespace_v1" "this" {
  metadata {
    name   = local.name
    labels = local.labels
  }
}

resource "helm_release" "this" {
  name       = local.name
  namespace  = kubernetes_namespace_v1.this.metadata[0].name
  repository = "https://charts.jetstack.io"
  version    = var.chart_version
  chart      = "cert-manager"
  values = [
    <<-EOF
    crds:
      enabled: true
    replicaCount: 2
    podLabels: ${jsonencode(merge(local.labels, { "component" = "cert-manager" }))}
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
        memory: ${var.cert_manager_memory_request}
        cpu: ${var.cert_manager_cpu_request}
      limits:
        memory: ${var.cert_manager_memory_limit}
        cpu: ${var.cert_manager_cpu_limit}
    ingressShim:
      defaultIssuerName: ${var.default_cert_issuer}
      defaultIssuerKind: ClusterIssuer
      defaultIssuerGroup: cert-manager.io
    webhook:
      resources:
        requests:
          memory: ${var.cert_manager_webhook_memory_request}
          cpu: ${var.cert_manager_webhook_cpu_request}
        limits:
          memory: ${var.cert_manager_webhook_memory_limit}
          cpu: ${var.cert_manager_webhook_cpu_limit}
    cainjector:
      resources:
        requests:
          memory: ${var.cert_manager_cainjector_memory_request}
          cpu: ${var.cert_manager_cainjector_cpu_request}
        limits:
          memory: ${var.cert_manager_cainjector_memory_limit}
          cpu: ${var.cert_manager_cainjector_cpu_limit}
  %{~if var.letsencrypt_issuer.dns_provider_vault_password != null~}
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
            secretProviderClass: ${kubernetes_manifest.dns_provider[0].manifest.metadata.name}
  %{~endif~}
  EOF
  ]
}