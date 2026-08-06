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
  certificate_server_name = "${var.cluster.name}-server"
  backup_secret_name      = var.create_backup_from_seaweedfs != null ? module.backup_storage[0].secret_name : kubernetes_secret_v1.backup[0].metadata[0].name
  backup_bucket_name      = var.create_backup_from_seaweedfs != null ? module.backup_storage[0].bucket : var.backup.s3_bucket
}

resource "terraform_data" "validate_backup_credentials" {
  lifecycle {
    precondition {
      condition = var.backup == null || (
        (var.s3_credentials != null) != (var.create_backup_from_seaweedfs != null)
      )
      error_message = "When 'backup' is set, exactly one of 's3_credentials' or 'create_backup_from_seaweedfs' must be specified (not both, not neither)."
    }
  }
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
    labels    = merge(local.labels, { component = "credentials" }, { "cnpg.io/reload" = "true" })
  }

  type = "kubernetes.io/basic-auth"

  data_wo = {
    username = each.key
    password = ephemeral.random_password.pg_roles[each.key].result
  }

  data_wo_revision = 2
}

# Immich does not accept secrets outside it's namespace
resource "kubernetes_secret_v1" "credentials_in_app_namespace" {
  for_each = local.roles_with_secrets

  metadata {
    name      = "${each.key}-credentials"
    namespace = each.value.create_secret_in_namespace
    labels    = merge(local.labels, { component = "credentials" }, { "cnpg.io/reload" = "true" })
  }

  type = "kubernetes.io/basic-auth"

  data_wo = {
    username = each.key
    password = ephemeral.random_password.pg_roles[each.key].result
  }

  data_wo_revision = 2
}

#TODO: test
resource "kubernetes_secret_v1" "backup" {
  count = var.backup != null && var.s3_credentials != null ? 1 : 0

  metadata {
    name      = "${var.cluster.name}-backup"
    namespace = kubernetes_namespace_v1.this.metadata[0].name
    labels    = merge(local.labels, { component = "credentials" })
  }

  data_wo = {
    ACCESS_KEY_ID     = var.s3_credentials.access_key_id
    ACCESS_SECRET_KEY = var.s3_credentials.secret_access_key
  }
}

module "backup_storage" {
  count = var.backup != null && var.create_backup_from_seaweedfs != null ? 1 : 0

  source    = "../seadweed-s3-bucket"
  seaweedfs = var.create_backup_from_seaweedfs
  application = {
    name      = var.cluster.name
    namespace = kubernetes_namespace_v1.this.metadata[0].name
  }
  access_key_field = "ACCESS_KEY_ID"
  secret_key_field = "ACCESS_SECRET_KEY"
}

resource "helm_release" "this" {
  depends_on = [kubernetes_secret_v1.credentials_in_pg_namespace]

  name             = var.cluster.name
  create_namespace = true
  namespace        = kubernetes_namespace_v1.this.metadata[0].name
  repository       = "https://cloudnative-pg.github.io/charts"
  version          = var.chart_version
  chart            = "cluster"
  max_history      = 10
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
    %{~if var.enable_metrics~}
      monitoring:
        enabled: true
        labels: ${jsonencode(merge(local.labels, { "component" = "observability" }))}
        prometheusRule:
          additionalLabels: ${jsonencode(merge(local.labels, { "component" = "observability" }))}
          excludeRules: ${jsonencode(var.disabled_alerts)}
    %{~endif~}
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
    backups:
      enabled: true
      retentionPolicy: "${var.backup.retention_policy}"
      endpointURL: ${var.backup.s3_endpoint}
      destinationPath: s3://${local.backup_bucket_name}/
      endpointCA:
        create: false
        name: ${kubernetes_manifest.certificate_server.manifest.metadata.name}
        key: ca.crt
      provider: s3
      s3:
        region: ""
        bucket: ${local.backup_bucket_name}
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
    %{~endif~}
    EOF
  ]
}
