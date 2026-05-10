Using GTW API requires all gtw certs to be wildcards. Bellow is why:

# Using non-wildcard certificates

When trying to install Gateway API with Let's Encrypt issuer when using non-wildcard certificates you need all certificates declared in the listener in the gateway.

How are you going to create listener and it's certificate if the app is still not ready? You enter in a sort of chicken and egg problem where you need listeners but they will only be available when actual apps use it and create it's own certificate.

This problem is resolved by ListenerSet which allows you to create ListenerSets as the application is created but Istio does not support it yet resulting on ListenerSet unknown


Here's what was tried with vault


```
resource "kubernetes_manifest" "certmanager_vault_ui" {
  count = var.certificate_issuer != null ? 1 : 0
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = local.vault_ui_secret
      namespace = kubernetes_namespace_v1.this.metadata[0].name
    }
    spec = {
      secretName = local.vault_ui_secret
      issuerRef = {
        name  = var.certificate_issuer
        kind  = "ClusterIssuer"
        group = "cert-manager.io"
      }
      dnsNames = [var.url]
    }
  }
}

resource "kubernetes_manifest" "listenerset_vault" {
  count = var.certificate_issuer != null ? 1 : 0

  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "ListenerSet"
    metadata = {
      name      = "vault-listener"
      namespace = kubernetes_namespace_v1.this.metadata[0].name
    }
    spec = {
      parentRef = {
        group     = "gateway.networking.k8s.io"
        kind      = "Gateway"
        name      = var.gateway.name
        namespace = var.gateway.namespace
      }
      listeners = [
        {
          name     = "https-vault"
          port     = 443
          protocol = "HTTPS"
          hostname = var.url
          tls = {
            mode            = "Terminate"
            certificateRefs = [{ name = kubernetes_manifest.certmanager_vault_ui[0].manifest.spec.secretName }]
          }
          allowedRoutes = { namespaces = { from = "Same" } }
        }
      ]
    }
  }
}

# HTTPRoute - not supported by Vault Helm yet
resource "kubernetes_manifest" "httproute_vault" {
  count = var.certificate_issuer != null ? 1 : 0

  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "vault-httproute"
      namespace = kubernetes_namespace_v1.this.metadata[0].name
    }
    spec = {
      parentRefs = [{
        group       = "gateway.networking.k8s.io"
        kind        = "ListenerSet"
        name        = kubernetes_manifest.listenerset_vault[0].manifest.metadata.name
        namespace   = kubernetes_manifest.listenerset_vault[0].manifest.metadata.namespace
        sectionName = kubernetes_manifest.listenerset_vault[0].manifest.spec.listeners[0].name
      }]
      hostnames = [var.url]
      rules = [
        {
          matches     = [{ path = { type = "PathPrefix", value = "/" } }]
          backendRefs = [{ name = "vault-ui", port = 8200 }]
        }
      ]
    }
  }
}
```


<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name                                                                   | Version |
| ---------------------------------------------------------------------- | ------- |
| <a name="provider_helm"></a> [helm](#provider\_helm)                   | n/a     |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | n/a     |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform)    | n/a     |

## Modules

No modules.

## Resources

| Name                                                                                                                                      | Type     |
| ----------------------------------------------------------------------------------------------------------------------------------------- | -------- |
| [helm_release.istio-base](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release)                           | resource |
| [helm_release.istiod](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release)                               | resource |
| [helm_release.metallb](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release)                              | resource |
| [kubernetes_manifest.gateway](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest)                | resource |
| [kubernetes_manifest.istio_ip_address_pool](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest)  | resource |
| [kubernetes_manifest.istio_l2_advertisement](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_namespace_v1.gateway](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace_v1)        | resource |
| [kubernetes_namespace_v1.istio](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace_v1)          | resource |
| [kubernetes_namespace_v1.metallb](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace_v1)        | resource |
| [terraform_data.gateway_crds](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data)                     | resource |

## Inputs

| Name                                                                                                              | Description                                   | Type     | Default    | Required |
| ----------------------------------------------------------------------------------------------------------------- | --------------------------------------------- | -------- | ---------- | :------: |
| <a name="input_controller_cpu_limit"></a> [controller\_cpu\_limit](#input\_controller\_cpu\_limit)                | n/a                                           | `string` | `"100m"`   |    no    |
| <a name="input_controller_cpu_request"></a> [controller\_cpu\_request](#input\_controller\_cpu\_request)          | n/a                                           | `string` | `"50m"`    |    no    |
| <a name="input_controller_memory_limit"></a> [controller\_memory\_limit](#input\_controller\_memory\_limit)       | n/a                                           | `string` | `"150Mi"`  |    no    |
| <a name="input_controller_memory_request"></a> [controller\_memory\_request](#input\_controller\_memory\_request) | n/a                                           | `string` | `"50Mi"`   |    no    |
| <a name="input_gateway_crds_version"></a> [gateway\_crds\_version](#input\_gateway\_crds\_version)                | Gateway API CRDs Version                      | `string` | `"v1.5.1"` |    no    |
| <a name="input_istio_chart_version"></a> [istio\_chart\_version](#input\_istio\_chart\_version)                   | Istio Chart Version                           | `string` | `"1.29.2"` |    no    |
| <a name="input_istio_ip"></a> [istio\_ip](#input\_istio\_ip)                                                      | Load Balancer IP assigned for Istio           | `string` | n/a        |   yes    |
| <a name="input_metallb_chart_version"></a> [metallb\_chart\_version](#input\_metallb\_chart\_version)             | Metal LB Chart Version                        | `string` | `"0.15.3"` |    no    |
| <a name="input_speaker_cpu_limit"></a> [speaker\_cpu\_limit](#input\_speaker\_cpu\_limit)                         | n/a                                           | `string` | `"100m"`   |    no    |
| <a name="input_speaker_cpu_request"></a> [speaker\_cpu\_request](#input\_speaker\_cpu\_request)                   | n/a                                           | `string` | `"50m"`    |    no    |
| <a name="input_speaker_memory_limit"></a> [speaker\_memory\_limit](#input\_speaker\_memory\_limit)                | n/a                                           | `string` | `"200Mi"`  |    no    |
| <a name="input_speaker_memory_request"></a> [speaker\_memory\_request](#input\_speaker\_memory\_request)          | n/a                                           | `string` | `"150Mi"`  |    no    |
| <a name="input_uses_metallb"></a> [uses\_metallb](#input\_uses\_metallb)                                          | Uses metallb to provide IPs to the controller | `bool`   | `false`    |    no    |

## Outputs

| Name                                                                                      | Description |
| ----------------------------------------------------------------------------------------- | ----------- |
| <a name="output_gateway"></a> [gateway](#output\_gateway)                                 | n/a         |
| <a name="output_istio_ip"></a> [istio\_ip](#output\_istio\_ip)                            | n/a         |
| <a name="output_metallb_namespace"></a> [metallb\_namespace](#output\_metallb\_namespace) | n/a         |
<!-- END_TF_DOCS -->