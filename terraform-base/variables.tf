variable "enable_nfs_csi" {
  default     = true
  description = "Whether to deploy NFS CSI driver and storage classes"
}

variable "environment" {
  description = "Environment you are runnning the code"
  default     = "prod"

  validation {
    condition     = contains(["prod", "local"], var.environment)
    error_message = "The environment must be either 'prod' or 'local'."
  }
}

variable "nfs" {
  description = "NFS Share for CSI NFS"
  type = object({
    ip           = string
    share_folder = string
    group_uid    = number
  })

  validation {
    condition     = var.enable_nfs_csi == true || var.nfs == null
    error_message = "nfs must be provided when enable_nfs_csi is true."
  }
}

variable "storage_provisioner" {
  description = "Storage provisioner. If enable_nfs_csi is false change it"

  validation {
    condition     = var.enable_nfs_csi == false || var.storage_provisioner == "nfs.csi.k8s.io"
    error_message = "enable_nfs_csi is false. A variable storage_provisioner needs to be other than the default value"
  }
}

variable "nginx_ip_cidrs" {
  type        = list(string)
  description = "IP assigned to NGINX"
  default     = []
}

variable "onepassword_connect_token" {
  description = "1password Connect Token"
  sensitive   = true
  default     = ""
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
  default     = 0
}

variable "vault_group_uid" {
  description = "Vault Group UID"
  default     = 0
}

variable "vault_apps_cert_pembundle_file_path" {
  description = "Vault CA File Path to import to Vault PKI"
}

variable "private_domain" {
  description = "Private domain name"
  default     = "cluster.local"
}

variable "private_cert_issuer" {
  description = "Cluster Issuer responsible for internal self signed certificates"
  default     = "private-issuer"
}

variable "onepassword_vault_id" {
  default     = ""
  description = "1password vault id for secrets"
}

variable "cloudflare_email" {
  description = "Email of cloudflare account"
  default     = ""
}