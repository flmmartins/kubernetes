# Pihole DNS

Pihole can act as a local DNS

## Access the UI

http://IP/admin/login

### Without IP

kubectl -n pihole port-forward service/pihole-web 8080:80

http://localhost:8080/admin

## Install

Sadly the Helm Chart is not official but since it seems to have lot of contributors and releases since 2019 I decided to give it a try

```
helm repo add mojo2600 https://mojo2600.github.io/pihole-kubernetes/

kubectl create ns pihole

sed -e 's|CIDR|<IP>/32|g' dns-ip-address.yaml | kubectl apply -f -
```

```
helm upgrade --install --version "~2.31.0" \
  --namespace pihole \
  -f pihole.yaml \
  pihole mojo2600/pihole
```

### How to configure pihole.conf
You can use FTL variables and convert them to environment variables as described in [here](https://docs.pi-hole.net/docker/configuration/?h=environment+variables#environment-variables)

### Fetch Admin Secret from Hashicorp Vault

**Create Vault Policy & Role**
```
vault policy write pihole - <<EOF
path "op/vaults/+/items/pihole" {
   capabilities = ["read"]
}
EOF
```

PiHole Helm doesn't support create a serviceAccount so we use default:

```
vault write auth/kubernetes/role/pihole \
      bound_service_account_names=default \
      bound_service_account_namespaces=pihole \
      policies=pihole \
      ttl=24h
```

### Configure Secret Provider Class
It was not possible to use vault injector because this helm chart only accepts secrets comming from a K8s secret. Passing it using WEBPASSWORD environment variable doesn't work because it always gets overwritten by helm chart defaults. Therefore the only way to make this work is with CSI Driver in Vault.

```
sed -e 's|VAULT_ID|<VAULT_ID_FROM_VAULT>/32|g' secret-provider-class.yaml.yaml | kubectl apply -f -
```

### Storage

Persistent volume was not created for pihole because all config can be defined in helm chart. Also there was some weird errors when enabling persistent volume maybe because 2 pods were hitting the same volume
