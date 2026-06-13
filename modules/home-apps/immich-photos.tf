locals {
  immich_app_name = "immich-photos"
  immich_url      = "photos.${var.domain}"
  immich_app_labels = {
    "part-of" = "photos"
  }
  immich_service_account = "immich-photos-server"
}

resource "kubernetes_namespace_v1" "immich" {
  count = var.photos_nfs_share != null ? 1 : 0
  metadata {
    name   = local.immich_app_name
    labels = local.immich_app_labels
  }
}

resource "kubernetes_persistent_volume_claim_v1" "immich_data" {
  count = var.photos_nfs_share != null ? 1 : 0
  metadata {
    name      = "${local.immich_app_name}-data"
    namespace = kubernetes_namespace_v1.immich[0].metadata[0].name
    labels = merge(local.immich_app_labels, {
      component = "data"
    })
  }

  spec {
    access_modes = [var.photos_nfs_share.access_mode]
    resources {
      requests = {
        storage = var.photos_nfs_share.size
      }
    }
    volume_name        = kubernetes_persistent_volume_v1.data_volumes["photos"].metadata[0].name
    storage_class_name = kubernetes_storage_class_v1.manual.metadata[0].name
  }
}

resource "kubernetes_persistent_volume_claim_v1" "immich_config" {
  count = var.photos_nfs_share != null ? 1 : 0

  metadata {
    name      = "${local.immich_app_name}-config"
    namespace = kubernetes_namespace_v1.immich[0].metadata[0].name
    labels = merge(local.immich_app_labels, {
      component = "config"
    })
  }
  spec {
    access_modes       = ["ReadWriteMany"]
    storage_class_name = var.persistent_storage_class
    resources {
      requests = {
        storage = "10Gi"
      }
    }
  }
}



resource "helm_release" "immich" {
  count = var.photos_nfs_share != null ? 1 : 0

  name       = local.immich_app_name
  namespace  = kubernetes_namespace_v1.immich[0].metadata[0].name
  repository = "oci://ghcr.io/immich-app/immich-charts"
  chart      = "immich"
  version    = var.immich_chart_version
  values = [
    <<-EOF
    defaultPodOptions:
      securityContext:
        runAsUser: ${var.photos_nfs_share.user_id}
        runAsGroup: ${var.photos_nfs_share.group_id}
        fsGroup: ${var.photos_nfs_share.group_id}
        runAsNonRoot: true
        fsGroupChangePolicy: OnRootMismatch
        seccompProfile:
          type: RuntimeDefault
    controllers:
      main:
        containers:
          main:
            env:
              REDIS_HOSTNAME: '{{ printf "%s-valkey" .Release.Name }}'
              IMMICH_MACHINE_LEARNING_URL: '{{ printf "http://%s-machine-learning:3003" .Release.Name }}'
              DB_HOSTNAME: ${var.immich_database.server}
              DB_DATABASE_NAME: ${var.immich_database.database_name}
              DB_USERNAME:
                valueFrom:
                  secretKeyRef:
                    name: ${var.immich_database.credentials_secret_name}
                    key: username
              DB_PASSWORD:
                valueFrom:
                  secretKeyRef:
                    name: ${var.immich_database.credentials_secret_name}
                    key: password
    server:
      controllers:
        main:
          replicas: 1
          containers:
            main:
              resources:
                requests:
                  memory: 256Mi
                  cpu: 100m
                limits:
                  memory: 2Gi 
                  cpu: 500m
              securityContext:
                allowPrivilegeEscalation: false
                capabilities:
                  drop:
                    - ALL
                runAsNonRoot: true
      persistence:
        photos:
          enabled: true
          type: persistentVolumeClaim
          existingClaim: ${kubernetes_persistent_volume_claim_v1.immich_data[0].metadata[0].name}
          globalMounts:
            - path: /photos
    valkey:
      enabled: true
      master:
        containerSecurityContext:
          allowPrivilegeEscalation: false
          capabilities:
            drop:
              - ALL
          runAsNonRoot: true
    machine-learning:
      controllers:
        main:
          containers:
            main:
              env:
                MACHINE_LEARNING_WORKERS: "1"
                MACHINE_LEARNING_WORKER_TIMEOUT: "120"
              resources:
                requests:
                  memory: 256Mi
                  cpu: 100m
                limits:
                  memory: 2Gi 
                  cpu: 500m
              securityContext:
                allowPrivilegeEscalation: false
                capabilities:
                  drop:
                    - ALL
                runAsNonRoot: true
    immich:
      metrics:
        enabled: true
      persistence:
        library:
          existingClaim: ${kubernetes_persistent_volume_claim_v1.immich_config[0].metadata[0].name}
  EOF
  ]
}

resource "kubernetes_manifest" "httproute_immich" {
  count      = var.photos_nfs_share != null ? 1 : 0
  depends_on = [helm_release.immich]

  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = local.immich_app_name
      namespace = kubernetes_namespace_v1.immich[0].metadata[0].name
      labels = merge(local.immich_app_labels, {
        component = "httproute"
      })
    }
    spec = {
      parentRefs = [
        {
          name      = var.gateway.name
          namespace = var.gateway.namespace
        }
      ]

      hostnames = [
        local.immich_url
      ]

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
              name = "immich-photos-server"
              port = 2283
            }
          ]
        }
      ]
    }
  }
}

