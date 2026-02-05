locals {
  storage_labels = var.enable_nfs_csi == true ? {
    component = "storage"
    part-of   = "truenas"
    } : {
    component = "storage"
    part-of   = "local"
  }

  # depends_on doesn't accept conditional so we add a label to create an implicit conditional on SC
  storage_class_labels = merge(local.storage_labels, { "nfs-driver-status" = var.enable_nfs_csi == true ? helm_release.csi-driver-nfs[0].metadata : "not-used" })
}

resource "helm_release" "csi-driver-nfs" {
  count = var.enable_nfs_csi == true ? 1 : 0

  name       = "csi-driver-nfs"
  namespace  = "kube-system"
  repository = "https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts"
  version    = var.csi_driver_nfs_version
  chart      = "csi-driver-nfs"
  values = [
    <<-EOF
    driver:
      mountPermissions: 0700
    controller:
      replicas: 2
      runOnControlPlane: true
      # Do not schedule pods on same node
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
                  - ${local.storage_labels.component}
              topologyKey: kubernetes.io/hostname
    customLabels: ${jsonencode(local.storage_labels)}
    storageClass:
      create: false #Not all options are present
    EOF
  ]
}

resource "kubernetes_storage_class_v1" "persistent" {

  metadata {
    name   = "persistent"
    labels = local.storage_class_labels
  }

  storage_provisioner = var.storage_provisioner

  parameters = var.enable_nfs_csi == true ? {
    server           = var.nfs.ip
    share            = var.nfs.share_folder
    subdir           = "$${pvc.metadata.namespace}-$${pvc.metadata.name}"
    mountPermissions = "0700"
  } : {}
  reclaim_policy         = "Retain"
  volume_binding_mode    = "Immediate"
  allow_volume_expansion = true
}

resource "kubernetes_storage_class_v1" "default" {
  metadata {
    name   = "default"
    labels = local.storage_class_labels
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }
  storage_provisioner = var.storage_provisioner
  parameters = var.enable_nfs_csi == true ? {
    server           = var.nfs.ip
    share            = var.nfs.share_folder
    subdir           = "$${pvc.metadata.namespace}-$${pvc.metadata.name}"
    mountPermissions = "0700"
  } : {}
  reclaim_policy         = "Delete"
  volume_binding_mode    = "Immediate"
  allow_volume_expansion = true
}

moved {
  from = helm_release.csi-driver-nfs
  to   = helm_release.csi-driver-nfs[0]
}