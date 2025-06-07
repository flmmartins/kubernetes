#!/bin/bash

VAULT_K8S_NAMESPACE="vault"
VAULT_SERVICE_NAME="vault-internal"
VAULT_SECRET_INJECTOR="vault.svc"
K8S_CLUSTER_NAME="cluster.local"
WORKDIR="vault_tls_cert"

mkdir -p "$WORKDIR"

# Generate key
openssl genrsa -out "${WORKDIR}"/vault.key 2048

#Define config
cat > "${WORKDIR}"/vault-csr.conf <<EOF
[req]
default_bits = 2048
prompt = no
encrypt_key = yes
default_md = sha256
distinguished_name = kubelet_serving
req_extensions = v3_req
[ kubelet_serving ]
O = system:nodes
CN = system:node:*.${VAULT_K8S_NAMESPACE}.svc.${K8S_CLUSTER_NAME}
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names
[alt_names]
DNS.1 = *.${VAULT_SERVICE_NAME}
DNS.2 = *.${VAULT_SERVICE_NAME}.${VAULT_K8S_NAMESPACE}.svc.${K8S_CLUSTER_NAME}
DNS.3 = *.${VAULT_K8S_NAMESPACE}
DNS.4 = *.${VAULT_SECRET_INJECTOR}
IP.1 = 127.0.0.1
EOF

# Generate CSR
openssl req -new -key "${WORKDIR}"/vault.key -out "${WORKDIR}"/vault.csr -config "${WORKDIR}"/vault-csr.conf

# Create in K8s
cat > ${WORKDIR}/csr.yaml <<EOF
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: vault.svc
spec:
  signerName: kubernetes.io/kubelet-serving
  expirationSeconds: 8640000
  request: $(cat ${WORKDIR}/vault.csr|base64|tr -d '\n')
  usages:
  - digital signature
  - key encipherment
  - server auth
EOF

kubectl create -f ${WORKDIR}/csr.yaml

# Sign with kubernetes
kubectl certificate approve vault.svc

#Wait a bit bc takes a little bit to approve
sleep 10

# Get signed certificate
kubectl get csr vault.svc -o jsonpath='{.status.certificate}' | openssl base64 -d -A -out ${WORKDIR}/vault.crt

# Get kubernetes CA
kubectl config view \
--raw \
--minify \
--flatten \
-o jsonpath='{.clusters[].cluster.certificate-authority-data}' \
| base64 -d > ${WORKDIR}/vault.ca

# Create Vault Namespace
kubectl create namespace $VAULT_K8S_NAMESPACE

# Relax Pod Security Admission due to CSI secret provider vault needing host path
kubectl label ns vault pod-security.kubernetes.io/enforce=privileged \
  --overwrite

kubectl create secret generic vault-ha-tls \
  -n $VAULT_K8S_NAMESPACE \
  --from-file=vault.key=${WORKDIR}/vault.key \
  --from-file=vault.crt=${WORKDIR}/vault.crt \
  --from-file=vault.ca=${WORKDIR}/vault.ca