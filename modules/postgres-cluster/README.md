<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [kubernetes_manifest.certificate_server](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_namespace_v1.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace_v1) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_certificate_issuer"></a> [certificate\_issuer](#input\_certificate\_issuer) | The Cert Manager issuer to use for PostgreSQL certificates. This should be the name of an existing issuer in your Kubernetes cluster. | `string` | n/a | yes |
| <a name="input_cluster"></a> [cluster](#input\_cluster) | Clusters to be created. If you don't provide a url, the cluster will not have external access and will only be accessible within the Kubernetes cluster | <pre>object({<br/>    name          = string<br/>    storage_class = optional(string)<br/>    url           = optional(string)<br/>    size          = optional(string, "10Gi")<br/>    instances     = optional(number, 1)<br/>  })</pre> | n/a | yes |
| <a name="input_cluster_resources_limits_cpu"></a> [cluster\_resources\_limits\_cpu](#input\_cluster\_resources\_limits\_cpu) | The CPU limit for the CloudNative PG operator.This defines the maximum CPU resources the operator can use. | `string` | `"100m"` | no |
| <a name="input_cluster_resources_limits_memory"></a> [cluster\_resources\_limits\_memory](#input\_cluster\_resources\_limits\_memory) | The memory limit for the CloudNative PG operator. This defines the maximum memory resources the operator can use. | `string` | `"200Mi"` | no |
| <a name="input_cluster_resources_requests_cpu"></a> [cluster\_resources\_requests\_cpu](#input\_cluster\_resources\_requests\_cpu) | The CPU request for the CloudNative PG operator. This defines the minimum CPU resources the operator will request. | `string` | `"100m"` | no |
| <a name="input_cluster_resources_requests_memory"></a> [cluster\_resources\_requests\_memory](#input\_cluster\_resources\_requests\_memory) | The memory request for the CloudNative PG operator. This defines the minimum memory resources the operator will request | `string` | `"200Mi"` | no |
| <a name="input_cluster_shared_buffers"></a> [cluster\_shared\_buffers](#input\_cluster\_shared\_buffers) | Shared buffers should be at least 25% of available memory | `string` | `"50MB"` | no |
| <a name="input_pg_operator_service_account"></a> [pg\_operator\_service\_account](#input\_pg\_operator\_service\_account) | Service account configuration for the PostgreSQL operator be able to manage resources | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->