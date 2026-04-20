output "kubernetes_svc" {
  description = "Kubernetes service for vault"
  value       = "https://vault.${kubernetes_namespace_v1.this.metadata[0].name}:8200"
}

output "url" {
  description = "Vault Admin UI"
  value       = "https://${var.url}"
}

output "csi_ca_path" {
  description = "Vault CA path inside CSI pod"
  value       = "${local.csi_cert_mounth_path}/ca.crt"
}
