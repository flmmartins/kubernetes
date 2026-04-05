locals {
  velero_app_name = "velero"
  velero_common_labels = {
    part-of = "backup"
  }
  velero_vault_secret_path    = format("%s/%s", var.onepassword_vault_path, local.velero_app_name)
  velero_service_account_name = local.velero_app_name
}

resource "kubernetes_namespace_v1" "velero" {
  metadata {
    name   = local.velero_app_name
    labels = local.velero_common_labels
  }
}

resource "vault_policy" "velero" {
  name   = local.velero_app_name
  policy = <<EOT
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
        bucket: "velero"
        default: true
        accessMode: ReadWrite
        config:
          region: seaweedfs
          s3ForcePathStyle: "true"
          s3Url: ${module.seaweedfs.s3_internal_endpoint}
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
        cpu: "50m"
        memory: "100Mi"
      limits:
        cpu: "250m"
        memory: "256Mi"
    EOF
  ]
}

# TODO: For now velero buckets and etc will be created by seaweedfs helm because aws_s3 provider can't:
# create users, keys or lifecycle pilicies
