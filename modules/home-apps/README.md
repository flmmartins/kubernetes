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
| [helm_release.immich](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.plex](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_cron_job_v1.immich_album_creator](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cron_job_v1) | resource |
| [kubernetes_deployment_v1.komga](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment_v1) | resource |
| [kubernetes_manifest.httproute_immich](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.httproute_komga](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.tcproute_plex](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_namespace_v1.immich](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace_v1) | resource |
| [kubernetes_namespace_v1.komga](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace_v1) | resource |
| [kubernetes_namespace_v1.plex](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace_v1) | resource |
| [kubernetes_persistent_volume_claim_v1.immich_config](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume_claim_v1) | resource |
| [kubernetes_persistent_volume_claim_v1.immich_data](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume_claim_v1) | resource |
| [kubernetes_persistent_volume_claim_v1.komga_config](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume_claim_v1) | resource |
| [kubernetes_persistent_volume_claim_v1.komga_data](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume_claim_v1) | resource |
| [kubernetes_persistent_volume_claim_v1.plex](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume_claim_v1) | resource |
| [kubernetes_persistent_volume_v1.data_volumes](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume_v1) | resource |
| [kubernetes_secret_v1.vault_ca](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret_v1) | resource |
| [kubernetes_service_v1.komga](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_v1) | resource |
| [kubernetes_storage_class_v1.manual](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/storage_class_v1) | resource |
| [vault_kubernetes_auth_backend_role.immich](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/kubernetes_auth_backend_role) | resource |
| [vault_policy.immich](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/policy) | resource |
| [kubernetes_config_map_v1.vault_ca](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/config_map_v1) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_domain"></a> [domain](#input\_domain) | Domain to use on apps | `string` | n/a | yes |
| <a name="input_ebooks_comics_nfs_share"></a> [ebooks\_comics\_nfs\_share](#input\_ebooks\_comics\_nfs\_share) | NFS share to use for ebooks and comics storage | <pre>object({<br/>    size        = string<br/>    user_id     = number<br/>    group_id    = number<br/>    access_mode = string<br/>    path        = string<br/>    server      = string<br/>  })</pre> | `null` | no |
| <a name="input_emulatorsrooms_nfs_share"></a> [emulatorsrooms\_nfs\_share](#input\_emulatorsrooms\_nfs\_share) | NFS share to use for old games emulators storage | <pre>object({<br/>    size        = string<br/>    user_id     = number<br/>    group_id    = number<br/>    access_mode = string<br/>    path        = string<br/>    server      = string<br/>  })</pre> | `null` | no |
| <a name="input_gateway"></a> [gateway](#input\_gateway) | Gateway to use for the app | <pre>object({<br/>    name      = string<br/>    namespace = string<br/>  })</pre> | n/a | yes |
| <a name="input_immich_album_creator_schedule"></a> [immich\_album\_creator\_schedule](#input\_immich\_album\_creator\_schedule) | Cron schedule for the album creator job | `string` | `"0 4 * * *"` | no |
| <a name="input_immich_album_creator_version"></a> [immich\_album\_creator\_version](#input\_immich\_album\_creator\_version) | Version of the immich-folder-album-creator image. According to github it has to be latest | `string` | `"latest"` | no |
| <a name="input_immich_api_key_vault"></a> [immich\_api\_key\_vault](#input\_immich\_api\_key\_vault) | Vault Agent configuration to inject the Immich API key into the album creator job.<br/>The API key must be stored in Vault and will be injected as an environment variable.<br/>In order for key to be fetched we require the name of the vault ca configmap and it will be copy to immich namespace<br/><br/>Example:<br/>immich\_api\_key\_vault = {<br/>  secret\_path   = "op/vaults/<vault-id>/items/immich"<br/>  vault\_address = "https://vault.vaultnamespace:8200"<br/>  api\_key\_field = "apiKey"<br/>  vault\_ca\_configmap\_name      = "vault-ca"<br/>  vault\_ca\_configmap\_namespace = "vault"<br/>} | <pre>object({<br/>    secret_path                  = string<br/>    vault_csi_ca_cert_path       = optional(string, "/vault/tls/ca.crt")<br/>    api_key_field                = optional(string, "immich-folder-album-creator")<br/>    vault_ca_configmap_name      = string<br/>    vault_ca_configmap_namespace = string<br/>  })</pre> | `null` | no |
| <a name="input_immich_chart_version"></a> [immich\_chart\_version](#input\_immich\_chart\_version) | Photos Processing App Version | `string` | `"0.12.0"` | no |
| <a name="input_immich_database"></a> [immich\_database](#input\_immich\_database) | Database spects for immich | <pre>object({<br/>    server                  = string<br/>    database_name           = string<br/>    credentials_secret_name = string<br/>  })</pre> | n/a | yes |
| <a name="input_komga_image_version"></a> [komga\_image\_version](#input\_komga\_image\_version) | Komga Ebooks & Comic Reader Version | `string` | `"latest"` | no |
| <a name="input_movies_nfs_share"></a> [movies\_nfs\_share](#input\_movies\_nfs\_share) | NFS share to use for movies storage | <pre>object({<br/>    size        = string<br/>    user_id     = number<br/>    group_id    = number<br/>    access_mode = string<br/>    path        = string<br/>    server      = string<br/>  })</pre> | `null` | no |
| <a name="input_music_nfs_share"></a> [music\_nfs\_share](#input\_music\_nfs\_share) | NFS share to use for music storage | <pre>object({<br/>    size        = string<br/>    user_id     = number<br/>    group_id    = number<br/>    access_mode = string<br/>    path        = string<br/>    server      = string<br/>  })</pre> | `null` | no |
| <a name="input_persistent_storage_class"></a> [persistent\_storage\_class](#input\_persistent\_storage\_class) | Name of the storage class which persist data | `string` | n/a | yes |
| <a name="input_photos_nfs_share"></a> [photos\_nfs\_share](#input\_photos\_nfs\_share) | NFS share to use for photos storage | <pre>object({<br/>    size        = string<br/>    user_id     = number<br/>    group_id    = number<br/>    access_mode = string<br/>    path        = string<br/>    server      = string<br/>  })</pre> | `null` | no |
| <a name="input_plex_chart_version"></a> [plex\_chart\_version](#input\_plex\_chart\_version) | Plex Version | `string` | `"1.5.0"` | no |
| <a name="input_plex_gateway_tcp_listener"></a> [plex\_gateway\_tcp\_listener](#input\_plex\_gateway\_tcp\_listener) | Name of the listener that will be used by plex to connect via IP | `string` | n/a | yes |
| <a name="input_plex_ip"></a> [plex\_ip](#input\_plex\_ip) | Plex needs load balancer IP to ADVERTISE\_IP configuration. This can be a load balancer IP. | `string` | n/a | yes |
| <a name="input_tvshows_nfs_share"></a> [tvshows\_nfs\_share](#input\_tvshows\_nfs\_share) | NFS share to use for TV shows storage | <pre>object({<br/>    size        = string<br/>    user_id     = number<br/>    group_id    = number<br/>    access_mode = string<br/>    path        = string<br/>    server      = string<br/>  })</pre> | `null` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->