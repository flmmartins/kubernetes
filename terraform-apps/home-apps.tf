module "home-apps" {
  source                   = "../modules/home-apps"
  domain                   = var.public_domain
  persistent_storage_class = var.persistent_storage_class
  plex_ip                  = var.nginx_ip
  existing_nfs_share       = var.existing_nfs_share
}
