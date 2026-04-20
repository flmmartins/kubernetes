variable "vault_address_internal" {
  description = "Vault Internal URL for communication between pods"
  default     = "https://vault.vault:8200"
}

variable "onepassword_vault_path" {
  type        = string
  description = "1password vault path for secrets. It contain the <path prefix>/<vault id>"
}

variable "private_domain" {
  type        = string
  description = "Apps private domain name"
}

variable "vault_pki_issuer" {
  description = "Cluster Issuer responsible for internal self signed certificates"
  default     = "vault-issuer"
}

variable "public_domain" {
  type        = string
  description = "Apps public domain name"
}

variable "nginx_ip" {
  type        = string
  description = "IP of NGINX"
}

variable "persistent_storage_class" {
  description = "Name of the storage class which persist data"
  default     = "persistent"
}

variable "existing_nfs_share" {
  description = "NFS shares"
  type = map(object({
    size        = optional(string, "50Gi")
    user_id     = number
    group_id    = number
    access_mode = optional(string, "ReadOnlyMany")
    server      = string
    path        = string
  }))
}

variable "objstore_credentials" {
  description = "Object Store User & Group ids"
  type = object({
    user_id  = number
    group_id = number
  })
}

variable "monitoring_credentials" {
  description = "Monitoring User & Group ids"
  type = object({
    user_id  = number
    group_id = number
  })
}
