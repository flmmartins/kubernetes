terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

locals {
  component = "storage"
  labels = merge(var.labels, {
    component = local.component
  })
}

resource "helm_release" "this" {
  name       = "csi-driver-nfs"
  namespace  = "kube-system"
  repository = "https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts"
  version    = var.chart_version
  chart      = "csi-driver-nfs"
  values = [
    <<-EOF
    driver:
      mountPermissions: ${var.mount_permissions}
    controller:
      replicas: ${var.replicas}
      resources:
        csiProvisioner:
          requests:
            cpu: ${var.controller_csi_provisioner_requests_cpu}
            memory: ${var.controller_csi_provisioner_requests_memory}
          limits:
            cpu: ${var.controller_csi_provisioner_limits_cpu}
            memory: ${var.controller_csi_provisioner_limits_memory}
        csiResizer:
          requests:
            cpu: ${var.controller_csi_resizer_requests_cpu}
            memory: ${var.controller_csi_resizer_requests_memory}
          limits:
            cpu: ${var.controller_csi_resizer_limits_cpu}
            memory: ${var.controller_csi_resizer_limits_memory}
        csiSnapshotter:
          requests:
            cpu: ${var.controller_csi_snapshotter_requests_cpu}
            memory: ${var.controller_csi_snapshotter_requests_memory}
          limits:
            cpu: ${var.controller_csi_snapshotter_limits_cpu}
            memory: ${var.controller_csi_snapshotter_limits_memory}
        livenessProbe:
          requests:
            cpu: ${var.controller_liveness_probe_requests_cpu}
            memory: ${var.controller_liveness_probe_requests_memory}
          limits:
            cpu: ${var.controller_liveness_probe_limits_cpu}
            memory: ${var.controller_liveness_probe_limits_memory}
        nfs:
          requests:
            cpu: ${var.controller_nfs_requests_cpu}
            memory: ${var.controller_nfs_requests_memory}
          limits:
            cpu: ${var.controller_nfs_limits_cpu}
            memory: ${var.controller_nfs_limits_memory}
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
                  - ${local.component}
              topologyKey: kubernetes.io/hostname
    node:
      resources:
        livenessProbe:
          requests:
            cpu: ${var.node_liveness_probe_requests_cpu}
            memory: ${var.node_liveness_probe_requests_memory}
          limits:
            cpu: ${var.node_liveness_probe_limits_cpu}
            memory: ${var.node_liveness_probe_limits_memory}
        nodeDriverRegistrar:
          requests:
            cpu: ${var.node_driver_registrar_requests_cpu}
            memory: ${var.node_driver_registrar_requests_memory}
          limits:
            cpu: ${var.node_driver_registrar_limits_cpu}
            memory: ${var.node_driver_registrar_limits_memory}
        nfs:
          requests:
            cpu: ${var.node_nfs_requests_cpu}
            memory: ${var.node_nfs_requests_memory}
          limits:
            cpu: ${var.node_nfs_limits_cpu}
            memory: ${var.node_nfs_limits_memory}
    customLabels: ${jsonencode(local.labels)}
    storageClass:
      create: false #Not all options are present
    EOF
  ]
}

resource "kubernetes_storage_class_v1" "persistent" {
  depends_on = [helm_release.this]
  metadata {
    name   = "persistent"
    labels = local.labels
  }
  storage_provisioner = "nfs.csi.k8s.io"
  parameters = {
    server           = var.server
    share            = var.folder
    subdir           = "$${pvc.metadata.namespace}-$${pvc.metadata.name}"
    mountPermissions = "0700"
  }
  reclaim_policy         = "Retain"
  volume_binding_mode    = "Immediate"
  allow_volume_expansion = true
}

resource "kubernetes_storage_class_v1" "default" {
  depends_on = [helm_release.this]
  metadata {
    name   = "default"
    labels = local.labels
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }
  storage_provisioner = "nfs.csi.k8s.io"
  parameters = {
    server           = var.server
    share            = var.folder
    subdir           = "$${pvc.metadata.namespace}-$${pvc.metadata.name}"
    mountPermissions = "0700"
  }
  reclaim_policy         = "Delete"
  volume_binding_mode    = "Immediate"
  allow_volume_expansion = true
}
