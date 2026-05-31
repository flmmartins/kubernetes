variable "chart_version" {
  description = "Hashicorp Vault Chart Version"
  default     = "0.32.0"
}

variable "plugin_onepasswordconnect_version" {
  description = "Version of 1password connect vault plugin"
  default     = "1.1.0"
}

variable "url" {
  type        = string
  description = "Vault URL"
}

variable "gateway" {
  description = "Gateway to use for the app"
  type = object({
    name                    = string
    namespace               = string
    internal_ca_certificate = string
  })
}

variable "install_onepassword_plugin" {
  description = "Wether to install one password plugin or not"
  default     = false
}

variable "persistent_storage_class_name" {
  description = "Storage class name for vault"
  type        = string
}

variable "security_context" {
  description = "Security context for the vault"
  type = object({
    user_id  = optional(number)
    group_id = optional(number)
  })
  default = null
}

variable "priority_class" {
  description = "Describe the priority class vault should be in"
  type        = string
  default     = null
}

variable "certificate_issuer" {
  description = "Cert Manager certificate issuer to issue the vault internal kubernetes certificate"
  default     = null
}

# =============================================================================
# Resource Variables
# =============================================================================

# -----------------------------------------------------------------------------
# Injector
# -----------------------------------------------------------------------------
variable "injector_requests_cpu" {
  description = "CPU request for the injector container (e.g. '20m', '1')."
  type        = string
  default     = "20m"
}

variable "injector_requests_memory" {
  description = "Memory request for the injector container (e.g. '80Mi', '1Gi')."
  type        = string
  default     = "80Mi"
}

variable "injector_limits_cpu" {
  description = "CPU limit for the injector container (e.g. '100m', '1')."
  type        = string
  default     = "100m"
}

variable "injector_limits_memory" {
  description = "Memory limit for the injector container (e.g. '100Mi', '1Gi')."
  type        = string
  default     = "100Mi"
}

# -----------------------------------------------------------------------------
# CSI
# -----------------------------------------------------------------------------

variable "csi_requests_cpu" {
  description = "CPU request for the csi container (e.g. '50m', '1')."
  type        = string
  default     = "50m"
}

variable "csi_requests_memory" {
  description = "Memory request for the csi container (e.g. '390Mi', '1Gi')."
  type        = string
  default     = "100Mi"
}

variable "csi_limits_cpu" {
  description = "CPU limit for the csi container (e.g. '100m', '1')."
  type        = string
  default     = "100m"
}

variable "csi_limits_memory" {
  description = "Memory limit for the csi container (e.g. '600Mi', '1Gi')."
  type        = string
  default     = "1024Mi"
}

# -----------------------------------------------------------------------------
# Server
# -----------------------------------------------------------------------------
variable "server_requests_cpu" {
  description = "CPU request for the server container (e.g. '100m', '1')."
  type        = string
  default     = "100m"
}

variable "server_requests_memory" {
  description = "Memory request for the server container (e.g. '512Mi', '1Gi')."
  type        = string
  default     = "400Mi"
}

variable "server_limits_cpu" {
  description = "CPU limit for the server container (e.g. '256m', '1')."
  type        = string
  default     = "256m"
}

variable "server_limits_memory" {
  description = "Memory limit for the server container (e.g. '512Mi', '1Gi')."
  type        = string
  default     = "1024Mi"
}
