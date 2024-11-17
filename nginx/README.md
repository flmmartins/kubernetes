# Nginx

## Instal

```
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
```

```
helm upgrade --install --version "~4.11.3" \
  --namespace nginx \
  --create-namespace \
  -f nginx.yaml \
  nginx ingress-nginx/ingress-nginx
```
