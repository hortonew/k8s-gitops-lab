# K8s gitops lab

An environment to play around with different gitops tools.

## Kind

```sh
kind create cluster --name gitops --config kind_config.yml
```

## ArgoCD

```sh
# Set up configuration
mkdir -p helm/values
helm show values bitnami/argo-cd --version 7.0.20 > helm/values/defaults-argocd.yml

# Install
helm upgrade --install argo-cd bitnami/argo-cd --create-namespace -n argocd -f helm/values/argocd.yml
k get secrets argocd-secret -n argocd -o yaml | grep clearPassword | awk '{print $2}' | base64 -d

# GUI
k port-forward svc/argo-cd-server -n argocd 8081:80
```

### Metrics Server

```sh
k apply -f argocd-apps/0-metrics-server/
```

### Cert Manager

```sh
k apply -f argocd-apps/1-cert-manager/
```

### RabbitMQ Operators

```sh
k apply -f argocd-apps/2-rabbitmq-operators/
```

## Apps

TBD