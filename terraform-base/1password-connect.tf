# Because helm_release does not support set-file and even with set using file doesn't work
resource "terraform_data" "onepassword-connect" {
  depends_on = [helm_release.metrics-server]

  triggers_replace = {
    version = var.onepassword_chart_version
    values  = filemd5("${path.module}/1password-connect.yaml")
  }

  provisioner "local-exec" {
    command = <<EOT
    helm upgrade --install --version ${var.onepassword_chart_version} \
      --namespace 1password-connect \
      --create-namespace \
      --set-file connect.credentials=${path.module}/1password-credentials.json \
      -f 1password-connect.yaml \
      1password-connect 1password/connect
    EOT
  }
}