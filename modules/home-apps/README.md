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
| [helm_release.plex](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_deployment_v1.komga](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment_v1) | resource |
| [kubernetes_ingress_v1.komga](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/ingress_v1) | resource |
| [kubernetes_namespace_v1.komga](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace_v1) | resource |
| [kubernetes_namespace_v1.plex](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace_v1) | resource |
| [kubernetes_persistent_volume_claim_v1.komga_config](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume_claim_v1) | resource |
| [kubernetes_persistent_volume_claim_v1.komga_data](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume_claim_v1) | resource |
| [kubernetes_persistent_volume_claim_v1.plex_movies](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume_claim_v1) | resource |
| [kubernetes_persistent_volume_claim_v1.plex_music](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume_claim_v1) | resource |
| [kubernetes_persistent_volume_claim_v1.plex_tvshows](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume_claim_v1) | resource |
| [kubernetes_persistent_volume_v1.data_volumes](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume_v1) | resource |
| [kubernetes_service_v1.komga](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_v1) | resource |
| [kubernetes_storage_class_v1.manual](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/storage_class_v1) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_domain"></a> [domain](#input\_domain) | Domain to use on apps | `string` | n/a | yes |
| <a name="input_existing_nfs_share"></a> [existing\_nfs\_share](#input\_existing\_nfs\_share) | NFS shares | <pre>map(object({<br/>    size        = string<br/>    user_id     = number<br/>    group_id    = number<br/>    access_mode = string<br/>    path        = string<br/>    server      = string<br/>  }))</pre> | n/a | yes |
| <a name="input_immich_chart_version"></a> [immich\_chart\_version](#input\_immich\_chart\_version) | Photos Processing App Version | `string` | `"0.9.3"` | no |
| <a name="input_komga_image_version"></a> [komga\_image\_version](#input\_komga\_image\_version) | Komga Ebooks & Comic Reader Version | `string` | `"latest"` | no |
| <a name="input_persistent_storage_class"></a> [persistent\_storage\_class](#input\_persistent\_storage\_class) | Name of the storage class which persist data | `string` | n/a | yes |
| <a name="input_plex_chart_version"></a> [plex\_chart\_version](#input\_plex\_chart\_version) | Plex Version | `string` | `"1.4.0"` | no |
| <a name="input_plex_ip"></a> [plex\_ip](#input\_plex\_ip) | Plex needs load balancer IP to ADVERTISE\_IP configuration. This can be a load balancer IP. | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->