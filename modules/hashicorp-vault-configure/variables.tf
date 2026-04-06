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
  description = "Data to create a PKI"
  type = object({
    ca_pembundle = string
    path         = optional(string, "pki")
    role_name    = optional(string, "pki")
  })
  default = null
}
