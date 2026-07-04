<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [terraform_data.this](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | 1password Connect Chart Version | `string` | `"2.4.1"` | no |
| <a name="input_credentials_json_base64"></a> [credentials\_json\_base64](#input\_credentials\_json\_base64) | 1password Credentials File json encoded in base64 | `string` | n/a | yes |
| <a name="input_priority_class"></a> [priority\_class](#input\_priority\_class) | Describe the priority class the cluster pods should be in | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_kubernetes_svc"></a> [kubernetes\_svc](#output\_kubernetes\_svc) | Kubernetes Service |
<!-- END_TF_DOCS -->