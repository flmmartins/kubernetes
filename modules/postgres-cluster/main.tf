terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    helm = {
      source = "hashicorp/helm"
    }
  }
}

locals {
  labels = {
    "part-of" = var.cluster.name
  }
  roles_with_secrets = {
    for role in var.roles : role.name => role
    if role.create_secret_in_namespace != null
  }
  backup_secret_name      = "${var.cluster.name}-backup"
  certificate_server_name = "${var.cluster.name}-server"

}

resource "kubernetes_namespace_v1" "this" {
  metadata {
    name   = var.cluster.name
    labels = local.labels
  }
}

resource "kubernetes_manifest" "certificate_server" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = local.certificate_server_name
      namespace = kubernetes_namespace_v1.this.metadata[0].name
      labels    = merge(local.labels, { component = "certificate" })
    }
    spec = {
      secretName = local.certificate_server_name
      commonName = "${var.cluster.name}-server"
      secretTemplate = {
        #  serves as an instruction to the CNPG operator, guiding it to reload the database whenever there are changes
        labels = {
          "cnpg.io/reload" = ""
        }
      }
      usages = [
        "server auth",
      ]
      dnsNames = compact([
        "${var.cluster.url}",
        "${var.cluster.name}-rw.${kubernetes_namespace_v1.this.metadata[0].name}.svc",
        "${var.cluster.name}-rw",
        "${var.cluster.name}-rw.${kubernetes_namespace_v1.this.metadata[0].name}",
        "${var.cluster.name}-r",
        "${var.cluster.name}-r.${kubernetes_namespace_v1.this.metadata[0].name}",
        "${var.cluster.name}-r.${kubernetes_namespace_v1.this.metadata[0].name}.svc",
        "${var.cluster.name}-ro",
        "${var.cluster.name}-ro.${kubernetes_namespace_v1.this.metadata[0].name}",
        "${var.cluster.name}-ro.${kubernetes_namespace_v1.this.metadata[0].name}.svc"
      ])
      issuerRef = {
        name  = var.certificate_issuer
        kind  = "ClusterIssuer"
        group = "cert-manager.io"
      }
    }
  }
}

ephemeral "random_password" "pg_roles" {
  for_each = local.roles_with_secrets

  length  = 32
  special = false
}

# PG Cluster does not accept secrets outside it's namespace
# It cannot be created by Vault because PG cluster on first run does not have a pod available to use CSI
resource "kubernetes_secret_v1" "credentials_in_pg_namespace" {
  for_each = local.roles_with_secrets

  metadata {
    name      = "${each.key}-pg-role"
    namespace = kubernetes_namespace_v1.this.metadata[0].name
    labels = {
      "cnpg.io/reload" = "true"
    }
  }

  type = "kubernetes.io/basic-auth"

  data_wo = {
    username = each.key
    password = ephemeral.random_password.pg_roles[each.key].result
  }

  data_wo_revision = 1
}

# Immich does not accept secrets outside it's namespace
resource "kubernetes_secret_v1" "credentials_in_app_namespace" {
  for_each = local.roles_with_secrets

  metadata {
    name      = "${each.key}-credentials"
    namespace = each.value.create_secret_in_namespace
    labels = {
      "cnpg.io/reload" = "true"
    }
  }

  type = "kubernetes.io/basic-auth"

  data_wo = {
    username = each.key
    password = ephemeral.random_password.pg_roles[each.key].result
  }

  data_wo_revision = 1
}

resource "vault_policy" "backup" {
  count = var.backup != null ? 1 : 0

  name   = "${var.cluster.name}-backup"
  policy = <<-EOT
    path "${var.backup.vault_password.secret_path}" { capabilities = ["read"] }
  EOT
}

resource "vault_kubernetes_auth_backend_role" "backup" {
  count = var.backup != null ? 1 : 0

  role_name                        = "${var.cluster.name}-backup"
  bound_service_account_names      = ["${var.cluster.name}"] # CNPG uses cluster name as SA
  bound_service_account_namespaces = [kubernetes_namespace_v1.this.metadata[0].name]
  token_max_ttl                    = 1440
  token_policies                   = [vault_policy.backup[0].name]
}

