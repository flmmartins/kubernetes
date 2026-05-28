# Kubelet Certificate Approver

When using talos, it was in the docs a recommendation to install this to auto rotate kubelet certificate.

However adding this via talos proved to be flaky. I added with extraManifests but it turns out I couldn't update the version easily sinced extraManifests are only applied in talos on bootstrap
<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [terraform_data.this](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Kubelet Cert Approver Chart Version | `string` | `"v0.11.0"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->