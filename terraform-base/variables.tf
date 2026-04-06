variable "nfs_ip" {
  description = "NFS IP"
}

variable "nfs_folder" {
  description = "NFS Folder"
}

variable "nginx_ip" {
  type        = string
  description = "IP assigned to NGINX"

}

variable "onepassword_connect_token" {
  description = "1password Connect Token"
  type        = string
  sensitive   = true
  default     = null
}

variable "onepassword_credentials_json_base64" {
  description = "1password Credentials File json encoded in base64"
  type        = string
  sensitive   = true
  default     = null
}

variable "vault_address_internal" {
  description = "Vault Internal URL for communication between pods"
  default     = "https://vault.vault:8200"
}

variable "vault_user_id" {
  description = "Vault User UID"
  default     = ""
}

variable "vault_group_id" {
  description = "Vault Group UID"
  default     = ""
}

variable "vault_apps_cert_pembundle" {
  description = "Vault CA File Path to import to Vault PKI"
  default     = null
}

variable "private_domain" {
  description = "Private domain name"
  default     = ""
}

variable "private_cert_issuer" {
  description = "Cluster Issuer responsible for internal self signed certificates"
  default     = "private-issuer"
}

variable "onepassword_vault_path" {
  default     = ""
  description = "1password vault path for secrets. It contain the <path prefix>/<vault id>"
}

variable "cloudflare_email" {
  description = "Email of cloudflare account"
  default     = null
}

variable "priority_class" {
  description = "Name of the critical priority class"
  type        = string
  default     = "critical"
}

variable "enable_csi_nfs" {
  description = "Whether to enable the NFS CSI driver"
  type        = bool
  default     = true
}
