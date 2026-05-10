#locals {
#  immich_app_name = "immich-photos"
#  immich_share    = "photos"
#  immich_url      = "${local.immich_app_name}.${var.private_domain}"
#  immich_common_labels = {
#    "part-of" = "photos"
#  }
#}
#
#resource "kubernetes_namespace_v1" "immich" {
#  count = var.photos_nfs_share != null ? 1 : 0
#  metadata {
#    name = local.immich_app_name
#  }
#}
#
#resource "kubernetes_persistent_volume_claim_v1" "immich_data" {
#  count = var.photos_nfs_share != null ? 1 : 0
#  metadata {
#    name = "${local.immich_app_name}-data"
#    namespace = kubernetes_namespace_v1.immich[0].metadata[0].name
#    labels = merge(local.immich_common_labels, {
#      component = "data"
#    })
#  }
#
#  spec {
#    access_modes = ["ReadWriteMany"]
#    resources {
#      requests = {
#        storage = var.photos_nfs_share.size
#      }
#    }
#    volume_name        = kubernetes_persistent_volume_v1.data_volumes[local.immich_share].metadata[0].name
#    storage_class_name = kubernetes_storage_class_v1.manual.metadata[0].name
#  }
#}
#
#resource "helm_release" "immich" {
#  count = var.photos_nfs_share != null ? 1 : 0

#  name       = local.immich_app_name
#  namespace  = kubernetes_namespace_v1.immich[0].metadata[0].name
#  repository = "oci://ghcr.io/immich-app/immich-charts/immich"
#  version    = var.immich_chart_version
#  chart      = "immichr"
#  values = [
#  <<-EOF
#  env:
#    REDIS_HOSTNAME: '{{ printf "%s-redis-master" .Release.Name }}'
#    DB_HOSTNAME: "TODO"
#    DB_USERNAME: "TOOD"
#    DB_DATABASE_NAME: "TODO"
#    DB_PASSWORD: "TODO"
#    IMMICH_MACHINE_LEARNING_URL: '{{ printf "http://%s-machine-learning:3003" .Release.Name }}'
#  redis:
#    enabled: true
#  persistence:
#    library:
#      existingClaim: ${kubernetes_persistent_volume_claim_v1.immich_data[0].metadata[0].name}
#  server:
#    image:
#      repository: ghcr.io/immich-app/immich-server
#      pullPolicy: IfNotPresent
#   machine-learning:
#     enabled: true
#     image:
#       repository: ghcr.io/immich-app/immich-machine-learning
#       pullPolicy: IfNotPresent
#     env:
#       TRANSFORMERS_CACHE: /cache
#     persistence:
#       cache:
#         enabled: true
#         size: 10Gi
#         # Optional: Set this to pvc to avoid downloading the ML models every start.
#         type: emptyDir
#         accessMode: ReadWriteMany
#         storageClass: var.persistent_storage_class
#  EOF
#  ]
#}
