variable "komga_image_version" {
  description = "Komga Ebooks & Comic Reader Version"
  default     = "latest"
}

variable "plex_chart_version" {
  description = "Plex Version"
  default     = "1.4.0"
}

variable "immich_chart_version" {
  description = "Photos Processing App Version"
  default     = "0.9.3"
}

variable "plex_ip" {
  description = "Plex needs load balancer IP to ADVERTISE_IP configuration. This can be a load balancer IP."
  type        = string
}

variable "domain" {
  type        = string
  description = "Domain to use on apps"
}

variable "persistent_storage_class" {
  type        = string
  description = "Name of the storage class which persist data"
}

variable "existing_nfs_share" {
  description = "NFS shares"
  type = map(object({
    size        = string
    user_id     = number
    group_id    = number
    access_mode = string
    path        = string
    server      = string
  }))
}

