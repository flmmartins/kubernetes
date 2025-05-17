# Nginx

Nginx is a high-performance, open-source web server and reverse proxy server. It is widely used for serving static content, managing load balancing, handling HTTP requests, and acting as a reverse proxy for APIs or backend services.

Once NGINX is create it will request an IP from MetalLB.

## Instal

```
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
```

Create IP Pool:

```
sed -e 's|CIDR|<IP>|g' nginx-ip.yaml | kubectl apply -f -
```

Install NGINX:
```
helm upgrade --install --version "~4.12.1" \
  --namespace nginx \
  --create-namespace \
  -f nginx.yaml \
  nginx ingress-nginx/ingress-nginx
```
