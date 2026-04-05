variable "vault_address_internal" {
  description = "Vault Internal URL for communication between pods"
  default     = "https://vault.vault:8200"
}

variable "vault_csi_ca_cert_path" {
  description = "Vault Parameters used by CSI Secret Provider Classes"
  default     = "/vault/tls/vault.ca"
}

variable "onepassword_vault_path" {
  type        = string
  description = "1password vault path for secrets. It contain the <path prefix>/<vault id>"
}

variable "private_domain" {
  type        = string
  description = "Apps private domain name"
}

variable "private_cert_issuer" {
  description = "Cluster Issuer responsible for internal self signed certificates"
  default     = "private-issuer"
}

variable "public_domain" {
  type        = string
  description = "Apps public domain name"
}

variable "nginx_ip" {
  type        = string
  description = "IP of NGINX"
}

variable "nfs_ip" {
  description = "NFS IP"
}

variable "persistent_storage_class" {
  description = "Name of the storage class which persist data"
  default     = "persistent"
}

variable "existing_nfs_share" {
  description = "NFS shares"
  type = map(object({
    path        = string
    size        = optional(string, "50Gi")
    user_uid    = number
    group_uid   = number
    access_mode = optional(string, "ReadOnlyMany")
  }))
}

variable "objstore" {
  description = "Object Store User & Group UIDs"
  type = object({
    user_id  = number
    group_id = number
  })
}

variable "monitoring" {
  description = "Monitoring User & Group UIDs"
  type = object({
    user_uid  = number
    group_uid = number
  })
}
