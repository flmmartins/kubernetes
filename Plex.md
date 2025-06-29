This is readme about how to install plex in different ways, what worked and what did not

Requirements:
* We need Plex to manage it's own config volume created dinamically by CSI
* Read-only mode for data volume and run with specific user

Looks simple but sadly, it's not.

# Plex Helm Chart

Plex official Helm chart does not have support for SecurityContext on pod level therefore you only have the following options available

```
securityContext:
  allowPrivilegeEscalation: false
  runAsGroup: xxx
  runAsUser: xxx
extraEnv:
  ALLOWED_NETWORKS: 0.0.0.0/0
  HOSTNAME: TalosPlexServer
  PLEX_GID: "xxx"
  PLEX_UID: "xxx"
```

If you set this to force the UID/GID you want, will get errors saying: `fatal: unable to mkdir /var/run/s6: Permission denied` and even if you are able to change this with initContainer you will eventually got `usr/bin/s6-setuidgid: Permission denied`. So this bloody container needs root to run with so we remove the `allowPrivilegeEscalation: false`


```
extraEnv:
  ALLOWED_NETWORKS: 0.0.0.0/0
  HOSTNAME: TalosPlexServer
  PLEX_GID: "xxx"
  PLEX_UID: "xxx"
```

So how can you adapt to it running as root?

## Config Volume

On the config, I could set fsGroup and fsChangePolicy BUT helm chart does not support it. It will become root and set ownership of all files to 700 and a strange UID 1000. This is not the UID of root. 

So I decided to force the user:

```
securityContext:
  runAsGroup: xxx
  runAsUser: xxx
extraEnv:
  ALLOWED_NETWORKS: 0.0.0.0/0
  HOSTNAME: TalosPlexServer
  PLEX_GID: "xxx"
  PLEX_UID: "xxx"
```

That was not enough, Plex was becoming root and messing everything up so I set a env variable CHANGE_CONFIG_DIR_OWNERSHIP to the container.

```
securityContext:
  runAsGroup: xxx
  runAsUser: xxx
extraEnv:
  ALLOWED_NETWORKS: 0.0.0.0/0
  HOSTNAME: TalosPlexServer
  PLEX_GID: "xxx"
  PLEX_UID: "xxx"
  CHANGE_CONFIG_DIR_OWNERSHIP: "false"
```

Now it's fine right? Nope. On first boot it cannot read the config so I had to manually change it. A better approach would have been: Make CSI Driver to do this with a special storage class with mount options to map user/group on NFS that suits plex but I decided to change manually. It's only on first boot.

After plex restarts it wants to run the s6-setuidgid and suddenly it broke everything so I did:

```
extraEnv:
  ALLOWED_NETWORKS: 0.0.0.0/0
  HOSTNAME: TalosPlexServer
  PLEX_GID: "xxx"
  PLEX_UID: "xxx"
  CHANGE_CONFIG_DIR_OWNERSHIP: "false"
```

I realized that when allowing plex to become root the PLEX_GID and UID does not matter anymore so I removed.

```
extraEnv:
  ALLOWED_NETWORKS: 0.0.0.0/0
  HOSTNAME: TalosPlexServer
  CHANGE_CONFIG_DIR_OWNERSHIP: "false"
```

Since plex is doing everything it wants anyway I remove the remaining end variable and ended up creating a plex user with UID 1000 that way I don't have so many issues with this config directory

**Plex Claim**
After everything is resolved don't forget to solve plex claim env variable on first boot as well! Once it works, you can remove from helm chart.

## Data Volume

**Using No Security Context**
NFS for data volume has a specific maproot user/group for user plex that is used by plex but I was still having problems

Later I realize that plex already had a /media path and these were conflicting with my volume which was called /media so I decided to break plex in several volumes each with a specific NFS.