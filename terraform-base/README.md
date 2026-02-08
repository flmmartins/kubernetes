# Terraform Init

## Prod

Currently configure in state.tf You need to configure AWS_S3_ENDPOINT, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY as env vars


```
cd terraform-base
../tfinit.sh prod
```


### Starting from scratch
If minio is not set, you might want to run terraform locally

```
terraform init \
  -backend-config="path=terraform.tfstate"
```


## Local


```
cd terraform-base
../tfinit.sh local
```


# Terraform Plan/Apply

`terraform plan/apply`

It will automatically get the terraform.tfvars file which is not commited in the repo