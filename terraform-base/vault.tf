locals {
  vault_namespace     = "vault"
  vault_pki_root_path = "pki/apps/root"
  vault_plugin_folder = "/usr/local/libexec/vault"
}

# Namespace is created on with this script
resource "terraform_data" "create-tls-cert" {
  depends_on = [helm_release.csi-driver-nfs, helm_release.csi-secrets-store]
  provisioner "local-exec" {
    command = "bash ${path.module}/create-vault-tls-cert.sh "
  }
}

resource "helm_release" "vault" {
  depends_on = [terraform_data.create-tls-cert]
  name       = "vault"
  namespace  = local.vault_namespace
  repository = "https://helm.releases.hashicorp.com"
  version    = var.vault_chart_version
  chart      = "vault"
  values = [
    <<-EOF
    global:
      enabled: true #Install all vault default components
      tlsDisable: false
    injector: # Secret injector
      enabled: true
      securityContext:
        pod:
          runAsNonRoot: true
          runAsUser: ${var.vault_user_uid}
          runAsGroup: ${var.vault_group_uid}
          fsGroup: ${var.nfs.user_id}
          fsGroupChangePolicy: "OnRootMismatch"
        container:
          allowPrivilegeEscalation: false
          seccompProfile:
            type: RuntimeDefault
          capabilities:
            drop:
              - ALL
    csi:
      enabled: true
      volumes:
        - name: tls
          secret:
            secretName: vault-ha-tls
      volumeMounts:
        - name: tls
          mountPath: /vault/tls
          readOnly: true
    server:
      # Plugin needs to be installed on every pod
      # Registration of plugin is only done once and remains in PV
      extraInitContainers:
        - name: plugin-installer
          image: "alpine"
          command: [sh, -c]
          args:
            - cd /tmp &&
              wget https://github.com/1Password/vault-plugin-secrets-onepassword/releases/download/v${var.vault_plugin_onepasswordconnect_version}/vault-plugin-secrets-onepassword_${var.vault_plugin_onepasswordconnect_version}_linux_amd64.zip -O onepassword-plugin.zip &&
              unzip onepassword-plugin.zip &&
              mv vault-plugin-secrets-onepassword_v${var.vault_plugin_onepasswordconnect_version} ${local.vault_plugin_folder}/op-connect &&
              chmod +x ${local.vault_plugin_folder}/op-connect
          volumeMounts:
            - name: plugins
              mountPath: ${local.vault_plugin_folder}
      extraEnvironmentVars:
        VAULT_CACERT: /vault/userconfig/vault-ha-tls/vault.ca
        VAULT_TLSCERT: /vault/userconfig/vault-ha-tls/vault.crt
        VAULT_TLSKEY: /vault/userconfig/vault-ha-tls/vault.key
      statefulSet:
        securityContext:
          pod:
            runAsNonRoot: true
            runAsUser: ${var.vault_user_uid}
            runAsGroup: ${var.vault_group_uid}
            fsGroup: ${var.nfs.user_id}
            fsGroupChangePolicy: "OnRootMismatch"
          container: #vault defaults
            allowPrivilegeEscalation: false
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
        - mountPath: ${local.vault_plugin_folder}
          name: plugins
          readOnly: true
      ingress:
        enabled: true
        annotations:
          kubernetes.io/tls-acme: "true"
          cert-manager.io/common-name: "vault.${var.apps_domain}"
          nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
        hosts:
        - host: vault.${var.apps_domain}
        tls:
          - hosts:
            - vault.${var.apps_domain}
            secretName: vault-ui-tls
      # This configures the Vault Statefulset to create a PVC for audit logs.
      # See https://www.vaultproject.io/docs/audit/index.html to know more
      auditStorage:
        enabled: true
        size: 1Gi
        mountPath: "/vault/audit"

      standalone:
        enabled: false

      dataStorage:
        storageClass: persistent
        size: 10Gi
        mountPath: /vault/data

      # Run Vault in "HA" mode.
      ha:
        enabled: true
        replicas: 2
        raft: #aka integrated storage
          enabled: true
          setNodeId: true #Set raft id to the name of the pod
          config: |
            cluster_name     = "vault-integrated-storage"
            plugin_directory = "${local.vault_plugin_folder}"
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

    # Vault UI
    ui:
      enabled: true
      serviceType: ClusterIP
      externalPort: 8200
    EOF
  ]
}


