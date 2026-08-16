## Backup manually (retry a failed backup)

```
velero backup create --from-schedule velero-daily-backup
velero backup describe <backup-name> --details
velero backup logs <backup-name>
```

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | n/a |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | n/a |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |
| <a name="provider_vault"></a> [vault](#provider\_vault) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_velero_bucket"></a> [velero\_bucket](#module\_velero\_bucket) | ../seadweed-s3-bucket | n/a |

## Resources

| Name | Type |
|------|------|
| [helm_release.this](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_config_map_v1.velero_grafana_dashboard](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map_v1) | resource |
| [kubernetes_namespace_v1.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace_v1) | resource |
| [kubernetes_secret_v1.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret_v1) | resource |
| [terraform_data.validate_credentials](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [vault_kubernetes_auth_backend_role.this](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/kubernetes_auth_backend_role) | resource |
| [vault_policy.this](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_plugin_version"></a> [aws\_plugin\_version](#input\_aws\_plugin\_version) | AWS Plugin for Velero Version. It has to be compatible with velero. Check: https://github.com/vmware-tanzu/velero-plugin-for-aws?tab=readme-ov-file#compatibility | `string` | `"v1.14.2"` | no |
| <a name="input_backup_schedule"></a> [backup\_schedule](#input\_backup\_schedule) | When to run velero | `any` | n/a | yes |
| <a name="input_backup_storage_location"></a> [backup\_storage\_location](#input\_backup\_storage\_location) | Use default TTL of 30d | <pre>object({<br/>    name        = optional(string, "seaweedfs")<br/>    provider    = optional(string, "aws")<br/>    bucket      = optional(string, "velero")<br/>    default     = optional(bool, true)<br/>    access_mode = optional(string, "ReadWrite")<br/>    config = object({<br/>      region           = optional(string, "seaweedfs")<br/>      s3ForcePathStyle = optional(string, "true")<br/>      s3Url            = string<br/>    })<br/>  })</pre> | n/a | yes |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Prometheus Stack Chart Version | `string` | `"12.1.0"` | no |
| <a name="input_create_backup_from_seaweedfs"></a> [create\_backup\_from\_seaweedfs](#input\_create\_backup\_from\_seaweedfs) | Name of seaweedfs cluster and namespace. If provided, bucket and credentials will be created | <pre>object({<br/>    cluster_name = string<br/>    namespace    = string<br/>  })</pre> | `null` | no |
| <a name="input_enable_metrics"></a> [enable\_metrics](#input\_enable\_metrics) | Whether to enable Prometheus metrics and ServiceMonitor for Velero | `bool` | `false` | no |
| <a name="input_limits_cpu"></a> [limits\_cpu](#input\_limits\_cpu) | CPU limit for the pod (e.g. '250m', '1'). | `string` | `"250m"` | no |
| <a name="input_limits_memory"></a> [limits\_memory](#input\_limits\_memory) | Memory limit for the pod (e.g. '256Mi', '1Gi'). | `string` | `"256Mi"` | no |
| <a name="input_requests_cpu"></a> [requests\_cpu](#input\_requests\_cpu) | CPU request for the pod (e.g. '50m', '1'). | `string` | `"50m"` | no |
| <a name="input_requests_memory"></a> [requests\_memory](#input\_requests\_memory) | Memory request for the pod (e.g. '100Mi', '1Gi'). | `string` | `"100Mi"` | no |
| <a name="input_s3_credentials"></a> [s3\_credentials](#input\_s3\_credentials) | Object containing access\_key\_id and secret\_access\_key for s3 | <pre>object({<br/>    access_key_id     = optional(string)<br/>    secret_access_key = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_snapshots_enabled"></a> [snapshots\_enabled](#input\_snapshots\_enabled) | Wether to take snapshots or not | `bool` | `true` | no |
| <a name="input_vault_password"></a> [vault\_password](#input\_vault\_password) | Vault configuration to read Velero S3 credentials from.<br/>The secret is expected to be stored as a JSON blob in a single Vault field.<br/><br/>Example:<br/>vault\_password = {<br/>  secret\_path   = "secret/velero"<br/>  vault\_address = "https://vault.internal:8200"<br/><br/>  # Optional overrides (these are the defaults):<br/>  vault\_csi\_ca\_cert\_path = "/vault/tls/vault.ca"<br/>  aws\_credentials\_field  = "notesPlain"<br/>}<br/><br/>The json\_field must point to a Vault field containing the Velero S3<br/>credentials in JSON format. Defaults to "notesPlain" for compatibility with 1Password secret references which is note.<br/>Vault field has to be on the following format:<br/>[default]<br/>aws\_access\_key\_id=ACCESS\_KEY<br/>aws\_secret\_access\_key=SECRET | <pre>object({<br/>    secret_path            = optional(string)<br/>    vault_address          = optional(string)<br/>    vault_csi_ca_cert_path = optional(string, "/vault/tls/ca.crt")<br/>    aws_credentials_field  = optional(string, "notesPlain")<br/>  })</pre> | `null` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->