<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | n/a |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | n/a |
| <a name="provider_vault"></a> [vault](#provider\_vault) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.this](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_manifest.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_namespace_v1.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace_v1) | resource |
| [kubernetes_secret_v1.s3](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret_v1) | resource |
| [vault_kubernetes_auth_backend_role.this](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/kubernetes_auth_backend_role) | resource |
| [vault_policy.this](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_cpu_limit"></a> [admin\_cpu\_limit](#input\_admin\_cpu\_limit) | CPU limit for SeaweedFS admin UI pods | `string` | `"100m"` | no |
| <a name="input_admin_cpu_request"></a> [admin\_cpu\_request](#input\_admin\_cpu\_request) | CPU request for SeaweedFS admin UI pods | `string` | `"50m"` | no |
| <a name="input_admin_memory_limit"></a> [admin\_memory\_limit](#input\_admin\_memory\_limit) | Memory limit for SeaweedFS admin UI pods | `string` | `"128Mi"` | no |
| <a name="input_admin_memory_request"></a> [admin\_memory\_request](#input\_admin\_memory\_request) | Memory request for SeaweedFS admin UI pods | `string` | `"64Mi"` | no |
| <a name="input_admin_ui_ingress_annotations"></a> [admin\_ui\_ingress\_annotations](#input\_admin\_ui\_ingress\_annotations) | n/a | `map(string)` | `{}` | no |
| <a name="input_admin_ui_port"></a> [admin\_ui\_port](#input\_admin\_ui\_port) | S3 api port | `number` | `23646` | no |
| <a name="input_admin_ui_url"></a> [admin\_ui\_url](#input\_admin\_ui\_url) | Admin URL | `string` | n/a | yes |
| <a name="input_buckets"></a> [buckets](#input\_buckets) | List of buckets to add to seadweedfs | <pre>list(object({<br/>    name          = string<br/>    ttl           = string<br/>    anonymousRead = optional(bool, false)<br/>    objectLock    = optional(bool, false)<br/>    versioning    = optional(string, "Enabled")<br/>  }))</pre> | <pre>[<br/>  {<br/>    "name": "terraform",<br/>    "objectLock": true,<br/>    "ttl": "90d"<br/>  }<br/>]</pre> | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Seaweedfs Chart Version | `string` | `"4.17.0"` | no |
| <a name="input_filer_cpu_limit"></a> [filer\_cpu\_limit](#input\_filer\_cpu\_limit) | CPU limit for SeaweedFS filer pods | `string` | `"250m"` | no |
| <a name="input_filer_cpu_request"></a> [filer\_cpu\_request](#input\_filer\_cpu\_request) | CPU request for SeaweedFS filer pods | `string` | `"50m"` | no |
| <a name="input_filer_memory_limit"></a> [filer\_memory\_limit](#input\_filer\_memory\_limit) | Memory limit for SeaweedFS filer pods | `string` | `"400Mi"` | no |
| <a name="input_filer_memory_request"></a> [filer\_memory\_request](#input\_filer\_memory\_request) | Memory request for SeaweedFS filer pods | `string` | `"100Mi"` | no |
| <a name="input_filer_storage_size"></a> [filer\_storage\_size](#input\_filer\_storage\_size) | PVC size for SeaweedFS file — where file metadata is stored | `string` | `"5Gi"` | no |
| <a name="input_master_cpu_limit"></a> [master\_cpu\_limit](#input\_master\_cpu\_limit) | CPU limit for SeaweedFS master pods | `string` | `"100m"` | no |
| <a name="input_master_cpu_request"></a> [master\_cpu\_request](#input\_master\_cpu\_request) | CPU request for SeaweedFS master pods | `string` | `"50m"` | no |
| <a name="input_master_memory_limit"></a> [master\_memory\_limit](#input\_master\_memory\_limit) | Memory limit for SeaweedFS master pods | `string` | `"128Mi"` | no |
| <a name="input_master_memory_request"></a> [master\_memory\_request](#input\_master\_memory\_request) | Memory request for SeaweedFS master pods | `string` | `"64Mi"` | no |
| <a name="input_persistent_storage_class_name"></a> [persistent\_storage\_class\_name](#input\_persistent\_storage\_class\_name) | Storage class name for PVC | `string` | n/a | yes |
| <a name="input_s3_cpu_limit"></a> [s3\_cpu\_limit](#input\_s3\_cpu\_limit) | CPU limit for SeaweedFS S3 gateway pods | `string` | `"250m"` | no |
| <a name="input_s3_cpu_request"></a> [s3\_cpu\_request](#input\_s3\_cpu\_request) | CPU request for SeaweedFS S3 gateway pods | `string` | `"50m"` | no |
| <a name="input_s3_memory_limit"></a> [s3\_memory\_limit](#input\_s3\_memory\_limit) | Memory limit for SeaweedFS S3 gateway pods | `string` | `"400Mi"` | no |
| <a name="input_s3_memory_request"></a> [s3\_memory\_request](#input\_s3\_memory\_request) | Memory request for SeaweedFS S3 gateway pods | `string` | `"100Mi"` | no |
| <a name="input_s3api_ingress_annotations"></a> [s3api\_ingress\_annotations](#input\_s3api\_ingress\_annotations) | n/a | `map(string)` | `{}` | no |
| <a name="input_s3api_port"></a> [s3api\_port](#input\_s3api\_port) | S3 api port | `number` | `8333` | no |
| <a name="input_s3api_url"></a> [s3api\_url](#input\_s3api\_url) | S3 api URL | `string` | n/a | yes |
| <a name="input_security_context"></a> [security\_context](#input\_security\_context) | Security context for the cluster | <pre>object({<br/>    user_id  = optional(number)<br/>    group_id = optional(number)<br/>  })</pre> | `null` | no |
| <a name="input_vault_password"></a> [vault\_password](#input\_vault\_password) | Vault configuration to read SeaweedFS credentials from.<br/>Supports reading admin credentials and S3 config JSON from a Vault secret.<br/>If this is not provided, secrets will be auto generated for s3 and seadweedfs admin secret will be empty<br/><br/>Example:<br/>vault\_password = {<br/>  secret\_path   = "secret/seaweedfs"<br/>  vault\_address = "https://vault.internal:8200"<br/><br/>  # Optional overrides (these are the defaults):<br/>  vault\_csi\_ca\_cert\_path          = "/vault/tls/vault.ca"<br/>  admin\_username\_field            = "Secret Field which represents admin user, username is default"<br/>  admin\_password\_field            = "Secret Field which represents admin pwd, password is default"<br/>  s3\_admin\_credentials\_json\_field = "Secret Field which represents s3 object store credentials, defaults to seaweedfs\_s3\_config, This is independent from admin credentials"<br/>}<br/><br/>The s3\_admin\_credentials\_json\_field must point to a Vault field containing<br/>the SeaweedFS S3 config in JSON format. Format has to be:<br/>seaweedfs\_s3\_config = {"identities":[{"name":"admin","credentials":[{"accessKey”:” ACCESID,”secretKey”:”SECRET”}],”actions":["Admin","Read","Write"]}]}]} | <pre>object({<br/>    secret_path            = optional(string)<br/>    vault_address          = optional(string)<br/>    vault_csi_ca_cert_path = optional(string, "/vault/tls/vault.ca")<br/>    # Fields in Secret Manager<br/>    admin_username_field = optional(string, "username")<br/>    admin_password_field = optional(string, "password")<br/>    # The S3 has to be in json format and to interact with CSI is best to store the json<br/>    s3_admin_credentials_json_field = optional(string, "seaweedfs_s3_config")<br/>  })</pre> | `null` | no |
| <a name="input_volume_cpu_limit"></a> [volume\_cpu\_limit](#input\_volume\_cpu\_limit) | CPU limit for SeaweedFS volume pods | `string` | `"250m"` | no |
| <a name="input_volume_cpu_request"></a> [volume\_cpu\_request](#input\_volume\_cpu\_request) | CPU request for SeaweedFS volume pods | `string` | `"50m"` | no |
| <a name="input_volume_memory_limit"></a> [volume\_memory\_limit](#input\_volume\_memory\_limit) | Memory limit for SeaweedFS volume pods | `string` | `"400Mi"` | no |
| <a name="input_volume_memory_request"></a> [volume\_memory\_request](#input\_volume\_memory\_request) | Memory request for SeaweedFS volume pods | `string` | `"100Mi"` | no |
| <a name="input_volume_storage_size"></a> [volume\_storage\_size](#input\_volume\_storage\_size) | PVC size for SeaweedFS volume servers — where object data is stored | `string` | `"10Gi"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_admin_url"></a> [admin\_url](#output\_admin\_url) | SeaweedFS Admin UI |
| <a name="output_s3_endpoint"></a> [s3\_endpoint](#output\_s3\_endpoint) | S3-compatible endpoint |
| <a name="output_s3_internal_endpoint"></a> [s3\_internal\_endpoint](#output\_s3\_internal\_endpoint) | S3-compatible internal to the cluster |
<!-- END_TF_DOCS -->