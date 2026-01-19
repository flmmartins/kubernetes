variable "kubernetes_api" {
  type        = string
  description = "Kubernetes API used by terraform provider"
}

variable "nfs" {
  description = "NFS Share for CSI NFS"
  type = object({
    ip           = string
    share_folder = string
    group_uid    = number
  })
}

variable "nginx_ip_cidrs" {
  type        = list(string)
  description = "IP assigned to NGINX"
}

variable "onepassword_connect_token" {
  description = "1password Connect Token"
  sensitive   = true
}

variable "vault_address" {
  description = "Vault Address for Terraform to be able to access"
  default     = "https://127.0.0.1:8200"
}

variable "vault_address_internal" {
  description = "Vault Internal URL for communication between pods"
  default     = "https://vault.vault:8200"
}

variable "vault_ca_file" {
  description = "Vault CA File for TF provider"
  default     = "vault.ca"
}

variable "vault_user_uid" {
  description = "Vault User UID"
}

variable "vault_group_uid" {
  description = "Vault Group UID"
}

variable "vault_apps_cert_pembundle_file_path" {
  description = "Vault CA File Path to import to Vault PKI"
}

variable "private_domain" {
  description = "Private domain name"
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
}