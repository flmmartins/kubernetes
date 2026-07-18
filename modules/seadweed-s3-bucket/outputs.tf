output "secret_name" {
  description = "Name of the secret in kubernetes containing s3 credentials"
  value       = kubernetes_manifest.s3_credentials.manifest.spec.secretRef.name
}

output "secret_fields" {
  description = "Name of the keys inside kubernetes secret"
  value = {
    access = var.access_key_field
    secret = var.secret_key_field
  }
}

output "bucket" {
  description = "Name of the created bucket"
  value       = kubernetes_manifest.bucket.manifest.metadata.name
}
