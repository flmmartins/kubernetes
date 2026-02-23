variable "grafana_vault_password" {
  description = "Object containing vault data to read grafana password from vault"
  type = object({
    secret_path            = optional(string)
    vault_address          = optional(string)
    vault_csi_ca_cert_path = optional(string)
  })
  default = {}
}

variable "chart_version" {
  type        = string
  description = "Prometheus Stack Chart Version"
  default     = "81.4.2"
}

variable "grafana_url" {
  type        = string
  description = "Grafana URL"
}

variable "grafana_ingress_annotations" {
  type    = map(string)
  default = {}
}

variable "grana_storage_size" {
  type        = string
  description = "Grafana Storage Size"
  default     = "10Gi"
}

variable "storage_class_name" {
  description = "Storage class name for prometheus and alertmanager"
  type        = string
}

variable "retention_days" {
  type        = string
  description = "Prometheus retention days"
  default     = "15d"
}

variable "prometheus_storage_size" {
  type        = string
  description = "Prometheus Storage Size"
  default     = "50Gi"
}

variable "prometheus_cpu_request" {
  type        = string
  description = "Prometheus CPU Request"
  default     = "100m"
}

variable "prometheus_cpu_limit" {
  type        = string
  description = "Prometheus CPU Limit"
  default     = "300m"
}

variable "prometheus_memory_request" {
  type        = string
  description = "Prometheus Memory Request"
  default     = "300Mi"
}

variable "prometheus_memory_limit" {
  type        = string
  description = "Prometheus Memory Limit"
  default     = "512Mi"
}

variable "alertmanager_storage_size" {
  type        = string
  description = "Alert Manager Storage Size"
  default     = "10Gi"
}

variable "alertmanager_cpu_request" {
  type        = string
  description = "Alert Manager CPU Request"
  default     = "25m"
}

variable "alertmanager_cpu_limit" {
  type        = string
  description = "Alert Manager CPU Limit"
  default     = "100m"
}

variable "alertmanager_memory_request" {
  type        = string
  description = "Alert Manager Memory Request"
  default     = "64Mi"
}

variable "alertmanager_memory_limit" {
  type        = string
  description = "Alert Manager Memory Limit"
  default     = "256Mi"
}

variable "operator_cpu_request" {
  type        = string
  description = "Operator CPU Request"
  default     = "100m"
}

variable "operator_cpu_limit" {
  type        = string
  description = "Operator CPU Limit"
  default     = "200m"
}

variable "operator_memory_request" {
  type        = string
  description = "Operator Memory Request"
  default     = "100Mi"
}

variable "operator_memory_limit" {
  type        = string
  description = "Operator Memory Limit"
  default     = "200Mi"
}

variable "security_context" {
  description = "Security context for the prometheus stack"
  type = object({
    user_uid  = optional(number)
    group_uid = optional(number)
  })
  default = {}
}


