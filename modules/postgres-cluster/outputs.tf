output "rw_svc" {
  description = "Read write service to connect to the cluster"
  value       = "${var.cluster.name}-rw.${kubernetes_namespace_v1.this.metadata[0].name}.svc"
}

output "ro_svc" {
  description = "Read only service to connect to the cluster"
  value       = "${var.cluster.name}-ro.${kubernetes_namespace_v1.this.metadata[0].name}.svc"
}

output "role_secret_names" {
  description = "Map of role name to the secret name created in the app namespace"
  value = {
    for name in keys(local.roles_with_secrets) : name => "${name}-credentials"
  }
}
