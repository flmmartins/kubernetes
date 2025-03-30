# Kubernetes

My Kubernetes Manifests and Releases. Each folder contains installation instructions.

## Pod Security Admission

Applications in this repo assume Pod Security Adminission as `baseline` enabled by default therefore settings are adjusted to it.

# Execution Order

1. storage
2. autoscaling (optional for hpa otw you need redeploy)
3. metallb
4. nginx
5. 1password_connect
6. vault

# Architecture

Below are some architecture ideas. Those marked with **Work In Progress** are not validated/implemented yet. 

**Not all code will be stored in this repo: read CI/CD below for more!**

## Network Load Balancer

     [ MetalLB: Assigns IP to Nginx ]
             |
             v
     [ Nginx: Reverse Proxy / Load Balancer ]


## DNS Resolution

**Work in Progress**

     [ External DNS: Populates Pihole]

      [ Users access a website in local network ] 
             |
             v
      [ Pi-hole: Local DNS Server, resolves the URL ]   
             |
             v
      [ Nginx: Reverse Proxy / Load Balancer ]

## Storage

      [ APP: Require storage]
            |
            v
      [ Storage Class with CSI NFS Driver ]

## Certificates 


    [ Application needs certificate ]
           |
           |
           v
    [ Cert Manager, using a self managed CA, generates certificate and rotates]


**Future:** Hashicorp Vault can be used together with Cert Manager

## Manage App Secrets

Secrets are staticaly defined. They are geenrated by Kubernetes OR manually while running releases.

**Future:** Make use of Hashicorp Vault

## Manage users and identity

**Work in Progress**

      [ User: Creates user in Keycloak]
                 |
                 |
                 v
      [ Keycloak: Identity provider ]
                 ^
                 |
                 |
     [ Applications: Read from keycloak ]


## CI/CD

 **Terraform** would be used to create components outside Kubernetes. You can also manage kubernetes applications with terraform but I am willing to give ArgoCD a chance.

 **ArgoCD** would create applications inside K8s

     [ CI/CD Pipeline trigger]   [Git Push]
       |                             |
       |                             |
       v                             v
     [CI/CD Runner]              [ArgoCD "runner"]
       |                             |
       |                             |
       |                             |
       v                             v
    [ Terraform ]                [Kubernetes]
       |
       |
       v
    [ Minio backend]