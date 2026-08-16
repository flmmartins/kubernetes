variable "chart_version" {
  description = "The version of the CloudNative PG chart to deploy. This should be a valid version string from the CNPG chart repository."
  type        = string
  default     = "0.8.0"
}

variable "postgres_version" {
  description = "The version of postgres database"
  type        = string
  default     = "16"
}

variable "cluster" {
  description = "Clusters to be created. If you don't provide a url, the cluster will not have external access and will only be accessible within the Kubernetes cluster"
  type = object({
    name          = string
    storage_class = optional(string)
    url           = optional(string)
    size          = optional(string, "30Gi")
    instances     = optional(number, 2)
  })
}

variable "databases" {
  description = "Database settings"
  type = list(object({
    name       = string
    owner      = string
    extensions = optional(list(string), [])
  }))
}

variable "roles" {
  description = "Role settings. This will create the role and if create secret in namespace is set as a k8s secret"
  type = list(object({
    name                       = string
    login                      = optional(bool, true)
    create_secret_in_namespace = optional(string)
    superuser                  = optional(bool, false)
    state                      = optional(string, "present")
  }))
}

variable "mode" {
  description = <<-EOT
  -- Cluster mode of operation. Available modes:
standalone - default mode. Creates new or updates an existing CNPG cluster.
replica - Creates a replica cluster from an existing CNPG cluster.
recovery - Same as standalone but creates a cluster from a backup, object store or via pg_basebackup.
EOT
  type        = string
  default     = "standalone"
}

variable "backup" {
  description = <<-EOT
    Backup to S3 specifications. Requires barman to be installed.
    Example:
    backup = {
      s3_endpoint  = "http://...:8333"
      s3_bucket    = "A BUCKET - If created with seaweed there's  no need to define"
      schedule     = "0 0 0 * * *". This expression expects 6 digits.
      retention_policy = "30d"
  EOT
  type = object({
    s3_endpoint      = string
    s3_bucket        = optional(string)
    schedule         = optional(string, "0 0 23 * * *")
    alert_thresholds = optional(string, "26h")
    retention_policy = optional(string, "30d")
  })
  default = null
}

variable "create_backup_from_seaweedfs" {
  description = "Name of seaweedfs cluster and namespace. If provided, bucket and credentials will be created"
  type = object({
    cluster_name = string
    namespace    = string
  })
  default = null
}

variable "s3_credentials" {
  description = "Object containing access_key_id and secret_access_key for s3"
  type = object({
    access_key_id     = string
    secret_access_key = string
  })
  default   = null
  sensitive = true
}

variable "certificate_issuer" {
  description = "The Cert Manager issuer to use for PostgreSQL certificates. This should be the name of an existing issuer in your Kubernetes cluster."
  type        = string
}

variable "enable_metrics" {
  description = "Whether to enable metrics"
  type        = bool
  default     = false
}

variable "disabled_alerts" {
  description = "Cluster comes with some alerts by default. This allows you to disable alerts by adding the alert name to the array"
  type        = list(string)
  default     = []
}

# =============================================================================
# Resource Variables
# =============================================================================

variable "cluster_resources_requests_cpu" {
  description = "The CPU request for the CloudNative PG operator. This defines the minimum CPU resources the operator will request."
  type        = string
  default     = "100m"
}

variable "cluster_resources_requests_memory" {
  description = "The memory request for the CloudNative PG operator. This defines the minimum memory resources the operator will request"
  type        = string
  default     = "256Mi"
}

variable "cluster_resources_limits_cpu" {
  description = "The CPU limit for the CloudNative PG operator.This defines the maximum CPU resources the operator can use."
  type        = string
  default     = "500m"
}

variable "cluster_resources_limits_memory" {
  description = "The memory limit for the CloudNative PG operator. This defines the maximum memory resources the operator can use."
  type        = string
  default     = "1Gi"
}

variable "cluster_shared_buffers" {
  description = "Shared buffers should be at least 25% of available memory"
  type        = string
  default     = "50MB"
}
