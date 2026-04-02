variable "chart_version" {
  type        = string
  description = "Seaweedfs Chart Version"
  default     = "4.17.0"
}

variable "s3api_port" {
  description = "S3 api port"
  default     = 8333
}

variable "s3api_url" {
  type        = string
  description = "S3 api URL"
}

variable "s3api_ingress_annotations" {
  type    = map(string)
  default = {}
}

variable "admin_ui_port" {
  description = "S3 api port"
  default     = 23646
}

variable "admin_ui_url" {
  type        = string
  description = "Admin URL"
}

variable "admin_ui_ingress_annotations" {
  type    = map(string)
  default = {}
}

variable "vault_password" {
  description = "Object containing vault data to read grafana password from vault"
  type = object({
    secret_path            = optional(string)
    vault_address          = optional(string)
    vault_csi_ca_cert_path = optional(string, "/vault/tls/vault.ca")
    # Fields in Secret Manager
    admin_username_field = optional(string, "username")
    admin_password_field = optional(string, "password")
    # The S3 has to be in json format and to interact with CSI is best to store the json
    s3_admin_credentials_json_field = optional(string, "seaweedfs_s3_config")
  })
  default = {}
}

# -----------------------------------------------------------------------------
# Storage
# -----------------------------------------------------------------------------
variable "persistent_storage_class_name" {
  description = "Storage class name for PVC"
  type        = string
}

variable "volume_storage_size" {
  description = "PVC size for SeaweedFS volume servers — where object data is stored"
  type        = string
  default     = "10Gi"
}

variable "filer_storage_size" {
  description = "PVC size for SeaweedFS file — where file metadata is stored"
  type        = string
  default     = "5Gi"
}

variable "security_context" {
  description = "Security context for the cluster"
  type = object({
    user_id  = optional(number)
    group_id = optional(number)
  })
  default = {}
}

# =============================================================================
# Resource Variables
# =============================================================================

# -----------------------------------------------------------------------------
# Master
# -----------------------------------------------------------------------------
variable "master_cpu_request" {
  description = "CPU request for SeaweedFS master pods"
  type        = string
  default     = "50m"
}

variable "master_memory_request" {
  description = "Memory request for SeaweedFS master pods"
  type        = string
  default     = "64Mi"
}

variable "master_cpu_limit" {
  description = "CPU limit for SeaweedFS master pods"
  type        = string
  default     = "100m"
}

variable "master_memory_limit" {
  description = "Memory limit for SeaweedFS master pods"
  type        = string
  default     = "128Mi"
}

# -----------------------------------------------------------------------------
# Filer
# -----------------------------------------------------------------------------
variable "filer_cpu_request" {
  description = "CPU request for SeaweedFS filer pods"
  type        = string
  default     = "50m"
}

variable "filer_memory_request" {
  description = "Memory request for SeaweedFS filer pods"
  type        = string
  default     = "100Mi"
}

variable "filer_cpu_limit" {
  description = "CPU limit for SeaweedFS filer pods"
  type        = string
  default     = "250m"
}

variable "filer_memory_limit" {
  description = "Memory limit for SeaweedFS filer pods"
  type        = string
  default     = "400Mi"
}


# -----------------------------------------------------------------------------
# Volume
# -----------------------------------------------------------------------------

variable "volume_cpu_request" {
  description = "CPU request for SeaweedFS volume pods"
  type        = string
  default     = "50m"
}

variable "volume_memory_request" {
  description = "Memory request for SeaweedFS volume pods"
  type        = string
  default     = "100Mi"
}

variable "volume_cpu_limit" {
  description = "CPU limit for SeaweedFS volume pods"
  type        = string
  default     = "250m"
}

variable "volume_memory_limit" {
  description = "Memory limit for SeaweedFS volume pods"
  type        = string
  default     = "400Mi"
}

# -----------------------------------------------------------------------------
# S3 Gateway
# -----------------------------------------------------------------------------
variable "s3_cpu_request" {
  description = "CPU request for SeaweedFS S3 gateway pods"
  type        = string
  default     = "50m"
}

variable "s3_memory_request" {
  description = "Memory request for SeaweedFS S3 gateway pods"
  type        = string
  default     = "100Mi"
}

variable "s3_cpu_limit" {
  description = "CPU limit for SeaweedFS S3 gateway pods"
  type        = string
  default     = "250m"
}

variable "s3_memory_limit" {
  description = "Memory limit for SeaweedFS S3 gateway pods"
  type        = string
  default     = "400Mi"
}

# -----------------------------------------------------------------------------
# Admin UI
# -----------------------------------------------------------------------------
variable "admin_cpu_request" {
  description = "CPU request for SeaweedFS admin UI pods"
  type        = string
  default     = "50m"
}

variable "admin_memory_request" {
  description = "Memory request for SeaweedFS admin UI pods"
  type        = string
  default     = "64Mi"
}

variable "admin_cpu_limit" {
  description = "CPU limit for SeaweedFS admin UI pods"
  type        = string
  default     = "100m"
}

variable "admin_memory_limit" {
  description = "Memory limit for SeaweedFS admin UI pods"
  type        = string
  default     = "128Mi"
}