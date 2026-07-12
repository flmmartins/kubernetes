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
| <a name="input_application"></a> [application](#input\_application) | Name and namespace of the application allowed to interact with bucket | <pre>object({<br/>    name      = string<br/>    namespace = string<br/>  })</pre> | n/a | yes |
| <a name="input_bucket_ttl"></a> [bucket\_ttl](#input\_bucket\_ttl) | TTL for objects to be excluded | `string` | `"30d"` | no |
| <a name="input_provider_api"></a> [provider\_api](#input\_provider\_api) | S3 Provider url | `string` | `"seaweed.seaweedfs.com/v1"` | no |
| <a name="input_seaweedfs"></a> [seaweedfs](#input\_seaweedfs) | Name of seaweedfs cluster and namespace | <pre>object({<br/>    cluster_name = string<br/>    namespace    = string<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_s3_secret_name"></a> [s3\_secret\_name](#output\_s3\_secret\_name) | Name of the secret in kubernetes containing s3 credentials |
<!-- END_TF_DOCS -->