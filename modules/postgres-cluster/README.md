# Creating roles/users

This module will create roles in the indicated namespaces. It's important the namespace is created before adding the role block

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
| [kubernetes_manifest.backup_secret_provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.certificate_server](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_namespace_v1.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace_v1) | resource |
| [kubernetes_secret_v1.credentials_in_app_namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret_v1) | resource |
| [kubernetes_secret_v1.credentials_in_pg_namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret_v1) | resource |
| [vault_kubernetes_auth_backend_role.backup](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/kubernetes_auth_backend_role) | resource |
| [vault_policy.backup](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_backup"></a> [backup](#input\_backup) | Backup to S3 specifications via Vault CSI.<br/>Example:<br/>backup = {<br/>  s3\_endpoint  = "http://...:8333"<br/>  s3\_bucket    = "pg-backups"<br/>  schedule     = "0 0 0 * * *"<br/>  retention\_policy = "30d"<br/>  vault\_password = {<br/>    vault\_address  = "https://vault.vault:8200"<br/>    secret\_path    = "op/vaults/my-vault/items/pg-backup-s3"<br/>    access\_key\_field = "accessKey"<br/>    secret\_key\_field = "secretKey"<br/>  }<br/>} | <pre>object({<br/>    s3_endpoint      = string<br/>    s3_bucket        = string<br/>    schedule         = string<br/>    retention_policy = string<br/>    vault_password = object({<br/>      vault_address          = string<br/>      secret_path            = string<br/>      vault_csi_ca_cert_path = optional(string, "/vault/tls/ca.crt")<br/>      access_key_field       = optional(string, "accessKey")<br/>      secret_key_field       = optional(string, "secretKey")<br/>    })<br/>  })</pre> | `null` | no |
| <a name="input_certificate_issuer"></a> [certificate\_issuer](#input\_certificate\_issuer) | The Cert Manager issuer to use for PostgreSQL certificates. This should be the name of an existing issuer in your Kubernetes cluster. | `string` | n/a | yes |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | The version of the CloudNative PG chart to deploy. This should be a valid version string from the CNPG chart repository. | `string` | `"0.6.1"` | no |
| <a name="input_cluster"></a> [cluster](#input\_cluster) | Clusters to be created. If you don't provide a url, the cluster will not have external access and will only be accessible within the Kubernetes cluster | <pre>object({<br/>    name          = string<br/>    storage_class = optional(string)<br/>    url           = optional(string)<br/>    size          = optional(string, "10Gi")<br/>    instances     = optional(number, 2)<br/>  })</pre> | n/a | yes |
| <a name="input_cluster_resources_limits_cpu"></a> [cluster\_resources\_limits\_cpu](#input\_cluster\_resources\_limits\_cpu) | The CPU limit for the CloudNative PG operator.This defines the maximum CPU resources the operator can use. | `string` | `"500m"` | no |
| <a name="input_cluster_resources_limits_memory"></a> [cluster\_resources\_limits\_memory](#input\_cluster\_resources\_limits\_memory) | The memory limit for the CloudNative PG operator. This defines the maximum memory resources the operator can use. | `string` | `"1Gi"` | no |
| <a name="input_cluster_resources_requests_cpu"></a> [cluster\_resources\_requests\_cpu](#input\_cluster\_resources\_requests\_cpu) | The CPU request for the CloudNative PG operator. This defines the minimum CPU resources the operator will request. | `string` | `"100m"` | no |
| <a name="input_cluster_resources_requests_memory"></a> [cluster\_resources\_requests\_memory](#input\_cluster\_resources\_requests\_memory) | The memory request for the CloudNative PG operator. This defines the minimum memory resources the operator will request | `string` | `"256Mi"` | no |
| <a name="input_cluster_shared_buffers"></a> [cluster\_shared\_buffers](#input\_cluster\_shared\_buffers) | Shared buffers should be at least 25% of available memory | `string` | `"50MB"` | no |
| <a name="input_databases"></a> [databases](#input\_databases) | Database settings | <pre>list(object({<br/>    name       = string<br/>    owner      = string<br/>    extensions = optional(list(string), [])<br/>  }))</pre> | n/a | yes |
| <a name="input_mode"></a> [mode](#input\_mode) | -- Cluster mode of operation. Available modes:<br/>standalone - default mode. Creates new or updates an existing CNPG cluster.<br/>replica - Creates a replica cluster from an existing CNPG cluster.<br/>recovery - Same as standalone but creates a cluster from a backup, object store or via pg\_basebackup. | `string` | `"standalone"` | no |
| <a name="input_postgres_version"></a> [postgres\_version](#input\_postgres\_version) | The version of postgres database | `string` | `"16"` | no |
| <a name="input_roles"></a> [roles](#input\_roles) | Role settings. This will create the role and if create secret in namespace is set as a k8s secret | <pre>list(object({<br/>    name                       = string<br/>    login                      = optional(bool, true)<br/>    create_secret_in_namespace = optional(string)<br/>    superuser                  = optional(bool, false)<br/>    state                      = optional(string, "present")<br/>  }))</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ro_svc"></a> [ro\_svc](#output\_ro\_svc) | Read only service to connect to the cluster |
| <a name="output_role_secret_names"></a> [role\_secret\_names](#output\_role\_secret\_names) | Map of role name to the secret name created in the app namespace |
| <a name="output_rw_svc"></a> [rw\_svc](#output\_rw\_svc) | Read write service to connect to the cluster |
<!-- END_TF_DOCS -->