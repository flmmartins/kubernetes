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

When I created the NFS I set a user and group to it. When creating a volume permissions are as follows:

```
drwxrwsr-x nfs_user nfs_group
```

However by using csi-driver-nfs you can do dynamic subdirectory permissions therefore each application will have it's own volume with proper permissions and security isolation

### How to assign permission to subdirectories

Create a user for the application and make it part of the group allowed to the NFS.

In the pod do:

```
securityContext:
  runAsUser: app_user
  runAsGroup: app_group
  fsGroup: nfs_group
  fsGroupChangePolicy: "OnRootMismatch"
```

The `fsGroupChangePolicy` is necessary bc that changes the permissions to the ones defined by `fsGroup` before volume is mounted.

Now you can see the permissions of the volume again:

```
drwxrwxr-x nfs_user nfs_group
```

If you enter a subdirectory of the volume the created files will have the rwx permissions according to the application behaviour. However ownership will be fully by application

Example:

```
-rw------- 1 app_user nfs_group db
```

Even if another application tries to use the volume it will not have permissions

Since the rwx permissions are determine by the application you might run into a case where you have:

```
-rw-r----- 1 app_user nfs_group db
```

This would allow everyone on the nfs_group to read such directories. Initially I tried setting `fsGroup` to app_group however due to NFS csi driver it always want to change files permissions inside the volume independent of `fsGroupChangePolicy` since files didn't had the nfs_group set it showed the following error: `applyFSGroup failed permission denied`

I opened an [issue](https://github.com/kubernetes-csi/csi-driver-nfs/issues/894) to understand more about it


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
