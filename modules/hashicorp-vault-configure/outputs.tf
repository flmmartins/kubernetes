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

output "pki_policy" {
  value = try(vault_policy.pki[0].name, "")
}

output "pki_sign_path" {
  value = try("${vault_mount.pki[0].path}/sign/${vault_pki_secret_backend_role.pki[0].name}", "")
}
