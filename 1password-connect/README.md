# 1password connect server

Deploys a 1password connect server which targets a 1password vault The ideia is that Hashicorp vault will manage secrets in this 1password vault.

Follow [instructions](https://github.com/1Password/vault-plugin-secrets-onepassword?tab=readme-ov-file)

1password connect server will target a specific 1password vault and credentials for the server are saved in another vault.

```
helm repo add 1password https://1password.github.io/connect-helm-charts/
```

````
helm upgrade --install --version "~1.17.0" \
  --namespace 1password-connect \
  --create-namespace \
  --set-file connect.credentials=./1password-credentials.json \
  -f 1password-connect.yaml \
  1password-connect 1password/connect
```