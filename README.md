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

# Set up metrics server
kubectl apply -f argocd-apps/0-metrics-server/application.yml

# Set up cert manager
kubectl apply -f argocd-apps/1-cert-manager/application.yml

# Optional: Set up prometheus
kubectl apply -f argocd-apps/8-prometheus/application.yml
kubectl apply -f argocd-apps/9-prometheus-blackbox-exporter/application.yml

# Optional: Set up grafana
kubectl apply -f argocd-apps/10-grafana/application.yml
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

# Or manually:
kubectl port-forward -n argocd svc/argo-cd-argocd-server 8080:80
kubectl port-forward -n grafana svc/grafana 3000:80
kubectl port-forward -n prometheus svc/prometheus-kube-prometheus-prometheus 9090:9090
# ...
```

## Teardown

```sh
just destroy

# or
kind delete cluster --name gitops
```
