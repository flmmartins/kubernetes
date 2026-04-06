output "kubernetes_svc" {
  description = "Kubernetes Service"
  value       = "http://onepassword-connect.${local.name}:8080"
}
