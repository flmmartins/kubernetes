<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | n/a |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | n/a |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.istio-base](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.istiod](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.metallb](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_manifest.istio_ip_address_pool](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.istio_l2_advertisement](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_namespace_v1.istio](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace_v1) | resource |
| [kubernetes_namespace_v1.metallb](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace_v1) | resource |
| [terraform_data.gateway_crds](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_controller_cpu_limit"></a> [controller\_cpu\_limit](#input\_controller\_cpu\_limit) | n/a | `string` | `"100m"` | no |
| <a name="input_controller_cpu_request"></a> [controller\_cpu\_request](#input\_controller\_cpu\_request) | n/a | `string` | `"50m"` | no |
| <a name="input_controller_memory_limit"></a> [controller\_memory\_limit](#input\_controller\_memory\_limit) | n/a | `string` | `"150Mi"` | no |
| <a name="input_controller_memory_request"></a> [controller\_memory\_request](#input\_controller\_memory\_request) | n/a | `string` | `"50Mi"` | no |
| <a name="input_gateway_crds_version"></a> [gateway\_crds\_version](#input\_gateway\_crds\_version) | Gateway API CRDs Version | `string` | `"v1.5.1"` | no |
| <a name="input_istio_chart_version"></a> [istio\_chart\_version](#input\_istio\_chart\_version) | Istio Chart Version | `string` | `"1.29.2"` | no |
| <a name="input_istio_ip"></a> [istio\_ip](#input\_istio\_ip) | Load Balancer IP assigned for Istio | `string` | n/a | yes |
| <a name="input_metallb_chart_version"></a> [metallb\_chart\_version](#input\_metallb\_chart\_version) | Metal LB Chart Version | `string` | `"0.15.3"` | no |
| <a name="input_speaker_cpu_limit"></a> [speaker\_cpu\_limit](#input\_speaker\_cpu\_limit) | n/a | `string` | `"100m"` | no |
| <a name="input_speaker_cpu_request"></a> [speaker\_cpu\_request](#input\_speaker\_cpu\_request) | n/a | `string` | `"50m"` | no |
| <a name="input_speaker_memory_limit"></a> [speaker\_memory\_limit](#input\_speaker\_memory\_limit) | n/a | `string` | `"200Mi"` | no |
| <a name="input_speaker_memory_request"></a> [speaker\_memory\_request](#input\_speaker\_memory\_request) | n/a | `string` | `"150Mi"` | no |
| <a name="input_uses_metallb"></a> [uses\_metallb](#input\_uses\_metallb) | Uses metallb to provide IPs to the controller | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_istio_ip"></a> [istio\_ip](#output\_istio\_ip) | n/a |
| <a name="output_metallb_namespace"></a> [metallb\_namespace](#output\_metallb\_namespace) | n/a |
<!-- END_TF_DOCS -->