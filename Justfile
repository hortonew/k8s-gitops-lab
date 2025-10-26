# Run 'just setup' to create the lab environment
# Run 'just destroy' to tear it down

default:
    @just --list

# Set up the complete lab environment
setup: create-cluster install-prometheus install-blackbox install-grafana install-argocd port-forward
    @echo "🎉 Lab setup complete!"
    @echo ""
    @echo "Grafana UI: http://localhost:3000 (admin/admin)"
    @echo "Prometheus UI: http://localhost:9090"
    @echo ""
    @echo "To access services:"
    @echo "  just port-forward"
    @echo ""

# Destroy the lab environment
destroy:
    @echo "🗑️  Destroying lab environment..."
    kind delete cluster --name gitops
    @echo "✅ Lab environment destroyed"

# Create Kind cluster
create-cluster:
    @echo "🚀 Creating Kind cluster..."
    kind create cluster --config kind_config.yml --name gitops
    @echo "✅ Cluster created"

# Install argocd
install-argocd:
    @echo "🚀 Installing ArgoCD..."
    helm repo add argo https://argoproj.github.io/argo-helm
    helm repo update
    helm upgrade --install argo-cd argo/argo-cd \
        --namespace argocd \
        --create-namespace \
        --values helm/values/argocd.yml \
        --wait
    kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Install Prometheus via Helm
install-prometheus:
    @echo "📈 Installing Prometheus..."
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update
    kubectl create namespace prometheus --dry-run=client -o yaml | kubectl apply -f -
    helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
        --namespace prometheus \
        --values helm/values/prometheus-values.yaml \
        --wait
    @echo "✅ Prometheus installed"

# Install Blackbox Exporter via Helm
install-blackbox:
    @echo "🔍 Installing Blackbox Exporter..."
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update
    helm upgrade --install blackbox-exporter prometheus-community/prometheus-blackbox-exporter \
        --namespace prometheus \
        --values helm/values/blackbox-exporter-values.yaml \
        --wait
    @echo "✅ Blackbox Exporter installed"

# Install Grafana via Helm
install-grafana:
    @echo "📊 Installing Grafana..."
    helm repo add grafana https://grafana.github.io/helm-charts
    helm repo update
    kubectl create namespace grafana --dry-run=client -o yaml | kubectl apply -f -
    helm upgrade --install grafana grafana/grafana \
        --namespace grafana \
        --values helm/values/grafana-values.yaml \
        --wait
    @echo "✅ Grafana installed"

# Port forward
port-forward:
    @echo "🌐 Port forwarding all services..."
    @echo "  Grafana UI: http://localhost:3000"
    @echo "  Prometheus UI: http://localhost:9090"
    @echo "  ArgoCD UI: http://localhost:8080"
    @echo ""
    @echo "Press Ctrl+C to stop the port forwards"
    kubectl port-forward -n grafana svc/grafana 3000:80 & \
    kubectl port-forward -n prometheus svc/prometheus-kube-prometheus-prometheus 9090:9090 & \
    kubectl port-forward -n argocd svc/argo-cd-argocd-server 8080:80 & \
    wait

# Get argocd admin password
get-argocd-password:
    @echo "ArgoCD admin password:"
    @kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode; echo

# Get Grafana admin password
get-grafana-password:
    @echo "Grafana admin password:"
    @kubectl get secret --namespace grafana grafana -o jsonpath="{.data.admin-password}" | base64 --decode; echo

# Show cluster info
cluster-info:
    @echo "📋 Cluster Information:"
    kubectl cluster-info
    @echo ""
    @echo "Nodes:"
    kubectl get nodes
    @echo ""
    @echo "Namespaces:"
    kubectl get namespaces
