provider "kubernetes" {
  host = var.kubernetes_api
}

provider "vault" {
  address = var.vault_address
  #token - configure VAULT_TOKEN env var
  ca_cert_file = var.vault_ca_file
}