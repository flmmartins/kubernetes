# Enable HPA

Install metric server

```
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
```

```
helm upgrade --install --version "~3.12.2" \
  --namespace metrics-server \
  --create-namespace \
  metrics-server metrics-server/metrics-server
```