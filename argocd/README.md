# Argo CD

## Install

```
helm repo add argo https://argoproj.github.io/argo-helm
```

```
helm install --version "~7.0.0" \
 --namespace argocd \
 --create-namespace \
 -f argo.yaml \
 argo-cd argo/argo-cd
```