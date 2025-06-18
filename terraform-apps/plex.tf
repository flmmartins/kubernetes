locals {
  plex_app_name = "plex"
  plex_share    = "media"
  plex_url      = "${local.plex_app_name}.${var.apps_domain}"
  plex_common_labels = {
    "part-of" = "media-server"
  }
}

resource "kubernetes_namespace_v1" "plex" {
  metadata {
    name = local.plex_app_name
  }
}

#Plex only works with IP, with nginx it didn't allow to configure it
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

resource "kubernetes_persistent_volume_claim_v1" "plex_data" {
  metadata {
    name      = "${local.plex_app_name}-data"
    namespace = kubernetes_namespace_v1.plex.metadata[0].name
    labels = merge(local.plex_common_labels, {
      component = "data"
    })
  }

  spec {
    access_modes = [var.existing_nfs_share[local.plex_share].access_mode]
    resources {
      requests = {
        storage = var.existing_nfs_share[local.plex_share].size
      }
    }
    volume_name        = kubernetes_persistent_volume_v1.data_volumes[local.plex_share].metadata[0].name
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
    # This is a container security context, fsGroup doesn't apply
    securityContext:
      runAsNonRoot: true
      runAsUser: ${var.existing_nfs_share[local.plex_share].user_uid}
      runAsGroup: ${var.existing_nfs_share[local.plex_share].group_uid}
      allowPrivilegeEscalation: false
    resources:
      requests:
        cpu: 100m
        memory: 200Mi
      limits:
        cpu: 300m
        memory: 400Mi
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
    PLEX_UID: ${var.existing_nfs_share[local.plex_share].user_uid}
    PLEX_GID: ${var.existing_nfs_share[local.plex_share].group_uid}
    #PLEX_CLAIM:
  extraVolumes:
  - name: media
    persistentVolumeClaim:
      claimName: ${kubernetes_persistent_volume_claim_v1.plex_data.metadata[0].name}
  extraVolumeMounts:
  - name: media
    mountPath: /media
    readOnly: true
  service:
    annotations:
      "metallb.universe.tf/address-pool": ${kubernetes_manifest.plex-l2-advertisement.manifest.metadata.name}
    type: LoadBalancer
  EOF
  ]
}