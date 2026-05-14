locals {
  seaweedfs_s3api_url = "s3api.${var.private_domain}"
  seaweedfs_admin_url = "seaweedfs.${var.private_domain}"
  grafana_url         = "grafana.${var.public_domain}"
}

module "seaweedfs" {
  source = "../modules/seaweedfs"

  buckets = [
    {
      name       = "terraform"
      objectLock = true
      ttl        = "90d"
    },
    {
      name = "velero"
      ttl  = "30d"
    }
  ]

  vault_password = {
    vault_address = var.vault_address_internal
    secret_path   = format("%s/seaweedfs", var.onepassword_vault_path)
  }

  security_context = {
    user_id  = var.objstore_credentials.user_id
    group_id = var.objstore_credentials.group_id
  }

  s3api_url    = local.seaweedfs_s3api_url
  admin_ui_url = local.seaweedfs_admin_url
  gateway      = var.gateway

  persistent_storage_class_name = var.persistent_storage_class
}

module "velero" {
  source = "../modules/velero"

  snapshots_enabled = false
  backup_storage_locations = [
    {
      name = "talos-truenas"
      config = {
        region = "seaweedfs"
        s3Url  = module.seaweedfs.s3_kubernetes_svc
      }
    }
  ]

  vault_password = {
    vault_address = var.vault_address_internal
    secret_path   = format("%s/velero", var.onepassword_vault_path)
  }
}

module "kube_prometheus_stack" {
  source = "../modules/prometheus-stack"

  vault_password = {
    vault_address = var.vault_address_internal
    secret_path   = format("%s/grafana", var.onepassword_vault_path)
  }

  persistent_storage_class_name = var.persistent_storage_class
  security_context = {
    user_id  = var.monitoring_credentials.user_id
    group_id = var.monitoring_credentials.group_id
  }

  grafana_url = local.grafana_url
  gateway     = var.gateway
}

module "home-apps" {
  source                    = "../modules/home-apps"
  domain                    = var.public_domain
  persistent_storage_class  = var.persistent_storage_class
  plex_ip                   = var.istio_ip
  plex_gateway_tcp_listener = "plex-tcp"
  gateway                   = var.gateway

  movies_nfs_share         = var.existing_nfs_share["movies"]
  music_nfs_share          = var.existing_nfs_share["music"]
  tvshows_nfs_share        = var.existing_nfs_share["tv-shows"]
  ebooks_comics_nfs_share  = var.existing_nfs_share["ebooks-comics"]
  emulatorsrooms_nfs_share = var.existing_nfs_share["emuladores-rooms"]
  photos_nfs_share         = var.existing_nfs_share["photos"]
}
