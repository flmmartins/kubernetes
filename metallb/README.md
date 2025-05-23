# Metal LB

MetalLB is an open-source load-balancer implementation for Kubernetes clusters running on bare-metal environments. Unlike cloud platforms that provide native load balancers, MetalLB enables Kubernetes services to expose public-facing IP addresses by integrating with existing network infrastructure. It supports key protocols like Layer 2 and BGP (Border Gateway Protocol) to manage traffic efficiently, making it ideal for environments without cloud-native load-balancing solutions.


[MetalLB](https://github.com/kubernetes/ingress-nginx/blob/main/docs/deploy/baremetal.md) requires a pool of IP addresses in order to be able to take ownership of the ingress-nginx Service. This pool can be defined through IPAddressPool objects in the same namespace as the MetalLB controller. This pool of IPs must be dedicated to MetalLB's use, you can't reuse the Kubernetes node IPs or IPs handed out by a DHCP server.

## Install

```
helm repo add metallb https://metallb.github.io/metallb
```

```
helm upgrade --install --version "~0.14.9" \
  --namespace metallb \
  --create-namespace \
  -f metallb.yaml \
  metallb metallb/metallb
```

If pod security is enabled:

```
kubectl label namespace metallb pod-security.kubernetes.io/enforce=privileged pod-security.kubernetes.io/audit=privileged pod-security.kubernetes.io/warn=privileged
```

## IP Configuration
IP pool and advertisement can only be created on metallb namespace
It's always necessary to create both and an advertisement points to a pool

IP configuration can be applied with:

```
sed -e 's|CIDR|<IP>|g' nginx-ip.yaml | kubectl apply -f -
```

CIDR can be a range or a single IP with /32.