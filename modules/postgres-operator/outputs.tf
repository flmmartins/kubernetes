output "service_account" {
  description = "The service account used by the PostgreSQL operator to manage resources in the cluster"
  value       = local.service_account
}
