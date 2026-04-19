module "gateway-api" {
  source       = "../modules/gateway-api"
  uses_metallb = true
}
