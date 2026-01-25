variable "pihole_chart_version" {
  description = "Pihole Version"
  default     = "2.31.0"
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
  default     = "1.0.2"
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