# Agent needs CA on the namespace of the application so here we do a copy
data "kubernetes_config_map_v1" "vault_ca" {
  count = var.photos_nfs_share != null && var.immich_api_key_vault != null ? 1 : 0

  metadata {
    name      = var.immich_api_key_vault.vault_ca_configmap_name
    namespace = var.immich_api_key_vault.vault_ca_configmap_namespace
  }
}

resource "kubernetes_secret_v1" "vault_ca" {
  count = var.photos_nfs_share != null && var.immich_api_key_vault != null ? 1 : 0

  metadata {
    name      = "vault-ca"
    namespace = kubernetes_namespace_v1.immich[0].metadata[0].name
    labels = merge(local.immich_app_labels, {
      component = "vault-ca"
    })
  }

  data_wo = {
    "ca.crt" = data.kubernetes_config_map_v1.vault_ca[0].data["ca.crt"]
  }

  data_wo_revision = 1
}

resource "vault_policy" "immich" {
  count = var.photos_nfs_share != null && var.immich_api_key_vault != null ? 1 : 0

  name   = local.immich_app_name
  policy = <<-EOT
    path "${var.immich_api_key_vault.secret_path}" { capabilities = ["read"] }
  EOT
}

resource "vault_kubernetes_auth_backend_role" "immich" {
  count = var.photos_nfs_share != null && var.immich_api_key_vault != null ? 1 : 0

  role_name                        = local.immich_app_name
  bound_service_account_names      = [local.immich_service_account]
  bound_service_account_namespaces = [kubernetes_namespace_v1.immich[0].metadata[0].name]
  token_max_ttl                    = 1440
  token_policies                   = [vault_policy.immich[0].name]
}

resource "kubernetes_cron_job_v1" "immich_album_creator" {
  count      = var.photos_nfs_share != null && var.immich_api_key_vault != null ? 1 : 0
  depends_on = [helm_release.immich]

  metadata {
    name      = "immich-album-creator"
    namespace = kubernetes_namespace_v1.immich[0].metadata[0].name
    labels = merge(local.immich_app_labels, {
      component = "album-creator"
    })
  }

  spec {
    schedule           = var.immich_album_creator_schedule
    concurrency_policy = "Forbid"

    job_template {
      metadata {
        labels = merge(local.immich_app_labels, {
          component = "album-creator"
        })
      }

      spec {
        template {
          metadata {
            labels = merge(local.immich_app_labels, {
              component = "album-creator"
            })
            annotations = {
              "vault.hashicorp.com/agent-inject"                 = "true"
              "vault.hashicorp.com/role"                         = vault_kubernetes_auth_backend_role.immich[0].role_name
              "vault.hashicorp.com/agent-pre-populate-only"      = "true"
              "vault.hashicorp.com/agent-extra-secret"           = kubernetes_secret_v1.vault_ca[0].metadata[0].name
              "vault.hashicorp.com/ca-cert"                      = "/vault/custom/ca.crt"
              "vault.hashicorp.com/agent-inject-secret-apikey"   = var.immich_api_key_vault.secret_path
              "vault.hashicorp.com/agent-inject-template-apikey" = <<-EOT
                {{- with secret "${var.immich_api_key_vault.secret_path}" -}}
                {{ index .Data "${var.immich_api_key_vault.api_key_field}" }}
                {{- end }}
              EOT
            }
          }

          spec {
            service_account_name = local.immich_service_account
            restart_policy       = "OnFailure"

            security_context {
              run_as_user     = var.photos_nfs_share.user_id
              run_as_group    = var.photos_nfs_share.group_id
              run_as_non_root = true
              seccomp_profile {
                type = "RuntimeDefault"
              }
            }

            container {
              name  = "album-creator"
              image = "salvoxia/immich-folder-album-creator:${var.immich_album_creator_version}"

              env {
                name  = "API_URL"
                value = "http://immich-photos-server.${kubernetes_namespace_v1.immich[0].metadata[0].name}.svc.cluster.local:2283/api"
              }

              env {
                name  = "API_KEY_FILE"
                value = "/vault/secrets/apikey"
              }

              env {
                name  = "ROOT_PATH"
                value = "/photos"
              }

              env {
                name  = "ALBUM_LEVELS"
                value = "-1"
              }

              env {
                name  = "UNATTENDED"
                value = "1"
              }

              security_context {
                allow_privilege_escalation = false
                read_only_root_filesystem  = false
                capabilities {
                  drop = ["ALL"]
                }
              }

              volume_mount {
                name       = "photos"
                mount_path = "/photos"
                read_only  = true
              }
            }

            volume {
              name = "photos"
              persistent_volume_claim {
                claim_name = kubernetes_persistent_volume_claim_v1.immich_data[0].metadata[0].name
                read_only  = true
              }
            }
          }
        }
      }
    }
  }
}
