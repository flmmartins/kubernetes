output "kubernetes_svc" {
  description = "Kubernetes service for vault"
  value       = "https://vault.${local.namespace}:8200"
}

output "url" {
  description = "Vault Admin UI"
  value       = "https://${var.url}"
}

output "csi_ca_path" {
  description = "Vault CA path inside CSI pod"
  value       = "${local.csi_cert_mounth_path}/vault.ca"
}
