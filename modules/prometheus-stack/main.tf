terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    vault = {
      source = "hashicorp/vault"
    }
  }
}

locals {
  name = "prometheus-stack"
  labels = {
    part-of = "monitoring"
  }
}

resource "kubernetes_namespace_v1" "this" {
  metadata {
    name = local.name
    labels = merge(local.labels,
      {
        "pod-security.kubernetes.io/enforce" = "privileged"
        "pod-security.kubernetes.io/audit"   = "privileged"
        "pod-security.kubernetes.io/warn"    = "privileged"
      }
    )
  }
}

# TODO: Test random password later
ephemeral "random_password" "this" {
  count = var.vault_password == null ? 1 : 0

  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "kubernetes_secret_v1" "this" {
  count = var.vault_password == null ? 1 : 0

  metadata {
    name      = "grafana"
    namespace = kubernetes_namespace_v1.this.metadata[0].name
    labels    = merge(local.labels, { component = "credentials" })
  }

  data_wo = {
    "admin-password" = ephemeral.random_password.this[0].result
    "admin-user"     = "admin"
  }
}

resource "vault_policy" "this" {
  count = var.vault_password != null ? 1 : 0

  name   = local.name
  policy = <<EOT
path "${var.vault_password.secret_path}" { capabilities = ["read"] }
EOT
}

resource "vault_kubernetes_auth_backend_role" "this" {
  count = var.vault_password != null ? 1 : 0

  role_name                        = local.name
  bound_service_account_names      = ["prometheus-stack-kube-prom-operator"]
  bound_service_account_namespaces = [kubernetes_namespace_v1.this.metadata[0].name]
  token_max_ttl                    = 1440 #24H
  token_policies                   = [vault_policy.this[0].name]
}

resource "helm_release" "this" {
  name       = local.name
  namespace  = kubernetes_namespace_v1.this.metadata[0].name
  repository = "https://prometheus-community.github.io/helm-charts"
  version    = var.chart_version
  chart      = "kube-prometheus-stack"
  values = [
    <<-EOF
    prometheus:
      prometheusSpec:
        retention: ${var.retention_days}
        resources:
          requests:
            cpu: ${var.prometheus_cpu_request}
            memory: ${var.prometheus_memory_request}
          limits:
            cpu: ${var.prometheus_cpu_limit}
            memory: ${var.prometheus_memory_limit}
        %{~if var.security_context != null~}
        securityContext:
          runAsUser: ${var.security_context.user_id}
          runAsGroup: ${var.security_context.group_id}
          fsGroup: ${var.security_context.group_id}
          fsGroupChangePolicy: OnRootMismatch
          seccompProfile:
            type: RuntimeDefault
        %{~endif~}
        storageSpec:
          volumeClaimTemplate:
            spec:
              storageClassName: ${var.storage_class_name}
              accessModes:
                - ReadWriteOnce
              resources:
                requests:
                  storage: ${var.prometheus_storage_size}
    alertmanager:
      alertmanagerSpec:
        resources:
          requests:
            cpu: ${var.alertmanager_cpu_request}
            memory: ${var.alertmanager_memory_request}
          limits:
            cpu: ${var.alertmanager_cpu_limit}
            memory: ${var.alertmanager_memory_limit}
        %{~if var.security_context != null~}
        securityContext:
          runAsUser: ${var.security_context.user_id}
          runAsGroup: ${var.security_context.group_id}
          fsGroup: ${var.security_context.group_id}
          fsGroupChangePolicy: OnRootMismatch
          seccompProfile:
            type: RuntimeDefault
        %{~endif~}
        storage:
          volumeClaimTemplate:
            spec:
              storageClassName: ${var.storage_class_name}
              accessModes:
                - ReadWriteOnce
              resources:
                requests:
                  storage: ${var.alertmanager_storage_size}
    grafana:
      admin:
      %{~if var.vault_password != null~} 
        existingSecret: grafana
      %{~else~}
        existingSecret: ${kubernetes_secret_v1.this[0].metadata[0].name}
      %{~endif~}
      ingress:
        enabled: true
        annotations: ${jsonencode(var.grafana_ingress_annotations)}
        hosts:
        - ${var.grafana_url}
        tls:
        - hosts:
          - ${var.grafana_url}
          secretName: ${split(".", var.grafana_url)[0]}-tls
      persistence:
        enabled: true
        storageClassName: ${var.storage_class_name}
        accessModes:
          - ReadWriteOnce
        size: ${var.grana_storage_size}
    commonLabels: ${jsonencode(merge(local.labels, { "component" = "prometheus_stack" }))}
    # There's no volumeMounts on grafana
    prometheusOperator:
      resources:
        requests:
          cpu: ${var.operator_cpu_request}
          memory: ${var.operator_memory_request}
        limits:
          cpu: ${var.operator_cpu_limit}
          memory: ${var.operator_memory_limit}
    %{~if var.vault_password != null~} 
      extraVolumeMounts:
      - name: csi-secret-driver
        mountPath: '/mnt/secrets-store'
        readOnly: true
      extraVolumes:
      - name: csi-secret-driver
        csi:
          driver: 'secrets-store.csi.k8s.io'
          readOnly: true
          volumeAttributes:
            secretProviderClass: ${local.name}
    extraManifests:
    - apiVersion: secrets-store.csi.x-k8s.io/v1
      kind: SecretProviderClass
      metadata:
        name: ${local.name}
      spec:
        provider: vault
        parameters:
          roleName: ${vault_kubernetes_auth_backend_role.this[0].role_name}
          vaultAddress: ${var.vault_password.vault_address}
          vaultCACertPath: ${var.vault_password.vault_csi_ca_cert_path}
          objects: |
            - objectName: password
              secretKey: ${var.vault_password.password_field}
              secretPath: ${var.vault_password.secret_path}
            - objectName: username
              secretKey: ${var.vault_password.username_field}
              secretPath: ${var.vault_password.secret_path}
        secretObjects:
          - secretName: grafana
            type: Opaque
            data:
            - key: admin-password
              objectName: password
            - key: admin-user
              objectName: username
      %{~endif~}
  EOF
  ]
}
