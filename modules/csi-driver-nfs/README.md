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
| [kubernetes_storage_class_v1.default](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/storage_class_v1) | resource |
| [kubernetes_storage_class_v1.persistent](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/storage_class_v1) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | CSI Driver NFS Chart Version | `string` | `"4.12.1"` | no |
| <a name="input_folder"></a> [folder](#input\_folder) | NFS Folder | `string` | n/a | yes |
| <a name="input_labels"></a> [labels](#input\_labels) | Labels to apply to all resources created by the CSI Driver NFS module | `map(string)` | `{}` | no |
| <a name="input_mount_permissions"></a> [mount\_permissions](#input\_mount\_permissions) | Mount permissions for the NFS volumes (e.g., 0700) | `string` | `"0700"` | no |
| <a name="input_replicas"></a> [replicas](#input\_replicas) | Number of replicas for the CSI Driver NFS controller | `number` | `1` | no |
| <a name="input_server"></a> [server](#input\_server) | NFS Server IP or hostname | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_default_storage_class"></a> [default\_storage\_class](#output\_default\_storage\_class) | Name of the default storage class |
| <a name="output_persistent_storage_class"></a> [persistent\_storage\_class](#output\_persistent\_storage\_class) | Name of the persistent storage class |
<!-- END_TF_DOCS -->