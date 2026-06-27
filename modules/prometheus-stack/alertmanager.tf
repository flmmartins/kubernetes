# Agent needs CA on the namespace of the application so here we do a copy
data "kubernetes_config_map_v1" "vault_ca" {
  count = var.alertmanager_email != null ? 1 : 0

  metadata {
    name      = var.alertmanager_email.vault_password.vault_ca_configmap_name
    namespace = var.alertmanager_email.vault_password.vault_ca_configmap_namespace
  }
}

resource "kubernetes_secret_v1" "vault_ca" {
  count = var.alertmanager_email != null ? 1 : 0

  metadata {
    name      = "vault-ca"
    namespace = kubernetes_namespace_v1.this.metadata[0].name
    labels = merge(local.labels, {
      component = "vault-ca"
    })
  }

  data_wo = {
    "ca.crt" = data.kubernetes_config_map_v1.vault_ca[0].data["ca.crt"]
  }

  data_wo_revision = 1
}

resource "vault_policy" "alertmanager" {
  count = var.alertmanager_email != null ? 1 : 0

  name   = "alertmanager"
  policy = <<EOT
path "${var.alertmanager_email.vault_password.secret_path}" { capabilities = ["read"] }
EOT
}

resource "vault_kubernetes_auth_backend_role" "alertmanager" {
  count = var.alertmanager_email != null ? 1 : 0

  role_name                        = "alertmanager"
  bound_service_account_names      = ["prometheus-stack-kube-prom-alertmanager"]
  bound_service_account_namespaces = [kubernetes_namespace_v1.this.metadata[0].name]
  token_max_ttl                    = 1440
  token_policies                   = [vault_policy.alertmanager[0].name]
}
