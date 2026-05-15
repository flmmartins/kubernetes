variable "chart_version" {
  description = "The version of the CloudNative PG chart to deploy. This should be a valid version string from the CNPG chart repository."
  default     = "v0.28.2"
}

variable "security_context" {
  description = "Security context for the operator be able to read/write to PVs"
  type = object({
    user_id  = optional(number)
    group_id = optional(number)
  })
  default = null
}

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