resource "kubernetes_manifest" "backup_secret_provider" {
  count = var.backup != null ? 1 : 0

  manifest = {
    apiVersion = "secrets-store.csi.x-k8s.io/v1"
    kind       = "SecretProviderClass"
    metadata = {
      name      = local.backup_secret_name
      namespace = kubernetes_namespace_v1.this.metadata[0].name
      labels    = local.labels
    }
    spec = {
      provider = "vault"
      parameters = {
        roleName        = vault_kubernetes_auth_backend_role.backup[0].role_name
        vaultAddress    = var.backup.vault_password.vault_address
        vaultCACertPath = var.backup.vault_password.vault_csi_ca_cert_path
        objects         = <<-EOT
          - objectName: s3-access-key
            secretPath: ${var.backup.vault_password.secret_path}
            secretKey: ${var.backup.vault_password.access_key_field}
          - objectName: s3-secret-key
            secretPath: ${var.backup.vault_password.secret_path}
            secretKey: ${var.backup.vault_password.secret_key_field}
        EOT
      }
      secretObjects = [{
        secretName = local.backup_secret_name
        type       = "Opaque"
        data = [
          {
            objectName = "s3-access-key"
            key        = "accessKey"
          },
          {
            objectName = "s3-secret-key"
            key        = "secretKey"
          }
        ]
      }]
    }
  }
}

resource "helm_release" "this" {
  depends_on = [kubernetes_secret_v1.credentials_in_pg_namespace]

  name             = var.cluster.name
  create_namespace = true
  namespace        = kubernetes_namespace_v1.this.metadata[0].name
  repository       = "https://cloudnative-pg.github.io/charts"
  version          = var.chart_version
  chart            = "cluster"
  values = [
    <<-EOF
    databases:
    %{~for db in var.databases~}
    - name: ${db.name}
      owner: ${db.owner}
      extensions:
        %{~for ext in db.extensions~}
        - name: ${ext}
          ensure: present
        %{~endfor~}
    %{~endfor~}
    mode: ${var.mode}
    version:
      postgresql: "${var.postgres_version}"
    cluster:
      instances: ${var.cluster.instances}
      roles:
      %{~for role in var.roles~}
      - name: ${role.name}
        ensure: ${role.state}
        login: ${role.login}
        superuser: ${role.superuser}
        %{~if role.create_secret_in_namespace != null~}
        passwordSecret:
          name: ${role.name}-pg-role
        %{~endif~}
      %{~endfor~}
      storage:
        size: ${var.cluster.size}
        storageClass: ${var.cluster.storage_class}
      # Operator will auto create a secret. It's not possible to do CSI here because there's no pod to CSI to run
      enableSuperuserAccess: true
      certificates:
        serverTLSSecret: ${kubernetes_manifest.certificate_server.manifest.spec.secretName}
        serverCASecret: ${kubernetes_manifest.certificate_server.manifest.spec.secretName}
      postgres:
        parameters:
          shared_buffers: ${var.cluster_shared_buffers}
      additionalLabels:
        part-of: "cloudnative-pg-operator"
        component: ${var.cluster.name}
      resources:
        requests:
          memory: ${var.cluster_resources_requests_memory}
          cpu: ${var.cluster_resources_requests_cpu}
        limits:
          memory: ${var.cluster_resources_limits_memory}
          cpu: ${var.cluster_resources_limits_cpu}
    %{~if var.backup != null~}
      projectedVolumeTemplate:
        sources:
        - csi:
            driver: secrets-store.csi.k8s.io
            readOnly: true
            volumeAttributes:
              secretProviderClass: ${kubernetes_manifest.backup_secret_provider[0].manifest.metadata.name}
    backups:
      enabled: true
      endpointURL: ${var.backup.s3_endpoint}
      destinationPath: s3://${var.backup.s3_bucket}/
      endpointCA:
        create: false
        name: ${kubernetes_manifest.certificate_server.manifest.metadata.name}
        key: ca.crt
      provider: s3
      s3:
        region: ""
        bucket: ${var.backup.s3_bucket}
        path: /
      secret:
        create: false
        name: ${local.backup_secret_name}
      wal:
        compression: gzip
        encryption: ""
        maxParallel: 1
      data:
        compression: gzip
        encryption: ""
        jobs: 2
      scheduledBackups:
      - name: daily-backup
        schedule: "${var.backup.schedule}"
        backupOwnerReference: self
        method: barmanObjectStore
        retentionPolicy: "${var.backup.retention_policy}"
    %{~endif~}
    EOF
  ]
}
