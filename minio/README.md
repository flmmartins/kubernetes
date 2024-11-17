# Minio

This install minio S3. The installation is minimal as possible and Minio will be used to house Terraform States and other objects.

## Storage

This assume a pre-existent storage class configured for your cluster. Check storage folder for more.


## Install Minio

```
helm repo add minio https://charts.min.io/
```

```
helm upgrade --install --version "~5.3.0" \
  --namespace minio \
  --create-namespace \
  --set rootPassword="SECRET" \
  -f minio.yaml minio minio/minio
```

## Pod Security Adminission
Changing Security Context for minio without Minio Operator is not possible therefore we relax it's permission on namespace

````
kubectl label namespace minio pod-security.kubernetes.io/enforce=privileged
```
