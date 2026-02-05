provider "kubernetes" {}

provider "helm" {}

provider "vault" {
  address = var.vault_address
  #token - configure VAULT_TOKEN env var
  ca_cert_file = var.vault_ca_file
}

# kubernetes_manifest error on plan with CRDs if resource is not created so we use kubectl instead
provider "kubectl" {
  config_path = "~/.kube/config"
}