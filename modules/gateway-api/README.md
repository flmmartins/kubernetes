<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | n/a |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.metallb](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_namespace_v1.metallb](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace_v1) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_controller_cpu_limit"></a> [controller\_cpu\_limit](#input\_controller\_cpu\_limit) | n/a | `string` | `"100m"` | no |
| <a name="input_controller_cpu_request"></a> [controller\_cpu\_request](#input\_controller\_cpu\_request) | n/a | `string` | `"50m"` | no |
| <a name="input_controller_memory_limit"></a> [controller\_memory\_limit](#input\_controller\_memory\_limit) | n/a | `string` | `"150Mi"` | no |
| <a name="input_controller_memory_request"></a> [controller\_memory\_request](#input\_controller\_memory\_request) | ----------------------------------------------------------------------------- Metallb ----------------------------------------------------------------------------- | `string` | `"50Mi"` | no |
| <a name="input_metallb_chart_version"></a> [metallb\_chart\_version](#input\_metallb\_chart\_version) | Metal LB Chart Version | `string` | `"0.15.3"` | no |
| <a name="input_speaker_cpu_limit"></a> [speaker\_cpu\_limit](#input\_speaker\_cpu\_limit) | n/a | `string` | `"100m"` | no |
| <a name="input_speaker_cpu_request"></a> [speaker\_cpu\_request](#input\_speaker\_cpu\_request) | n/a | `string` | `"50m"` | no |
| <a name="input_speaker_memory_limit"></a> [speaker\_memory\_limit](#input\_speaker\_memory\_limit) | n/a | `string` | `"200Mi"` | no |
| <a name="input_speaker_memory_request"></a> [speaker\_memory\_request](#input\_speaker\_memory\_request) | n/a | `string` | `"150Mi"` | no |
| <a name="input_uses_metallb"></a> [uses\_metallb](#input\_uses\_metallb) | Uses metallb to provide IPs to the controller | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_metallb_namespace"></a> [metallb\_namespace](#output\_metallb\_namespace) | n/a |
<!-- END_TF_DOCS -->