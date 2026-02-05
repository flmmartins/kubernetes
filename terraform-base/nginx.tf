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
        minReplicas: 1
        maxReplicas: 3
        targetCPUUtilizationPercentage: 80
        targetMemoryUtilizationPercentage: 80
      resources:
        requests:
          cpu: 100m
          memory: 90Mi
        limits:
          memory: 200Mi
          cpu: 300m
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

resource "kubectl_manifest" "nginx-ip-address-pool" {
  yaml_body = yamlencode({
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
  })
}

resource "kubectl_manifest" "nginx-l2-advertisement" {
  yaml_body = yamlencode({
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
      ipAddressPools = [kubectl_manifest.nginx-ip-address-pool.name]
    }
  })
}