##################################
# KUBERNETES AUTH
##################################

resource "vault_auth_backend" "kubernetes" {
  depends_on = [helm_release.vault]
  type       = "kubernetes"
}

resource "vault_kubernetes_auth_backend_config" "kubernetes" {
  backend         = vault_auth_backend.kubernetes.path
  kubernetes_host = "https://kubernetes.default.svc.cluster.local:443"
}

##################################
# 1PASSWORD SECRET ENGINE
##################################
resource "vault_plugin" "op_connect" {
  depends_on = [helm_release.vault]
  type       = "secret"
  name       = "op-connect"
  command    = "op-connect"
  sha256     = "8eb865ca4ac9c7c87fa902985383da0132462f299765752f74e6f212e796a5bd"
}

# Vault Mount terraform doesn't do mount on plugins
# Although it seems like it, it doesn't do all operations
# https://github.com/hashicorp/terraform-provider-vault/issues/623
resource "vault_generic_endpoint" "op_connect_mount" {
  depends_on = [vault_plugin.op_connect]

  path = "sys/mounts/op"

  data_json = jsonencode({
    type        = "plugin",
    plugin_name = vault_plugin.op_connect.name,
    description = "1Password Connect secrets engine"

  })
  # Due to data being sensitive it always changes
  lifecycle {
    ignore_changes = [data_json]
  }
}

resource "vault_generic_endpoint" "onepassword-connect-config" {
  depends_on = [vault_generic_endpoint.op_connect_mount]
  path       = "op/config"

  data_json = jsonencode({
    op_connect_host  = "http://onepassword-connect.1password-connect:8080"
    op_connect_token = var.onepassword_connect_token
  })
  # Due to data being sensitive it always changes
  lifecycle {
    ignore_changes = [data_json]
  }
}


##################################
# PKI & CERT MANAGER
##################################
resource "vault_mount" "pki-apps-root" {
  depends_on = [helm_release.vault]

  path                  = local.vault_pki_root_path
  type                  = "pki"
  description           = "Tamriel Tower Apps CA"
  max_lease_ttl_seconds = 31536000 # 1 years
}

resource "vault_pki_secret_backend_config_ca" "pki-apps-root" {
  depends_on = [vault_mount.pki-apps-root]

  backend = vault_mount.pki-apps-root.path

  pem_bundle = <<EOT
  ${file(var.vault_apps_cert_pembundle_file_path)}
  EOT
}

resource "vault_pki_secret_backend_config_urls" "pki-apps-root" {
  depends_on = [vault_mount.pki-apps-root]

  backend = vault_mount.pki-apps-root.path

  issuing_certificates = [
    "http://vault.${local.vault_namespace}:8200/v1/${local.vault_pki_root_path}/ca",
  ]
  crl_distribution_points = [
    "http://vault.${local.vault_namespace}:8200/v1/${local.vault_pki_root_path}/crl",
  ]
}

# Tried many combinations for kubernetes, in the end had to allow any
resource "vault_pki_secret_backend_role" "apps-tamrieltower-local" {
  backend                     = vault_mount.pki-apps-root.path
  name                        = "apps-tamrieltower-local"
  allow_any_name              = true
  allow_glob_domains          = true
  allow_wildcard_certificates = true
}

resource "vault_policy" "issuer-apps-tamrieltower-local" {
  depends_on = [helm_release.vault]

  name   = "issuer-apps-tamrieltower-local"
  policy = <<EOT
path "${vault_mount.pki-apps-root.path}*" {
  capabilities = ["read", "list"] }
path "${vault_mount.pki-apps-root.path}/sign/${vault_pki_secret_backend_role.apps-tamrieltower-local.name}" {
  capabilities = ["create", "update"] } 
path "${vault_mount.pki-apps-root.path}/issue/${vault_pki_secret_backend_role.apps-tamrieltower-local.name}" {
  capabilities = ["create"] }
EOT
}