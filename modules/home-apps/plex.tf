locals {
  plex_app_name = "plex"
  plex_url      = "${local.plex_app_name}.${var.domain}"
  plex_common_labels = {
    "part-of" = "media-server"
  }
  plex_shares = {
    for k, v in {
      movies   = var.movies_nfs_share
      music    = var.music_nfs_share
      tv-shows = var.tvshows_nfs_share
    } : k => v
    if v != null
  }
}

resource "kubernetes_namespace_v1" "plex" {
  count = length(local.plex_shares) != null ? 1 : 0
  metadata {
    name = local.plex_app_name
  }
}

resource "kubernetes_persistent_volume_claim_v1" "plex" {
  for_each = local.plex_shares

  metadata {
    name      = "${local.plex_app_name}-${each.key}"
    namespace = kubernetes_namespace_v1.plex[0].metadata[0].name
    labels = merge(local.plex_common_labels, {
      component = "data"
    })
  }

  spec {
    access_modes = [each.value.access_mode]
    resources {
      requests = {
        storage = each.value.size
      }
    }
    volume_name        = kubernetes_persistent_volume_v1.data_volumes[each.key].metadata[0].name
    storage_class_name = kubernetes_storage_class_v1.manual.metadata[0].name
  }
}

resource "helm_release" "plex" {
  count = length(local.plex_shares) != null ? 1 : 0

  name       = local.plex_app_name
  namespace  = kubernetes_namespace_v1.plex[0].metadata[0].name
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
          cpu: 300m
          memory: 512Mi
        limits:
          cpu: 3
          memory: 1Gi
    commonLabels: ${jsonencode(merge(local.plex_common_labels, { "component" = "plex" }))}
    extraEnv:
      HOSTNAME: "TalosPlexServer"
      TZ: "Europe/Amsterdam"
      ALLOWED_NETWORKS: "0.0.0.0/0" 
      ADVERTISE_IP: "http://${var.plex_ip}:32400,https://${local.plex_url}"
      #PLEX_CLAIM:
    extraVolumes:
    %{~for name, _ in local.plex_shares~}
    - name: ${name}
      persistentVolumeClaim:
        claimName: ${kubernetes_persistent_volume_claim_v1.plex[name].metadata[0].name}
    %{~endfor~}
    extraVolumeMounts:
    %{~for name, _ in local.plex_shares~}
    - name: ${name}
      mountPath: /${name}
      readOnly: true
    %{~endfor~}
    httpRoute:
      enabled: true
      parentRefs:
      - name: ${var.gateway.name}
        namespace: ${var.gateway.namespace}
      hostnames: [${local.plex_url}]
    EOF
  ]
}

# For TV to work - not supported by helm chart
resource "kubernetes_manifest" "tcproute_plex" {
  count      = length(local.plex_shares) != null ? 1 : 0
  depends_on = [helm_release.plex]

  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1alpha2"
    kind       = "TCPRoute"
    metadata = {
      name      = local.plex_app_name
      namespace = kubernetes_namespace_v1.plex[0].metadata[0].name
    }
    spec = {
      parentRefs = [
        {
          name        = var.gateway.name
          namespace   = var.gateway.namespace
          sectionName = var.plex_gateway_tcp_listener
        }
      ]
      rules = [
        {
          backendRefs = [
            {
              name = "plex-plex-media-server"
              port = 32400
            }
          ]
        }
      ]
    }
  }
}
