# K8s GitOps Lab Architecture

Note: Arrows are in the direction of data flow or management.

## 1. GitOps Management (ArgoCD)

```mermaid
graph TB
    ArgoCD[ArgoCD<br/>GitOps Controller<br/>Port 8080]
    
    MetricsServer[Metrics Server]
    Minio[Minio<br/>S3 Storage]
    Prometheus[Prometheus Stack]
    Blackbox[Blackbox Exporter]
    Grafana[Grafana]
    Loki[Loki]
    Promtail[Promtail]
    
    ArgoCD -->|Manages| MetricsServer
    ArgoCD -->|Manages| Minio
    ArgoCD -->|Manages| Prometheus
    ArgoCD -->|Manages| Blackbox
    ArgoCD -->|Manages| Grafana
    ArgoCD -->|Manages| Loki
    ArgoCD -->|Manages| Promtail
    
    classDef gitops fill:#e8f5e9,stroke:#1b5e20,stroke-width:2px
    class ArgoCD gitops
```

## 2. Metrics Monitoring (Prometheus & Grafana)

```mermaid
graph TB
    subgraph "Data Sources"
        Nodes[Kubernetes Nodes]
        Pods[Kubernetes Pods]
        Services[Services]
    end
    
    subgraph "Exporters"
        NodeExporter[Node Exporter<br/>DaemonSet]
        KubeStateMetrics[Kube State Metrics]
        MetricsServer[Metrics Server]
        Blackbox[Blackbox Exporter<br/>Probes]
    end
    
    Prometheus[Prometheus<br/>Metrics Storage<br/>Port 9090]
    Grafana[Grafana<br/>Visualization<br/>Port 3000]
    
    Nodes -->|CPU, Memory, Disk| NodeExporter
    Pods -->|Pod Status| KubeStateMetrics
    Nodes -->|Resource Metrics| MetricsServer
    Services -->|HTTP Checks| Blackbox
    
    NodeExporter -->|Scrape| Prometheus
    KubeStateMetrics -->|Scrape| Prometheus
    MetricsServer -->|Scrape| Prometheus
    Blackbox -->|Scrape| Prometheus
    
    Prometheus -->|Query| Grafana
    
    classDef monitoring fill:#e1f5ff,stroke:#01579b,stroke-width:2px
    class Prometheus,Grafana,NodeExporter,KubeStateMetrics,MetricsServer,Blackbox monitoring
```

## 3. Logs Monitoring (Loki, Promtail & Grafana)

```mermaid
graph TB
    subgraph "Log Sources"
        Pods[All Pods<br/>Container Logs]
    end
    
    Promtail[Promtail<br/>Log Collector<br/>DaemonSet<br/>Port 3101]
    Loki[Loki<br/>Log Aggregation<br/>Port 3100]
    
    subgraph "S3 Storage - Minio"
        Minio[Minio API<br/>Port 9000]
        LokiChunks[(loki-chunks<br/>Log Data)]
        LokiRuler[(loki-ruler<br/>Alert Rules)]
        LokiAdmin[(loki-admin<br/>Metadata)]
    end
    
    Grafana[Grafana<br/>Log Visualization<br/>Port 3000]
    
    Pods -->|Read from<br/>/var/log/pods| Promtail
    Promtail -->|Ship logs<br/>HTTP Push| Loki
    Loki -->|Store chunks| Minio
    Minio -->|Write| LokiChunks
    Minio -->|Write| LokiRuler
    Minio -->|Write| LokiAdmin
    Loki -->|Query logs| Grafana
    
    classDef logging fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef storage fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    classDef viz fill:#e1f5ff,stroke:#01579b,stroke-width:2px
    
    class Loki,Promtail logging
    class Minio,LokiChunks,LokiRuler,LokiAdmin storage
    class Grafana viz
```
