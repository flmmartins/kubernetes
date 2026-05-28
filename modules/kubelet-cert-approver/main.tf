variable "chart_version" {
  description = "Kubelet Cert Approver Chart Version"
  default     = "v0.11.0"
}

data "http" "this" {
  url = "https://raw.githubusercontent.com/alex1989hu/kubelet-serving-cert-approver/${var.chart_version}/deploy/standalone-install.yaml"
}

resource "local_file" "kubelet_serving_cert_approver" {
  content = replace(
    data.http.this.response_body,
    "memory: 32Mi",
    "memory: 128Mi"
  )
  filename = "${path.module}/kubelet-serving-cert-approver.yaml"
}

resource "terraform_data" "kubelet_serving_cert_approver" {
  depends_on = [local_file.kubelet_serving_cert_approver]

  input = local_file.kubelet_serving_cert_approver.filename

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
