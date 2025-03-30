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
 argo argo/argo-cd
```

kubectl port-forward service/argo-argocd-server -n argocd 8080:443

http://localhost:8080
User is `admin`