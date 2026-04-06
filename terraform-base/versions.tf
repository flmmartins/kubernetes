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

variable "cert_manager_version" {
  description = "Cert Manager Version"
  default     = "v1.19.2"
}
