# Resources need to be created on seaweedfs namespace otherwise you need ref grants
locals {
  secret_name = "seaweedfs-credential"
  labels = {
    part-of   = var.application.name
    component = "seaweedfs"
  }
}

resource "kubernetes_manifest" "s3_identity" {

  manifest = {
    apiVersion = var.provider_api
    kind       = "S3Identity"
    metadata = {
      name      = var.application.name
      namespace = var.seaweedfs.namespace
      labels    = local.labels
    }
    spec = {
      seaweedRef    = { name = var.seaweedfs.cluster_name }
      reclaimPolicy = "Retain"
    }
  }
}

resource "kubernetes_manifest" "allow_app_create_seaweedfs_secret" {
  manifest = {
    apiVersion = var.provider_api
    kind       = "ResourceReferenceGrant"
    metadata = {
      name      = "allow-seaweedfs-s3credentials"
      namespace = var.application.namespace
      labels    = local.labels
    }
    spec = {
      from = [
        {
          group     = "seaweed.seaweedfs.com"
          kind      = "S3Credentials"
          namespace = var.seaweedfs.namespace
        }
      ]
      to = [
        {
          group = ""
          kind  = "Secret"
          name  = local.secret_name
        }
      ]
    }
  }
}

resource "kubernetes_secret_v1" "s3_credentials_placeholder" {
  metadata {
    name      = local.secret_name
    namespace = var.application.namespace
    labels    = local.labels
  }
  type = "Opaque"
  # leave data empty — the S3Credentials controller writes accessKey/secretKey
  # into this Secret in place once it exists
}

resource "kubernetes_manifest" "s3_credentials" {
  manifest = {
    apiVersion = var.provider_api
    kind       = "S3Credentials"
    metadata = {
      name      = var.application.name
      namespace = var.seaweedfs.namespace
      labels    = local.labels
    }
    spec = {
      seaweedRef  = { name = var.seaweedfs.cluster_name }
      identityRef = { name = kubernetes_manifest.s3_identity.manifest.metadata.name }
      secretRef = {
        name      = kubernetes_secret_v1.s3_credentials_placeholder.metadata[0].name
        namespace = kubernetes_secret_v1.s3_credentials_placeholder.metadata[0].namespace
      }
      reclaimPolicy = "Retain"
    }
  }
}

resource "kubernetes_manifest" "bucket" {
  manifest = {
    apiVersion = var.provider_api
    kind       = "Bucket"
    metadata = {
      name      = var.application.name
      namespace = var.seaweedfs.namespace
      labels    = local.labels
    }
    spec = {
      clusterRef    = { name = var.seaweedfs.cluster_name }
      reclaimPolicy = "Retain" # Do not delete bucket when CRD is deleted
      owner         = kubernetes_manifest.s3_identity.manifest.metadata.name
    }
  }
}

resource "kubernetes_manifest" "s3_policy" {
  manifest = {
    apiVersion = var.provider_api
    kind       = "S3Policy"
    metadata = {
      name      = var.application.name
      namespace = var.seaweedfs.namespace
      labels    = local.labels
    }
    spec = {
      seaweedRef = { name = var.seaweedfs.cluster_name }
      statements = [
        {
          effect    = "Allow"
          actions   = ["s3:*"]
          resources = ["arn:aws:s3:::${kubernetes_manifest.bucket.manifest.metadata.name}", "arn:aws:s3:::${kubernetes_manifest.bucket.manifest.metadata.name}/*"]
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "s3_policy_binding" {
  manifest = {
    apiVersion = var.provider_api
    kind       = "S3PolicyBinding"
    metadata = {
      name      = var.application.name
      namespace = var.seaweedfs.namespace
      labels    = local.labels
    }
    spec = {
      seaweedRef = { name = var.seaweedfs.cluster_name }
      policyRef = {
        name = kubernetes_manifest.s3_policy.manifest.metadata.name
      }
      subjects = [
        {
          kind = "S3Identity"
          name = kubernetes_manifest.s3_identity.manifest.metadata.name
        }
      ]
    }
  }
}
