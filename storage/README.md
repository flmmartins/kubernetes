# Storage

This creates storage for PVs

## NFS

### How NFS is created

When I created the NFS I set a user and group to it. When creating a volume permissions are as follows:

```
drwxrwsr-x nfs_user nfs_group
```

However by using csi-driver-nfs you can do dynamic subdirectory permissions therefore each application will have it's own volume with proper permissions and security isolation

```
helm repo add csi-driver-nfs https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts

helm upgrade --install --version "~v4.9.0" \
    --namespace kube-system \
    -f csi-driver-nfs.yaml \
    csi-driver-nfs csi-driver-nfs/csi-driver-nfs
```

Example of creating a storage class can be found in storage.yaml.

You can apply with command below:

```
sed -e 's|SERVER|<IP>|g; s|SHARE|<NFS_NAME>/|g' storage.yaml | kubectl apply -f -
```

### How to assign permission to subdirectories

Create a user for the application and make it part of the group allowed to the NFS.

In the pod do:

```
securityContext:
  runAsUser: app_user
  runAsGroup: app_group
  fsGroup: nfs_group
  fsGroupChangePolicy: "OnRootMismatch"
``

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