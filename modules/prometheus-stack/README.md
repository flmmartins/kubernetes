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
| [kubernetes_namespace_v1.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace_v1) | resource |
| [kubernetes_secret_v1.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret_v1) | resource |
| [vault_kubernetes_auth_backend_role.this](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/kubernetes_auth_backend_role) | resource |
| [vault_policy.this](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alertmanager_cpu_limit"></a> [alertmanager\_cpu\_limit](#input\_alertmanager\_cpu\_limit) | Alert Manager CPU Limit | `string` | `"100m"` | no |
| <a name="input_alertmanager_cpu_request"></a> [alertmanager\_cpu\_request](#input\_alertmanager\_cpu\_request) | Alert Manager CPU Request | `string` | `"25m"` | no |
| <a name="input_alertmanager_memory_limit"></a> [alertmanager\_memory\_limit](#input\_alertmanager\_memory\_limit) | Alert Manager Memory Limit | `string` | `"256Mi"` | no |
| <a name="input_alertmanager_memory_request"></a> [alertmanager\_memory\_request](#input\_alertmanager\_memory\_request) | Alert Manager Memory Request | `string` | `"64Mi"` | no |
| <a name="input_alertmanager_storage_size"></a> [alertmanager\_storage\_size](#input\_alertmanager\_storage\_size) | Alert Manager Storage Size | `string` | `"10Gi"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Prometheus Stack Chart Version | `string` | `"81.4.2"` | no |
| <a name="input_grafana_ingress_annotations"></a> [grafana\_ingress\_annotations](#input\_grafana\_ingress\_annotations) | n/a | `map(string)` | `{}` | no |
| <a name="input_grafana_url"></a> [grafana\_url](#input\_grafana\_url) | Grafana URL | `string` | n/a | yes |
| <a name="input_grana_storage_size"></a> [grana\_storage\_size](#input\_grana\_storage\_size) | Grafana Storage Size | `string` | `"10Gi"` | no |
| <a name="input_operator_cpu_limit"></a> [operator\_cpu\_limit](#input\_operator\_cpu\_limit) | Operator CPU Limit | `string` | `"200m"` | no |
| <a name="input_operator_cpu_request"></a> [operator\_cpu\_request](#input\_operator\_cpu\_request) | Operator CPU Request | `string` | `"100m"` | no |
| <a name="input_operator_memory_limit"></a> [operator\_memory\_limit](#input\_operator\_memory\_limit) | Operator Memory Limit | `string` | `"200Mi"` | no |
| <a name="input_operator_memory_request"></a> [operator\_memory\_request](#input\_operator\_memory\_request) | Operator Memory Request | `string` | `"100Mi"` | no |
| <a name="input_persistent_storage_class_name"></a> [persistent\_storage\_class\_name](#input\_persistent\_storage\_class\_name) | Storage class name for prometheus and alertmanager | `string` | n/a | yes |
| <a name="input_prometheus_cpu_limit"></a> [prometheus\_cpu\_limit](#input\_prometheus\_cpu\_limit) | Prometheus CPU Limit | `string` | `"600m"` | no |
| <a name="input_prometheus_cpu_request"></a> [prometheus\_cpu\_request](#input\_prometheus\_cpu\_request) | Prometheus CPU Request | `string` | `"300m"` | no |
| <a name="input_prometheus_memory_limit"></a> [prometheus\_memory\_limit](#input\_prometheus\_memory\_limit) | Prometheus Memory Limit | `string` | `"512Mi"` | no |
| <a name="input_prometheus_memory_request"></a> [prometheus\_memory\_request](#input\_prometheus\_memory\_request) | Prometheus Memory Request | `string` | `"450Mi"` | no |
| <a name="input_prometheus_storage_size"></a> [prometheus\_storage\_size](#input\_prometheus\_storage\_size) | Prometheus Storage Size | `string` | `"50Gi"` | no |
| <a name="input_retention_days"></a> [retention\_days](#input\_retention\_days) | Prometheus retention days | `string` | `"15d"` | no |
| <a name="input_security_context"></a> [security\_context](#input\_security\_context) | Security context for the prometheus stack | <pre>object({<br/>    user_id  = optional(number)<br/>    group_id = optional(number)<br/>  })</pre> | `null` | no |
| <a name="input_vault_password"></a> [vault\_password](#input\_vault\_password) | Object containing vault data to read grafana password from vault. If not, provided a password will be generated | <pre>object({<br/>    secret_path            = optional(string)<br/>    vault_address          = optional(string)<br/>    vault_csi_ca_cert_path = optional(string, "/vault/tls/ca.crt")<br/>    # Fields in Secret Manager<br/>    username_field = optional(string, "username")<br/>    password_field = optional(string, "password")<br/>  })</pre> | `null` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->