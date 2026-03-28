variable "chart_version" {
  type        = string
  description = "Prometheus Stack Chart Version"
  default     = "1.5.6"
}
# =============================================================================
# Resource Variables
# =============================================================================

# -----------------------------------------------------------------------------
# Driver
# -----------------------------------------------------------------------------
variable "csi_driver_limit_cpu" {
  description = "CPU limit for the CSI driver container"
  type        = string
  default     = "150m"
}

variable "csi_driver_limit_memory" {
  description = "Memory limit for the CSI driver container"
  type        = string
  default     = "128Mi"
}

variable "csi_driver_request_cpu" {
  description = "CPU request for the CSI driver container"
  type        = string
  default     = "25m"
}

variable "csi_driver_request_memory" {
  description = "Memory request for the CSI driver container"
  type        = string
  default     = "64Mi"
}

# -----------------------------------------------------------------------------
# Registrar
# -----------------------------------------------------------------------------
variable "csi_registrar_limit_cpu" {
  description = "CPU limit for the CSI registrar container"
  type        = string
  default     = "50m"
}

variable "csi_registrar_limit_memory" {
  description = "Memory limit for the CSI registrar container"
  type        = string
  default     = "64Mi"
}

variable "csi_registrar_request_cpu" {
  description = "CPU request for the CSI registrar container"
  type        = string
  default     = "5m"
}

variable "csi_registrar_request_memory" {
  description = "Memory request for the CSI registrar container"
  type        = string
  default     = "32Mi"
}

# -----------------------------------------------------------------------------
# Liveness Probe
# -----------------------------------------------------------------------------
variable "csi_liveness_probe_limit_cpu" {
  description = "CPU limit for the CSI liveness probe container"
  type        = string
  default     = "50m"
}

variable "csi_liveness_probe_limit_memory" {
  description = "Memory limit for the CSI liveness probe container"
  type        = string
  default     = "64Mi"
}

variable "csi_liveness_probe_request_cpu" {
  description = "CPU request for the CSI liveness probe container"
  type        = string
  default     = "5m"
}

variable "csi_liveness_probe_request_memory" {
  description = "Memory request for the CSI liveness probe container"
  type        = string
  default     = "32Mi"
}