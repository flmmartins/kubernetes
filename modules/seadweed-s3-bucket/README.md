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
| [kubernetes_manifest.allow_app_create_seaweedfs_secret](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.bucket](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.s3_credentials](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.s3_identity](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.s3_policy](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.s3_policy_binding](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_secret_v1.s3_credentials_placeholder](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret_v1) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_key_field"></a> [access\_key\_field](#input\_access\_key\_field) | The secret field that should contain the access key id | `string` | `"accessKey"` | no |
| <a name="input_application"></a> [application](#input\_application) | Name and namespace of the application allowed to interact with bucket | <pre>object({<br/>    name      = string<br/>    namespace = string<br/>  })</pre> | n/a | yes |
| <a name="input_provider_api"></a> [provider\_api](#input\_provider\_api) | S3 Provider url | `string` | `"seaweed.seaweedfs.com/v1"` | no |
| <a name="input_seaweedfs"></a> [seaweedfs](#input\_seaweedfs) | Name of seaweedfs cluster and namespace | <pre>object({<br/>    cluster_name = string<br/>    namespace    = string<br/>  })</pre> | n/a | yes |
| <a name="input_secret_key_field"></a> [secret\_key\_field](#input\_secret\_key\_field) | The secret field that should contain the secret key | `string` | `"secretKey"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bucket"></a> [bucket](#output\_bucket) | Name of the created bucket |
| <a name="output_secret_fields"></a> [secret\_fields](#output\_secret\_fields) | Name of the keys inside kubernetes secret |
| <a name="output_secret_name"></a> [secret\_name](#output\_secret\_name) | Name of the secret in kubernetes containing s3 credentials |
<!-- END_TF_DOCS -->