#=====================
# VERSIONS
#=====================
variable "metric_server_chart_version" {
  description = "Metric Server Chart Version"
  default     = "3.13.0"
}

variable "metallb_chart_version" {
  description = "Metal LB Chart Version"
  default     = "0.15.3"
}

variable "nginx_chart_version" {
  description = "NGINX Chart Version"
  default     = "4.14.2"
}

variable "csi_secret_store_chart_version" {
  description = "CSI Secret Store Chart Version"
  default     = "1.5.5"
}

variable "vault_chart_version" {
  description = "Hashicorp Vault Chart Version"
  default     = "0.32.0"
}

variable "csi_driver_nfs_version" {
  description = "CSI Driver NFS Chart Version"
  default     = "4.12.1"
}

variable "onepassword_chart_version" {
  description = "1password Connect Chart Version"
  default     = "2.2.1"
}

variable "vault_plugin_onepasswordconnect_version" {
  description = "Version of 1password connect vault plugin"
  default     = "1.1.0"
}

variable "cert_manager_version" {
  description = "Cert Manager Version"
  default     = "v1.19.2"
}