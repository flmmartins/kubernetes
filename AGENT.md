# Project Context

## Cluster
- Talos Linux v1.12.2, Kubernetes v1.35.0

## Infrastructure
- All infra managed with Terraform

## Conventions
- Always use helm releases to install existing charts. If chart doesn't exist use kubernetes resources
- Terraform Modules follow standard module structure
- Terraform Modules always have variables with descriptions. It has examples with instructions on how to use inside the description attribute if variable has no default value. If description is multine line, use heredoc sintax with <<--EOT description EOT
- Prefer to use helm releases instead of kubernetes resources in terraform
- Helm releases always have a variable with chart version
- Helm releases or deployments always have resource variables and those should have the minimal values necessary
- Helm releases always use values with EOF sintax
- Helm relases or deployments always have part-of label and per component label
- Helm relases or deployments always have affinity based on component label
- If vault_password is not null, always use CSI Secret Provider Class else provide create a random secret in kubernetes
- Always create persistent volumes if data should survive pod restarts
- When creating a persistent volume always set security context
- When creating a persistent volume always use minimal data disk
- If you need to create a CRD prefer to use helm release extraObjects or extraManifests over kubernetes_manifests resources
- Helm releases or deployments always create a Gateway API HTTP Route and they receive the variable gateway