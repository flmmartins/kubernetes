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

# This chart has subcharts
resource "helm_release" "this" {
  name       = local.name
  namespace  = kubernetes_namespace_v1.this.metadata[0].name
  repository = "https://prometheus-community.github.io/helm-charts"
  version    = var.chart_version
  chart      = "kube-prometheus-stack"
  values = [
    <<-EOF
    # I would have to provide talos IPs to this, instead it's easier to monitor the pod itsef for now
    kubeScheduler:
      enabled: false 
    kubeControllerManager:
      enabled: false
    kubeProxy:
      enabled: false
    defaultRules:
      rules:
        kubeApiserverBurnrate: false #replace by below
    additionalPrometheusRulesMap:
      custom-alerts:
        groups:
          - name: pods
            rules:
            - alert: PodNotRunning
              expr: |
                kube_pod_status_phase{phase!~"Running|Succeeded"} == 1
              for: 5m
              labels:
                severity: warning
              annotations:
                summary: "Pod {{`{{`}} $labels.namespace {{`}}`}}/{{`{{`}} $labels.pod {{`}}`}} is not running"
                description: "Pod has been in {{`{{`}} $labels.phase {{`}}`}} state for more than 5 minutes."
          - name: nodes
            rules:
            - alert: NodeNotReady
              expr: |
                kube_node_status_condition{condition="Ready",status="true"} == 0
              for: 5m
              labels:
                severity: critical
              annotations:
                summary: "Node {{`{{`}} $labels.node {{`}}`}} is not ready"
                description: "Node {{`{{`}} $labels.node {{`}}`}} has been in NotReady state for more than 5 minutes."
          - name: apiserver
            rules:
              - alert: KubernetesAPIDown
                expr: up{job="apiserver"} == 0
                for: 5m
                labels:
                  severity: critical
                annotations:
                  summary: Kubernetes API is down
              - alert: KubernetesAPISlow
                expr: |
                  histogram_quantile(
                    0.99,
                    sum(rate(apiserver_request_duration_seconds_bucket[5m])) by (le)
                  ) > 5
                for: 15m
                labels:
                  severity: warning
                annotations:
                  summary: Kubernetes API is slow
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
              storageClassName: ${var.persistent_storage_class_name}
              accessModes:
                - ReadWriteOnce
              resources:
                requests:
                  storage: ${var.prometheus_storage_size}
    kube-state-metrics:
      resources:
        requests:
          cpu: ${var.kube_state_metrics_cpu_request}
          memory: ${var.kube_state_metrics_memory_request}
        limits:
          cpu: ${var.kube_state_metrics_cpu_limit}
          memory: ${var.kube_state_metrics_memory_limit}
    prometheus-node-exporter:
      resources:
        requests:
          cpu: ${var.node_exporter_cpu_request}
          memory: ${var.node_exporter_memory_request}
        limits:
          cpu: ${var.node_exporter_cpu_limit}
          memory: ${var.node_exporter_memory_limit}
    alertmanager:
      config:
        route:
          group_by: ['namespace', 'alertname']
          group_wait: 30s
          group_interval: 5m
          repeat_interval: 4h
          receiver: default
          routes:
            - matchers:
                - alertname = "InfoInhibitor" # As said on manual this should be sent to null
              receiver: "null"
            - matchers:
                - alertname = "Watchdog" # This should always be firing so send to null
              receiver: "null"
            - matchers:
                - alertname="CPUThrottlingHigh"
                - namespace="prometheus-stack"
              receiver: "null"
        global:
          resolve_timeout: 5m
        %{~if var.alertmanager_email != null~}
          smtp_auth_username: '${var.alertmanager_email.from}'
          smtp_auth_password_file: /vault/secrets/smtp-password
          smtp_smarthost: '${var.alertmanager_email.smarthost}'
          smtp_from: '${var.alertmanager_email.from}'
          smtp_require_tls: ${var.alertmanager_email.require_tls}
        receivers:
          - name: default
            email_configs:
              - to: '${var.alertmanager_email.to}'
        %{~else~}
        receivers:
          - name: default
        %{~endif~}
      alertmanagerSpec:
        %{~if var.alertmanager_email != null~}
        podMetadata:
          annotations:
            vault.hashicorp.com/agent-inject: "true"
            vault.hashicorp.com/role: ${vault_kubernetes_auth_backend_role.alertmanager[0].role_name}
            vault.hashicorp.com/agent-pre-populate-only: "true"
            vault.hashicorp.com/agent-extra-secret: ${kubernetes_secret_v1.vault_ca[0].metadata[0].name}
            vault.hashicorp.com/ca-cert: "/vault/custom/ca.crt"
            vault.hashicorp.com/agent-inject-secret-smtp-password: "${var.alertmanager_email.vault_password.secret_path}"
            vault.hashicorp.com/agent-inject-template-smtp-password: |
              {{- with secret "${var.alertmanager_email.vault_password.secret_path}" -}}
              {{ index .Data "${var.alertmanager_email.vault_password.password_field}" }}
              {{- end }}
        %{~endif~}
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
              storageClassName: ${var.persistent_storage_class_name}
              accessModes:
                - ReadWriteOnce
              resources:
                requests:
                  storage: ${var.alertmanager_storage_size}
    grafana:
      grafana.ini:
        dataproxy:
          max_concurrent_query_limit: 5
      admin:
      %{~if var.grafana_vault_password != null~} 
        existingSecret: grafana
      %{~else~}
        existingSecret: ${kubernetes_secret_v1.grafana[0].metadata[0].name}
      %{~endif~}
      persistence:
        enabled: true
        storageClassName: ${var.persistent_storage_class_name}
        accessModes:
          - ReadWriteOnce
        size: ${var.grana_storage_size}
      resources:
        limits:
          cpu: ${var.grafana_cpu_limit}
          memory: ${var.grafana_memory_limit}
        requests:
          cpu: ${var.grafana_cpu_request}
          memory: ${var.grafana_memory_request}
      sidecar:
        resources:
          requests:
            cpu: ${var.grafana_sidecar_cpu_request}
            memory: ${var.grafana_sidecar_memory_request}
          limits:
            cpu: ${var.grafana_sidecar_cpu_limit}
            memory: ${var.grafana_sidecar_memory_limit}
      route:
        main:
          enabled: true
          labels: ${jsonencode(merge(local.labels, { "component" = "prometheus_stack" }))}
          hostnames: [${var.grafana_url}]
          parentRefs:
          - name: ${var.gateway.name}
            namespace: ${var.gateway.namespace}
      deploymentStrategy:
        type: Recreate
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
    %{~if var.grafana_vault_password != null~} 
      extraVolumeMounts:
      - name: grafana-csi-secret-driver
        mountPath: '/mnt/secrets-store'
        readOnly: true
      extraVolumes:
      - name: grafana-csi-secret-driver
        csi:
          driver: 'secrets-store.csi.k8s.io'
          readOnly: true
          volumeAttributes:
            secretProviderClass: grafana
    extraManifests:
    - apiVersion: secrets-store.csi.x-k8s.io/v1
      kind: SecretProviderClass
      metadata:
        name: grafana
      spec:
        provider: vault
        parameters:
          roleName: ${vault_kubernetes_auth_backend_role.grafana[0].role_name}
          vaultAddress: ${var.grafana_vault_password.vault_address}
          vaultCACertPath: ${var.grafana_vault_password.vault_csi_ca_cert_path}
          objects: |
            - objectName: password
              secretKey: ${var.grafana_vault_password.password_field}
              secretPath: ${var.grafana_vault_password.secret_path}
            - objectName: username
              secretKey: ${var.grafana_vault_password.username_field}
              secretPath: ${var.grafana_vault_password.secret_path}
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
