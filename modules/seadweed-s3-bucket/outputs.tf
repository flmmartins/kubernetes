output "s3_secret_name" {
  description = "Name of the secret in kubernetes containing s3 credentials"
  value       = kubernetes_manifest.s3_credentials.manifest.spec.secretRef.name
}

output "s3_bucket" {
  description = "Name of the created bucket"
  value       = kubernetes_manifest.bucket.manifest.metadata.name
}
