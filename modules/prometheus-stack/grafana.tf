# TODO: Test random password later
ephemeral "random_password" "grafana" {
  count = var.grafana_vault_password == null ? 1 : 0

  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "kubernetes_secret_v1" "grafana" {
  count = var.grafana_vault_password == null ? 1 : 0

  metadata {
    name      = "grafana"
    namespace = kubernetes_namespace_v1.this.metadata[0].name
    labels    = merge(local.labels, { component = "credentials" })
  }

  data_wo = {
    "admin-password" = ephemeral.random_password.grafana[0].result
    "admin-user"     = "admin"
  }
}

resource "vault_policy" "grafana" {
  count = var.grafana_vault_password != null ? 1 : 0

  name   = "grafana"
  policy = <<EOT
path "${var.grafana_vault_password.secret_path}" { capabilities = ["read"] }
EOT
}

resource "vault_kubernetes_auth_backend_role" "grafana" {
  count = var.grafana_vault_password != null ? 1 : 0

  role_name                        = "grafana"
  bound_service_account_names      = ["prometheus-stack-kube-prom-operator"]
  bound_service_account_namespaces = [kubernetes_namespace_v1.this.metadata[0].name]
  token_max_ttl                    = 1440 #24H
  token_policies                   = [vault_policy.grafana[0].name]
}
