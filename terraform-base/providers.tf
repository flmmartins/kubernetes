provider "kubernetes" {
  host = var.kubernetes_api
}

# Don't use manifests = true in helm provider. The mutating webhook from vault injects things in vault pods
# Terraform wants to remove then and you end up in a loop
provider "helm" {}

provider "vault" {
  address = var.vault_address
  #token - configure VAULT_TOKEN env var
  ca_cert_file = var.vault_ca_file
}