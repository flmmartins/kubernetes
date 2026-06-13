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

# PG Operator is different module due to the CRD manifest issue on plan
# Where it can't find CRD, so you have to apply with target
module "pg-operator" {
  source = "../modules/cloudnative-pg"

  security_context = {
    user_id  = var.postgres_credentials.user_id
    group_id = var.postgres_credentials.group_id
  }
}

module "main-pg-cluster" {
  source = "../modules/postgres-cluster"

  cluster = {
    name          = "pg-cluster"
    storage_class = var.persistent_storage_class
  }

  certificate_issuer = var.vault_pki_issuer

  # When adding a role, it will create the password in the namespace
  roles = [{
    name                       = "immich"
    create_secret_in_namespace = "immich-photos"
  }]

  databases = [{
    name       = "immich"
    owner      = "immich"
    extensions = ["cube", "earthdistance", "vector"]
  }]
}

module "home-apps" {
  depends_on                = [module.main-pg-cluster]
  source                    = "../modules/home-apps"
  domain                    = var.public_domain
  persistent_storage_class  = var.persistent_storage_class
  plex_ip                   = var.istio_ip
  plex_gateway_tcp_listener = "plex-tcp"
  gateway                   = var.gateway
  immich_database = {
    server                  = module.main-pg-cluster.rw_svc
    database_name           = "immich"
    credentials_secret_name = module.main-pg-cluster.role_secret_names["immich"]
  }
  immich_api_key_vault = {
    vault_address                = var.vault_address_internal
    vault_ca_configmap_name      = var.vault_ca_configmap.name
    vault_ca_configmap_namespace = var.vault_ca_configmap.namespace
    secret_path                  = format("%s/immich", var.onepassword_vault_path)
  }

  movies_nfs_share         = var.existing_nfs_share["movies"]
  music_nfs_share          = var.existing_nfs_share["music"]
  tvshows_nfs_share        = var.existing_nfs_share["tv-shows"]
  ebooks_comics_nfs_share  = var.existing_nfs_share["ebooks-comics"]
  emulatorsrooms_nfs_share = var.existing_nfs_share["emuladores-rooms"]
  photos_nfs_share         = var.existing_nfs_share["photos"]
}
