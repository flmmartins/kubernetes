locals {
  pg_operator_namespace = "pg-clusters"
  pg_op_labels = {
    "part-of" = "postgres-operator"
  }
  pg_prd_cluster_name = "pg-prd"

  pg_prd_superuser_secret_name = "${local.pg_prd_cluster_name}-superuser"
  ca_secret_name               = "apps-ca-cert"
}

resource "helm_release" "postgres_operator" {
  name             = "pg-operator"
  create_namespace = true
  namespace        = local.pg_operator_namespace
  repository       = "https://cloudnative-pg.github.io/charts"
  version          = var.postgres_operator_chart_version
  chart            = "cloudnative-pg"
  values = [
    <<-EOF
    podLabels: ${jsonencode(merge(local.pg_op_labels, { "component" = "postgres-operator" }))}
    resources:
      requests:
        cpu: 50m
        memory: 100Mi
      limits:
        cpu: 100m
        memory: 200Mi
    EOF
  ]
}

resource "kubernetes_manifest" "pg_prd_superuser_server_cert" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name = "${local.pg_prd_cluster_name}-server-cert"
    }
    spec = {
      secretName = "${local.pg_prd_cluster_name}-server-cert"
      secretTemplate = {
        #  serves as an instruction to the CNPG operator, guiding it to reload the database whenever there are changes
        labels = {
          "cnpg.io/reload" = ""
        }
      }
      usages = [
        "server auth"
      ]
      dnsNames = [
        "${local.pg_prd_cluster_name}.${var.private_domain}",
        "${local.pg_prd_cluster_name}-rw",
        "${local.pg_prd_cluster_name}-rw.default",
        "${local.pg_prd_cluster_name}-rw.default.svc",
        "${local.pg_prd_cluster_name}-r",
        "${local.pg_prd_cluster_name}-r.default",
        "${local.pg_prd_cluster_name}-r.default.svc",
        "${local.pg_prd_cluster_name}-ro",
        "${local.pg_prd_cluster_name}-ro.default",
        "${local.pg_prd_cluster_name}-ro.default.svc"
      ]
      issuerRef = {
        name  = var.private_cert_issuer
        kind  = "ClusterIssuer"
        group = "cert-manager.io"
      }
    }
  }
}

resource "kubernetes_manifest" "pg_prd_superuser" {
  manifest = {
    apiVersion = "secrets-store.csi.x-k8s.io/v1"
    kind       = "SecretProviderClass"

    metadata = {
      name      = local.pg_prd_superuser_secret_name
      namespace = helm_release.postgres_operator.metadata[0].namespace
      labels    = merge(local.pg_op_labels, { component = "credentials" })
    }

    spec = {
      provider = "vault"
      parameters = {
        roleName        = vault_kubernetes_auth_backend_role.pg_cluster_admin.role_name
        vaultAddress    = var.vault_address_internal
        vaultCACertPath = var.vault_csi_ca_cert_path #TLS mounted on CSI pod
        objects         = <<EOT
- objectName: password
  secretPath: op/vaults/${var.onepassword_vault_id}/items/${local.pg_prd_superuser_secret_name}
  secretKey: password
- objectName: username
  secretPath: op/vaults/${var.onepassword_vault_id}/items/${local.pg_prd_superuser_secret_name}
  secretKey: username
        EOT
      }
      # Will become the following K8s secret - Secret needs to have rootPassword and user
      secretObjects = [{
        secretName = local.pg_prd_superuser_secret_name
        type       = "kubernetes.io/basic-auth"
        data = [
          {
            objectName = "password"
            key        = "password"
          },
          {
            objectName = "username"
            key        = "username"
          }
        ]
      }]
    }
  }
}

# One cluster for all kubernetes apps
# MTLS will not be done bc we will be using Vault Dynamic Secrets
resource "kubernetes_manifest" "database_cluster_prd" {
  manifest = {
    apiVersion = "postgresql.cnpg.io/v1"
    kind       = "Cluster"

    metadata = {
      name      = local.pg_prd_cluster_name
      namespace = helm_release.postgres_operator.metadata[0].namespace
      labels    = merge(local.pg_op_labels, { component = local.pg_prd_cluster_name })
    }

    spec = {
      instances   = 2
      description = "Production database cluster"
      inheritedMetadata = {
        labels = merge(local.pg_op_labels, { component = local.pg_prd_cluster_name })
      }
      certificates = {
        serverTLSSecret = kubernetes_manifest.pg_prd_superuser_server_cert.metadata[0].name
        serverCASecret  = kubernetes_manifest.pg_prd_superuser_server_cert.metadata[0].name
      }
      storage = {
        size         = "10Gi"
        storageClass = var.persistent_storage_class
      }
      postgresUID = var.postgres[]
      postgresGID = 
      # I don't want a default db. They will be created by apps
      # That's why I didn't use the cluster chart bc it forces this
      bootstrap = {
        initdb = {
          database = ""
          owner    = ""
          secret   = ""
        }
      }

      enableSuperuserAccess = true
      superuserSecret       = kubernetes_manifest.pg_prd_superuser.metadata[0].name
    }
  }
}
