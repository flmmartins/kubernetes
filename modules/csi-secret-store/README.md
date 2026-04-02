<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.this](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Prometheus Stack Chart Version | `string` | `"1.5.6"` | no |
| <a name="input_csi_driver_limit_cpu"></a> [csi\_driver\_limit\_cpu](#input\_csi\_driver\_limit\_cpu) | CPU limit for the CSI driver container | `string` | `"150m"` | no |
| <a name="input_csi_driver_limit_memory"></a> [csi\_driver\_limit\_memory](#input\_csi\_driver\_limit\_memory) | Memory limit for the CSI driver container | `string` | `"128Mi"` | no |
| <a name="input_csi_driver_request_cpu"></a> [csi\_driver\_request\_cpu](#input\_csi\_driver\_request\_cpu) | CPU request for the CSI driver container | `string` | `"25m"` | no |
| <a name="input_csi_driver_request_memory"></a> [csi\_driver\_request\_memory](#input\_csi\_driver\_request\_memory) | Memory request for the CSI driver container | `string` | `"64Mi"` | no |
| <a name="input_csi_liveness_probe_limit_cpu"></a> [csi\_liveness\_probe\_limit\_cpu](#input\_csi\_liveness\_probe\_limit\_cpu) | CPU limit for the CSI liveness probe container | `string` | `"50m"` | no |
| <a name="input_csi_liveness_probe_limit_memory"></a> [csi\_liveness\_probe\_limit\_memory](#input\_csi\_liveness\_probe\_limit\_memory) | Memory limit for the CSI liveness probe container | `string` | `"64Mi"` | no |
| <a name="input_csi_liveness_probe_request_cpu"></a> [csi\_liveness\_probe\_request\_cpu](#input\_csi\_liveness\_probe\_request\_cpu) | CPU request for the CSI liveness probe container | `string` | `"5m"` | no |
| <a name="input_csi_liveness_probe_request_memory"></a> [csi\_liveness\_probe\_request\_memory](#input\_csi\_liveness\_probe\_request\_memory) | Memory request for the CSI liveness probe container | `string` | `"32Mi"` | no |
| <a name="input_csi_registrar_limit_cpu"></a> [csi\_registrar\_limit\_cpu](#input\_csi\_registrar\_limit\_cpu) | CPU limit for the CSI registrar container | `string` | `"50m"` | no |
| <a name="input_csi_registrar_limit_memory"></a> [csi\_registrar\_limit\_memory](#input\_csi\_registrar\_limit\_memory) | Memory limit for the CSI registrar container | `string` | `"64Mi"` | no |
| <a name="input_csi_registrar_request_cpu"></a> [csi\_registrar\_request\_cpu](#input\_csi\_registrar\_request\_cpu) | CPU request for the CSI registrar container | `string` | `"5m"` | no |
| <a name="input_csi_registrar_request_memory"></a> [csi\_registrar\_request\_memory](#input\_csi\_registrar\_request\_memory) | Memory request for the CSI registrar container | `string` | `"32Mi"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->