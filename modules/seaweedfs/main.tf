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
  s3_admin_secret_name  = "admin-s3-secret"
  admin_k8s_secret_name = "seaweedfs-admin"
}

resource "kubernetes_namespace_v1" "this" {
  metadata {
    name   = local.name
    labels = local.labels
  }
}

# CRD don't create serviceaccount and neither operator
resource "kubernetes_service_account_v1" "seaweedfs" {
  metadata {
    name      = "${local.name}-objstore"
    namespace = kubernetes_namespace_v1.this.metadata[0].name
    labels    = local.labels
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
    name      = local.s3_admin_secret_name
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
  bound_service_account_names      = [kubernetes_service_account_v1.seaweedfs.metadata[0].name]
  bound_service_account_namespaces = [kubernetes_namespace_v1.this.metadata[0].name]
  token_max_ttl                    = 1440 #24H
  token_policies                   = [vault_policy.this[0].name]
}

resource "kubernetes_manifest" "admin_credentials" {
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
        EOT
      }
      secretObjects = [{
        secretName = local.admin_k8s_secret_name
        type       = "Opaque"
        data = [
          {
            objectName = "admin-username"
            key        = "adminUser"
          },
          {
            objectName = "admin-password"
            key        = "adminPassword"
          }
        ]
      }]
    }
  }
}

resource "helm_release" "operator" {
  name             = "seaweedfs-operator"
  namespace        = kubernetes_namespace_v1.this.metadata[0].name
  create_namespace = true
  repository       = "https://seaweedfs.github.io/seaweedfs-operator/"
  chart            = "seaweedfs-operator"
  version          = var.operator_chart_version

  values = [<<-EOF
    commonLabels: ${jsonencode(merge(local.labels, { "component" = "plex" }))}
    resources:
      requests:
        cpu: ${var.operator_cpu_request}
        memory: ${var.operator_memory_request}
      limits:
        cpu: ${var.operator_cpu_limit}
        memory: ${var.operator_memory_limit}
  EOF
  ]
}

