variable "chart_version" {
  type        = string
  description = "Prometheus Stack Chart Version"
  default     = "12.0.0"
}

variable "aws_plugin_version" {
  description = "AWS Plugin for Velero Version. It has to be compatible with velero. Check: https://github.com/vmware-tanzu/velero-plugin-for-aws?tab=readme-ov-file#compatibility"
  default     = "v1.13.2"
}

variable "backup_schedule" {
  description = "When to run velero"
  default     = "0 0 * * *"
}

variable "backup_storage_locations" {
  type = list(object({
    name        = string
    provider    = optional(string, "aws")
    bucket      = optional(string, "velero")
    default     = optional(bool, true)
    access_mode = optional(string, "ReadWrite")
    config = object({
      region           = string
      s3ForcePathStyle = optional(string, "true")
      s3Url            = string
    })
  }))
}

variable "snapshots_enabled" {
  description = "Wether to take snapshots or not"
  default     = true
}

variable "s3_credentials" {
  description = "Object containing access_key_id and secret_access_key for s3"
  type = object({
    access_key_id     = optional(string)
    secret_access_key = optional(string)
  })
  default   = null
  sensitive = true
}

variable "vault_password" {
  description = <<-EOT
    Vault configuration to read Velero S3 credentials from.
    The secret is expected to be stored as a JSON blob in a single Vault field.

    Example:
    vault_password = {
      secret_path   = "secret/velero"
      vault_address = "https://vault.internal:8200"

      # Optional overrides (these are the defaults):
      vault_csi_ca_cert_path = "/vault/tls/vault.ca"
      aws_credentials_field  = "notesPlain"
    }

    The json_field must point to a Vault field containing the Velero S3
    credentials in JSON format. Defaults to "notesPlain" for compatibility with 1Password secret references which is note.
    Vault field has to be on the following format:
    [default]
    aws_access_key_id=ACCESS_KEY
    aws_secret_access_key=SECRET
  EOT

  type = object({
    secret_path            = optional(string)
    vault_address          = optional(string)
    vault_csi_ca_cert_path = optional(string, "/vault/tls/ca.crt")
    aws_credentials_field  = optional(string, "notesPlain")
  })
  default = null
}

# =============================================================================
# Resource Variables
# =============================================================================
variable "requests_cpu" {
  description = "CPU request for the pod (e.g. '50m', '1')."
  type        = string
  default     = "50m"
}

variable "requests_memory" {
  description = "Memory request for the pod (e.g. '100Mi', '1Gi')."
  type        = string
  default     = "100Mi"
}

variable "limits_cpu" {
  description = "CPU limit for the pod (e.g. '250m', '1')."
  type        = string
  default     = "250m"
}

variable "limits_memory" {
  description = "Memory limit for the pod (e.g. '256Mi', '1Gi')."
  type        = string
  default     = "256Mi"
}
