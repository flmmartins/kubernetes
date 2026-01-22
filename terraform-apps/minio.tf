locals {
  minio_sa                      = "minio"
  minio_credentials_secret_name = "minio"
  minio_certificate_secret_name = "minio-tls"
  minio_api_hostname            = "minio-api.${var.private_domain}"
  minio_hostname                = "minio.${var.private_domain}"
  minio_common_labels = {
    "part-of" = "storage"
  }
}

resource "kubernetes_namespace_v1" "minio" {
  metadata {
    name = "minio"
  }
}

resource "vault_policy" "minio" {
  name   = "minio"
  policy = <<EOT
path "${var.onepassword_vault_path}/minio" {
  capabilities = ["read"]
}
EOT
}

resource "vault_kubernetes_auth_backend_role" "minio" {
  role_name                        = "minio"
  bound_service_account_names      = [local.minio_sa]
  bound_service_account_namespaces = [kubernetes_namespace_v1.minio.metadata[0].name]
  token_max_ttl                    = 1440 #24H
  token_policies                   = [vault_policy.minio.name]
}

resource "kubernetes_manifest" "minio_credentials" {
  manifest = {
    apiVersion = "secrets-store.csi.x-k8s.io/v1"
    kind       = "SecretProviderClass"

    metadata = {
      name      = local.minio_credentials_secret_name
      namespace = kubernetes_namespace_v1.minio.metadata[0].name
      labels    = merge(local.minio_common_labels, { component = "credentials" })
    }

    spec = {
      provider = "vault"
      parameters = {
        roleName        = vault_kubernetes_auth_backend_role.minio.role_name
        vaultAddress    = var.vault_address_internal
        vaultCACertPath = var.vault_csi_ca_cert_path #TLS mounted on CSI pod
        objects         = <<EOT
- objectName: password
  secretPath: ${var.onepassword_vault_path}/${local.minio_credentials_secret_name}
  secretKey: password
- objectName: user
  secretPath: ${var.onepassword_vault_path}/${local.minio_credentials_secret_name}
  secretKey: username
        EOT
      }
      # Will become the following K8s secret - Secret needs to have rootPassword and user
      secretObjects = [{
        secretName = local.minio_credentials_secret_name
        type       = "Opaque"
        data = [
          {
            objectName = "password"
            key        = "rootPassword"
          },
          {
            objectName = "user"
            key        = "rootUser"
          }
        ]
      }]
    }
  }
}

resource "kubernetes_manifest" "minio_certificate" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = local.minio_certificate_secret_name
      namespace = kubernetes_namespace_v1.minio.metadata[0].name
      labels    = merge(local.minio_common_labels, { component = "certificate" })
    }
    spec = {
      secretName  = local.minio_certificate_secret_name
      duration    = "2160h" # 90d
      renewBefore = "360h"  # 15d
      commonName  = local.minio_hostname
      dnsNames = [
        "*.minio.svc.cluster.local",
        "*.minio.svc",
        "*.minio-svc.minio.svc",
        "*.minio",
        "localhost",
        local.minio_api_hostname,
        local.minio_hostname
      ]
      issuerRef = {
        name = var.private_cert_issuer
        kind = "ClusterIssuer"
      }
    }
  }
}


resource "helm_release" "minio" {
  name       = "minio"
  namespace  = kubernetes_namespace_v1.minio.metadata[0].name
  repository = "https://charts.min.io"
  version    = var.minio_chart_version
  chart      = "minio"
  values = [
    <<-EOF
    minioAPIPort: "9000"
    minioConsolePort: "9001"
    replicas: 2
    existingSecret: ${kubernetes_manifest.minio_credentials.manifest.metadata.name}
    additionalLabels: ${jsonencode(merge(local.minio_common_labels, { "component" = "minio" }))}
    # By default minio requires tons of memory
    resources:
      requests:
        memory: 100Mi
      limits:
        memory: 400Mi
    tls:
      enabled: true
      ## Create a secret with private.key and public.crt files and pass that here. Ref: https://github.com/minio/minio/tree/master/docs/tls/kubernetes#2-create-kubernetes-secret
      certSecret: ${kubernetes_manifest.minio_certificate.manifest.metadata.name}
      publicCrt: tls.crt
      privateKey: tls.key
    # It will create volume x replicas for redudant storage
    persistence: {
      enabled: "true",
      storageClass: ${var.persistent_storage_class},
      size: 5Gi
    }
    ingress:
      enabled: true
      annotations:
        nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
      hosts:
      - ${local.minio_api_hostname}
      tls:
      - hosts:
        - ${local.minio_api_hostname}
        secretName: ${kubernetes_manifest.minio_certificate.manifest.metadata.name}
    consoleIngress:
      enabled: true
      annotations:
        nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
      hosts:
      - ${local.minio_hostname}
      tls:
      - hosts:
        - ${local.minio_hostname}
        secretName: ${kubernetes_manifest.minio_certificate.manifest.metadata.name}
    serviceAccount:
      create: true
      name: ${local.minio_sa}
    # Set user and group so it can create files in the volume with those
    securityContext:
      enabled: true
      runAsUser: ${var.minio.user_uid}
      runAsGroup: ${var.minio.group_uid}
      fsGroup: ${var.minio.group_uid}
      fsGroupChangePolicy: "OnRootMismatch"
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
                - minio
            topologyKey: kubernetes.io/hostname
    # Volumes are defined only so CSI Secret Driver can run
    extraVolumeMounts:
    - name: csi-secret-driver-for-minio-credentials
      mountPath: '/mnt/secrets-store'
      readOnly: true
    extraVolumes:
    - name: csi-secret-driver-for-minio-credentials
      csi:
        driver: 'secrets-store.csi.k8s.io'
        readOnly: true
        volumeAttributes:
          secretProviderClass: ${kubernetes_manifest.minio_credentials.manifest.metadata.name}
  EOF
  ]
}