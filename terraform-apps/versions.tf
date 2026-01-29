variable "pihole_chart_version" {
  description = "Pihole Version"
  default     = "2.35.0"
}

variable "minio_chart_version" {
  description = "Minio Version"
  default     = "5.4.0"
}

variable "komga_image_version" {
  description = "Komga Ebooks & Comic Reader Version"
  default     = "latest"
}

variable "plex_chart_version" {
  description = "Plex Version"
  default     = "1.4.0"
}

variable "postgres_operator_chart_version" {
  description = "CloudNative PG Version"
  default     = "v0.24.0"
}

variable "immich_chart_version" {
  description = "Photos Processing App Version"
  default     = "0.9.3"
}

variable "velero_chart_version" {
  description = "Velero Version"
  default     = "11.3.2"
}

variable "velero_aws_plugin_version" {
  description = "AWS Plugin for Velero Version. It has to be compatible with velero. Check: https://github.com/vmware-tanzu/velero-plugin-for-aws?tab=readme-ov-file#compatibility"
  default     = "v1.13.2"
}