variable "chart_version" {
  description = "1password Connect Chart Version"
  default     = "2.2.1"
}

variable "credentials_json_base64" {
  description = "1password Credentials File json encoded in base64"
  type        = string
  sensitive   = true
}
