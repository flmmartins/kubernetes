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
    random = {
      source = "hashicorp/random"
    }
  }
}

locals {
  name = "seaweedfs"
  labels = {
    part-of = "object_storage"
  }
  s3_k8s_secret_name    = "seaweedfs-s3"
  admin_k8s_secret_name = "seaweedfs-admin"
  service_account       = "seaweedfs"
}

resource "kubernetes_namespace_v1" "this" {
  metadata {
    name   = local.name
    labels = local.labels
  }
}

# TODO: Test random password later
ephemeral "random_password" "s3_admin_access_key" {
  count = var.vault_password == null ? 1 : 0

  length  = 20
  special = false
  upper   = true
  lower   = false
  numeric = true
}

ephemeral "random_password" "s3_admin_secret_key" {
  count = var.vault_password == null ? 1 : 0

  length  = 40
  special = false
  upper   = true
  lower   = true
  numeric = true
}

resource "kubernetes_secret_v1" "s3" {
  count = var.vault_password == null ? 1 : 0

  metadata {
    name      = local.s3_k8s_secret_name
    namespace = kubernetes_namespace_v1.this.metadata[0].name
    labels    = merge(local.labels, { component = "credentials" })
  }

  data_wo = {
    seaweedfs_s3_config = jsonencode({
      identities = [
        {
          name = "admin"
          credentials = [
            {
              accessKey = ephemeral.random_password.s3_admin_access_key[0].result
              secretKey = ephemeral.random_password.s3_admin_secret_key[0].result
            }
          ]
          actions = ["Admin", "Read", "Write"]
        }
      ]
    })
  }
}

resource "vault_policy" "this" {
  count = var.vault_password != null ? 1 : 0

  name   = local.name
  policy = <<EOT
path "${var.vault_password.secret_path}" { capabilities = ["read"] }
EOT
}

resource "vault_kubernetes_auth_backend_role" "this" {
  count = var.vault_password != null ? 1 : 0

  role_name                        = local.name
  bound_service_account_names      = [local.service_account]
  bound_service_account_namespaces = [kubernetes_namespace_v1.this.metadata[0].name]
  token_max_ttl                    = 1440 #24H
  token_policies                   = [vault_policy.this[0].name]
}

resource "kubernetes_manifest" "this" {
  count = var.vault_password != null ? 1 : 0
  manifest = {
    apiVersion = "secrets-store.csi.x-k8s.io/v1"
    kind       = "SecretProviderClass"

    metadata = {
      name      = local.name
      namespace = kubernetes_namespace_v1.this.metadata[0].name
      labels    = merge(local.labels, { component = "credentials" })
    }

    spec = {
      provider = "vault"
      parameters = {
        roleName        = vault_kubernetes_auth_backend_role.this[0].role_name
        vaultAddress    = var.vault_password.vault_address
        vaultCACertPath = var.vault_password.vault_csi_ca_cert_path
        objects         = <<EOT
- objectName: admin-username
  secretPath: ${var.vault_password.secret_path}
  secretKey: ${var.vault_password.admin_username_field}
- objectName: admin-password
  secretPath: ${var.vault_password.secret_path}
  secretKey: ${var.vault_password.admin_password_field}
- objectName: s3-credentials-json
  secretPath: ${var.vault_password.secret_path}
  secretKey: ${var.vault_password.s3_admin_credentials_json_field}
        EOT
      }
      secretObjects = [{
        secretName = local.s3_k8s_secret_name
        type       = "Opaque"
        data = [
          {
            objectName = "s3-credentials-json"
            key        = "seaweedfs_s3_config" # This key has to be hardcoded bc it's the only that seadweed accepts
          }
        ]
        },
        {
          secretName = local.admin_k8s_secret_name
          type       = "Opaque"
          data = [
            {
              objectName = "admin-username"
              key        = var.vault_password.admin_username_field
            },
            {
              objectName = "admin-password"
              key        = var.vault_password.admin_password_field
            }
          ]
      }]
    }
  }
}

