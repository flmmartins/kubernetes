locals {
  grafana_url = "grafana.${var.public_domain}"
}

module "kube_prometheus_stack" {
  source = "../modules/prometheus-stack"

  grafana_vault_password = {
    vault_address          = var.vault_address_internal
    vault_csi_ca_cert_path = var.vault_csi_ca_cert_path
    secret_path            = format("%s/grafana", var.onepassword_vault_path)
  }
  chart_version = var.prometheus_stack_chart_version
  grafana_url   = local.grafana_url
  security_context = {
    user_uid  = var.monitoring.user_uid
    group_uid = var.monitoring.group_uid
  }

  storage_class_name = var.persistent_storage_class
  grafana_ingress_annotations = {
    "kubernetes.io/tls-acme"      = "true"
    "cert-manager.io/common-name" = local.grafana_url
    "cert-manager.io/dns-names"   = local.grafana_url
  }
}