module "gateway-api" {
  source       = "../modules/gateway-api"
  uses_metallb = true
  istio_ip     = var.istio_ip
}
