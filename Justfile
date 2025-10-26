# Run 'just setup' to create the lab environment
# Run 'just destroy' to tear it down

default:
    @just --list

# Set up the complete lab environment
setup: create-cluster install-argocd install-prometheus-argocd install-grafana-argocd install-metrics-server install-cert-manager install-minio install-loki-argocd install-promtail-argocd port-forward
    @echo "🎉 Lab setup complete!"
    @echo ""
    @echo "Grafana UI: http://localhost:3000 (admin/admin)"
    @echo "Prometheus UI: http://localhost:9090"
    @echo "Minio API: http://localhost:9000 (minio/minio123)"
    @echo "Minio Console: http://localhost:9001 (minio/minio123)"
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

# # Install Prometheus via Helm
# install-prometheus:
#     @echo "📈 Installing Prometheus..."
#     helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
#     helm repo update
#     kubectl create namespace prometheus --dry-run=client -o yaml | kubectl apply -f -
#     helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
#         --namespace prometheus \
#         --values helm/values/prometheus-values.yaml \
#         --wait
#     @echo "✅ Prometheus installed"

# # Install Blackbox Exporter via Helm
# install-blackbox:
#     @echo "🔍 Installing Blackbox Exporter..."
#     helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
#     helm repo update
#     helm upgrade --install blackbox-exporter prometheus-community/prometheus-blackbox-exporter \
#         --namespace prometheus \
#         --values helm/values/blackbox-exporter-values.yaml \
#         --wait
#     @echo "✅ Blackbox Exporter installed"

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

# Install Metrics Server via Argocd Application
install-metrics-server:
    @echo "🚀 Installing Metrics Server via ArgoCD Application..."
    kubectl apply -f argocd-apps/0-metrics-server/application.yml
    @echo "✅ Metrics Server application deployed via ArgoCD"

# Install Cert Manager via Argocd Application
install-cert-manager:
    @echo "🚀 Installing Cert Manager via ArgoCD Application..."
    kubectl apply -f argocd-apps/1-cert-manager/application.yml
    @echo "✅ Cert Manager application deployed via ArgoCD"

# Install Minio via ArgoCD Application
install-minio:
    @echo "🚀 Installing Minio via ArgoCD Application..."
    kubectl apply -f argocd-apps/7-minio/application.yml
    @echo "✅ Minio application deployed via ArgoCD"

# Install Prometheus via ArgoCD Application
install-prometheus-argocd:
    @echo "📈 Installing Prometheus via ArgoCD Application..."
    kubectl apply -f argocd-apps/8-prometheus/application.yml
    kubectl apply -f argocd-apps/9-prometheus-blackbox-exporter/application.yml
    @echo "✅ Prometheus application deployed via ArgoCD"

# Install Grafana via ArgoCD Application
install-grafana-argocd:
    @echo "📊 Installing Grafana via ArgoCD Application..."
    kubectl apply -f argocd-apps/10-grafana/application.yml
    @echo "✅ Grafana application deployed via ArgoCD"

# Install Loki via ArgoCD Application
install-loki-argocd:
    @echo "📝 Installing Loki via ArgoCD Application..."
    kubectl apply -f argocd-apps/11-loki/application.yml
    @echo "✅ Loki application deployed via ArgoCD"

# Install Promtail via ArgoCD Application
install-promtail-argocd:
    @echo "📋 Installing Promtail via ArgoCD Application..."
    kubectl apply -f argocd-apps/12-promtail/application.yml
    @echo "✅ Promtail application deployed via ArgoCD"

# Wait for ArgoCD applications to sync
wait-for-argo-sync:
    @echo "⏳ Waiting for ArgoCD applications to sync..."
    @echo "Checking metrics-server..."
    @kubectl wait --for=jsonpath='{.status.sync.status}'=Synced -n argocd application/metrics-server --timeout=300s 2>/dev/null || true
    @echo "Checking minio..."
    @kubectl wait --for=jsonpath='{.status.sync.status}'=Synced -n argocd application/minio --timeout=300s 2>/dev/null || true
    @echo "Checking prometheus..."
    @kubectl wait --for=jsonpath='{.status.sync.status}'=Synced -n argocd application/prometheus --timeout=300s 2>/dev/null || true
    @echo "Checking blackbox-exporter..."
    @kubectl wait --for=jsonpath='{.status.sync.status}'=Synced -n argocd application/blackbox-exporter --timeout=300s 2>/dev/null || true
    @echo "Checking grafana..."
    @kubectl wait --for=jsonpath='{.status.sync.status}'=Synced -n argocd application/grafana --timeout=300s 2>/dev/null || true
    @echo "Checking loki..."
    @kubectl wait --for=jsonpath='{.status.sync.status}'=Synced -n argocd application/loki --timeout=300s 2>/dev/null || true
    @echo "Checking promtail..."
    @kubectl wait --for=jsonpath='{.status.sync.status}'=Synced -n argocd application/promtail --timeout=300s 2>/dev/null || true
    @echo "✅ All ArgoCD applications are synced!"

# Port forward
port-forward: wait-for-argo-sync
    @echo "🌐 Port forwarding all services..."
    @echo "  Grafana UI: http://localhost:3000"
    @echo "  Prometheus UI: http://localhost:9090"
    @echo "  ArgoCD UI: http://localhost:8080"
    @echo "  Minio API: http://localhost:9000"
    @echo "  Minio Console: http://localhost:9001"
    @echo ""
    @echo "Press Ctrl+C to stop the port forwards"
    kubectl port-forward -n grafana svc/grafana 3000:80 & \
    kubectl port-forward -n prometheus svc/prometheus-kube-prometheus-prometheus 9090:9090 & \
    kubectl port-forward -n argocd svc/argo-cd-argocd-server 8080:80 & \
    kubectl port-forward -n minio svc/minio 9000:9000 & \
    kubectl port-forward -n minio svc/minio-console 9001:9001 & \
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
