locals {
  name = "1password-connect"
}

# Avoid secret in terraform state hence why not using helm_release here
resource "terraform_data" "this" {
  triggers_replace = {
    version = var.chart_version
    values  = filemd5("${path.module}/1password-connect.yaml")
  }

  provisioner "local-exec" {
    command = <<EOT
    helm upgrade --install --version ${var.chart_version} \
      --namespace ${local.name} \
      --create-namespace \
      --set connect.credentials_base64=${var.credentials_json_base64} \
      -f ${path.module}/1password-connect.yaml \
      ${local.name} 1password/connect
    EOT
  }
}
