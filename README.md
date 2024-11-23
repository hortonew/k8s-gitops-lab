# K8s gitops lab

An environment to play around with different gitops tools.

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
# curl -kLs -o apps/0-rabbitmq-operators/k8s/rabbitmq-cluster-operator.yml https://github.com/rabbitmq/cluster-operator/releases/latest/download/cluster-operator.yml  
# curl -kLs -o  apps/0-rabbitmq-operators/k8s/rabbitmq-messaging-topology-operator.yml https://github.com/rabbitmq/messaging-topology-operator/releases/latest/download/messaging-topology-operator-with-certmanager.yaml

# push these changes up if there are any, then run:
k apply -f argocd-apps/2-rabbitmq-operators/
```

## Apps

### RabbitMQ Cluster

```sh
k apply -f argocd-apps/3-rabbitmq-cluster/
```

### RabbitMQ Rust App

App to make use of queues in rabbitmq.

TODO: Should also build a rust app that makes use of these queues, and push to Dockerhub.

```sh
k apply -f argocd-apps/4-rabbitmq-rust-app/
```

![RabbitMQ Queues](images/rabbitmq-queues.png)