# -----------------------------------------------------------------------------
# Istio Gateway
# -----------------------------------------------------------------------------
variable "istio_chart_version" {
  description = "Istio Chart Version"
  default     = "1.29.2"
}

variable "gateway_crds_version" {
  description = "Gateway API CRDs Version"
  default     = "v1.5.1"
}

variable "istio_ip" {
  description = "Load Balancer IP assigned for Istio"
  type        = string
}

# -----------------------------------------------------------------------------
# Metallb
# -----------------------------------------------------------------------------

variable "metallb_chart_version" {
  description = "Metal LB Chart Version"
  default     = "0.15.3"
}

variable "uses_metallb" {
  description = "Uses metallb to provide IPs to the controller"
  default     = false
}

# =============================================================================
# Resource Variables
# =============================================================================

variable "controller_memory_request" {
  type    = string
  default = "50Mi"
}

variable "controller_memory_limit" {
  type    = string
  default = "150Mi"
}

variable "controller_cpu_request" {
  type    = string
  default = "50m"
}

variable "controller_cpu_limit" {
  type    = string
  default = "100m"
}

variable "speaker_memory_request" {
  type    = string
  default = "150Mi"
}

variable "speaker_memory_limit" {
  type    = string
  default = "200Mi"
}

variable "speaker_cpu_request" {
  type    = string
  default = "50m"
}

variable "speaker_cpu_limit" {
  type    = string
  default = "100m"
}
