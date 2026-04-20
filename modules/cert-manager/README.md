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
| [kubernetes_manifest.dns_provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.letsencrypt_issuer](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.uploaded_ca_issuer](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.vault_pki_issuer](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_namespace_v1.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace_v1) | resource |
| [kubernetes_secret_v1.cert_manager_sa_token](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret_v1) | resource |
| [kubernetes_secret_v1.dns_provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret_v1) | resource |
| [kubernetes_secret_v1.uploaded_ca](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret_v1) | resource |
| [vault_kubernetes_auth_backend_role.this](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/kubernetes_auth_backend_role) | resource |
| [vault_policy.dns_provider](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cert_manager_cainjector_cpu_limit"></a> [cert\_manager\_cainjector\_cpu\_limit](#input\_cert\_manager\_cainjector\_cpu\_limit) | CPU limit for cert-manager cainjector | `string` | `"100m"` | no |
| <a name="input_cert_manager_cainjector_cpu_request"></a> [cert\_manager\_cainjector\_cpu\_request](#input\_cert\_manager\_cainjector\_cpu\_request) | CPU request for cert-manager cainjector | `string` | `"20m"` | no |
| <a name="input_cert_manager_cainjector_memory_limit"></a> [cert\_manager\_cainjector\_memory\_limit](#input\_cert\_manager\_cainjector\_memory\_limit) | Memory limit for cert-manager cainjector | `string` | `"200Mi"` | no |
| <a name="input_cert_manager_cainjector_memory_request"></a> [cert\_manager\_cainjector\_memory\_request](#input\_cert\_manager\_cainjector\_memory\_request) | Memory request for cert-manager cainjector | `string` | `"90Mi"` | no |
| <a name="input_cert_manager_cpu_limit"></a> [cert\_manager\_cpu\_limit](#input\_cert\_manager\_cpu\_limit) | CPU limit for cert-manager controller | `string` | `"20m"` | no |
| <a name="input_cert_manager_cpu_request"></a> [cert\_manager\_cpu\_request](#input\_cert\_manager\_cpu\_request) | CPU request for cert-manager controller | `string` | `"5m"` | no |
| <a name="input_cert_manager_memory_limit"></a> [cert\_manager\_memory\_limit](#input\_cert\_manager\_memory\_limit) | Memory limit for cert-manager controller | `string` | `"100Mi"` | no |
| <a name="input_cert_manager_memory_request"></a> [cert\_manager\_memory\_request](#input\_cert\_manager\_memory\_request) | Memory request for cert-manager controller | `string` | `"25Mi"` | no |
| <a name="input_cert_manager_webhook_cpu_limit"></a> [cert\_manager\_webhook\_cpu\_limit](#input\_cert\_manager\_webhook\_cpu\_limit) | CPU limit for cert-manager webhook | `string` | `"20m"` | no |
| <a name="input_cert_manager_webhook_cpu_request"></a> [cert\_manager\_webhook\_cpu\_request](#input\_cert\_manager\_webhook\_cpu\_request) | CPU request for cert-manager webhook | `string` | `"5m"` | no |
| <a name="input_cert_manager_webhook_memory_limit"></a> [cert\_manager\_webhook\_memory\_limit](#input\_cert\_manager\_webhook\_memory\_limit) | Memory limit for cert-manager webhook | `string` | `"120Mi"` | no |
| <a name="input_cert_manager_webhook_memory_request"></a> [cert\_manager\_webhook\_memory\_request](#input\_cert\_manager\_webhook\_memory\_request) | Memory request for cert-manager webhook | `string` | `"75Mi"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Cert Manager Version | `string` | `"v1.19.2"` | no |
| <a name="input_default_cert_issuer"></a> [default\_cert\_issuer](#input\_default\_cert\_issuer) | Default cluster issuer name. If this is changed make sure it has a matching issuer block | `string` | `"uploaded-ca-issuer"` | no |
| <a name="input_letsencrypt_issuer"></a> [letsencrypt\_issuer](#input\_letsencrypt\_issuer) | Letsencrypt issuer | <pre>object({<br/>    issuer_name = optional(string, "letsencrypt-issuer")<br/>    dns_provider = object({<br/>      name      = string<br/>      e-mail    = string<br/>      api_token = optional(string)<br/>    })<br/>    dns_provider_vault_password = optional(object({<br/>      secret_path            = string<br/>      vault_address          = string<br/>      vault_csi_ca_cert_path = optional(string, "/vault/tls/ca.crt")<br/>      # Fields in Secret Manager<br/>      password_field = optional(string, "password")<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_uploaded_ca_issuer"></a> [uploaded\_ca\_issuer](#input\_uploaded\_ca\_issuer) | This will create an issue based on CA you upload. Please include cert and key so cert manager can issue certificates from it | <pre>object({<br/>    issuer_name      = optional(string, "uploaded-ca-issuer")<br/>    certificate_cert = string<br/>    certificate_key  = string<br/>  })</pre> | `null` | no |
| <a name="input_vault_pki_issuer"></a> [vault\_pki\_issuer](#input\_vault\_pki\_issuer) | Vault pki issuer | <pre>object({<br/>    issuer_name = optional(string, "vault-issuer")<br/>    ca_file     = string<br/>    server      = string<br/>    sign_path   = string<br/>    policy      = string<br/>  })</pre> | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_letsencrypt_issuer"></a> [letsencrypt\_issuer](#output\_letsencrypt\_issuer) | n/a |
| <a name="output_uploaded_ca_issuer"></a> [uploaded\_ca\_issuer](#output\_uploaded\_ca\_issuer) | n/a |
| <a name="output_vault_pki_issuer"></a> [vault\_pki\_issuer](#output\_vault\_pki\_issuer) | n/a |
<!-- END_TF_DOCS -->