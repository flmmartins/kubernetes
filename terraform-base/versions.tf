#=====================
# VERSIONS
#=====================
variable "nginx_chart_version" {
  description = "NGINX Chart Version"
  default     = "4.14.2"
}

variable "cert_manager_version" {
  description = "Cert Manager Version"
  default     = "v1.19.2"
}
