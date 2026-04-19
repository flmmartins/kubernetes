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

# -----------------------------------------------------------------------------
# Metallb
# -----------------------------------------------------------------------------
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
