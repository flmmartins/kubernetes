variable "onepassword_connect" {
  description = "OnePassword plugin configuration. This variable contains sensitive information required to connect to OnePassword. If provided, the plugin will be installed and configured automatically."
  type = object({
    token = string
    host  = string
  })
  sensitive = true
  default   = null
}

variable "address" {
  description = "URL of the Vault server. This is required for connecting to Vault. Example: \"https://vault.example.com\""
  type        = string
}

variable "kv_path" {
  description = "Path prefix for key-value storage engine in vault. This is used to create a namespaced key-value store. If null, no storage will be created. Example: \"secret\" would create keys under /secret."
  type        = string
  default     = null
}

variable "pki" {
  description = <<EOT
Configuration for PKI (Public Key Infrastructure) setup. This variable contains information needed to create a PKI backend and associated issuer in Vault.
Attributes:
  root_ca: Path to the PKI Root Certificate Authority (CA) certificate
  path: Path prefix for PKI storage
  role_name: Name of the PKI role that signs certificates
  vault_internal_ca: Internal Vault CA certificate for Kubernetes cluster. This is required for to allow communication from cert manager to Vault internal svc.
  certmanager_sa: Service account configuration for Cert Manager integration
EOT
  type = object({
    root_ca           = string
    path              = optional(string, "pki")
    role_name         = optional(string, "pki")
    vault_internal_ca = string
    certmanager_sa = object({
      namespace = string
      name      = string
      secret    = string
    })
  })
  default = null
}
