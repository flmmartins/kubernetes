output "s3_secret_name" {
  description = "Name of the secret in kubernetes containing s3 credentials"
  value       = local.secret_name
}
