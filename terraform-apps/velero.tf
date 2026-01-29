locals {
  velero_app_name = "velero"
  velero_common_labels = {
    part-of = "backup"
  }
  velero_vault_secret_path    = format("%s/%s", var.onepassword_vault_path, minio_iam_user.velero.name)
  velero_service_account_name = local.velero_app_name
}

# Helm chart only accepts Minio root like this. Other options with environment variables are very opionated and horrible
# This is the minio root cert for TLS. While mino presents the leaf, clients need to present root and intermediate as well
data "vault_generic_secret" "minio_ca" {
  path = "pki/apps/root/cert/ca_chain"
}

resource "kubernetes_namespace_v1" "velero" {
  metadata {
    name   = local.velero_app_name
    labels = local.velero_common_labels
  }
}

resource "minio_s3_bucket" "velero" {
  depends_on = [helm_release.minio]
  bucket     = local.velero_app_name
}

resource "minio_iam_user" "velero" {
  name = local.velero_app_name
}

resource "minio_iam_policy" "velero" {
  name = local.velero_app_name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["s3:ListBucket", "s3:GetBucketLocation"],
        Resource = [minio_s3_bucket.velero.arn]
      },
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:PutObjectTagging",
          "s3:AbortMultipartUpload",
          "s3:ListMultipartUploadParts"
        ],
        Resource = ["${minio_s3_bucket.velero.arn}/*"]
      }
    ]
  })
}

resource "minio_iam_user_policy_attachment" "velero" {
  user_name   = minio_iam_user.velero.id
  policy_name = minio_iam_policy.velero.id
}

resource "minio_ilm_policy" "velero" {
  bucket = minio_s3_bucket.velero.bucket

  rule {
    id         = "erase-after-time"
    status     = "Enabled"
    expiration = "30d"
    filter     = "*"
  }
}

# Don't store secret in state
resource "null_resource" "velero" {
  depends_on = [minio_iam_user_policy_attachment.velero]
  triggers = {
    user = minio_iam_user.velero.name
    kv   = var.onepassword_vault_path
  }
  provisioner "local-exec" {
    command = "bash ${path.module}/create-minio-credentials.sh ${minio_iam_user.velero.name} ${var.onepassword_vault_path}"
  }
}

resource "vault_policy" "velero" {
  depends_on = [null_resource.velero]
  name       = local.velero_app_name
  policy     = <<EOT
path "${local.velero_vault_secret_path}" { capabilities = ["read"] }
EOT
}

resource "vault_kubernetes_auth_backend_role" "velero" {
  role_name                        = local.velero_app_name
  bound_service_account_names      = [local.velero_service_account_name]
  bound_service_account_namespaces = [kubernetes_namespace_v1.velero.metadata[0].name]
  token_max_ttl                    = 1440 #24H
  token_policies                   = [vault_policy.velero.name]
}

resource "helm_release" "velero" {
  name       = local.velero_app_name
  namespace  = kubernetes_namespace_v1.velero.metadata[0].name
  repository = "https://vmware-tanzu.github.io/helm-charts"
  version    = var.velero_chart_version
  chart      = "velero"
  values = [
    <<-EOF
    schedules:
      daily-backup:
        schedule: "0 0 * * *"
        template:
          includedNamespaces:
          - "*"
    backupsEnabled: true
    snapshotsEnabled: false
    credentials:
      useSecret: true
      existingSecret: ${local.velero_app_name}
    extraObjects:
    - apiVersion: secrets-store.csi.x-k8s.io/v1
      kind: SecretProviderClass
      metadata:
        name: ${local.velero_app_name}
      spec:
        provider: vault
        parameters:
          roleName: ${vault_kubernetes_auth_backend_role.velero.role_name}
          vaultAddress: ${var.vault_address_internal}
          vaultCACertPath: ${var.vault_csi_ca_cert_path}
          objects: |
            - objectName: aws_credentials
              secretKey: notesPlain
              secretPath: ${local.velero_vault_secret_path}
        secretObjects:
          - secretName: ${local.velero_app_name}
            type: Opaque
            data:
            - key: cloud
              objectName: aws_credentials
    initContainers:
    - name: velero-plugin-for-aws
      image: velero/velero-plugin-for-aws:${var.velero_aws_plugin_version}
      volumeMounts:
      - mountPath: /target
        name: plugins
    configuration:
      backupStorageLocation:
      - name: "talos-truenas"
        provider: "aws"
        bucket: "${minio_s3_bucket.velero.bucket}"
        caCert:   ${base64encode(data.vault_generic_secret.minio_ca.data["ca_chain"])}
        default: true
        accessMode: ReadWrite
        config:
          region: minio
          s3ForcePathStyle: "true"
          s3Url: https://minio.${kubernetes_namespace_v1.minio.metadata[0].name}.svc.cluster.local:9000
    serviceAccount:
      server:
        create: true
        name: ${local.velero_service_account_name}
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
          secretProviderClass: ${local.velero_app_name}
    labels: ${jsonencode(merge(local.velero_common_labels, { "component" = "velero" }))}
    podLabels: ${jsonencode(merge(local.velero_common_labels, { "component" = "velero" }))}
    resources:
      requests:
        cpu: "180m"
        memory: "100Mi"
      limits:
        cpu: "350m"
        memory: "256Mi"
    EOF
  ]
}