terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

locals {
  labels = {
    part-of = "loadbalancer"
  }
}

resource "kubernetes_namespace_v1" "metallb" {
  count = var.uses_metallb == true ? 1 : 0
  metadata {
    name = "metallb"
    labels = {
      "kubernetes.io/enforce"            = "privileged"
      "pod-security.kubernetes.io/audit" = "privileged"
      "pod-security.kubernetes.io/warn"  = "privileged"
    }
  }
}

resource "helm_release" "metallb" {
  count = var.uses_metallb == true ? 1 : 0

  name       = "metallb"
  namespace  = kubernetes_namespace_v1.metallb[0].metadata[0].name
  repository = "https://metallb.github.io/metallb"
  version    = var.metallb_chart_version
  chart      = "metallb"
  values = [
    <<-EOF
    controller:
      additionalLabels: ${jsonencode(merge(local.labels, { "component" = "loadbalancer" }))}
      resources:
        requests:
          memory: ${var.controller_memory_request}
          cpu: ${var.controller_cpu_request}
        limits:
          memory: ${var.controller_memory_limit}
          cpu: ${var.controller_cpu_limit}
    speaker:
      resources:
        requests:
          memory: ${var.speaker_memory_request}
          cpu: ${var.speaker_cpu_request}
        limits:
          memory: ${var.speaker_memory_limit}
          cpu: ${var.speaker_cpu_limit}
    EOF
  ]
}

resource "kubernetes_namespace_v1" "istio" {
  metadata {
    name = "istio-system"
  }
}

resource "helm_release" "istio-base" {
  name       = "istio-base"
  namespace  = kubernetes_namespace_v1.istio.metadata[0].name
  repository = "https://istio-release.storage.googleapis.com/charts"
  version    = var.istio_chart_version
  chart      = "base"
}

resource "helm_release" "istiod" {
  name       = "istiod"
  namespace  = kubernetes_namespace_v1.istio.metadata[0].name
  repository = "https://istio-release.storage.googleapis.com/charts"
  version    = var.istio_chart_version
  chart      = "istiod"
}
resource "terraform_data" "gateway_crds" {
  triggers_replace = {
    version = var.gateway_crds_version
  }

  provisioner "local-exec" {
    command = <<EOT
    kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
    { kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref=${var.gateway_crds_version}" | kubectl apply -f -; }
    EOT
  }
}

resource "kubernetes_manifest" "istio_ip_address_pool" {
  count = var.uses_metallb == true ? 1 : 0

  manifest = {
    apiVersion = "metallb.io/v1beta1"
    kind       = "IPAddressPool"
    metadata = {
      name      = "istio"
      namespace = kubernetes_namespace_v1.metallb[0].metadata[0].name
      labels    = local.labels
    }
    spec = {
      addresses  = ["${var.istio_ip}/32"]
      autoAssign = true
    }
  }
}

resource "kubernetes_manifest" "istio_l2_advertisement" {
  count = var.uses_metallb == true ? 1 : 0

  manifest = {
    apiVersion = "metallb.io/v1beta1"
    kind       = "L2Advertisement"
    metadata = {
      name      = "istio"
      namespace = kubernetes_namespace_v1.metallb[0].metadata[0].name
      labels    = local.labels
    }
    spec = {
      ipAddressPools = [kubernetes_manifest.istio_ip_address_pool[0].manifest.metadata.name]
    }
  }
}