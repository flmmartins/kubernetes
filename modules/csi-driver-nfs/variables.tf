variable "chart_version" {
  description = "CSI Driver NFS Chart Version"
  default     = "4.12.1"
}

variable "labels" {
  description = "Labels to apply to all resources created by the CSI Driver NFS module"
  type        = map(string)
  default     = {}
}

variable "server" {
  description = "NFS Server IP or hostname"
  type        = string
}

variable "folder" {
  description = "NFS Folder"
  type        = string
}

variable "mount_permissions" {
  description = "Mount permissions for the NFS volumes (e.g., 0700)"
  type        = string
  default     = "0700"
}

variable "replicas" {
  description = "Number of replicas for the CSI Driver NFS controller"
  type        = number
  default     = 1
}

# =============================================================================
# Resource Variables
# =============================================================================
# controller - csiProvisioner
variable "controller_csi_provisioner_requests_cpu" {
  description = "CPU request for the controller csiProvisioner container (e.g. '25m', '1')."
  type        = string
  default     = "25m"
}

variable "controller_csi_provisioner_requests_memory" {
  description = "Memory request for the controller csiProvisioner container (e.g. '32Mi', '1Gi')."
  type        = string
  default     = "32Mi"
}

variable "controller_csi_provisioner_limits_cpu" {
  description = "CPU limit for the controller csiProvisioner container (e.g. '100m', '1')."
  type        = string
  default     = "100m"
}

variable "controller_csi_provisioner_limits_memory" {
  description = "Memory limit for the controller csiProvisioner container (e.g. '128Mi', '1Gi')."
  type        = string
  default     = "128Mi"
}

# controller - csiResizer
variable "controller_csi_resizer_requests_cpu" {
  description = "CPU request for the controller csiResizer container (e.g. '25m', '1')."
  type        = string
  default     = "25m"
}

variable "controller_csi_resizer_requests_memory" {
  description = "Memory request for the controller csiResizer container (e.g. '32Mi', '1Gi')."
  type        = string
  default     = "32Mi"
}

variable "controller_csi_resizer_limits_cpu" {
  description = "CPU limit for the controller csiResizer container (e.g. '100m', '1')."
  type        = string
  default     = "100m"
}

variable "controller_csi_resizer_limits_memory" {
  description = "Memory limit for the controller csiResizer container (e.g. '128Mi', '1Gi')."
  type        = string
  default     = "128Mi"
}

# controller - csiSnapshotter
variable "controller_csi_snapshotter_requests_cpu" {
  description = "CPU request for the controller csiSnapshotter container (e.g. '15m', '1')."
  type        = string
  default     = "15m"
}

variable "controller_csi_snapshotter_requests_memory" {
  description = "Memory request for the controller csiSnapshotter container (e.g. '32Mi', '1Gi')."
  type        = string
  default     = "32Mi"
}

variable "controller_csi_snapshotter_limits_cpu" {
  description = "CPU limit for the controller csiSnapshotter container (e.g. '75m', '1')."
  type        = string
  default     = "75m"
}

variable "controller_csi_snapshotter_limits_memory" {
  description = "Memory limit for the controller csiSnapshotter container (e.g. '96Mi', '1Gi')."
  type        = string
  default     = "96Mi"
}

# controller - livenessProbe
variable "controller_liveness_probe_requests_cpu" {
  description = "CPU request for the controller livenessProbe container (e.g. '10m', '1')."
  type        = string
  default     = "10m"
}

variable "controller_liveness_probe_requests_memory" {
  description = "Memory request for the controller livenessProbe container (e.g. '16Mi', '1Gi')."
  type        = string
  default     = "16Mi"
}

variable "controller_liveness_probe_limits_cpu" {
  description = "CPU limit for the controller livenessProbe container (e.g. '50m', '1')."
  type        = string
  default     = "50m"
}

variable "controller_liveness_probe_limits_memory" {
  description = "Memory limit for the controller livenessProbe container (e.g. '32Mi', '1Gi')."
  type        = string
  default     = "32Mi"
}

# controller - nfs
variable "controller_nfs_requests_cpu" {
  description = "CPU request for the controller nfs container (e.g. '25m', '1')."
  type        = string
  default     = "25m"
}

variable "controller_nfs_requests_memory" {
  description = "Memory request for the controller nfs container (e.g. '32Mi', '1Gi')."
  type        = string
  default     = "32Mi"
}

variable "controller_nfs_limits_cpu" {
  description = "CPU limit for the controller nfs container (e.g. '100m', '1')."
  type        = string
  default     = "100m"
}

variable "controller_nfs_limits_memory" {
  description = "Memory limit for the controller nfs container (e.g. '128Mi', '1Gi')."
  type        = string
  default     = "128Mi"
}

# node - livenessProbe
variable "node_liveness_probe_requests_cpu" {
  description = "CPU request for the node livenessProbe container (e.g. '10m', '1')."
  type        = string
  default     = "10m"
}

variable "node_liveness_probe_requests_memory" {
  description = "Memory request for the node livenessProbe container (e.g. '28Mi', '1Gi')."
  type        = string
  default     = "28Mi"
}

variable "node_liveness_probe_limits_cpu" {
  description = "CPU limit for the node livenessProbe container (e.g. '50m', '1')."
  type        = string
  default     = "50m"
}

variable "node_liveness_probe_limits_memory" {
  description = "Memory limit for the node livenessProbe container (e.g. '56Mi', '1Gi')."
  type        = string
  default     = "56Mi"
}

# node - nodeDriverRegistrar
variable "node_driver_registrar_requests_cpu" {
  description = "CPU request for the node nodeDriverRegistrar container (e.g. '10m', '1')."
  type        = string
  default     = "10m"
}

variable "node_driver_registrar_requests_memory" {
  description = "Memory request for the node nodeDriverRegistrar container (e.g. '28Mi', '1Gi')."
  type        = string
  default     = "28Mi"
}

variable "node_driver_registrar_limits_cpu" {
  description = "CPU limit for the node nodeDriverRegistrar container (e.g. '50m', '1')."
  type        = string
  default     = "50m"
}

variable "node_driver_registrar_limits_memory" {
  description = "Memory limit for the node nodeDriverRegistrar container (e.g. '56Mi', '1Gi')."
  type        = string
  default     = "56Mi"
}

# node - nfs
variable "node_nfs_requests_cpu" {
  description = "CPU request for the node nfs container (e.g. '25m', '1')."
  type        = string
  default     = "25m"
}

variable "node_nfs_requests_memory" {
  description = "Memory request for the node nfs container (e.g. '64Mi', '1Gi')."
  type        = string
  default     = "64Mi"
}

variable "node_nfs_limits_cpu" {
  description = "CPU limit for the node nfs container (e.g. '100m', '1')."
  type        = string
  default     = "100m"
}

variable "node_nfs_limits_memory" {
  description = "Memory limit for the node nfs container (e.g. '128Mi', '1Gi')."
  type        = string
  default     = "128Mi"
}
