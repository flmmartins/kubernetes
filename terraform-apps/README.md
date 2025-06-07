# Terraform

## Local Init

If minio is not set, you might want to run terraform locally

```
terraform init \
  -backend-config="path=terraform.tfstate"
```

# Plan/Apply

`terraform plan/apply`

It will automatically get the terraform.tfvars file which is not commited in the repo