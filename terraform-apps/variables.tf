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

variable "onepassword_vault_id" {
  type        = string
  description = "1password vault id for secrets"
}

variable "apps_domain" {
  type        = string
  description = "Apps domain name"
}

variable "pihole_ip_cidr" {
  type        = string
  description = "IP CIDR assigned to Pihole DNS"
}

variable "nginx_ip" {
  type        = string
  description = "IP of NGINX"
}

variable "plex_ip_cidr" {
  type        = string
  description = "IP of Plex"
}

variable "pihole_additionalHostsEntries" {
  type        = list(string)
  description = "Pihole Hosts Entries comming from router"
}

variable "certificate_cluster_issuer" {
  description = "Certificate Cluster Issuer"
  default     = "apps-tamrieltower-local"
}

variable "nfs_ip" {
  description = "NFS IP"
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