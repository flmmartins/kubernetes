variable "kubernetes_api" {
  type        = string
  description = "Kubernetes API used by terraform provider"
}

variable "vault_address" {
  description = "Vault Address for Terraform to be able to access"
  default     = "https://127.0.0.1:8200"
}

variable "vault_address_internal" {
  description = "Vault Internal URL for communication between pods"
  default     = "https://vault.vault:8200"
}

variable "vault_csi_ca_cert_path" {
  description = "Vault Parameters used by CSI Secret Provider Classes"
  default     = "/vault/tls/vault.ca"
}

variable "vault_ca_file" {
  description = "Vault CA File for TF provider"
  default     = "vault.ca"
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

variable "pihole_ip_cidr" {
  type        = string
  description = "IP CIDR assigned to Pihole DNS"
}

variable "pihole_additionalHostsEntries" {
  type        = list(string)
  description = "Pihole Hosts Entries comming from router"
}

variable "nginx_ip" {
  type        = string
  description = "IP of NGINX"
}

variable "nfs_ip" {
  description = "NFS IP"
}

variable "plex_ip_cidr" {
  type        = string
  description = "IP of Plex"
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

variable "minio" {
  description = "Minio User & Group UIDs"
  type = object({
    user_uid  = number
    group_uid = number
  })
}

variable "monitoring" {
  description = "Monitoring User & Group UIDs"
  type = object({
    user_uid  = number
    group_uid = number
  })
}