resource "kubernetes_manifest" "seaweed" {
  depends_on = [helm_release.operator, kubernetes_manifest.admin_credentials]

  manifest = {
    apiVersion = "seaweed.seaweedfs.com/v1"
    kind       = "Seaweed"
    metadata = {
      name      = "${local.name}-objstore"
      namespace = kubernetes_namespace_v1.this.metadata[0].name
      labels    = merge(local.labels, { "component" = "core" })
    }
    spec = {
      image           = "chrislusf/seaweedfs:${var.application_image_version}"
      pvReclaimPolicy = "Retain"

      master = {
        replicas          = 1
        volumeSizeLimitMB = 1024
        requests = {
          cpu    = var.master_cpu_request
          memory = var.master_memory_request
        }
        limits = {
          cpu    = var.master_cpu_limit
          memory = var.master_memory_limit
        }
        podSecurityContext = var.security_context != null ? {
          runAsNonRoot        = true
          runAsUser           = var.security_context.user_id
          runAsGroup          = var.security_context.group_id
          fsGroup             = var.security_context.group_id
          fsGroupChangePolicy = "OnRootMismatch"
          seccompProfile = {
            type = "RuntimeDefault"
          }
        } : null
        containerSecurityContext = {
          allowPrivilegeEscalation = false
          capabilities = {
            drop = ["ALL"]
          }
          seccompProfile = {
            type = "RuntimeDefault"
          }
        }
        affinity = {
          podAntiAffinity = {
            preferredDuringSchedulingIgnoredDuringExecution = [
              {
                weight = 100
                podAffinityTerm = {
                  labelSelector = {
                    matchExpressions = [{
                      key      = "app.kubernetes.io/component"
                      operator = "In"
                      values   = ["master"]
                    }]
                  }
                  topologyKey = "kubernetes.io/hostname"
                }
              }
            ]
          }
        }
      }

      volume = {
        replicas         = 2
        storageClassName = var.persistent_storage_class_name
        requests = {
          cpu     = var.volume_cpu_request
          memory  = var.volume_memory_request
          storage = var.volume_storage_size
        }
        limits = {
          cpu    = var.volume_cpu_limit
          memory = var.volume_memory_limit
        }
        podSecurityContext = var.security_context != null ? {
          runAsNonRoot        = true
          runAsUser           = var.security_context.user_id
          runAsGroup          = var.security_context.group_id
          fsGroup             = var.security_context.group_id
          fsGroupChangePolicy = "OnRootMismatch"
          seccompProfile = {
            type = "RuntimeDefault"
          }
        } : null
        containerSecurityContext = {
          allowPrivilegeEscalation = false
          capabilities = {
            drop = ["ALL"]
          }
          seccompProfile = {
            type = "RuntimeDefault"
          }
        }
        affinity = {
          podAntiAffinity = {
            preferredDuringSchedulingIgnoredDuringExecution = [
              {
                weight = 100
                podAffinityTerm = {
                  labelSelector = {
                    matchExpressions = [{
                      key      = "app.kubernetes.io/component"
                      operator = "In"
                      values   = ["volume"]
                    }]
                  }
                  topologyKey = "kubernetes.io/hostname"
                }
              }
            ]
          }
        }
      }

      filer = {
        replicas = 2
        requests = {
          cpu    = var.filer_cpu_request
          memory = var.filer_memory_request
        }
        limits = {
          cpu    = var.filer_cpu_limit
          memory = var.filer_memory_limit
        }
        persistence = {
          enabled          = true
          storageClassName = var.persistent_storage_class_name
          accessModes      = ["ReadWriteOnce"]
          resources = {
            requests = {
              storage = var.filer_storage_size
            }
          }
        }
        podSecurityContext = var.security_context != null ? {
          runAsNonRoot        = true
          runAsUser           = var.security_context.user_id
          runAsGroup          = var.security_context.group_id
          fsGroup             = var.security_context.group_id
          fsGroupChangePolicy = "OnRootMismatch"
          seccompProfile = {
            type = "RuntimeDefault"
          }
        } : null
        containerSecurityContext = {
          allowPrivilegeEscalation = false
          capabilities = {
            drop = ["ALL"]
          }
          seccompProfile = {
            type = "RuntimeDefault"
          }
        }
        affinity = {
          podAntiAffinity = {
            preferredDuringSchedulingIgnoredDuringExecution = [
              {
                weight = 100
                podAffinityTerm = {
                  labelSelector = {
                    matchExpressions = [{
                      key      = "app.kubernetes.io/component"
                      operator = "In"
                      values   = ["filer"]
                    }]
                  }
                  topologyKey = "kubernetes.io/hostname"
                }
              }
            ]
          }
        }
        config = <<-EOT
          [leveldb2]
          enabled = true
          dir = "/data/filerldb2"
        EOT
      }

      s3 = {
        replicas = 1
        port     = var.s3api_port
        iam      = true
        requests = {
          cpu    = var.s3_cpu_request
          memory = var.s3_memory_request
        }
        limits = {
          cpu    = var.s3_cpu_limit
          memory = var.s3_memory_limit
        }
        containerSecurityContext = {
          allowPrivilegeEscalation = false
          capabilities = {
            drop = ["ALL"]
          }
          seccompProfile = {
            type = "RuntimeDefault"
          }
        }
        affinity = {
          podAntiAffinity = {
            preferredDuringSchedulingIgnoredDuringExecution = [
              {
                weight = 100
                podAffinityTerm = {
                  labelSelector = {
                    matchExpressions = [{
                      key      = "app.kubernetes.io/component"
                      operator = "In"
                      values   = ["s3"]
                    }]
                  }
                  topologyKey = "kubernetes.io/hostname"
                }
              }
            ]
          }
        }
      }

      admin = {
        requests = {
          cpu    = var.admin_cpu_request
          memory = var.admin_memory_request
        }
        limits = {
          cpu    = var.admin_cpu_limit
          memory = var.admin_memory_limit
        }
        credentialsSecret = {
          name = local.admin_k8s_secret_name
        }
        containerSecurityContext = {
          allowPrivilegeEscalation = false
          capabilities = {
            drop = ["ALL"]
          }
          seccompProfile = {
            type = "RuntimeDefault"
          }
        }
        volumes = [
          {
            name = "csi-secret-driver-for-seaweedfs-credentials"
            csi = {
              driver   = "secrets-store.csi.k8s.io"
              readOnly = true
              volumeAttributes = {
                secretProviderClass = kubernetes_manifest.admin_credentials[0].manifest.metadata.name
              }
            }
          }
        ]
        serviceAccountName = kubernetes_service_account_v1.seaweedfs.metadata[0].name
        volumeMounts = [
          {
            name      = "csi-secret-driver-for-seaweedfs-credentials"
            mountPath = "/mnt/secrets-store"
            readOnly  = true
          }
        ]
      }
    }
  }
}

