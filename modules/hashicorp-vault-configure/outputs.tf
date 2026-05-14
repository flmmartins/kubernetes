output "kubernetes_backend" {
  value = vault_auth_backend.kubernetes.path
}

output "pki_backend" {
  value = try(vault_mount.pki[0].path, "")
}

output "onepassword_backend" {
  value = try(vault_generic_endpoint.op_connect_mount[0].path, "")
}

output "kv_backend" {
  value = try(vault_mount.kv[0].path, "")
}

output "vault_pki_issuer" {
  value = try(kubernetes_manifest.pki_issuer[0].manifest.metadata.name, "")
}
