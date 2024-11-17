# Metal LB

[MetalLB](https://github.com/kubernetes/ingress-nginx/blob/main/docs/deploy/baremetal.md) provides Load Balancer for Bare Metal.

MetalLB requires a pool of IP addresses in order to be able to take ownership of the ingress-nginx Service. This pool can be defined through IPAddressPool objects in the same namespace as the MetalLB controller. This pool of IPs must be dedicated to MetalLB's use, you can't reuse the Kubernetes node IPs or IPs handed out by a DHCP server.

## Install

```
helm repo add metallb https://metallb.github.io/metallb
```

```
helm upgrade --install --version "~0.14.8" \
  --namespace metallb \
  --create-namespace \
  -f metallb.yaml \
  metallb metallb/metallb
```

IP configuration can be applied with:

```
sed -e 's|CIDR|<IP>|g' ip_advertisement.yaml | kubectl apply -f -
```

CIDR can be a range or a single IP with /32.

## Pod Security Admission
If pod security is enabled:

````
kubectl label namespace metallb pod-security.kubernetes.io/enforce=privileged
```