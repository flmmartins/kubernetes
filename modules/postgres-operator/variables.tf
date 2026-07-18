variable "chart_version" {
  description = "The version of the CloudNative PG chart to deploy. This should be a valid version string from the CNPG chart repository."
  default     = "v0.28.2"
}

variable "barman_chart_version" {
  description = "Barman Cloud Plugin (Backup Engine) Chart Version"
  type        = string
  default     = "v0.7.0"
}

variable "security_context" {
  description = "Security context for the operator be able to read/write to PVs"
  type = object({
    user_id  = optional(number)
    group_id = optional(number)
  })
  default = null
}


# =============================================================================
# Resource Variables
# =============================================================================

# -----------------------------------------------------------------------------
# Operator
# -----------------------------------------------------------------------------

variable "operator_resources_requests_cpu" {
  description = "The CPU request for the CloudNative PG operator. This defines the minimum CPU resources the operator will request."
  type        = string
  default     = "50m"
}

variable "operator_resources_requests_memory" {
  description = "The memory request for the CloudNative PG operator. This defines the minimum memory resources the operator will request"
  type        = string
  default     = "100Mi"
}

variable "operator_resources_limits_cpu" {
  description = "The CPU limit for the CloudNative PG operator.This defines the maximum CPU resources the operator can use."
  type        = string
  default     = "100m"
}

variable "operator_resources_limits_memory" {
  description = "The memory limit for the CloudNative PG operator. This defines the maximum memory resources the operator can use."
  type        = string
  default     = "200Mi"
}

# -----------------------------------------------------------------------------
# Barman
# -----------------------------------------------------------------------------

variable "barman_requests_cpu" {
  description = "CPU request for the Barman Cloud Plugin pod (e.g. '25m', '1')."
  type        = string
  default     = "25m"
}

variable "barman_requests_memory" {
  description = "Memory request for the Barman Cloud Plugin pod (e.g. '64Mi', '1Gi')."
  type        = string
  default     = "64Mi"
}

variable "barman_limits_cpu" {
  description = "CPU limit for the Barman Cloud Plugin pod (e.g. '100m', '1')."
  type        = string
  default     = "100m"
}

variable "barman_limits_memory" {
  description = "Memory limit for the Barman Cloud Plugin pod (e.g. '128Mi', '1Gi')."
  type        = string
  default     = "128Mi"
}
