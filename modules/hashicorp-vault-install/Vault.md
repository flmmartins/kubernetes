# Accessing the UI

Without ingress: `kubectl -n vault port-forward service/vault -n vault 8200:8200`

# Install

Terraform will run `create-vault-tls-cert.sh` which will create certificate, namespace and kubernetes secret.

To create the script it was used instructions from vault [website](https://developer.hashicorp.com/vault/tutorials/kubernetes/kubernetes-minikube-tls) to add certificate and to initiliase vault

When using Secret Injector we missed a [SAN](https://github.com/hashicorp/vault/issues/19131) (vault.vault.svc) to the certificate so I made a script that install vault and add the appropriate fixes.

After running the script, terraform will install the helm chart but if it's the first ever run vault needs to be initiliased according to next section and only then terraform can continue run

## Initialise

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

## Joining another pod to vault

Example where vault-1 is the joinee and vault-0 is the leader

```
kubectl exec -n vault -it vault-1 -- /bin/sh

vault operator raft join -address=https://vault-1.vault-internal:8200 -leader-ca-cert="$(cat /vault/userconfig/vault-ha-tls/vault.ca)" -leader-client-cert="$(cat /vault/userconfig/vault-ha-tls/vault.crt)" -leader-client-key="$(cat /vault/userconfig/vault-ha-tls/vault.key)" https://vault-0.vault-internal:8200
```

After joining unseal vault-1 


## Checks

```
kubectl exec -n $VAULT_K8S_NAMESPACE vault-0 -- vault login $CLUSTER_ROOT_TOKEN

vault operator raft list-peers
vault status
```

You need to remove the key afterwards

## Installing 1password plugin

The initContainer in Helm will install the binary. Afterwards you need to:

```
SHA256_CHECKSUM=$(sha256sum /usr/local/libexec/vault/op-connect | cut -d ' ' -f1)
vault plugin register -sha256=$SHA256_CHECKSUM secret op-connect
vault secrets enable --path="op" op-connect
vault write op/config \
  op_connect_host=http://onepassword-connect.1password-connect:8080 \
  op_connect_token=$OP_CONNECT_TOKEN
```
These commands are now done by terraform

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

## Configure Kubernetes Authentication

This is now done by terraform but I let the manual reference documented

```
vault auth enable kubernetes

vault write auth/kubernetes/config \
  issuer="https://kubernetes.default.svc.cluster.local" \
  token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
  kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443" \
  kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
```

**Issue with token_reviewer_jwt**

The issue of defining a token_reviewer_jwt happens when all vault pods go down. It loses the token and kubernetes authentication goes bad.
If you remove from the command above it, kubernetes will fetch a new one when necessary but then pods starts to complain about `invalid issuer (iss) claim`

In the end the solution was to remove most of arguments and leave as in terraform


### How to troubeshoot

Check auth:

```
vault read auth/kubernetes/config
```

Check if getting the token works:
```
KUBE_TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)

TOKEN=$(curl --cacert /run/secrets/kubernetes.io/serviceaccount/ca.crt --request POST --data '{"jwt": "'"$KUBE_TOKEN"'", "role": "pihole"}' https://vault.vault.svc:8200/v1/auth/kubernetes/login | jq -r '.auth | .client_token')
```

Check if policy works:

```
curl -H "X-Vault-Token: $TOKEN" \
     https://vault.vault.svc:8200/v1/op/vaults/<vault-id>/items/my_secret
```

```
vault policy read my_policy
vault read auth/kubernetes/role/my_role
```

# Vault Secret Injector

It allows you to inject secret in the pod (unfortunately it doesn't support Kubernetes Secrets creation, read about CSI for that)

In order to use Secret Injector you need:
1. Create a Policy and Role in Vault
2. Add annotations to pod as below:

Example: The secret injector injects secret as file or environment variable
```
podAnnotations:
  vault.hashicorp.com/agent-inject: 'true'
  vault.hashicorp.com/role: 'pihole'
  vault.hashicorp.com/agent-inject-secret-admin: 'op/vaults/bla/items/pihole'
  vault.hashicorp.com/ca-cert: "/run/secrets/kubernetes.io/serviceaccount/ca.crt"
  vault.hashicorp.com/agent-inject-template-webpassword: |
    {{- with secret "op/vaults/bla/items/pihole" -}}
    WEBPASSWORD="{{ .Data.password }}"
    {{- end }}
```

# Using Vault CSI Driver

We use Vault CSI Provider to create Kubernetes Secret Objects based on Vault content

## Usage

You need:
1. Create a Policy and Role in Vault
2. Mount the CSI driver to your pod
3. Create a Secret Provider Class

Examples can be found in [here](https://developer.hashicorp.com/vault/docs/deploy/kubernetes/csi/examples).

Don't forget to pass the TLS cert and role as:


```
roleName: "pihole"
vaultCACertPath: "/run/secrets/kubernetes.io/serviceaccount/ca.crt"
```


## Install

The CSI Driver allows you to fetch and create kubernetes secrets

First you need to install CSI Secret Driver:

```
helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts

helm upgrade --install csi-secrets-store secrets-store-csi-driver/secrets-store-csi-driver --namespace kube-system --set syncSecret.enabled=true
```

Once that installed you can use [Secret Provider Class](https://developer.hashicorp.com/vault/docs/deploy/kubernetes/csi) and point it to vault to create your Kubernetes Secret

Requirement:

You need to allow Vault CSI Provider to use hostpath by doing:

```
kubectl label ns vault pod-security.kubernetes.io/enforce=privileged \
  --overwrite
```

In CSI you have:
* CSI Container
* Secret Class
* App mounting CSI

It was crazy to figure out how to pass the certificate. After multiple combination it was determined that you could do:

```
csi:
  enabled: true
  agent:
    extraArgs:
    - -ca-cert=/vault/tls/vault.ca
  volumes:
  - name: tls
    secret:
      secretName: vault-ha-tls
  volumeMounts:
  - name: tls
    mountPath: /vault/tls
    readOnly: true
```

However you can see CSI all over the place so I moved all that responsability to the Secret Provider Class and removed the agent. Now all CSI needs is defined in Secret Provider Class:

Example:

```
roleName: "pihole"
vaultCACertPath: "/run/secrets/kubernetes.io/serviceaccount/ca.crt"
```

# PKI

We will import root CA
```
cat talos-apps-tamrieltower-local.key > talos-apps-tamrieltower-local.pem
cat talos-apps-tamrieltower-local.crt >> talos-apps-tamrieltower-local.pem
```

Run 

```
kubectl port-forward service/vault -n vault 8200:8200
export VAULT_ADDR=https://127.0.0.1:8200
export VAULT_TOKEN=$VAULT_TOKEN
export VAULT_CACERT=PATH_TO_VAULT_CA
./create-pki.sh
```