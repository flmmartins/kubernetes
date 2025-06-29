Here you will see a description of components

Ideas and project track can be found [here](https://github.com/users/flmmartins/projects/3)

Execution is done via terraform:
1. Terraform Base - Install infrastructure components
2. Terraform Apps - Install Apps

This differentiation is necessary because there're several dependencies between infrastructure and apps. Additionaly almost all apps require a Vault ID which can only be fetched after Vault is configured. Since this Vault ID comes from 1password plugin, there's no terraform resource for it and wanted to keep it a secret.

**Pod Security Admissions**
Applications in this repo assume Pod Security Adminission as `baseline` enabled by default therefore settings are adjusted to it

# Table of Contents

[Terraform Base](#TerraformBase)
1. [Storage & NFS](##Storage)
2. [Autoscaling](##NFS)
3. [Auto Scaling](##AutoScaling)
4. [Load Balancer](##LoadBalancer)
5. [Secret Management](##SecretManagement)
6. [Certificates](#Certificates)
7. [Apps](#Apps)

# Terraform Base
Contains the Base Infrastructure

Execution Order:
1. Storage
2. Autoscaling (optional for hpa otw you need redeploy)
3. Metallb
4. Nginx
5. 1password_connect
6. CSI Secret Store
7. Hashicorp Vault
8. Cert-Manager

## Storage

      [ APP: Require storage]
            |
            v
      [ Storage Class with CSI NFS Driver ]

This creates storage for PVs

### How NFS is created

When I created the NFS I set a user and group to it. I restricted access to K8s machines.

When creating a NFS permissions are as follows:

```
drwx---- root wheel
```

In the NFS I had also to configure maproot_user to root and maproot_group to wheel, this is called `no_root_squash` permissions are absolutely necessary for CSI NFS be able to do fsGroupChangePolicy and allow CSI to delete from NFS

I wanted to strict permissions per application on NFS as much as possible. So I tried to play only by assigning app_user to nfs_group and then don't use fsGroup or fsGroupChangePolicy. Vault needs to stat the root directory so I added 711 but that didn't work and if I did more permissions would breach security. So there's no running from fsGroup and fsGroupChangePolicy. 

If you set an fsGroup, fsGroupChangePolicy will run and set that as the group.

### How to assign permission to subdirectories

In the pod do:

```
securityContext:
  runAsUser: app_user
  runAsGroup: app_group
  fsGroup: app_group
  fsGroupChangePolicy: "OnRootMismatch"
```

### Minio

I made a branch called minio with Bitnami Helm Chart which has much more features however when I installed it didn't had UI to create api keys, no bucket versioning. So I stick with the version I currently have which is an older release but with more decent.

## AutoScaling
Metric server is installing to enable HPA

## LoadBalancer

     [ MetalLB: Assigns IP to Nginx ]
             |
             v
     [ Nginx: Reverse Proxy / Load Balancer ]

### Metal LB

MetalLB is an open-source load-balancer implementation for Kubernetes clusters running on bare-metal environments. Unlike cloud platforms that provide native load balancers, MetalLB enables Kubernetes services to expose public-facing IP addresses by integrating with existing network infrastructure. It supports key protocols like Layer 2 and BGP (Border Gateway Protocol) to manage traffic efficiently, making it ideal for environments without cloud-native load-balancing solutions.


[MetalLB](https://github.com/kubernetes/ingress-nginx/blob/main/docs/deploy/baremetal.md) requires a pool of IP addresses in order to be able to take ownership of the ingress-nginx Service. This pool can be defined through IPAddressPool objects in the same namespace as the MetalLB controller. This pool of IPs must be dedicated to MetalLB's use, you can't reuse the Kubernetes node IPs or IPs handed out by a DHCP server.

#### IP Configuration
IP pool and advertisement can only be created on metallb namespace
It's always necessary to create both and an  advertisement points to a pool

## Secret Management

                 [ Hashicorp Vault: reads from 1password ]
                                 |
                                 v
                 [ 1password Connect: 1password component] 
                             |                 |          
                             v                 v
                [CSI Secret Store ]           [Vault Agent]


Vault Agent: Injects secrets into pods using environment variables or file. Sadly it doesn't create Kubernetes Secretes.

CSI Secret Store & Vault Provider: Creates Kubernetes Secret from Secret

Since Vault installation is by far the most complex component a separate README was created for [Vault](Vault.md)

## Certificates 
    [ Vault has a PKI with a imported CA]

    [ Application needs certificate ]
           |
           |
           v
    [ Creates an ingress ]
           |
           |
           v
    [ Cert Manager detects ingress and issue a certificate]
           |
           |
           v
    [ Cert Manager uses Hashicorp Vault to sign the certificate and manages rotation]

### Internal Vs External Certificates
Ideally you want one set of certificates for internal TLS of vault or minio and another set for external facing certificate however since I only have one set is all done with the same certificate

# Terraform Apps

## DNS Resolution

      [ Users access a website in local network ] 
             |
             v
      [ Pi-hole: Local DNS Server, resolves the URL ]   
             |
             v
      [ Nginx: Reverse Proxy / Load Balancer ]

Pihole has DNS masq so it will resolve all DNS to nginx IP. However in a setup without DNS Masq you can install External DNS to automatically add each record to each IP.

### How to configure pihole.conf
You can use FTL variables and convert them to environment variables as described in [here](https://docs.pi-hole.net/docker/configuration/?h=environment+variables#environment-variables)

## Plex

Check Plex.md