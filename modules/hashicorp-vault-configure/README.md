# PKI

## First installation
You need to import the root CA for the PKI and you can do it with:

(cat cert.key; echo; cat cert.crt; echo; cat root_ca_if_any.crt; echo)


## Rotation
I used the UI, imported new Root and later set it as defaut with:

```
vault write pki/apps/root/root/replace default=UID
```

Terraform wanted to re-create the mount because certificate changed so I did a terraform state rm and just let it apply again. There were no conflict


## Extensions
PS: When considering doing MTLS with certificates make sure the ROOT CA and any intermediate have this as extension: serverAuth,clientAuth

There were cases where MTLS was not working because it was missing clientAuth in all certificates of the chain and that was a workful to fix because I had to reissue the entire chain.

ROOT:

```
[req]
distinguished_name = req
[v3_ca]
basicConstraints = critical,CA:TRUE
keyUsage = critical,keyCertSign,cRLSign
extendedKeyUsage = serverAuth,clientAuth
```

Intermediates:

```
basicConstraints = critical,CA:TRUE
keyUsage = critical,keyCertSign,cRLSign
extendedKeyUsage = serverAuth,clientAuth
```

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | n/a |
| <a name="provider_vault"></a> [vault](#provider\_vault) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [kubernetes_manifest.pki_issuer](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [vault_auth_backend.kubernetes](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/auth_backend) | resource |
| [vault_generic_endpoint.onepassword-connect-config](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/generic_endpoint) | resource |
| [vault_generic_endpoint.op_connect_mount](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/generic_endpoint) | resource |
| [vault_kubernetes_auth_backend_config.kubernetes](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/kubernetes_auth_backend_config) | resource |
| [vault_kubernetes_auth_backend_role.pki-issuer](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/kubernetes_auth_backend_role) | resource |
| [vault_mount.kv](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/mount) | resource |
| [vault_mount.pki](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/mount) | resource |
| [vault_pki_secret_backend_config_ca.pki](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/pki_secret_backend_config_ca) | resource |
| [vault_pki_secret_backend_config_urls.pki](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/pki_secret_backend_config_urls) | resource |
| [vault_pki_secret_backend_role.pki](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/pki_secret_backend_role) | resource |
| [vault_plugin.op_connect](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/plugin) | resource |
| [vault_policy.pki](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_address"></a> [address](#input\_address) | URL of the Vault server. This is required for connecting to Vault. Example: "https://vault.example.com" | `string` | n/a | yes |
| <a name="input_kv_path"></a> [kv\_path](#input\_kv\_path) | Path prefix for key-value storage engine in vault. This is used to create a namespaced key-value store. If null, no storage will be created. Example: "secret" would create keys under /secret. | `string` | `null` | no |
| <a name="input_onepassword_connect"></a> [onepassword\_connect](#input\_onepassword\_connect) | OnePassword plugin configuration. This variable contains sensitive information required to connect to OnePassword. If provided, the plugin will be installed and configured automatically. | <pre>object({<br/>    token = string<br/>    host  = string<br/>  })</pre> | `null` | no |
| <a name="input_pki"></a> [pki](#input\_pki) | Configuration for PKI (Public Key Infrastructure) setup. This variable contains information needed to create a PKI backend and associated issuer in Vault.<br/>Attributes:<br/>  root\_ca: Path to the PKI Root Certificate Authority (CA) certificate<br/>  path: Path prefix for PKI storage, default to pki<br/>  role\_name: Name of the PKI role that signs certificates, defaults to pki<br/>  vault\_internal\_ca: Internal Vault CA certificate for Kubernetes cluster. This is required for to allow communication from cert manager to Vault internal svc.<br/>  certmanager\_sa: Service account configuration for Cert Manager integration<br/><br/>  root\_ca can be generated with: (cat cert.key; echo; cat cert.crt; echo; cat root\_ca.crt; echo)<br/>  The whole content should be passed to this variable" | <pre>object({<br/>    root_ca           = string<br/>    path              = optional(string, "pki")<br/>    role_name         = optional(string, "pki")<br/>    vault_internal_ca = string<br/>    certmanager_sa = object({<br/>      namespace = string<br/>      name      = string<br/>      secret    = string<br/>    })<br/>  })</pre> | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_kubernetes_backend"></a> [kubernetes\_backend](#output\_kubernetes\_backend) | n/a |
| <a name="output_kv_backend"></a> [kv\_backend](#output\_kv\_backend) | n/a |
| <a name="output_onepassword_backend"></a> [onepassword\_backend](#output\_onepassword\_backend) | n/a |
| <a name="output_pki_backend"></a> [pki\_backend](#output\_pki\_backend) | n/a |
| <a name="output_vault_pki_issuer"></a> [vault\_pki\_issuer](#output\_vault\_pki\_issuer) | n/a |
<!-- END_TF_DOCS -->