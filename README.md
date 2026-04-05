# How to run

Execution is done via terraform:
1. Terraform Base - Install infrastructure components
2. Terraform Apps - Install Apps

This differentiation is necessary because there're several dependencies between infrastructure and apps. Additionaly almost all apps require a Vault ID which can only be fetched after Vault is configured.

**Migrating to Terraform Stacks**
Hopefully the problems above can be resolved in the future with Terraform Stacks. This repository is slowly migrating to conform to the terraform stack organization so you will see some code as modules and things might be a messy while is being migrated!!

## Terraform init

tfinit.sh was created to allow handling of multiple states from different backends. Terraform Stacks hopefully will be used in the future to handle this better than using a script!

Currently there are 2 environments: 
* dev => Which is a kind cluster, using a local terraform state
* prd => Which is a full cluster with several machines using a remote s3 terraform state

## With S3 backend (prod)

You need to configure AWS_S3_ENDPOINT, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY as env vars


```
cd terraform-apps OR terraform-base
../tfinit.sh prod
```

## With Local state (dev)

```
cd terraform-apps OR terraform-base
../tfinit.sh local
```

# Secret Management

Currently due to my integration with 1password I created a file with 1p references and I ran terraform as follows:

Example of .env.prd:

TF_VAR_my_ip=op://MY_VAULT/SECRET_NAME/FIELD

1password fetch this passwords based on references above and inject while running terraform with:

```
op run --env-file=envs/.env.prd --no-masking -- terraform COMMAND
```

Where COMMAND can be plan, apply....

Teoretically since now my secrets are not text-clear I could commit to git but better not provide any information on my Vault Name to the outside

**Old way of running**

Before having integration with 1password I did like this:

`terraform plan/apply`

It will automatically get the terraform.tfvars file which is was not commited in the repo.


# Archiecture & Components

Ideas and project track can be found [here](https://github.com/users/flmmartins/projects/3)

**Pod Security Admissions**
Applications in this repo assume Pod Security Adminission as `baseline` enabled by default therefore settings are adjusted to it

# Table of Contents
[Run Local](#RunningLocal)
[Terraform Base](#TerraformBase)
1. [Storage & NFS](##Storage)
2. [Autoscaling](##NFS)
3. [Auto Scaling](##AutoScaling)
4. [Load Balancer](##LoadBalancer)
5. [Secret Management](##SecretManagement)
6. [Certificates](#Certificates)
7. [Apps](#Apps)

# Running Local

## Create a kubernetes cluster

If you want to run this localy on laptop do:
```
kind create cluster
```

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

### SeaweedFS

Minio was deprecated and is now in maintenance mode. Seaweedfs is the replacement

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
Ideally you want one set of certificates for internal TLS of vault and another set for external facing certificate however since I only have one set is all done with the same certificate

# Backups

We use Velero for Backups. It authenticates with an objet store to create the necessary assets using environment variables

# Terraform Apps

## DNS Resolution

      [ Users access a website in local network ] 
             |
             v
      [ Ad-Guard: Local DNS Server, resolves the URL - outside kubernetes ]   
             |
             v
      [ Nginx: Reverse Proxy / Load Balancer ]

Ad Guard has DNS masq so it will resolve all DNS to reverse proxy IP. However in a setup without DNS Masq you can install External DNS to automatically add each record to each IP.

## Plex

Check [Plex](Plex.md)