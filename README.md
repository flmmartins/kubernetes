# Kubernetes

My Kubernetes Manifests and Releases.  Each folder contains installation instructions.

Those applications  are suppose to be installed in my homelab which is on prem and contain configuration for it

Maybe in the future the installation can be automated but that requires a Continuous Delivery server which will be installed on this cluster. Therefore we have a chicken and egg situation eg minio will be used by Terraform and ArgoCD for automation of helm releases.

## Pod Security Admission

Applications in this repo assume Pod Security Adminission as `baseline` enabled by default therefore settings are adjusted to it.
