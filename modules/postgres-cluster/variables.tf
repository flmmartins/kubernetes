variable "cluster" {
  description = "Clusters to be created. If you don't provide a url, the cluster will not have external access and will only be accessible within the Kubernetes cluster"
  type = object({
    name          = string
    storage_class = optional(string)
    url           = optional(string)
    size          = optional(string, "10Gi")
    instances     = optional(number, 1)
  })
}

variable "pg_operator_service_account" {
  description = "Service account configuration for the PostgreSQL operator be able to manage resources"
  type        = string
}

variable "certificate_issuer" {
  description = "The Cert Manager issuer to use for PostgreSQL certificates. This should be the name of an existing issuer in your Kubernetes cluster."
  type        = string
}

variable "cluster_resources_requests_cpu" {
  description = "The CPU request for the CloudNative PG operator. This defines the minimum CPU resources the operator will request."
  type        = string
  default     = "100m"
}

variable "cluster_resources_requests_memory" {
  description = "The memory request for the CloudNative PG operator. This defines the minimum memory resources the operator will request"
  type        = string
  default     = "200Mi"
}

variable "cluster_resources_limits_cpu" {
  description = "The CPU limit for the CloudNative PG operator.This defines the maximum CPU resources the operator can use."
  type        = string
  default     = "100m"
}

variable "cluster_resources_limits_memory" {
  description = "The memory limit for the CloudNative PG operator. This defines the maximum memory resources the operator can use."
  type        = string
  default     = "200Mi"
}

variable "cluster_shared_buffers" {
  description = "Shared buffers should be at least 25% of available memory"
  type        = string
  default     = "50MB"
}
