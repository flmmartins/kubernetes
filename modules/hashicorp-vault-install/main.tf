terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
    }
    vault = {
      source = "hashicorp/vault"
    }
  }
}

locals {
  name                 = "vault"
  namespace            = "vault"
  plugin_folder        = "/usr/local/libexec/vault"
  csi_cert_mounth_path = "/vault/tls"
}

# Namespace is created on with this script
resource "terraform_data" "create-tls-cert" {
  provisioner "local-exec" {
    command = "bash ${path.module}/create-vault-tls-cert.sh "
  }
}

resource "helm_release" "this" {
  depends_on = [terraform_data.create-tls-cert]
  name       = "vault"
  namespace  = local.namespace
  repository = "https://helm.releases.hashicorp.com"
  version    = var.chart_version
  chart      = "vault"
  values = [
    <<-EOF
    global:
      enabled: true #Install all vault default components
      tlsDisable: false
    injector: # Secret injector
      enabled: true
    %{~if var.security_context != null~}
      securityContext:
        pod:
          runAsNonRoot: true
          runAsUser: ${var.security_context.user_id}
          runAsGroup: ${var.security_context.group_id}
          fsGroup: ${var.security_context.group_id}
          fsGroupChangePolicy: "OnRootMismatch"
        container:
          allowPrivilegeEscalation: false
          seccompProfile:
            type: RuntimeDefault
          capabilities:
            drop:
              - ALL
    %{~endif~}
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
            - weight: 100
              podAffinityTerm:
                topologyKey: kubernetes.io/hostname
                labelSelector:
                  matchLabels:
                    app.kubernetes.io/name: vault-agent-injector
                    app.kubernetes.io/instance: vault
                    component: webhook
      resources:
        requests:
          memory: ${var.injector_requests_memory}
          cpu: ${var.injector_requests_cpu}
        limits:
          memory: ${var.injector_limits_memory}
          cpu: ${var.injector_limits_cpu}
    csi:
      enabled: true
      volumes:
        - name: tls
          secret:
            secretName: vault-ha-tls
      volumeMounts:
        - name: tls
          mountPath: ${local.csi_cert_mounth_path}
          readOnly: true
      resources:
        requests:
          cpu: ${var.csi_requests_cpu}
          memory: ${var.csi_requests_memory}
        limits:
          cpu: ${var.csi_limits_cpu}
          memory: ${var.csi_limits_memory}
    server:
    %{~if var.priority_class != null~}
      priorityClassName: ${var.priority_class}
    %{~endif~}
    %{~if var.install_onepassword_plugin == true~}
      # Plugin needs to be installed on every pod
      # Registration of plugin is only done once and remains in PV
      extraInitContainers:
        - name: plugin-installer
          image: "alpine"
          command: [sh, -c]
          args:
            - cd /tmp &&
              wget https://github.com/1Password/vault-plugin-secrets-onepassword/releases/download/v${var.plugin_onepasswordconnect_version}/vault-plugin-secrets-onepassword_${var.plugin_onepasswordconnect_version}_linux_amd64.zip -O onepassword-plugin.zip &&
              unzip onepassword-plugin.zip &&
              mv vault-plugin-secrets-onepassword_v${var.plugin_onepasswordconnect_version} ${local.plugin_folder}/op-connect &&
              chmod +x ${local.plugin_folder}/op-connect
          volumeMounts:
            - name: plugins
              mountPath: ${local.plugin_folder}
      %{~endif~}
      resources:
        requests:
          cpu: ${var.server_requests_cpu}
          memory: ${var.server_requests_memory}
        limits:
          cpu: ${var.server_limits_cpu}
          memory: ${var.server_limits_memory}
      extraEnvironmentVars:
        VAULT_CACERT: /vault/userconfig/vault-ha-tls/vault.ca
        VAULT_TLSCERT: /vault/userconfig/vault-ha-tls/vault.crt
        VAULT_TLSKEY: /vault/userconfig/vault-ha-tls/vault.key
      statefulSet:
      %{~if var.security_context != null~}
        securityContext:
          pod:
            runAsNonRoot: true
            runAsUser: ${var.security_context.user_id}
            runAsGroup: ${var.security_context.group_id}
            fsGroup: ${var.security_context.group_id}
            fsGroupChangePolicy: "OnRootMismatch"
          container: #vault defaults
            allowPrivilegeEscalation: false
      %{~endif~}
      volumes:
        - name: userconfig-vault-ha-tls
          secret:
            defaultMode: 420
            secretName: vault-ha-tls # Secret containing certificates
        - name: plugins
          emptyDir: {}
      volumeMounts:
        - mountPath: /vault/userconfig/vault-ha-tls
          name: userconfig-vault-ha-tls
          readOnly: true
        - mountPath: ${local.plugin_folder}
          name: plugins
          readOnly: true
      ingress:
        enabled: true
        annotations: ${jsonencode(var.ingress_annotations)}
        hosts:
        - host: ${var.url}
        tls:
          - hosts:
            - ${var.url}
            secretName: ${split(".", var.url)[0]}-ui-tls
      # This configures the Vault Statefulset to create a PVC for audit logs.
      # See https://www.vaultproject.io/docs/audit/index.html to know more
      auditStorage:
        enabled: true
        size: 1Gi
        mountPath: "/vault/audit"

      standalone:
        enabled: false

      dataStorage:
        storageClass: ${var.persistent_storage_class_name}
        size: 10Gi
        mountPath: /vault/data

      # Run Vault in "HA" mode.
      ha:
        enabled: true
        replicas: 3
        raft: #aka integrated storage
          enabled: true
          setNodeId: true #Set raft id to the name of the pod
          config: |
            cluster_name     = "vault-integrated-storage"
            plugin_directory = "${local.plugin_folder}"
            ui = true
            listener "tcp" {
              tls_disable = 0
              address = "[::]:8200"
              cluster_address = "[::]:8201"
              tls_cert_file = "/vault/userconfig/vault-ha-tls/vault.crt"
              tls_key_file  = "/vault/userconfig/vault-ha-tls/vault.key"
              tls_client_ca_file = "/vault/userconfig/vault-ha-tls/vault.ca"
            }
            storage "raft" {
              path = "/vault/data"
            }
            disable_mlock = true
            service_registration "kubernetes" {}
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
            - weight: 100
              podAffinityTerm:
                topologyKey: kubernetes.io/hostname
                labelSelector:
                  matchLabels:
                    app.kubernetes.io/name: vault
                    app.kubernetes.io/instance: vault
                    component: server
    # Vault UI
    ui:
      enabled: true
      serviceType: ClusterIP
      externalPort: 8200
    EOF
  ]
}
