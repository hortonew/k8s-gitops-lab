# K8s gitops lab

An environment to play around with different gitops tools.

## Setup

```sh
just setup
```


### Or if you want to run each command manually
```sh
# Create Kind cluster
kind create cluster --config kind_config.yml --name gitops

# Setup ArgoCD
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm upgrade --install argo-cd argo/argo-cd \
    --namespace argocd \
    --create-namespace \
    --values helm/values/argocd.yml \
    --wait

# get admin secret
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Set up prometheus
kubectl apply -f argocd-apps/8-prometheus/application.yml
kubectl apply -f argocd-apps/9-prometheus-blackbox-exporter/application.yml

# Set up grafana
kubectl apply -f argocd-apps/10-grafana/application.yml

# Set up metrics server
kubectl apply -f argocd-apps/0-metrics-server/application.yml

# Set up cert manager
kubectl apply -f argocd-apps/1-cert-manager/application.yml

# see Justfile setup command for more commands ran automatically
```

## Port Forward

Note: Setup does this automatically now and waits for services to be ready.

```sh
just port-forward
# navigate to applications: 
#   Grafana UI: http://localhost:3000
#   Prometheus UI: http://localhost:9090
#   ArgoCD UI: http://localhost:8080
#   Minio API: http://localhost:9000
#   Minio Console: http://localhost:9001
```

## Teardown

```sh
just destroy
```

## Kind

```sh
kind create cluster --name gitops --config kind_config.yml
```

## ArgoCD

![ArgoCD Applications](images/argocd-applications.png)

```sh
# Install
helm upgrade --install argo-cd bitnami/argo-cd --create-namespace -n argocd -f helm/values/argocd.yml
k get secrets argocd-secret -n argocd -o yaml | grep clearPassword | awk '{print $2}' | base64 -d

# GUI
k port-forward svc/argo-cd-server -n argocd 8081:80
```

![RabbitMQ Queues](images/rabbitmq-queues.png)

### Metallb

Start to build out ingress controllers (nginx/traefik), but first we need some IPs.

```sh
k apply -f argocd-apps/5-metallb/
```

### Traefik Ingress

```sh
k apply -f argocd-apps/6-ingress-controller-traefik/
```

### Nginx Ingress

```sh
k apply -f argocd-apps/6-ingress-controller-nginx
```
