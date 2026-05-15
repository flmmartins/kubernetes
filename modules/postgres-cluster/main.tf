terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    vault = {
      source = "hashicorp/vault"
    }
  }
}

locals {
  labels = {
    "part-of" = var.cluster.name
  }
  #replica_address = "streaming-replica.${kubernetes_namespace_v1.this.metadata[0].name}.svc.cluster.local"
}

resource "kubernetes_namespace_v1" "this" {
  metadata {
    name   = var.cluster.name
    labels = local.labels
  }
}

resource "kubernetes_manifest" "certificate_server" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "${var.cluster.name}-server"
      namespace = kubernetes_namespace_v1.this.metadata[0].name
      labels    = merge(local.labels, { component = "certificate" })
    }
    spec = {
      secretName = "${var.cluster.name}-server"
      commonName = "${var.cluster.name}-server"
      secretTemplate = {
        #  serves as an instruction to the CNPG operator, guiding it to reload the database whenever there are changes
        labels = {
          "cnpg.io/reload" = ""
        }
      }
      usages = [
        "server auth",
      ]
      dnsNames = compact([
        "${var.cluster.url}",
        "${var.cluster.name}-rw.${kubernetes_namespace_v1.this.metadata[0].name}.svc",
        "${var.cluster.name}-rw",
        "${var.cluster.name}-rw.${kubernetes_namespace_v1.this.metadata[0].name}",
        "${var.cluster.name}-r",
        "${var.cluster.name}-r.${kubernetes_namespace_v1.this.metadata[0].name}",
        "${var.cluster.name}-r.${kubernetes_namespace_v1.this.metadata[0].name}.svc",
        "${var.cluster.name}-ro",
        "${var.cluster.name}-ro.${kubernetes_namespace_v1.this.metadata[0].name}",
        "${var.cluster.name}-ro.${kubernetes_namespace_v1.this.metadata[0].name}.svc"
      ])
      issuerRef = {
        name  = var.certificate_issuer
        kind  = "ClusterIssuer"
        group = "cert-manager.io"
      }
    }
  }
}

#resource "kubernetes_manifest" "certificate_replicationclient" {
#  manifest = {
#    apiVersion = "cert-manager.io/v1"
#    kind       = "Certificate"
#    metadata = {
#      name      = "${var.cluster.name}-replication-client"
#      namespace = kubernetes_namespace_v1.this.metadata[0].name
#      labels    = merge(local.labels, { component = "certificate" })
#    }
#    spec = {
#      secretName = "${var.cluster.name}-replication-client"
#      usages = [
#        "client auth",
#        "digital signature",
#        "key encipherment",
#      ]
#      commonName = local.replica_address
#      secretTemplate = {
#        labels = { "cnpg.io/reload" = "" }
#      }
#      issuerRef = {
#        name  = var.certificate_issuer
#        kind  = "ClusterIssuer"
#        group = "cert-manager.io"
#      }
#    }
#  }
#}

# One cluster for all kubernetes apps
resource "kubernetes_manifest" "this" {
  manifest = {
    apiVersion = "postgresql.cnpg.io/v1"
    kind       = "Cluster"
    metadata = {
      name      = var.cluster.name
      namespace = kubernetes_namespace_v1.this.metadata[0].name
      labels = {
        part-of   = "cloudnative-pg-operator"
        component = var.cluster.name
      }
    }
    spec = {
      instances = var.cluster.instances

      inheritedMetadata = {
        labels = merge(local.labels, { component = var.cluster.name })
      }

      certificates = {
        serverTLSSecret = kubernetes_manifest.certificate_server.manifest.spec.secretName
        serverCASecret  = kubernetes_manifest.certificate_server.manifest.spec.secretName
        # Somehow when trying to add my own client certificate I had incompatible key usage error so we operator create this one
        #clientCASecret       = kubernetes_manifest.certificate_replicationclient.manifest.spec.secretName
        #replicationTLSSecret = kubernetes_manifest.certificate_replicationclient.manifest.spec.secretName
      }

      # common name on replication needs to be streaming_replica however vault doesn't accept underline\
      # due to this we need to say to postgres what's the modified name of streaming_replica 
      #postgresql = {
      #  pg_ident = ["cnpg_streaming_replica ${local.replica_address} streaming_replica"]
      #}

      storage = {
        size         = var.cluster.size
        storageClass = var.cluster.storage_class
      }

      # Operator will auto create a secret
      # It's not possible to do CSI here because there's no pod to CSI to run
      enableSuperuserAccess = true

      resources = {
        requests = {
          memory = var.cluster_resources_requests_memory
          cpu    = var.cluster_resources_requests_cpu
        }
        limits = {
          memory = var.cluster_resources_limits_memory
          cpu    = var.cluster_resources_limits_cpu
        }
      }

      # Somehow this always changes in terraform which causes terraform to go bananas
      #postgresql = {
      #  parameters = {
      #    shared_buffers = var.cluster_shared_buffers
      #  }
      #}
    }
  }
}
