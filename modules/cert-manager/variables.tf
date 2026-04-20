variable "chart_version" {
  description = "Cert Manager Version"
  default     = "v1.19.2"
}

variable "default_cert_issuer" {
  description = "Default cluster issuer name. If this is changed make sure it has a matching issuer block"
  default     = "uploaded-ca-issuer"
}

variable "vault_pki_issuer" {
  description = "Vault pki issuer"
  type = object({
    issuer_name = optional(string, "vault-issuer")
    ca_file     = string
    server      = string
    sign_path   = string
    policy      = string
  })
  default = null
}

variable "letsencrypt_issuer" {
  description = "Letsencrypt issuer"
  type = object({
    issuer_name = optional(string, "letsencrypt-issuer")
    dns_provider = object({
      name      = string
      e-mail    = string
      api_token = optional(string)
    })
    dns_provider_vault_password = optional(object({
      secret_path            = string
      vault_address          = string
      vault_csi_ca_cert_path = optional(string, "/vault/tls/ca.crt")
      # Fields in Secret Manager
      password_field = optional(string, "password")
    }))
  })
  sensitive = true
  default   = null
}

variable "uploaded_ca_issuer" {
  description = "This will create an issue based on CA you upload. Please include cert and key so cert manager can issue certificates from it"
  type = object({
    issuer_name      = optional(string, "uploaded-ca-issuer")
    certificate_cert = string
    certificate_key  = string
  })
  sensitive = true
  default   = null
}

# =============================================================================
# Resource Variables
# =============================================================================

# -----------------------------------------------------------------------------
# Controller
# -----------------------------------------------------------------------------

variable "cert_manager_memory_request" {
  description = "Memory request for cert-manager controller"
  type        = string
  default     = "25Mi"
}

variable "cert_manager_cpu_request" {
  description = "CPU request for cert-manager controller"
  type        = string
  default     = "5m"
}

variable "cert_manager_memory_limit" {
  description = "Memory limit for cert-manager controller"
  type        = string
  default     = "100Mi"
}

variable "cert_manager_cpu_limit" {
  description = "CPU limit for cert-manager controller"
  type        = string
  default     = "20m"
}

# -----------------------------------------------------------------------------
# Webhook
# -----------------------------------------------------------------------------
variable "cert_manager_webhook_memory_request" {
  description = "Memory request for cert-manager webhook"
  type        = string
  default     = "75Mi"
}

variable "cert_manager_webhook_cpu_request" {
  description = "CPU request for cert-manager webhook"
  type        = string
  default     = "5m"
}

variable "cert_manager_webhook_memory_limit" {
  description = "Memory limit for cert-manager webhook"
  type        = string
  default     = "120Mi"
}

variable "cert_manager_webhook_cpu_limit" {
  description = "CPU limit for cert-manager webhook"
  type        = string
  default     = "20m"
}

# -----------------------------------------------------------------------------
# CA Injector
# -----------------------------------------------------------------------------
variable "cert_manager_cainjector_memory_request" {
  description = "Memory request for cert-manager cainjector"
  type        = string
  default     = "90Mi"
}

variable "cert_manager_cainjector_cpu_request" {
  description = "CPU request for cert-manager cainjector"
  type        = string
  default     = "20m"
}

variable "cert_manager_cainjector_memory_limit" {
  description = "Memory limit for cert-manager cainjector"
  type        = string
  default     = "200Mi"
}

variable "cert_manager_cainjector_cpu_limit" {
  description = "CPU limit for cert-manager cainjector"
  type        = string
  default     = "100m"
}