resource "kubernetes_manifest" "httproute_seaweedfs_admin" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"

    metadata = {
      name      = "seaweedfs-admin"
      namespace = kubernetes_namespace_v1.this.metadata[0].name
      labels    = merge(local.labels, { component = "httproute" })
    }

    spec = {
      parentRefs = [
        {
          name      = var.gateway.name
          namespace = var.gateway.namespace
        }
      ]

      hostnames = [var.admin_ui_url]

      rules = [
        {
          matches = [
            {
              path = {
                type  = "PathPrefix"
                value = "/"
              }
            }
          ]

          backendRefs = [
            {
              name = "${kubernetes_manifest.seaweed.manifest.metadata.name}-admin"
              port = var.admin_ui_port
            }
          ]
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "httproute_s3_api" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"

    metadata = {
      name      = "s3-admin"
      namespace = kubernetes_namespace_v1.this.metadata[0].name
      labels    = merge(local.labels, { component = "httproute" })
    }

    spec = {
      parentRefs = [
        {
          name      = var.gateway.name
          namespace = var.gateway.namespace
        }
      ]

      hostnames = [var.s3api_url]

      rules = [
        {
          matches = [
            {
              path = {
                type  = "PathPrefix"
                value = "/"
              }
            }
          ]

          backendRefs = [
            {
              name = "${kubernetes_manifest.seaweed.manifest.metadata.name}-s3"
              port = var.s3api_port
            }
          ]
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "s3_identity_admin" {
  manifest = {
    apiVersion = "seaweed.seaweedfs.com/v1"
    kind       = "S3Identity"
    metadata = {
      name      = "admin"
      namespace = kubernetes_namespace_v1.this.metadata[0].name
      labels    = merge(local.labels, { "component" = "identity" })
    }
    spec = {
      seaweedRef = {
        name = kubernetes_manifest.seaweed.manifest.metadata.name
      }
    }
  }
}

resource "kubernetes_manifest" "s3_credentials_admin" {
  manifest = {
    apiVersion = "seaweed.seaweedfs.com/v1"
    kind       = "S3Credentials"
    metadata = {
      name      = "admin"
      namespace = kubernetes_namespace_v1.this.metadata[0].name
      labels    = merge(local.labels, { "component" = "credential" })
    }
    spec = {
      seaweedRef = {
        name = kubernetes_manifest.seaweed.manifest.metadata.name
      }
      identityRef = {
        name = kubernetes_manifest.s3_identity_admin.manifest.metadata.name
      }
      secretRef = {
        name = local.s3_admin_secret_name
      }
    }
  }
}

resource "kubernetes_manifest" "s3_policy_admin" {
  manifest = {
    apiVersion = "seaweed.seaweedfs.com/v1"
    kind       = "S3Policy"
    metadata = {
      name      = "admin"
      namespace = "seaweedfs"
      labels    = merge(local.labels, { "component" = "policy" })
    }
    spec = {
      seaweedRef = {
        name = kubernetes_manifest.seaweed.manifest.metadata.name
      }
      statements = [
        {
          effect    = "Allow"
          actions   = ["*"]
          resources = ["*"]
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "s3_policy_binding_admin" {
  manifest = {
    apiVersion = "seaweed.seaweedfs.com/v1"
    kind       = "S3PolicyBinding"
    metadata = {
      name      = "admin"
      namespace = kubernetes_namespace_v1.this.metadata[0].name
      labels    = merge(local.labels, { "component" = "policybinding" })
    }
    spec = {
      seaweedRef = {
        name = kubernetes_manifest.seaweed.manifest.metadata.name
      }
      policyRef = {
        name = kubernetes_manifest.s3_policy_admin.manifest.metadata.name
      }
      subjects = [
        {
          kind = "S3Identity"
          name = kubernetes_manifest.s3_identity_admin.manifest.metadata.name
        }
      ]
    }
  }
}

# Terraform credentials will be admin
resource "kubernetes_manifest" "bucket_terraform" {
  depends_on = [kubernetes_manifest.seaweed]

  manifest = {
    apiVersion = "seaweed.seaweedfs.com/v1"
    kind       = "Bucket"
    metadata = {
      name      = "terraform"
      namespace = kubernetes_namespace_v1.this.metadata[0].name
      labels    = merge(local.labels, { "component" = "bucket" })
    }
    spec = {
      clusterRef = {
        name = kubernetes_manifest.seaweed.manifest.metadata.name
      }
      reclaimPolicy = "Retain" # Do not delete bucket when CRD is deleted
      versioning    = "Enabled"
      objectLock    = true
      owner         = kubernetes_manifest.s3_identity_admin.manifest.metadata.name
      placement = {
        ttl = "90d"
      }
    }
  }
}