resource "helm_release" "this" {
  name       = local.name
  repository = "https://seaweedfs.github.io/seaweedfs/helm"
  chart      = "seaweedfs"
  version    = var.chart_version
  namespace  = kubernetes_namespace_v1.this.metadata[0].name

  values = [<<-EOF
    podLabels: ${jsonencode(local.labels)}

    # -------------------------------------------------------------------------
    # Master — Manages volume locations and allocation
    # -------------------------------------------------------------------------
    master:
      enabled: true
      replicas: 1
      %{~if var.security_context != null~}
      podSecurityContext:
        runAsUser: ${var.security_context.user_id}
        runAsGroup: ${var.security_context.group_id}
        fsGroup: ${var.security_context.group_id}
        fsGroupChangePolicy: OnRootMismatch
        seccompProfile:
          type: RuntimeDefault
      %{~endif~}
      data:
        type: persistentVolumeClaim
        size: 1Gi
      logs:
        type: persistentVolumeClaim
        size: 1Gi
      resources:
        requests:
          cpu: ${var.master_cpu_request}
          memory: ${var.master_memory_request}
        limits:
          cpu: ${var.master_cpu_limit}
          memory: ${var.master_memory_limit}
      affinity: |
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
            - weight: 100
              podAffinityTerm:
                labelSelector:
                  matchExpressions:
                    - key: app.kubernetes.io/component
                      operator: In
                      values:
                        - master
                topologyKey: kubernetes.io/hostname
    # -------------------------------------------------------------------------
    # Volume — Manage disks
    # -------------------------------------------------------------------------
    volume:
      enabled: true
      replicas: 2
    %{~if var.security_context != null~}
      podSecurityContext:
        runAsUser: ${var.security_context.user_id}
        runAsGroup: ${var.security_context.group_id}
        fsGroup: ${var.security_context.group_id}
        fsGroupChangePolicy: OnRootMismatch
        seccompProfile:
          type: RuntimeDefault
      %{~endif~}
      dataDirs:
        - name: data
          type: "persistentVolumeClaim"
          size: ${var.volume_storage_size}
          storageClass: ${var.persistent_storage_class_name}
          maxVolumes: 0   # 0 = auto-configure based on disk size
      resources:
        requests:
          cpu: ${var.volume_cpu_request}
          memory: ${var.volume_memory_request}
        limits:
          cpu: ${var.volume_cpu_limit}
          memory: ${var.volume_memory_limit}
      affinity: |
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
            - weight: 100
              podAffinityTerm:
                labelSelector:
                  matchExpressions:
                    - key: app.kubernetes.io/component
                      operator: In
                      values:
                        - volume
                topologyKey: kubernetes.io/hostname
    # -------------------------------------------------------------------------
    # Filer — provides directory structure and metadata for S3 objects.
    # S3 API runs on top of the Filer. Required for S3 support.
    # -------------------------------------------------------------------------
    filer:
      enabled: true
      replicas: 2
    %{~if var.security_context != null~}
      podSecurityContext:
        runAsUser: ${var.security_context.user_id}
        runAsGroup: ${var.security_context.group_id}
        fsGroup: ${var.security_context.group_id}
        fsGroupChangePolicy: OnRootMismatch
        seccompProfile:
          type: RuntimeDefault
      %{~endif~}
      data:
        type: "persistentVolumeClaim"
        size: ${var.filer_storage_size}
        storageClass: ${var.persistent_storage_class_name}
      logs:
        type: persistentVolumeClaim
        size: 1G
      resources:
        requests:
          cpu: ${var.filer_cpu_request}
          memory: ${var.filer_memory_request}
        limits:
          cpu: ${var.filer_cpu_limit}
          memory: ${var.filer_memory_limit}
      affinity: |
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
            - weight: 100
              podAffinityTerm:
                labelSelector:
                  matchExpressions:
                    - key: app.kubernetes.io/component
                      operator: In
                      values:
                        - filer
                topologyKey: kubernetes.io/hostname
    # -------------------------------------------------------------------------
    # S3
    # -------------------------------------------------------------------------
    s3:
      enabled: true
      port: ${var.s3api_port}        # internal S3 API port
      enableAuth: true  # enables access key / secret key authentication
      existingConfigSecret: ${local.s3_k8s_secret_name}
      serviceAccountName: ${local.service_account} #this is the default account but chart has a bug
    %{~if var.vault_password != null~}
      extraVolumes: |
        - name: csi-secret-driver-for-seaweedfs-credentials
          csi:
            driver: secrets-store.csi.k8s.io
            readOnly: true  
            volumeAttributes:
              secretProviderClass: ${kubernetes_manifest.this[0].manifest.metadata.name}
      extraVolumeMounts: |
        - name: csi-secret-driver-for-seaweedfs-credentials
          mountPath: /mnt/secrets-store
          readOnly: true
    %{~endif~}
      logs:
        type: persistentVolumeClaim
        size: 1G
      resources:
        requests:
          cpu: ${var.s3_cpu_request}
          memory: ${var.s3_memory_request}
        limits:
          cpu: ${var.s3_cpu_limit}
          memory: ${var.s3_memory_limit}
      ingress:
        enabled: true
        className: "nginx"
        annotations: ${jsonencode(var.s3api_ingress_annotations)}
        host: "${var.s3api_url}"
        tls:
        - hosts:
          - ${var.s3api_url}
          secretName: ${split(".", var.s3api_url)[0]}-tls
      affinity: |
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
            - weight: 100
              podAffinityTerm:
                labelSelector:
                  matchExpressions:
                    - key: app.kubernetes.io/component
                      operator: In
                      values:
                        - s3
                topologyKey: kubernetes.io/hostname
      createBuckets: ${jsonencode(var.buckets)}

    # -------------------------------------------------------------------------
    # Admin UI
    # -------------------------------------------------------------------------
    admin:
      enabled: true
      port: ${var.admin_ui_port}
    %{~if var.vault_password != null~}
      secret:
        existingSecret: ${local.admin_k8s_secret_name}
        userKey: ${var.vault_password.admin_username_field}
        pwKey: ${var.vault_password.admin_password_field}
    %{~endif~}
      ingress:
        enabled: true
        className: "nginx"
        annotations: ${jsonencode(var.admin_ui_ingress_annotations)}
        host: "${var.admin_ui_url}"
        tls:
          - hosts:
              - ${var.admin_ui_url}
            secretName: ${split(".", var.admin_ui_url)[0]}-tls
      resources:
        requests:
          cpu: ${var.admin_cpu_request}
          memory: ${var.admin_memory_request}
        limits:
          cpu: ${var.admin_cpu_limit}
          memory: ${var.admin_memory_limit}

    # -------------------------------------------------------------------------
    # Disable unused components
    # -------------------------------------------------------------------------
    worker:
      enabled: false
  EOF
  ]
}
