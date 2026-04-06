# =============================================================================
# OUTPUTS
# =============================================================================

output "s3_url" {
  description = "S3-compatible endpoint"
  value       = "https://${var.s3api_url}"
}

output "s3_kubernetes_svc" {
  description = "S3-compatible internal to the cluster"
  value       = "http://seaweedfs-s3.${kubernetes_namespace_v1.this.metadata[0].name}.svc.cluster.local:8333"
}

output "admin_url" {
  description = "SeaweedFS Admin UI"
  value       = "https://${var.admin_ui_url}"
}
