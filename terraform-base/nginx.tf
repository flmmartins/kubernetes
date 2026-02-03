resource "helm_release" "nginx" {
  depends_on       = [helm_release.metrics-server]
  name             = "nginx"
  namespace        = "nginx"
  create_namespace = true
  repository       = "https://kubernetes.github.io/ingress-nginx"
  version          = var.nginx_chart_version
  chart            = "ingress-nginx"
  values = [
    <<-EOF
    tcp:
      "32400" : "plex/plex-plex-media-server:32400"
    commonLabels:
      component: ingress-controller
      part-of: ingress-controller
    controller:
      #For pihole
      allowSnippetAnnotations: true
      config:
        annotations-risk-level: Critical
      autoscaling:
        enabled: true
        minReplicas: 2
        maxReplicas: 3
        targetCPUUtilizationPercentage: 80
        targetMemoryUtilizationPercentage: 80
      resources:
        requests:
          cpu: 50m
          memory: 90Mi
        limits:
          memory: 200Mi
          cpu: 200m
      ingressClassResource:
        name: nginx
        enabled: true
        default: true
      affinity:
        # Do not schedule pods on same node
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: component
                  operator: In
                  values:
                  - ingress-controller
              topologyKey: kubernetes.io/hostname
    EOF
  ]
}

resource "kubernetes_manifest" "nginx-ip-address-pool" {
  manifest = {
    apiVersion = "metallb.io/v1beta1"
    kind       = "IPAddressPool"
    metadata = {
      name      = "default"
      namespace = kubernetes_namespace_v1.metallb.metadata[0].name
      labels = {
        "part-of" = "ingress-controller"
      }
    }
    spec = {
      addresses  = var.nginx_ip_cidrs
      autoAssign = true
    }
  }
}

resource "kubernetes_manifest" "nginx-l2-advertisement" {
  manifest = {
    apiVersion = "metallb.io/v1beta1"
    kind       = "L2Advertisement"
    metadata = {
      name      = "default"
      namespace = kubernetes_namespace_v1.metallb.metadata[0].name
      labels = {
        "part-of" = "ingress-controller"
      }
    }
    spec = {
      ipAddressPools = [kubernetes_manifest.nginx-ip-address-pool.manifest.metadata.name]
    }
  }
}