locals {
  pihole_secret_name = "pihole"
  pihole_secret_key  = "password"
  pihole_metallb_annotations = {
    "metallb.universe.tf/address-pool"    = kubernetes_manifest.pihole-l2-advertisement.manifest.metadata.name
    "metallb.universe.tf/allow-shared-ip" = "pihole-services"
  }
}

resource "kubernetes_namespace_v1" "pihole" {
  metadata {
    name = "pihole"
  }
}

resource "vault_policy" "pihole" {
  name   = "pihole"
  policy = <<EOT
path "${var.onepassword_vault_path}/${local.pihole_secret_name}" {
  capabilities = ["read"]
}
EOT
}

# PiHole chart doesn't support the creation of service account hence why default
resource "vault_kubernetes_auth_backend_role" "pihole" {
  role_name                        = "pihole"
  bound_service_account_names      = ["default"]
  bound_service_account_namespaces = [kubernetes_namespace_v1.pihole.metadata[0].name]
  token_max_ttl                    = 1440 #24H
  token_policies                   = [vault_policy.pihole.name]
}

resource "kubernetes_manifest" "pihole-admin-secret" {
  manifest = {
    apiVersion = "secrets-store.csi.x-k8s.io/v1"
    kind       = "SecretProviderClass"

    metadata = {
      name      = local.pihole_secret_name
      namespace = kubernetes_namespace_v1.pihole.metadata[0].name
    }

    spec = {
      provider = "vault"
      parameters = {
        roleName        = vault_kubernetes_auth_backend_role.pihole.role_name
        vaultAddress    = var.vault_address_internal
        vaultCACertPath = var.vault_csi_ca_cert_path #TLS mounted on CSI pod
        objects         = <<EOT
- objectName: ${local.pihole_secret_name}
  secretPath: ${var.onepassword_vault_path}/${local.pihole_secret_name}
  secretKey: ${local.pihole_secret_key}
        EOT
      }
      # Will become the following K8s secret
      secretObjects = [{
        secretName = local.pihole_secret_name
        type       = "Opaque"
        data = [{
          objectName = local.pihole_secret_name
          key        = local.pihole_secret_key
        }]
      }]
    }
  }
}

resource "kubernetes_manifest" "pihole-ip-address-pool" {
  manifest = {
    apiVersion = "metallb.io/v1beta1"
    kind       = "IPAddressPool"
    metadata = {
      name      = "pihole-dns"
      namespace = "metallb"
      labels = {
        "part-of" = "pihole"
      }
    }
    spec = {
      addresses  = [var.pihole_ip_cidr]
      autoAssign = false
    }
  }
}

resource "kubernetes_manifest" "pihole-l2-advertisement" {
  manifest = {
    apiVersion = "metallb.io/v1beta1"
    kind       = "L2Advertisement"
    metadata = {
      name      = "pihole-dns"
      namespace = "metallb"
      labels = {
        "part-of" = "pihole"
      }
    }
    spec = {
      ipAddressPools = [kubernetes_manifest.pihole-ip-address-pool.manifest.metadata.name]
    }
  }
}

resource "helm_release" "pihole" {
  name       = "pihole"
  namespace  = kubernetes_namespace_v1.pihole.metadata[0].name
  repository = "https://mojo2600.github.io/pihole-kubernetes"
  version    = var.pihole_chart_version
  chart      = "pihole"
  values = [
    <<-EOF
    # Pihole with 2 replicas causes issue with persistentVolume
    # WARNING: Cannot get exclusive lock for /etc/pihole/pihole.toml: Bad file descriptor
    replicaCount: 1
    extraEnvVars:
      TZ: Europe/Amsterdam
      FTLCONF_dns_listeningMode: 'all'
      FTLCONF_dns_dnssec: 'true'
      FTLCONF_dns_upstreams: '127.0.0.1#5053'
    serviceDns:
      annotations: ${jsonencode(local.pihole_metallb_annotations)}
      mixedService: true #tcp and udp dns svc on same ip
      type: LoadBalancer
    persistentVolumeClaim:
      enabled: true
      accessModes:
      - ReadWriteMany
      size: "1Gi"
      storageClass: ${var.persistent_storage_class}
    # Volumes are defined only so CSI Secret Driver can run
    extraVolumeMounts:
      csi-secret-driver-for-admin-pwd:
        mountPath: '/mnt/secrets-store'
        readOnly: true
    extraVolumes:
      csi-secret-driver-for-admin-pwd:
        csi:
          driver: 'secrets-store.csi.k8s.io'
          readOnly: true
          volumeAttributes:
            secretProviderClass: ${kubernetes_manifest.pihole-admin-secret.manifest.metadata.name}
    admin:
      enabled: true
      existingSecret: ${kubernetes_manifest.pihole-admin-secret.manifest.metadata.name}
      passwordKey: ${local.pihole_secret_key}
    # If podDnsConfig is set you cannot resolve kube service addresses
    podDnsConfig:
      enabled: false
    extraContainers:
    - name: cloudflared
      image: "cloudflare/cloudflared:latest"
      command: ["cloudflared", "proxy-dns"]
      env:
      - name: TUNNEL_DNS_UPSTREAM
        value: "https://1.1.1.1/dns-query,https://1.0.0.1/dns-query"
      - name: TUNNEL_DNS_PORT
        value: "5053"
      - name: TUNNEL_DNS_ADDRESS
        value: "0.0.0.0"
    serviceDhcp:
      enabled: false
    # Not possible with ingress due to https://github.com/MoJo2600/pihole-kubernetes/issues/375
    ingress:
      enabled: true
      annotations:
        kubernetes.io/tls-acme: "true" #Auto-tls creation by cert-manager
        cert-manager.io/common-name: "pihole.${var.private_domain}"
        cert-manager.io/cluster-issuer: "${var.private_cert_issuer}"
      hosts:
      - pihole.${var.private_domain}
      tls:
      - hosts:
        - pihole.${var.private_domain}
        secretName: pihole-tls
    dnsmasq:
      enableCustomDnsMasq: true
      customDnsEntries:
      - address=/${var.public_domain}/${var.nginx_ip}
      - address=/${var.private_domain}/${var.nginx_ip}
      additionalHostsEntries: ${jsonencode(var.pihole_additionalHostsEntries)}
    EOF
  ]
}

