locals {
  immich_app_name = "immich-photos"
  immich_url      = "photos.${var.domain}"
  immich_app_labels = {
    "part-of" = "photos"
  }
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
                  memory: 1Gi 
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
                  memory: 512Mi 
                  cpu: 300m
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
