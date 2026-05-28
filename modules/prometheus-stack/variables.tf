variable "chart_version" {
  type        = string
  description = "Prometheus Stack Chart Version"
  default     = "84.5.0"
}

variable "grafana_url" {
  type        = string
  description = "Grafana URL"
}

variable "gateway" {
  description = "Gateway to use for the app"
  type = object({
    name      = string
    namespace = string
  })
}

variable "retention_days" {
  type        = string
  description = "Prometheus retention days"
  default     = "15d"
}

variable "vault_password" {
  description = "Object containing vault data to read grafana password from vault. If not, provided a password will be generated"
  type = object({
    secret_path            = optional(string)
    vault_address          = optional(string)
    vault_csi_ca_cert_path = optional(string, "/vault/tls/ca.crt")
    # Fields in Secret Manager
    username_field = optional(string, "username")
    password_field = optional(string, "password")
  })
  default = null
}

# -----------------------------------------------------------------------------
# Storage
# -----------------------------------------------------------------------------
variable "persistent_storage_class_name" {
  description = "Storage class name for prometheus and alertmanager"
  type        = string
}

variable "prometheus_storage_size" {
  type        = string
  description = "Prometheus Storage Size"
  default     = "50Gi"
}

variable "alertmanager_storage_size" {
  type        = string
  description = "Alert Manager Storage Size"
  default     = "10Gi"
}

variable "grana_storage_size" {
  type        = string
  description = "Grafana Storage Size"
  default     = "10Gi"
}

variable "security_context" {
  description = "Security context for the prometheus stack"
  type = object({
    user_id  = optional(number)
    group_id = optional(number)
  })
  default = null
}

# =============================================================================
# Resource Variables
# =============================================================================

# -----------------------------------------------------------------------------
# Prometheus
# -----------------------------------------------------------------------------
variable "prometheus_cpu_request" {
  type        = string
  description = "Prometheus CPU Request"
  default     = "300m"
}

variable "prometheus_cpu_limit" {
  type        = string
  description = "Prometheus CPU Limit"
  default     = "300m"
}

variable "prometheus_memory_request" {
  type        = string
  description = "Prometheus Memory Request"
  default     = "1Gi"
}

variable "prometheus_memory_limit" {
  type        = string
  description = "Prometheus Memory Limit"
  default     = "1Gi"
}

# -----------------------------------------------------------------------------
# Grafana
# -----------------------------------------------------------------------------
variable "grafana_cpu_request" {
  type    = string
  default = "200m"
}

variable "grafana_cpu_limit" {
  type    = string
  default = "200m"
}

variable "grafana_memory_request" {
  type    = string
  default = "756Mi"
}

variable "grafana_memory_limit" {
  type    = string
  default = "756Mi"
}


# -----------------------------------------------------------------------------
# Kube State metrics
# -----------------------------------------------------------------------------
variable "kube_state_metrics_cpu_request" {
  type    = string
  default = "100m"
}

variable "kube_state_metrics_cpu_limit" {
  type    = string
  default = "100m"
}

variable "kube_state_metrics_memory_request" {
  type    = string
  default = "256Mi"
}

variable "kube_state_metrics_memory_limit" {
  type    = string
  default = "256Mi"
}

# -----------------------------------------------------------------------------
# Alert Manager
# -----------------------------------------------------------------------------
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

# -----------------------------------------------------------------------------
# Operator
# -----------------------------------------------------------------------------
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

# -----------------------------------------------------------------------------
# Node Exporter
# -----------------------------------------------------------------------------
variable "node_exporter_cpu_request" {
  type    = string
  default = "50m"
}
variable "node_exporter_cpu_limit" {
  type    = string
  default = "200m"
}
variable "node_exporter_memory_request" {
  type    = string
  default = "64Mi"
}
variable "node_exporter_memory_limit" {
  type    = string
  default = "128Mi"
}