<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.postgres_operator](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | The version of the CloudNative PG chart to deploy. This should be a valid version string from the CNPG chart repository. | `string` | `"v0.28.2"` | no |
| <a name="input_operator_resources_limits_cpu"></a> [operator\_resources\_limits\_cpu](#input\_operator\_resources\_limits\_cpu) | The CPU limit for the CloudNative PG operator.This defines the maximum CPU resources the operator can use. | `string` | `"100m"` | no |
| <a name="input_operator_resources_limits_memory"></a> [operator\_resources\_limits\_memory](#input\_operator\_resources\_limits\_memory) | The memory limit for the CloudNative PG operator. This defines the maximum memory resources the operator can use. | `string` | `"200Mi"` | no |
| <a name="input_operator_resources_requests_cpu"></a> [operator\_resources\_requests\_cpu](#input\_operator\_resources\_requests\_cpu) | The CPU request for the CloudNative PG operator. This defines the minimum CPU resources the operator will request. | `string` | `"50m"` | no |
| <a name="input_operator_resources_requests_memory"></a> [operator\_resources\_requests\_memory](#input\_operator\_resources\_requests\_memory) | The memory request for the CloudNative PG operator. This defines the minimum memory resources the operator will request | `string` | `"100Mi"` | no |
| <a name="input_security_context"></a> [security\_context](#input\_security\_context) | Security context for the operator be able to read/write to PVs | <pre>object({<br/>    user_id  = optional(number)<br/>    group_id = optional(number)<br/>  })</pre> | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_service_account"></a> [service\_account](#output\_service\_account) | The service account used by the PostgreSQL operator to manage resources in the cluster |
<!-- END_TF_DOCS -->