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
  name = "velero"
  labels = {
    part-of = "backup"
  }
  velero_service_account_name = local.name
}

resource "terraform_data" "validate_credentials" {
  lifecycle {
    precondition {
      condition = (
        (var.vault_password != null) != (var.s3_credentials != null) != (var.create_backup_from_seaweedfs.cluster_name != null)
      )
      error_message = "Exactly one of vault_password or s3_credentials or seaweedfs.cluster_name must be defined, not all and not neither."
    }
  }
}

resource "kubernetes_namespace_v1" "this" {
  metadata {
    name   = local.name
    labels = local.labels
  }
}

# TODO: Test later
resource "kubernetes_secret_v1" "this" {
  count = var.vault_password == null && var.create_backup_from_seaweedfs == null ? 1 : 0

  metadata {
    name      = local.name
    namespace = kubernetes_namespace_v1.this.metadata[0].name
    labels    = merge(local.labels, { component = "credentials" })
  }

  data_wo = {
    cloud = <<-EOT
      [default]
      aws_access_key_id=${var.s3_credentials.access_key_id}
      aws_secret_access_key=${var.s3_credentials.secret_access_key}
    EOT
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
  bound_service_account_names      = [local.velero_service_account_name]
  bound_service_account_namespaces = [kubernetes_namespace_v1.this.metadata[0].name]
  token_max_ttl                    = 1440 #24H
  token_policies                   = [vault_policy.this[0].name]
}

module "velero_bucket" {
  count = var.create_backup_from_seaweedfs != null ? 1 : 0

  source    = "../seadweed-s3-bucket"
  seaweedfs = var.create_backup_from_seaweedfs
  application = {
    name      = local.name
    namespace = kubernetes_namespace_v1.this.metadata[0].name
  }
}

resource "helm_release" "this" {
  name        = local.name
  namespace   = kubernetes_namespace_v1.this.metadata[0].name
  repository  = "https://vmware-tanzu.github.io/helm-charts"
  version     = var.chart_version
  chart       = "velero"
  max_history = 10
  values = [
    <<-EOF
    schedules:
      daily-backup:
        schedule: ${var.backup_schedule}
        template:
          includedNamespaces:
          - "*"
    backupsEnabled: true
    snapshotsEnabled: ${var.snapshots_enabled}
    credentials:
    %{~if var.create_backup_from_seaweedfs == null~}
      useSecret: true
      existingSecret: ${local.name}
    %{~else~}
      useSecret: false
    %{~endif~}
    initContainers:
    - name: velero-plugin-for-aws
      image: velero/velero-plugin-for-aws:${var.aws_plugin_version}
      volumeMounts:
      - mountPath: /target
        name: plugins
    %{~if var.create_backup_from_seaweedfs != null~}
    - name: velero-plugin-credential-formatter
      image: alpine:latest
      command:
        - /bin/sh
        - -c
        - printf '[default]\naws_access_key_id=%s\naws_secret_access_key=%s\n' "$AWS_KEY" "$AWS_SECRET" > /credentials/cloud
      env:
      - name: AWS_KEY
        valueFrom:
          secretKeyRef:
            name: ${module.velero_bucket[0].secret_name}
            key: ${module.velero_bucket[0].secret_fields.access}
      - name: AWS_SECRET
        valueFrom:
          secretKeyRef:
            name: ${module.velero_bucket[0].secret_name}
            key: ${module.velero_bucket[0].secret_fields.secret}
      volumeMounts:
      - name: credentials
        mountPath: /credentials
    extraVolumes:
    - name: credentials
      emptyDir: {}
    extraVolumeMounts:
    - name: credentials
      mountPath: /credentials
    %{~endif~}
    configuration:
      backupStorageLocation: ${jsonencode([var.backup_storage_location])}
      %{~if var.create_backup_from_seaweedfs != null~}
      extraEnvVars:
      - name: AWS_SHARED_CREDENTIALS_FILE
        value: /credentials/cloud
      %{~endif~}
    serviceAccount:
      server:
        create: true
        name: ${local.velero_service_account_name}
    labels: ${jsonencode(merge(local.labels, { "component" = "velero" }))}
    podLabels: ${jsonencode(merge(local.labels, { "component" = "velero" }))}
    resources:
      requests:
        cpu: ${var.requests_cpu}
        memory: ${var.requests_memory}
      limits:
        cpu: ${var.limits_cpu}
        memory: ${var.limits_memory}
  %{~if var.vault_password != null~}
    extraVolumeMounts:
    - name: csi-secret-driver
      mountPath: '/mnt/secrets-store'
      readOnly: true
    extraVolumes:
    - name: csi-secret-driver
      csi:
        driver: 'secrets-store.csi.k8s.io'
        readOnly: true
        volumeAttributes:
          secretProviderClass: ${local.name}
    extraObjects:
    - apiVersion: secrets-store.csi.x-k8s.io/v1
      kind: SecretProviderClass
      metadata:
        name: ${local.name}
      spec:
        provider: vault
        parameters:
          roleName: ${vault_kubernetes_auth_backend_role.this[0].role_name}
          vaultAddress: ${var.vault_password.vault_address}
          vaultCACertPath: ${var.vault_password.vault_csi_ca_cert_path}
          objects: |
            - objectName: aws_credentials
              secretKey: ${var.vault_password.aws_credentials_field}
              secretPath: ${var.vault_password.secret_path}
        secretObjects:
          - secretName: ${local.name}
            type: Opaque
            data:
            - key: cloud
              objectName: aws_credentials
  %{~endif~}
    EOF
  ]
}
