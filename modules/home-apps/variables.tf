variable "komga_image_version" {
  description = "Komga Ebooks & Comic Reader Version"
  default     = "latest"
}

variable "gateway" {
  description = "Gateway to use for the app"
  type = object({
    name      = string
    namespace = string
  })
}

variable "domain" {
  type        = string
  description = "Domain to use on apps"
}

variable "plex_chart_version" {
  description = "Plex Version"
  default     = "1.5.0"
}

variable "plex_gateway_tcp_listener" {
  description = "Name of the listener that will be used by plex to connect via IP"
  type        = string
}

variable "plex_ip" {
  description = "Plex needs load balancer IP to ADVERTISE_IP configuration. This can be a load balancer IP."
  type        = string
}

variable "immich_chart_version" {
  description = "Photos Processing App Version"
  default     = "0.12.0"
}

variable "immich_database" {
  description = "Database spects for immich"
  type = object({
    server                  = string
    database_name           = string
    credentials_secret_name = string
  })
}

variable "persistent_storage_class" {
  type        = string
  description = "Name of the storage class which persist data"
}

variable "movies_nfs_share" {
  description = "NFS share to use for movies storage"
  type = object({
    size        = string
    user_id     = number
    group_id    = number
    access_mode = string
    path        = string
    server      = string
  })
  default = null
}

variable "music_nfs_share" {
  description = "NFS share to use for music storage"
  type = object({
    size        = string
    user_id     = number
    group_id    = number
    access_mode = string
    path        = string
    server      = string
  })
  default = null
}

variable "tvshows_nfs_share" {
  description = "NFS share to use for TV shows storage"
  type = object({
    size        = string
    user_id     = number
    group_id    = number
    access_mode = string
    path        = string
    server      = string
  })
  default = null
}

variable "ebooks_comics_nfs_share" {
  description = "NFS share to use for ebooks and comics storage"
  type = object({
    size        = string
    user_id     = number
    group_id    = number
    access_mode = string
    path        = string
    server      = string
  })
  default = null
}

variable "emulatorsrooms_nfs_share" {
  description = "NFS share to use for old games emulators storage"
  type = object({
    size        = string
    user_id     = number
    group_id    = number
    access_mode = string
    path        = string
    server      = string
  })
  default = null
}

variable "photos_nfs_share" {
  description = "NFS share to use for photos storage"
  type = object({
    size        = string
    user_id     = number
    group_id    = number
    access_mode = string
    path        = string
    server      = string
  })
  default = null
}
