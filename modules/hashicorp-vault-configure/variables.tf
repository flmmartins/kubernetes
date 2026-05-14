variable "onepassword_connect" {
  description = "Plugin will be installed if data is provided"
  type = object({
    token = string
    host  = string
  })
  sensitive = true
  default   = null
}

variable "address" {
  description = "Vault URL"
  type        = string
}

variable "kv_path" {
  description = "Set this to create a standalone key value. Eg: secret"
  type        = string
  default     = null
}

variable "pki" {
  description = "Data to create a PKI and a cluster issuer for pki. If not provided, PKI won't be created. Root CA is the CA of PKI for external clients and vault_internal_ca is to use inside kubernetes only"
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
