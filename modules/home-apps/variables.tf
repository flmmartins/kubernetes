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

variable "immich_album_creator_version" {
  description = "Version of the immich-folder-album-creator image. According to github it has to be latest"
  type        = string
  default     = "latest"
}

variable "immich_album_creator_schedule" {
  description = "Cron schedule for the album creator job"
  type        = string
  default     = "0 4 * * *"
}

variable "immich_api_key_vault" {
  description = <<-EOT
    Vault Agent configuration to inject the Immich API key into the album creator job.
    The API key must be stored in Vault and will be injected as an environment variable.
    In order for key to be fetched we require the name of the vault ca configmap and it will be copy to immich namespace

    Example:
    immich_api_key_vault = {
      secret_path   = "op/vaults/<vault-id>/items/immich"
      vault_address = "https://vault.vaultnamespace:8200"
      api_key_field = "apiKey"
      vault_ca_configmap_name      = "vault-ca"
      vault_ca_configmap_namespace = "vault"
    }
  EOT
  type = object({
    secret_path                  = string
    vault_csi_ca_cert_path       = optional(string, "/vault/tls/ca.crt")
    api_key_field                = optional(string, "immich-folder-album-creator")
    vault_ca_configmap_name      = string
    vault_ca_configmap_namespace = string
  })
  default = null
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
