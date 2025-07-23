locals {
  plex_app_name = "plex"
  plex_url      = "${local.plex_app_name}.${var.public_domain}"
  plex_common_labels = {
    "part-of" = "media-server"
  }
}

resource "kubernetes_namespace_v1" "plex" {
  metadata {
    name = local.plex_app_name
  }
}

resource "kubernetes_persistent_volume_claim_v1" "plex_movies" {
  metadata {
    name      = "${local.plex_app_name}-movies"
    namespace = kubernetes_namespace_v1.plex.metadata[0].name
    labels = merge(local.plex_common_labels, {
      component = "data"
    })
  }

  spec {
    access_modes = [var.existing_nfs_share["movies"].access_mode]
    resources {
      requests = {
        storage = var.existing_nfs_share["movies"].size
      }
    }
    volume_name        = kubernetes_persistent_volume_v1.data_volumes["movies"].metadata[0].name
    storage_class_name = kubernetes_storage_class_v1.manual.metadata[0].name
  }
}

resource "kubernetes_persistent_volume_claim_v1" "plex_music" {
  metadata {
    name      = "${local.plex_app_name}-music"
    namespace = kubernetes_namespace_v1.plex.metadata[0].name
    labels = merge(local.plex_common_labels, {
      component = "data"
    })
  }

  spec {
    access_modes = [var.existing_nfs_share["music"].access_mode]
    resources {
      requests = {
        storage = var.existing_nfs_share["music"].size
      }
    }
    volume_name        = kubernetes_persistent_volume_v1.data_volumes["music"].metadata[0].name
    storage_class_name = kubernetes_storage_class_v1.manual.metadata[0].name
  }
}

resource "kubernetes_persistent_volume_claim_v1" "plex_tvshows" {
  metadata {
    name      = "${local.plex_app_name}-tv-shows"
    namespace = kubernetes_namespace_v1.plex.metadata[0].name
    labels = merge(local.plex_common_labels, {
      component = "data"
    })
  }

  spec {
    access_modes = [var.existing_nfs_share["tv-shows"].access_mode]
    resources {
      requests = {
        storage = var.existing_nfs_share["tv-shows"].size
      }
    }
    volume_name        = kubernetes_persistent_volume_v1.data_volumes["tv-shows"].metadata[0].name
    storage_class_name = kubernetes_storage_class_v1.manual.metadata[0].name
  }
}

resource "helm_release" "plex" {
  name       = local.plex_app_name
  namespace  = kubernetes_namespace_v1.plex.metadata[0].name
  repository = "https://raw.githubusercontent.com/plexinc/pms-docker/gh-pages"
  version    = var.plex_chart_version
  chart      = "plex-media-server"
  values = [
    <<-EOF
    pms:
      # On first boot: https://www.plex.tv/claim/. Edit env var below - claim token is temp
      storageClassName: ${var.persistent_storage_class}
      configStorage: 5Gi
      resources:
        requests:
          cpu: 200m
          memory: 300Mi
    commonLabels: ${jsonencode(merge(local.plex_common_labels, { "component" = "plex" }))}
    extraEnv:
      HOSTNAME: "TalosPlexServer"
      TZ: "Europe/Amsterdam"
      ALLOWED_NETWORKS: "0.0.0.0/0"
      #PLEX_CLAIM:
    extraVolumes:
    - name: movies
      persistentVolumeClaim:
        claimName: ${kubernetes_persistent_volume_claim_v1.plex_movies.metadata[0].name}
    - name: music
      persistentVolumeClaim:
        claimName: ${kubernetes_persistent_volume_claim_v1.plex_music.metadata[0].name}
    - name: tvshows
      persistentVolumeClaim:
        claimName: ${kubernetes_persistent_volume_claim_v1.plex_tvshows.metadata[0].name}
    extraVolumeMounts:
    - name: movies
      mountPath: /movies
      readOnly: true
    - name: music
      mountPath: /music
      readOnly: true
    - name: tvshows
      mountPath: /tv_shows
      readOnly: true
    ingress:
      enabled: true
      ingressClassName: "nginx"
      url: ${local.plex_url}
      annotations: 
        kubernetes.io/tls-acme: "true" #Auto-tls creation by cert-manager
        cert-manager.io/common-name: "${local.plex_url}"
      tls:
      - hosts:
        - ${local.plex_url}
        secretName: ${local.plex_app_name}-tls
    EOF
  ]
}