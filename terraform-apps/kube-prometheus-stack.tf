locals {
  grafana_url = "grafana.${var.public_domain}"
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
  grafana_ingress_annotations = {
    "kubernetes.io/tls-acme"      = "true"
    "cert-manager.io/common-name" = local.grafana_url
    "cert-manager.io/dns-names"   = local.grafana_url
  }
}
