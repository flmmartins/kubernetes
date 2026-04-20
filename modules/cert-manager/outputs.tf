output "letsencrypt_issuer" {
  value = try(kubernetes_manifest.letsencrypt_issuer[0].manifest.metadata.name, "not-avaiable")
}

output "uploaded_ca_issuer" {
  value = try(kubernetes_manifest.uploaded_ca_issuer[0].manifest.metadata.name, "not-avaiable")
}

output "vault_pki_issuer" {
  value = try(kubernetes_manifest.vault_pki_issuer[0].manifest.metadata.name, "not-avaiable")
}
