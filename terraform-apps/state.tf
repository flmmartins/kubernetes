# AWS_S3_ENDPOINT, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY as env vars
terraform {
  backend "s3" {
    bucket                      = "terraform"
    key                         = "kubernetes-apps.tfstate"
    region                      = "talos"
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    use_path_style              = true
    skip_requesting_account_id  = true
  }
}