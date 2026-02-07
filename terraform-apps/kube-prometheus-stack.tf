locals {
  prometheus_stack_app_name = "prometheus-stack"
  prometheus_stack_common_labels = {
    part-of = "monitoring"
  }
  grafana_vault_secret_path       = format("%s/grafana", var.onepassword_vault_path)
  prometheus_service_account_name = "prometheus-stack-kube-prom-operator"
  grafana_url                     = "grafana.${var.public_domain}"
}

resource "kubernetes_namespace_v1" "prometheus_stack" {
  metadata {
    name = local.prometheus_stack_app_name
    labels = merge(local.prometheus_stack_common_labels,
      {
        "pod-security.kubernetes.io/enforce" = "privileged"
        "pod-security.kubernetes.io/audit"   = "privileged"
        "pod-security.kubernetes.io/warn"    = "privileged"
      }
    )
  }
}

resource "vault_policy" "prometheus_stack" {
  name   = local.prometheus_stack_app_name
  policy = <<EOT
path "${local.grafana_vault_secret_path}" { capabilities = ["read"] }
EOT
}

resource "vault_kubernetes_auth_backend_role" "prometheus_stack" {
  role_name                        = local.prometheus_stack_app_name
  bound_service_account_names      = [local.prometheus_service_account_name]
  bound_service_account_namespaces = [kubernetes_namespace_v1.prometheus_stack.metadata[0].name]
  token_max_ttl                    = 1440 #24H
  token_policies                   = [vault_policy.prometheus_stack.name]
}

resource "helm_release" "prometheus_stack" {
  name       = local.prometheus_stack_app_name
  namespace  = kubernetes_namespace_v1.prometheus_stack.metadata[0].name
  repository = "https://prometheus-community.github.io/helm-charts"
  version    = var.prometheus_stack_chart_version
  chart      = "kube-prometheus-stack"
  values = [
    <<-EOF
    prometheus:
      prometheusSpec:
        retention: 15d
        resources:
          requests:
            cpu: 100m
            memory: 300Mi
          limits:
            cpu: 300m
            memory: 512Gi
        securityContext:
          runAsUser: ${var.monitoring.user_uid}
          runAsGroup: ${var.monitoring.group_uid}
          fsGroup: ${var.monitoring.group_uid}
          fsGroupChangePolicy: OnRootMismatch
          seccompProfile:
            type: RuntimeDefault
        storageSpec:
          volumeClaimTemplate:
            spec:
              storageClassName: persistent
              accessModes:
                - ReadWriteOnce
              resources:
                requests:
                  storage: 50Gi
    alertmanager:
      alertmanagerSpec:
        resources:
          requests:
            cpu: 25m
            memory: 64Mi
          limits:
            cpu: 100m
            memory: 256Mi
        securityContext:
          runAsUser: ${var.monitoring.user_uid}
          runAsGroup: ${var.monitoring.group_uid}
          fsGroup: ${var.monitoring.group_uid}
          fsGroupChangePolicy: OnRootMismatch
          seccompProfile:
            type: RuntimeDefault
        storage:
          volumeClaimTemplate:
            spec:
              storageClassName: persistent
              accessModes:
                - ReadWriteOnce
              resources:
                requests:
                  storage: 10Gi
    grafana:
      admin:
        existingSecret: grafana
      ingress:
        enabled: true
        annotations: 
          kubernetes.io/tls-acme: "true"
          cert-manager.io/common-name: "${local.grafana_url}"
          cert-manager.io/dns-names: "${local.grafana_url}"
        hosts:
        - ${local.grafana_url}
        tls:
        - hosts:
          - ${local.grafana_url}
          secretName: grafana-tls
      persistence:
        enabled: true
        storageClassName: persistent
        accessModes:
          - ReadWriteOnce
        size: 10Gi
    commonLabels: ${jsonencode(merge(local.prometheus_stack_common_labels, { "component" = "prometheus_stack" }))}
    # There's no volumeMounts on grafana
    prometheusOperator:
      resources:
        limits:
          cpu: 200m
          memory: 200Mi
        requests:
          cpu: 100m
          memory: 100Mi
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
            secretProviderClass: ${local.prometheus_stack_app_name}
    extraManifests:
    - apiVersion: secrets-store.csi.x-k8s.io/v1
      kind: SecretProviderClass
      metadata:
        name: ${local.prometheus_stack_app_name}
      spec:
        provider: vault
        parameters:
          roleName: ${vault_kubernetes_auth_backend_role.prometheus_stack.role_name}
          vaultAddress: ${var.vault_address_internal}
          vaultCACertPath: ${var.vault_csi_ca_cert_path}
          objects: |
            - objectName: password
              secretKey: password
              secretPath: ${local.grafana_vault_secret_path}
            - objectName: username
              secretKey: username
              secretPath: ${local.grafana_vault_secret_path}
        secretObjects:
          - secretName: grafana
            type: Opaque
            data:
            - key: admin-password
              objectName: password
            - key: admin-user
              objectName: username
  EOF
  ]
}