# Install

# Vault Certificates

Firstly it's necessary to generate certificates for TLS.. I generated vault certificates from the truenas tamrieltower CA.

Used instructions from vault [website](https://developer.hashicorp.com/vault/tutorials/kubernetes/kubernetes-minikube-tls) to add certificate and to initiliase vault

`kubectl create ns vault`

```
kubectl create secret generic vault-ha-tls \
   -n vault \
   --from-file=vault.key=$(PWD)/hashicorp_vault.key \
   --from-file=vault.crt=$(PWD)/hashicorp_vault.crt \
   --from-file=vault.ca=$(PWD)/TamrielTower.crt
```

# Install Vault

```
helm upgrade --install --version "~0.29.1" \
    --namespace vault \
    -f vault.yaml \
    vault hashicorp/vault
```

# Initialise

```
kubectl exec -n vault vault-0 -- vault operator init \
    -key-shares=1 \
    -key-threshold=1 \
    -format=json > ./cluster-keys.json
```

`key-shares` is the number of unseal keys to generate
`key-threshold` number of keys to reconstruct the root key. Needs to be less or equal to key-shares

This will output unseal key and root key

Enter `vault-0` and unseal with `vault operator unseal` with the unseal b64 info from the file.

# Joining another pod to vault

Example where vault-1 is the joinee and vault-0 is the leader

```
kubectl exec -n vault -it vault-1 -- /bin/sh

vault operator raft join -address=https://vault-1.vault-internal:8200 -leader-ca-cert="$(cat /vault/userconfig/vault-ha-tls/vault.ca)" -leader-client-cert="$(cat /vault/userconfig/vault-ha-tls/vault.crt)" -leader-client-key="$(cat /vault/userconfig/vault-ha-tls/vault.key)" https://vault-0.vault-internal:8200
```

After joining unseal vault-1 


# Checks


```
kubectl exec -n $VAULT_K8S_NAMESPACE vault-0 -- vault login $CLUSTER_ROOT_TOKEN

vault operator raft list-peers
vault status
```

You need to remove the key afterwards

# Installing 1password plugin

The initContainer in Helm will install the binary. Afterwards you need to:

```
SHA256_CHECKSUM=$(sha256sum /usr/local/libexec/vault/op-connect | cut -d ' ' -f1)
vault plugin register -sha256=$SHA256_CHECKSUM secret op-connect
vault secrets enable --path="op" op-connect
vault write op/config \
  op_connect_host=http://onepassword-connect.1password-connect:8080 \
  op_connect_token=$OP_CONNECT_TOKEN
```
Checks:

Returns the names and UUIDs for the vault(s) that are accessible to the Connect access token:

```
vault list op/vaults
vault list op/vaults/<vault_name_or_uuid_from_command_above>/items
```

Read item:

```
vault read op/vaults/<vault_name_or_uuid>/items/<item_title_or_uuid>
```