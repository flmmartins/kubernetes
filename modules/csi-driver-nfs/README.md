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
| <a name="input_controller_csi_provisioner_limits_cpu"></a> [controller\_csi\_provisioner\_limits\_cpu](#input\_controller\_csi\_provisioner\_limits\_cpu) | CPU limit for the controller csiProvisioner container (e.g. '100m', '1'). | `string` | `"100m"` | no |
| <a name="input_controller_csi_provisioner_limits_memory"></a> [controller\_csi\_provisioner\_limits\_memory](#input\_controller\_csi\_provisioner\_limits\_memory) | Memory limit for the controller csiProvisioner container (e.g. '128Mi', '1Gi'). | `string` | `"128Mi"` | no |
| <a name="input_controller_csi_provisioner_requests_cpu"></a> [controller\_csi\_provisioner\_requests\_cpu](#input\_controller\_csi\_provisioner\_requests\_cpu) | CPU request for the controller csiProvisioner container (e.g. '25m', '1'). | `string` | `"25m"` | no |
| <a name="input_controller_csi_provisioner_requests_memory"></a> [controller\_csi\_provisioner\_requests\_memory](#input\_controller\_csi\_provisioner\_requests\_memory) | Memory request for the controller csiProvisioner container (e.g. '32Mi', '1Gi'). | `string` | `"32Mi"` | no |
| <a name="input_controller_csi_resizer_limits_cpu"></a> [controller\_csi\_resizer\_limits\_cpu](#input\_controller\_csi\_resizer\_limits\_cpu) | CPU limit for the controller csiResizer container (e.g. '100m', '1'). | `string` | `"100m"` | no |
| <a name="input_controller_csi_resizer_limits_memory"></a> [controller\_csi\_resizer\_limits\_memory](#input\_controller\_csi\_resizer\_limits\_memory) | Memory limit for the controller csiResizer container (e.g. '128Mi', '1Gi'). | `string` | `"128Mi"` | no |
| <a name="input_controller_csi_resizer_requests_cpu"></a> [controller\_csi\_resizer\_requests\_cpu](#input\_controller\_csi\_resizer\_requests\_cpu) | CPU request for the controller csiResizer container (e.g. '25m', '1'). | `string` | `"25m"` | no |
| <a name="input_controller_csi_resizer_requests_memory"></a> [controller\_csi\_resizer\_requests\_memory](#input\_controller\_csi\_resizer\_requests\_memory) | Memory request for the controller csiResizer container (e.g. '32Mi', '1Gi'). | `string` | `"32Mi"` | no |
| <a name="input_controller_csi_snapshotter_limits_cpu"></a> [controller\_csi\_snapshotter\_limits\_cpu](#input\_controller\_csi\_snapshotter\_limits\_cpu) | CPU limit for the controller csiSnapshotter container (e.g. '75m', '1'). | `string` | `"75m"` | no |
| <a name="input_controller_csi_snapshotter_limits_memory"></a> [controller\_csi\_snapshotter\_limits\_memory](#input\_controller\_csi\_snapshotter\_limits\_memory) | Memory limit for the controller csiSnapshotter container (e.g. '96Mi', '1Gi'). | `string` | `"96Mi"` | no |
| <a name="input_controller_csi_snapshotter_requests_cpu"></a> [controller\_csi\_snapshotter\_requests\_cpu](#input\_controller\_csi\_snapshotter\_requests\_cpu) | CPU request for the controller csiSnapshotter container (e.g. '15m', '1'). | `string` | `"15m"` | no |
| <a name="input_controller_csi_snapshotter_requests_memory"></a> [controller\_csi\_snapshotter\_requests\_memory](#input\_controller\_csi\_snapshotter\_requests\_memory) | Memory request for the controller csiSnapshotter container (e.g. '32Mi', '1Gi'). | `string` | `"32Mi"` | no |
| <a name="input_controller_liveness_probe_limits_cpu"></a> [controller\_liveness\_probe\_limits\_cpu](#input\_controller\_liveness\_probe\_limits\_cpu) | CPU limit for the controller livenessProbe container (e.g. '50m', '1'). | `string` | `"50m"` | no |
| <a name="input_controller_liveness_probe_limits_memory"></a> [controller\_liveness\_probe\_limits\_memory](#input\_controller\_liveness\_probe\_limits\_memory) | Memory limit for the controller livenessProbe container (e.g. '32Mi', '1Gi'). | `string` | `"32Mi"` | no |
| <a name="input_controller_liveness_probe_requests_cpu"></a> [controller\_liveness\_probe\_requests\_cpu](#input\_controller\_liveness\_probe\_requests\_cpu) | CPU request for the controller livenessProbe container (e.g. '10m', '1'). | `string` | `"10m"` | no |
| <a name="input_controller_liveness_probe_requests_memory"></a> [controller\_liveness\_probe\_requests\_memory](#input\_controller\_liveness\_probe\_requests\_memory) | Memory request for the controller livenessProbe container (e.g. '16Mi', '1Gi'). | `string` | `"16Mi"` | no |
| <a name="input_controller_nfs_limits_cpu"></a> [controller\_nfs\_limits\_cpu](#input\_controller\_nfs\_limits\_cpu) | CPU limit for the controller nfs container (e.g. '100m', '1'). | `string` | `"100m"` | no |
| <a name="input_controller_nfs_limits_memory"></a> [controller\_nfs\_limits\_memory](#input\_controller\_nfs\_limits\_memory) | Memory limit for the controller nfs container (e.g. '128Mi', '1Gi'). | `string` | `"128Mi"` | no |
| <a name="input_controller_nfs_requests_cpu"></a> [controller\_nfs\_requests\_cpu](#input\_controller\_nfs\_requests\_cpu) | CPU request for the controller nfs container (e.g. '25m', '1'). | `string` | `"25m"` | no |
| <a name="input_controller_nfs_requests_memory"></a> [controller\_nfs\_requests\_memory](#input\_controller\_nfs\_requests\_memory) | Memory request for the controller nfs container (e.g. '32Mi', '1Gi'). | `string` | `"32Mi"` | no |
| <a name="input_folder"></a> [folder](#input\_folder) | NFS Folder | `string` | n/a | yes |
| <a name="input_labels"></a> [labels](#input\_labels) | Labels to apply to all resources created by the CSI Driver NFS module | `map(string)` | `{}` | no |
| <a name="input_mount_permissions"></a> [mount\_permissions](#input\_mount\_permissions) | Mount permissions for the NFS volumes (e.g., 0700) | `string` | `"0700"` | no |
| <a name="input_node_driver_registrar_limits_cpu"></a> [node\_driver\_registrar\_limits\_cpu](#input\_node\_driver\_registrar\_limits\_cpu) | CPU limit for the node nodeDriverRegistrar container (e.g. '50m', '1'). | `string` | `"50m"` | no |
| <a name="input_node_driver_registrar_limits_memory"></a> [node\_driver\_registrar\_limits\_memory](#input\_node\_driver\_registrar\_limits\_memory) | Memory limit for the node nodeDriverRegistrar container (e.g. '56Mi', '1Gi'). | `string` | `"56Mi"` | no |
| <a name="input_node_driver_registrar_requests_cpu"></a> [node\_driver\_registrar\_requests\_cpu](#input\_node\_driver\_registrar\_requests\_cpu) | CPU request for the node nodeDriverRegistrar container (e.g. '10m', '1'). | `string` | `"10m"` | no |
| <a name="input_node_driver_registrar_requests_memory"></a> [node\_driver\_registrar\_requests\_memory](#input\_node\_driver\_registrar\_requests\_memory) | Memory request for the node nodeDriverRegistrar container (e.g. '28Mi', '1Gi'). | `string` | `"28Mi"` | no |
| <a name="input_node_liveness_probe_limits_cpu"></a> [node\_liveness\_probe\_limits\_cpu](#input\_node\_liveness\_probe\_limits\_cpu) | CPU limit for the node livenessProbe container (e.g. '50m', '1'). | `string` | `"50m"` | no |
| <a name="input_node_liveness_probe_limits_memory"></a> [node\_liveness\_probe\_limits\_memory](#input\_node\_liveness\_probe\_limits\_memory) | Memory limit for the node livenessProbe container (e.g. '56Mi', '1Gi'). | `string` | `"56Mi"` | no |
| <a name="input_node_liveness_probe_requests_cpu"></a> [node\_liveness\_probe\_requests\_cpu](#input\_node\_liveness\_probe\_requests\_cpu) | CPU request for the node livenessProbe container (e.g. '10m', '1'). | `string` | `"10m"` | no |
| <a name="input_node_liveness_probe_requests_memory"></a> [node\_liveness\_probe\_requests\_memory](#input\_node\_liveness\_probe\_requests\_memory) | Memory request for the node livenessProbe container (e.g. '28Mi', '1Gi'). | `string` | `"28Mi"` | no |
| <a name="input_node_nfs_limits_cpu"></a> [node\_nfs\_limits\_cpu](#input\_node\_nfs\_limits\_cpu) | CPU limit for the node nfs container (e.g. '100m', '1'). | `string` | `"100m"` | no |
| <a name="input_node_nfs_limits_memory"></a> [node\_nfs\_limits\_memory](#input\_node\_nfs\_limits\_memory) | Memory limit for the node nfs container (e.g. '128Mi', '1Gi'). | `string` | `"128Mi"` | no |
| <a name="input_node_nfs_requests_cpu"></a> [node\_nfs\_requests\_cpu](#input\_node\_nfs\_requests\_cpu) | CPU request for the node nfs container (e.g. '25m', '1'). | `string` | `"25m"` | no |
| <a name="input_node_nfs_requests_memory"></a> [node\_nfs\_requests\_memory](#input\_node\_nfs\_requests\_memory) | Memory request for the node nfs container (e.g. '64Mi', '1Gi'). | `string` | `"64Mi"` | no |
| <a name="input_replicas"></a> [replicas](#input\_replicas) | Number of replicas for the CSI Driver NFS controller | `number` | `1` | no |
| <a name="input_server"></a> [server](#input\_server) | NFS Server IP or hostname | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_default_storage_class"></a> [default\_storage\_class](#output\_default\_storage\_class) | Name of the default storage class |
| <a name="output_persistent_storage_class"></a> [persistent\_storage\_class](#output\_persistent\_storage\_class) | Name of the persistent storage class |
<!-- END_TF_DOCS -->