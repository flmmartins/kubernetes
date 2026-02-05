### How to created NFS

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