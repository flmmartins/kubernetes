locals {
  plex_app_name      = "plex"
  plex_url           = "${local.plex_app_name}.${var.apps_domain}"
  plex_ip            = cidrhost(var.plex_ip_cidr, 0)
  plex_common_labels = {
    "part-of" = "media-server"
  }
}

resource "kubernetes_namespace_v1" "plex" {
  metadata {
    name = local.plex_app_name
  }
}

#TV and mobile apps don't work using reverse proxy. Check readme
resource "kubernetes_manifest" "plex-ip-address-pool" {
  manifest = {
    apiVersion = "metallb.io/v1beta1"
    kind       = "IPAddressPool"
    metadata = {
      name      = local.plex_app_name
      namespace = "metallb"
      labels    = local.plex_common_labels
    }
    spec = {
      addresses  = [var.plex_ip_cidr]
      autoAssign = false
    }
  }
}

resource "kubernetes_manifest" "plex-l2-advertisement" {
  manifest = {
    apiVersion = "metallb.io/v1beta1"
    kind       = "L2Advertisement"
    metadata = {
      name      = local.plex_app_name
      namespace = "metallb"
      labels    = local.plex_common_labels
    }
    spec = {
      ipAddressPools = [kubernetes_manifest.plex-ip-address-pool.manifest.metadata.name]
    }
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
    storageClassName: persistent
    configStorage: 5Gi
    resources:
      requests:
        cpu: 100m
        memory: 200Mi
  commonLabels: ${jsonencode(merge(local.plex_common_labels, { "component" = "plex" }))}
  affinity:
    podAntiAffinity:
        preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 100
          podAffinityTerm:
            labelSelector:
              matchExpressions:
              - key: component
                operator: In
                values:
                - plex
            topologyKey: kubernetes.io/hostname
  extraEnv:
    HOSTNAME: "TalosPlexServer"
    TZ: "Europe/Amsterdam"
    ALLOWED_NETWORKS: "0.0.0.0/0"
    ADVERTISE_IP: "http://${local.plex_ip}:32400,https://${local.plex_ip}:32400"
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
  service:
    annotations:
      "metallb.universe.tf/address-pool": ${kubernetes_manifest.plex-l2-advertisement.manifest.metadata.name}
    type: LoadBalancer
  EOF
  ]
}