locals {
  csi_driver_nfs_labels = {
    component = "storage"
    part-of   = "truenas"
  }
}

resource "helm_release" "csi-driver-nfs" {
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
      replicas: 1
      runOnControlPlane: true
      resources:
        csiProvisioner:
          requests:
            cpu: 25m
            memory: 32Mi
          limits:
            cpu: 100m
            memory: 128Mi
        csiResizer:
          requests:
            cpu: 25m
            memory: 32Mi
          limits:
            cpu: 100m
            memory: 128Mi
        csiSnapshotter:
          requests:
            cpu: 15m
            memory: 32Mi
          limits:
            cpu: 75m
            memory: 96Mi
        livenessProbe:
          requests:
            cpu: 10m
            memory: 16Mi
          limits:
            cpu: 50m
            memory: 32Mi
        nfs:
          requests:
            cpu: 25m
            memory: 32Mi
          limits:
            cpu: 100m
            memory: 128Mi
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
                  - ${local.csi_driver_nfs_labels.component}
              topologyKey: kubernetes.io/hostname
    node:
      resources:
        livenessProbe:
          requests:
            cpu: 10m
            memory: 16Mi
          limits:
            cpu: 50m
            memory: 32Mi
        nodeDriverRegistrar:
          requests:
            cpu: 10m
            memory: 16Mi
          limits:
            cpu: 50m
            memory: 32Mi
        nfs:
          requests:
            cpu: 25m
            memory: 32Mi
          limits:
            cpu: 100m
            memory: 128Mi
    customLabels: ${jsonencode(local.csi_driver_nfs_labels)}
    storageClass:
      create: false #Not all options are present
    EOF
  ]
}

resource "kubernetes_storage_class_v1" "persistent" {
  depends_on = [helm_release.csi-driver-nfs]
  metadata {
    name   = "persistent"
    labels = local.csi_driver_nfs_labels
  }
  storage_provisioner = "nfs.csi.k8s.io"
  parameters = {
    server           = var.nfs.ip
    share            = var.nfs.share_folder
    subdir           = "$${pvc.metadata.namespace}-$${pvc.metadata.name}"
    mountPermissions = "0700"
  }
  reclaim_policy         = "Retain"
  volume_binding_mode    = "Immediate"
  allow_volume_expansion = true
}

resource "kubernetes_storage_class_v1" "default" {
  depends_on = [helm_release.csi-driver-nfs]
  metadata {
    name   = "default"
    labels = local.csi_driver_nfs_labels
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }
  storage_provisioner = "nfs.csi.k8s.io"
  parameters = {
    server           = var.nfs.ip
    share            = var.nfs.share_folder
    subdir           = "$${pvc.metadata.namespace}-$${pvc.metadata.name}"
    mountPermissions = "0700"
  }
  reclaim_policy         = "Delete"
  volume_binding_mode    = "Immediate"
  allow_volume_expansion = true
}