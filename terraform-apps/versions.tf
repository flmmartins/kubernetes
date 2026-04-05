variable "postgres_operator_chart_version" {
  description = "CloudNative PG Version"
  default     = "v0.24.0"
}

variable "velero_chart_version" {
  description = "Velero Version"
  default     = "12.0.0"
}

variable "velero_aws_plugin_version" {
  description = "AWS Plugin for Velero Version. It has to be compatible with velero. Check: https://github.com/vmware-tanzu/velero-plugin-for-aws?tab=readme-ov-file#compatibility"
  default     = "v1.13.2"
}
