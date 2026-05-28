variable "chart_version" {
  description = "Kubelet Cert Approver Chart Version"
  default     = "v0.11.0"
}

resource "terraform_data" "this" {
  input = "https://raw.githubusercontent.com/alex1989hu/kubelet-serving-cert-approver/${var.chart_version}/deploy/standalone-install.yaml"

  triggers_replace = {
    version = var.chart_version
  }

  provisioner "local-exec" {
    command = "kubectl apply -f ${self.input}"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl delete -f ${self.input} --ignore-not-found"
  }
}
