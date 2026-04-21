output "metallb_namespace" {
  value = kubernetes_namespace_v1.metallb[0].metadata[0].name
}

output "istio_ip" {
  value = var.istio_ip
}

