resource "kubernetes_namespace_v1" "metallb" {
  metadata {
    name = "metallb"
    # Due to Pod Security
    labels = {
      "kubernetes.io/enforce"            = "privileged"
      "pod-security.kubernetes.io/audit" = "privileged"
      "pod-security.kubernetes.io/warn"  = "privileged"
    }
  }
}

resource "helm_release" "metallb" {
  name       = "metallb"
  namespace  = kubernetes_namespace_v1.metallb.metadata[0].name
  repository = "https://metallb.github.io/metallb"
  version    = var.metallb_chart_version
  chart      = "metallb"
  values = [
    <<-EOF
    controller:
      additionalLabels:
        component: loadbalancer
        part-of: loadbalancer
      resources:
        requests:
          memory: 50Mi
          cpu: 50m
        limits:
          memory: 100Mi
          cpu: 100m
    speaker:
      ignoreExcludeLB: true #Allows MetalLB to assign IPs using controlplane nodes
      resources:
        requests:
          memory: 100Mi
          cpu: 50m
        limits:
          memory: 200Mi
          cpu: 100m
    EOF
  ]
}