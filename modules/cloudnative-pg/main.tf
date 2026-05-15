terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
    }
  }
}

locals {
  name            = "pg-operator"
  service_account = "pg-operator"
}

resource "helm_release" "postgres_operator" {
  name             = local.name
  create_namespace = true
  namespace        = local.name
  repository       = "https://cloudnative-pg.github.io/charts"
  version          = var.chart_version
  chart            = "cloudnative-pg"
  values = [
    <<-EOF
    serviceAccount:
      name: ${local.service_account}
    podLabels:
      part-of: cloudnative-pg
      component: operator
    %{~if var.security_context != null~}
    podSecurityContext:
      runAsUser: ${var.security_context.user_id}
      runAsGroup: ${var.security_context.group_id}
      fsGroup: ${var.security_context.group_id}
      fsGroupChangePolicy: OnRootMismatch
      seccompProfile:
        type: RuntimeDefault
    %{~endif~}
    resources:
      requests:
        cpu: ${var.operator_resources_requests_cpu}
        memory: ${var.operator_resources_requests_memory}
      limits:
        cpu: ${var.operator_resources_limits_cpu}
        memory: ${var.operator_resources_limits_memory}
    EOF
  ]
}
