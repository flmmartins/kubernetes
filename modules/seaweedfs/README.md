## Notes

Operator has to be installed first with terraform target

### TLS

I try to enable TLS between the seaweed pods with the code below but that didn't work and all the pods started having trouble to communicate

```
tls = var.certificate_issuer != null ? {
        enabled = true
        issuerRef = {
          name  = var.certificate_issuer
          kind  = "ClusterIssuer"
          group = "cert-manager.io"
        }
      } : nul`
```

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
| [helm_release.operator](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_manifest.admin_credentials](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.bucket_terraform](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.httproute_s3_api](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.httproute_seaweedfs_admin](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.s3_credentials_admin](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.s3_identity_admin](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.s3_policy_admin](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.s3_policy_binding_admin](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.seaweed](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_namespace_v1.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace_v1) | resource |
| [kubernetes_secret_v1.s3](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret_v1) | resource |
| [kubernetes_service_account_v1.seaweedfs](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account_v1) | resource |
| [vault_kubernetes_auth_backend_role.this](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/kubernetes_auth_backend_role) | resource |
| [vault_policy.this](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_cpu_limit"></a> [admin\_cpu\_limit](#input\_admin\_cpu\_limit) | CPU limit for SeaweedFS admin UI pods | `string` | `"100m"` | no |
| <a name="input_admin_cpu_request"></a> [admin\_cpu\_request](#input\_admin\_cpu\_request) | CPU request for SeaweedFS admin UI pods | `string` | `"50m"` | no |
| <a name="input_admin_memory_limit"></a> [admin\_memory\_limit](#input\_admin\_memory\_limit) | Memory limit for SeaweedFS admin UI pods | `string` | `"100Mi"` | no |
| <a name="input_admin_memory_request"></a> [admin\_memory\_request](#input\_admin\_memory\_request) | Memory request for SeaweedFS admin UI pods | `string` | `"50Mi"` | no |
| <a name="input_admin_ui_port"></a> [admin\_ui\_port](#input\_admin\_ui\_port) | S3 api port | `number` | `23646` | no |
| <a name="input_admin_ui_url"></a> [admin\_ui\_url](#input\_admin\_ui\_url) | Admin URL | `string` | n/a | yes |
| <a name="input_application_image_version"></a> [application\_image\_version](#input\_application\_image\_version) | Seaweedfs Docker Image Version | `string` | `"4.38"` | no |
| <a name="input_filer_cpu_limit"></a> [filer\_cpu\_limit](#input\_filer\_cpu\_limit) | CPU limit for SeaweedFS filer pods | `string` | `"250m"` | no |
| <a name="input_filer_cpu_request"></a> [filer\_cpu\_request](#input\_filer\_cpu\_request) | CPU request for SeaweedFS filer pods | `string` | `"50m"` | no |
| <a name="input_filer_memory_limit"></a> [filer\_memory\_limit](#input\_filer\_memory\_limit) | Memory limit for SeaweedFS filer pods | `string` | `"200Mi"` | no |
| <a name="input_filer_memory_request"></a> [filer\_memory\_request](#input\_filer\_memory\_request) | Memory request for SeaweedFS filer pods | `string` | `"130Mi"` | no |
| <a name="input_filer_storage_size"></a> [filer\_storage\_size](#input\_filer\_storage\_size) | PVC size for SeaweedFS file — where file metadata is stored | `string` | `"5Gi"` | no |
| <a name="input_gateway"></a> [gateway](#input\_gateway) | Gateway to use for the app | <pre>object({<br/>    name      = string<br/>    namespace = string<br/>  })</pre> | n/a | yes |
| <a name="input_master_cpu_limit"></a> [master\_cpu\_limit](#input\_master\_cpu\_limit) | CPU limit for SeaweedFS master pods | `string` | `"100m"` | no |
| <a name="input_master_cpu_request"></a> [master\_cpu\_request](#input\_master\_cpu\_request) | CPU request for SeaweedFS master pods | `string` | `"50m"` | no |
| <a name="input_master_memory_limit"></a> [master\_memory\_limit](#input\_master\_memory\_limit) | Memory limit for SeaweedFS master pods | `string` | `"128Mi"` | no |
| <a name="input_master_memory_request"></a> [master\_memory\_request](#input\_master\_memory\_request) | Memory request for SeaweedFS master pods | `string` | `"64Mi"` | no |
| <a name="input_operator_chart_version"></a> [operator\_chart\_version](#input\_operator\_chart\_version) | Seaweedfs Chart Operator Version | `string` | `"0.1.33"` | no |
| <a name="input_operator_cpu_limit"></a> [operator\_cpu\_limit](#input\_operator\_cpu\_limit) | CPU limit for the SeaweedFS operator controller manager | `string` | `"100m"` | no |
| <a name="input_operator_cpu_request"></a> [operator\_cpu\_request](#input\_operator\_cpu\_request) | CPU request for the SeaweedFS operator controller manager | `string` | `"50m"` | no |
| <a name="input_operator_memory_limit"></a> [operator\_memory\_limit](#input\_operator\_memory\_limit) | Memory limit for the SeaweedFS operator controller manager | `string` | `"128Mi"` | no |
| <a name="input_operator_memory_request"></a> [operator\_memory\_request](#input\_operator\_memory\_request) | Memory request for the SeaweedFS operator controller manager | `string` | `"64Mi"` | no |
| <a name="input_persistent_storage_class_name"></a> [persistent\_storage\_class\_name](#input\_persistent\_storage\_class\_name) | Storage class name for PVC | `string` | n/a | yes |
| <a name="input_s3_cpu_limit"></a> [s3\_cpu\_limit](#input\_s3\_cpu\_limit) | CPU limit for SeaweedFS S3 gateway pods | `string` | `"250m"` | no |
| <a name="input_s3_cpu_request"></a> [s3\_cpu\_request](#input\_s3\_cpu\_request) | CPU request for SeaweedFS S3 gateway pods | `string` | `"50m"` | no |
| <a name="input_s3_memory_limit"></a> [s3\_memory\_limit](#input\_s3\_memory\_limit) | Memory limit for SeaweedFS S3 gateway pods | `string` | `"400Mi"` | no |
| <a name="input_s3_memory_request"></a> [s3\_memory\_request](#input\_s3\_memory\_request) | Memory request for SeaweedFS S3 gateway pods | `string` | `"70Mi"` | no |
| <a name="input_s3api_port"></a> [s3api\_port](#input\_s3api\_port) | S3 api port | `number` | `8333` | no |
| <a name="input_s3api_url"></a> [s3api\_url](#input\_s3api\_url) | S3 api URL | `string` | n/a | yes |
| <a name="input_security_context"></a> [security\_context](#input\_security\_context) | Security context for the cluster | <pre>object({<br/>    user_id  = optional(number)<br/>    group_id = optional(number)<br/>  })</pre> | `null` | no |
| <a name="input_vault_password"></a> [vault\_password](#input\_vault\_password) | Vault configuration to read SeaweedFS credentials from.<br/>Supports reading admin credentials and S3 config JSON from a Vault secret.<br/>If this is not provided, secrets will be auto generated for s3 and seaweedfs admin secret will be empty<br/><br/>Example:<br/>vault\_password = {<br/>  secret\_path   = "secret/seaweedfs"<br/>  vault\_address = "https://vault.internal:8200"<br/><br/>  # Optional overrides (these are the defaults):<br/>  vault\_csi\_ca\_cert\_path          = "/vault/tls/vault.ca"<br/>  admin\_username\_field            = "Secret Field which represents admin user, username is default"<br/>  admin\_password\_field            = "Secret Field which represents admin pwd, password is default"<br/>  s3\_admin\_credentials\_json\_field = "Secret Field which represents s3 object store credentials, defaults to seaweedfs\_s3\_config, This is independent from admin credentials"<br/>}<br/><br/>The s3\_admin\_credentials\_json\_field must point to a Vault field containing<br/>the SeaweedFS S3 config in JSON format. Format has to be:<br/>seaweedfs\_s3\_config = {"identities":[{"name":"admin","credentials":[{"accessKey”:” ACCESID,”secretKey”:”SECRET”}],”actions":["Admin","Read","Write"]}]}]} | <pre>object({<br/>    secret_path            = optional(string)<br/>    vault_address          = optional(string)<br/>    vault_csi_ca_cert_path = optional(string, "/vault/tls/ca.crt")<br/>    # Fields in Secret Manager<br/>    admin_username_field = optional(string, "username")<br/>    admin_password_field = optional(string, "password")<br/>    # The S3 has to be in json format and to interact with CSI is best to store the json<br/>    s3_admin_credentials_json_field = optional(string, "seaweedfs_s3_config")<br/>  })</pre> | `null` | no |
| <a name="input_volume_cpu_limit"></a> [volume\_cpu\_limit](#input\_volume\_cpu\_limit) | CPU limit for SeaweedFS volume pods | `string` | `"250m"` | no |
| <a name="input_volume_cpu_request"></a> [volume\_cpu\_request](#input\_volume\_cpu\_request) | CPU request for SeaweedFS volume pods | `string` | `"50m"` | no |
| <a name="input_volume_memory_limit"></a> [volume\_memory\_limit](#input\_volume\_memory\_limit) | Memory limit for SeaweedFS volume pods | `string` | `"200Mi"` | no |
| <a name="input_volume_memory_request"></a> [volume\_memory\_request](#input\_volume\_memory\_request) | Memory request for SeaweedFS volume pods | `string` | `"70Mi"` | no |
| <a name="input_volume_storage_size"></a> [volume\_storage\_size](#input\_volume\_storage\_size) | PVC size for SeaweedFS volume servers — where object data is stored | `string` | `"10Gi"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_admin_url"></a> [admin\_url](#output\_admin\_url) | SeaweedFS Admin UI |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | Seaweedfs cluster name |
| <a name="output_namespace"></a> [namespace](#output\_namespace) | Seaweedfs namespace |
| <a name="output_s3_kubernetes_svc"></a> [s3\_kubernetes\_svc](#output\_s3\_kubernetes\_svc) | S3-compatible internal to the cluster |
| <a name="output_s3_url"></a> [s3\_url](#output\_s3\_url) | S3-compatible endpoint |
<!-- END_TF_DOCS -->