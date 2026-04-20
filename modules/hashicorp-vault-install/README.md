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
| [helm_release.this](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_manifest.certmanager_vault_tls](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_namespace_v1.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace_v1) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_certificate_issuer"></a> [certificate\_issuer](#input\_certificate\_issuer) | Cert Manager certificate issuer to issue the vault certificate | `any` | `null` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Hashicorp Vault Chart Version | `string` | `"0.32.0"` | no |
| <a name="input_csi_limits_cpu"></a> [csi\_limits\_cpu](#input\_csi\_limits\_cpu) | CPU limit for the csi container (e.g. '100m', '1'). | `string` | `"100m"` | no |
| <a name="input_csi_limits_memory"></a> [csi\_limits\_memory](#input\_csi\_limits\_memory) | Memory limit for the csi container (e.g. '600Mi', '1Gi'). | `string` | `"600Mi"` | no |
| <a name="input_csi_requests_cpu"></a> [csi\_requests\_cpu](#input\_csi\_requests\_cpu) | CPU request for the csi container (e.g. '50m', '1'). | `string` | `"50m"` | no |
| <a name="input_csi_requests_memory"></a> [csi\_requests\_memory](#input\_csi\_requests\_memory) | Memory request for the csi container (e.g. '390Mi', '1Gi'). | `string` | `"390Mi"` | no |
| <a name="input_ingress_annotations"></a> [ingress\_annotations](#input\_ingress\_annotations) | n/a | `map(string)` | `{}` | no |
| <a name="input_injector_limits_cpu"></a> [injector\_limits\_cpu](#input\_injector\_limits\_cpu) | CPU limit for the injector container (e.g. '100m', '1'). | `string` | `"100m"` | no |
| <a name="input_injector_limits_memory"></a> [injector\_limits\_memory](#input\_injector\_limits\_memory) | Memory limit for the injector container (e.g. '100Mi', '1Gi'). | `string` | `"100Mi"` | no |
| <a name="input_injector_requests_cpu"></a> [injector\_requests\_cpu](#input\_injector\_requests\_cpu) | CPU request for the injector container (e.g. '20m', '1'). | `string` | `"20m"` | no |
| <a name="input_injector_requests_memory"></a> [injector\_requests\_memory](#input\_injector\_requests\_memory) | Memory request for the injector container (e.g. '80Mi', '1Gi'). | `string` | `"80Mi"` | no |
| <a name="input_install_onepassword_plugin"></a> [install\_onepassword\_plugin](#input\_install\_onepassword\_plugin) | Wether to install one password plugin or not | `bool` | `false` | no |
| <a name="input_persistent_storage_class_name"></a> [persistent\_storage\_class\_name](#input\_persistent\_storage\_class\_name) | Storage class name for vault | `string` | n/a | yes |
| <a name="input_plugin_onepasswordconnect_version"></a> [plugin\_onepasswordconnect\_version](#input\_plugin\_onepasswordconnect\_version) | Version of 1password connect vault plugin | `string` | `"1.1.0"` | no |
| <a name="input_priority_class"></a> [priority\_class](#input\_priority\_class) | Describe the priority class vault should be in | `string` | `null` | no |
| <a name="input_security_context"></a> [security\_context](#input\_security\_context) | Security context for the vault | <pre>object({<br/>    user_id  = optional(number)<br/>    group_id = optional(number)<br/>  })</pre> | `null` | no |
| <a name="input_server_limits_cpu"></a> [server\_limits\_cpu](#input\_server\_limits\_cpu) | CPU limit for the server container (e.g. '256m', '1'). | `string` | `"256m"` | no |
| <a name="input_server_limits_memory"></a> [server\_limits\_memory](#input\_server\_limits\_memory) | Memory limit for the server container (e.g. '512Mi', '1Gi'). | `string` | `"512Mi"` | no |
| <a name="input_server_requests_cpu"></a> [server\_requests\_cpu](#input\_server\_requests\_cpu) | CPU request for the server container (e.g. '100m', '1'). | `string` | `"100m"` | no |
| <a name="input_server_requests_memory"></a> [server\_requests\_memory](#input\_server\_requests\_memory) | Memory request for the server container (e.g. '512Mi', '1Gi'). | `string` | `"512Mi"` | no |
| <a name="input_url"></a> [url](#input\_url) | Vault URL | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_csi_ca_path"></a> [csi\_ca\_path](#output\_csi\_ca\_path) | Vault CA path inside CSI pod |
| <a name="output_kubernetes_svc"></a> [kubernetes\_svc](#output\_kubernetes\_svc) | Kubernetes service for vault |
| <a name="output_url"></a> [url](#output\_url) | Vault Admin UI |
<!-- END_TF_DOCS -->