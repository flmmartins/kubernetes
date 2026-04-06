terraform {
  required_providers {
    vault = {
      source = "hashicorp/vault"
    }
  }
}

##################################
# KUBERNETES AUTH
##################################
resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
}

resource "vault_kubernetes_auth_backend_config" "kubernetes" {
  backend         = vault_auth_backend.kubernetes.path
  kubernetes_host = "https://kubernetes.default.svc.cluster.local:443"
}


##################################
# STANDALONE SECRET ENGINE
##################################

resource "vault_mount" "kv" {
  count = var.kv_path != null ? 1 : 0

  path        = var.kv_path
  type        = "kv"
  options     = { version = "2" }
  description = "KV secret engine"
}


##################################
# 1PASSWORD SECRET ENGINE
##################################
resource "vault_plugin" "op_connect" {
  count = var.onepassword_connect != null ? 1 : 0

  type    = "secret"
  name    = "op-connect"
  command = "op-connect"
  sha256  = "8eb865ca4ac9c7c87fa902985383da0132462f299765752f74e6f212e796a5bd"
}

# Vault Mount terraform doesn't do mount on plugins
# Although it seems like it, it doesn't do all operations
# https://github.com/hashicorp/terraform-provider-vault/issues/623
resource "vault_generic_endpoint" "op_connect_mount" {
  count = var.onepassword_connect != null ? 1 : 0

  depends_on = [vault_plugin.op_connect]

  path = "sys/mounts/op"

  data_json = jsonencode({
    type        = "plugin",
    plugin_name = vault_plugin.op_connect[0].name,
    description = "1Password Connect secrets engine"

    # Because default ttl is 32 days
    config = {
      default_lease_ttl = "5m",
      max_lease_ttl     = "1h",
      force_no_cache    = true
    }
  })
  # Due to data being sensitive it always changes
  lifecycle {
    ignore_changes = [data_json]
  }
}

resource "vault_generic_endpoint" "onepassword-connect-config" {
  count = var.onepassword_connect != null ? 1 : 0

  depends_on = [vault_generic_endpoint.op_connect_mount]

  path = "op/config"

  data_json = jsonencode({
    op_connect_host  = var.onepassword_connect.host
    op_connect_token = var.onepassword_connect.token
  })
  # Due to data being sensitive it always changes
  lifecycle {
    ignore_changes = [data_json]
  }
}


##################################
# PKI & CERT MANAGER
##################################
resource "vault_mount" "pki" {
  count = var.pki != null ? 1 : 0

  path                  = var.pki.path
  type                  = "pki"
  description           = "Tamriel Tower Apps CA"
  max_lease_ttl_seconds = 31536000 # 1 years
}

resource "vault_pki_secret_backend_config_ca" "pki" {
  count = var.pki != null ? 1 : 0

  depends_on = [vault_mount.pki]

  backend = vault_mount.pki[0].path

  pem_bundle = <<EOT
  ${var.pki.ca_pembundle}
  EOT
}

resource "vault_pki_secret_backend_config_urls" "pki" {
  count      = var.pki != null ? 1 : 0
  depends_on = [vault_mount.pki]

  backend = vault_mount.pki[0].path

  issuing_certificates = [
    "${var.address}/v1/${var.pki.path}/ca",
  ]
  crl_distribution_points = [
    "${var.address}/v1/${var.pki.path}/crl",
  ]
}

# Tried many combinations for kubernetes, in the end had to allow any
resource "vault_pki_secret_backend_role" "pki" {
  count = var.pki != null ? 1 : 0

  backend                     = vault_mount.pki[0].path
  name                        = var.pki.role_name
  allow_any_name              = true
  allow_glob_domains          = true
  allow_wildcard_certificates = true
}

resource "vault_policy" "pki" {
  count = var.pki != null ? 1 : 0

  name   = "issuer-${var.pki.role_name}"
  policy = <<EOT
path "${vault_mount.pki[0].path}*" {
  capabilities = ["read", "list"] }
path "${vault_mount.pki[0].path}/sign/${vault_pki_secret_backend_role.pki[0].name}" {
  capabilities = ["create", "update"] } 
path "${vault_mount.pki[0].path}/issue/${vault_pki_secret_backend_role.pki[0].name}" {
  capabilities = ["create"] }
EOT
}
