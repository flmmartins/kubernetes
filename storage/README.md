# Storage

This creates storage for PVs

## NFS

```
helm repo add csi-driver-nfs https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts
helm install csi-driver-nfs csi-driver-nfs/csi-driver-nfs --namespace kube-system --version v4.9.0
```

Example of creating a storage class can be found in storage.yaml.

You can apply with command below:

```
sed -e 's|SERVER|<IP>|g; s|SHARE|<NFS_NAME>/|g' storage.yaml | kubectl apply -f -
```