output "persistent_storage_class" {
  description = "Name of the persistent storage class"
  value       = kubernetes_storage_class_v1.persistent.metadata[0].name
}

output "default_storage_class" {
  description = "Name of the default storage class"
  value       = kubernetes_storage_class_v1.default.metadata[0].name
}