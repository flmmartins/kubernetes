output "letsencrypt_issuer" {
  value = try(kubernetes_manifest.letsencrypt_issuer[0].manifest.metadata.name, "not-avaiable")
}

output "uploaded_ca_issuer" {
  value = try(kubernetes_manifest.uploaded_ca_issuer[0].manifest.metadata.name, "not-avaiable")
}

output "namespace" {
  value = kubernetes_namespace_v1.this.metadata[0].name
}

output "service_account_secret_name" {
  value = kubernetes_secret_v1.cert_manager_sa_token.metadata[0].name
}

output "service_account_name" {
  value = local.service_account_name
}
