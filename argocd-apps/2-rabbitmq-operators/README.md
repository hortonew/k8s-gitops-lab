# RabbitMQ app on k8s

# Manual
```sh
kubectl apply -f https://github.com/rabbitmq/cluster-operator/releases/latest/download/cluster-operator.yml
# requires cert-manager
kubectl apply -f https://github.com/rabbitmq/messaging-topology-operator/releases/latest/download/messaging-topology-operator-with-certmanager.yaml

kubectl port-forward -n rabbitmq service/rabbitmq 15672:15672
```

# With ArgoCD

```sh
k apply -f argocd-apps/2-rabbitmq-operators/
```
