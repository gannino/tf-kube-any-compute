# Prometheus Stack Helm Module

This Terraform module deploys the Prometheus monitoring stack (Prometheus, Alertmanager, Grafana) using the kube-prometheus-stack Helm chart.

## Features

- **📊 Complete Monitoring Stack**: Prometheus, Alertmanager, and Grafana in one deployment
- **🎯 Kubernetes Native**: Pre-configured for Kubernetes cluster monitoring
- **📋 Pre-built Dashboards**: Comprehensive set of Grafana dashboards
- **🚨 Alerting Rules**: Production-ready alerting rules for Kubernetes
- **🔍 Service Discovery**: Automatic discovery of Kubernetes services
- **📈 Node Monitoring**: Node Exporter for system metrics
- **⚙️ Operator Management**: Prometheus Operator for easy configuration
- **💾 Long-term Storage**: Configurable retention and storage options

## Usage

### Basic Usage

```hcl
module "prometheus_stack" {
  source = "./helm-prometheus-stack"
  
  namespace = "monitoring"
  
  storage_class = "fast-ssd"
  prometheus_storage_size = "20Gi"
}
```

### Advanced Configuration

```hcl
module "prometheus_stack" {
  source = "./helm-prometheus-stack"
  
  namespace     = "monitoring"
  chart_version = "61.7.2"
  
  # Storage configuration
  storage_class = "fast-ssd"
  prometheus_storage_size = "50Gi"
  alertmanager_storage_size = "5Gi"
  
  # Ingress configuration
  domain_name = "example.com"
  traefik_cert_resolver = "letsencrypt"
  
  # Resource configuration
  prometheus_cpu_limit = "2000m"
  prometheus_memory_limit = "4Gi"
  alertmanager_cpu_limit = "500m"
  alertmanager_memory_limit = "512Mi"
  
  # Retention settings
  prometheus_retention = "30d"
  prometheus_retention_size = "45GB"
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| helm | >= 2.0 |
| kubernetes | >= 2.0 |

## Providers

| Name | Version |
|------|---------|
| helm | >= 2.0 |
| kubernetes | >= 2.0 |

## Resources

| Name | Type |
|------|------|
| kubernetes_namespace.this | resource |
| helm_release.this | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| namespace | Namespace for Prometheus stack | `string` | `"monitoring"` | no |
| name | Helm release name | `string` | `"prometheus-stack"` | no |
| chart_name | Helm chart name | `string` | `"kube-prometheus-stack"` | no |
| chart_repo | Helm repository | `string` | `"https://prometheus-community.github.io/helm-charts"` | no |
| chart_version | Helm chart version | `string` | `"61.7.2"` | no |
| storage_class | Storage class for Prometheus | `string` | `"hostpath"` | no |
| prometheus_storage_size | Storage size for Prometheus | `string` | `"10Gi"` | no |
| alertmanager_storage_size | Storage size for Alertmanager | `string` | `"2Gi"` | no |
| prometheus_retention | Prometheus data retention period | `string` | `"15d"` | no |
| prometheus_retention_size | Prometheus storage retention size | `string` | `"9GB"` | no |
| prometheus_cpu_limit | CPU limit for Prometheus | `string` | `"1000m"` | no |
| prometheus_memory_limit | Memory limit for Prometheus | `string` | `"2Gi"` | no |
| alertmanager_cpu_limit | CPU limit for Alertmanager | `string` | `"200m"` | no |
| alertmanager_memory_limit | Memory limit for Alertmanager | `string` | `"256Mi"` | no |
| cpu_arch | CPU architecture constraint | `string` | `"amd64"` | no |
| domain_name | Domain name for ingress | `string` | `".local"` | no |
| traefik_cert_resolver | Traefik certificate resolver | `string` | `"default"` | no |

## Outputs

| Name | Description |
|------|-------------|
| namespace | Prometheus stack namespace |
| prometheus_url | Prometheus web UI URL |
| alertmanager_url | Alertmanager web UI URL |
| grafana_url | Grafana dashboard URL |

## Stack Components

### Prometheus Server

The core metrics collection and storage engine:

- **Metrics Collection**: Scrapes metrics from Kubernetes API and exporters
- **Storage**: Time-series database with configurable retention
- **Query Engine**: PromQL for complex metric queries
- **Service Discovery**: Automatic target discovery in Kubernetes

### Alertmanager

Handles alerts sent by Prometheus:

- **Alert Routing**: Route alerts to different notification channels
- **Grouping**: Group similar alerts to reduce noise
- **Silencing**: Temporarily silence alerts during maintenance
- **Inhibition**: Suppress alerts based on other active alerts

### Grafana Integration

Pre-configured Grafana instance with:

- **Data Sources**: Prometheus and Alertmanager automatically configured
- **Dashboards**: Comprehensive set of monitoring dashboards
- **Authentication**: Admin user with auto-generated password
- **Alerting**: Grafana alerting rules and notification channels

### Node Exporter

System metrics collection:

- **Hardware Metrics**: CPU, memory, disk, network statistics
- **OS Metrics**: Filesystem usage, system load, process statistics
- **DaemonSet Deployment**: Runs on every cluster node
- **Secure Collection**: TLS and authentication support

## Pre-configured Dashboards

The stack includes production-ready dashboards:

### Cluster Overview
- **Cluster Resource Usage**: CPU, memory, disk across all nodes
- **Pod Statistics**: Running, pending, failed pods
- **Namespace Usage**: Resource consumption by namespace
- **Network Traffic**: Ingress/egress traffic patterns

### Node Monitoring
- **Node Resource Usage**: Per-node CPU, memory, disk utilization
- **System Metrics**: Load average, filesystem usage, network interfaces
- **Hardware Information**: Node capacity, architecture, kernel version
- **Alerts**: Node down, high resource usage, disk space warnings

### Kubernetes Components
- **API Server**: Request rate, latency, error rate
- **Scheduler**: Scheduling latency and queue depth
- **Controller Manager**: Work queue metrics and reconciliation time
- **kubelet**: Pod lifecycle, container runtime metrics

### Application Monitoring
- **Workload Overview**: Deployment, StatefulSet, DaemonSet status
- **Pod Metrics**: CPU, memory usage per pod
- **Container Insights**: Container lifecycle and resource usage
- **Service Metrics**: Service discovery and endpoint health

## Alerting Rules

Production-ready alerting rules included:

### Infrastructure Alerts
```yaml
# Node down alert
- alert: NodeDown
  expr: up{job="node-exporter"} == 0
  for: 5m
  labels:
    severity: critical
  annotations:
    summary: "Node {{ $labels.instance }} is down"

# High CPU usage
- alert: HighCPUUsage
  expr: 100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
  for: 10m
  labels:
    severity: warning
  annotations:
    summary: "High CPU usage on {{ $labels.instance }}"
```

### Kubernetes Alerts
```yaml
# Pod crash looping
- alert: PodCrashLooping
  expr: rate(kube_pod_container_status_restarts_total[10m]) > 0
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "Pod {{ $labels.namespace }}/{{ $labels.pod }} is crash looping"

# Persistent volume usage
- alert: PersistentVolumeUsageHigh
  expr: kubelet_volume_stats_used_bytes / kubelet_volume_stats_capacity_bytes > 0.8
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "PV usage high: {{ $value | humanizePercentage }}"
```

## Storage Configuration

### Prometheus Storage

```hcl
# Production storage configuration
prometheus_storage_size = "100Gi"
prometheus_retention = "30d"
prometheus_retention_size = "90GB"
storage_class = "fast-ssd"
```

### Storage Sizing Guidelines

| Environment | Storage Size | Retention | Expected Usage |
|-------------|--------------|-----------|----------------|
| Development | 10-20Gi | 7-15d | Small cluster, basic monitoring |
| Staging | 50-100Gi | 15-30d | Medium cluster, full monitoring |
| Production | 200-500Gi | 30-90d | Large cluster, comprehensive monitoring |

## Performance Tuning

### Resource Allocation

```hcl
# High-performance configuration
prometheus_cpu_limit = "4000m"
prometheus_memory_limit = "8Gi"
prometheus_storage_size = "500Gi"

# Resource-constrained configuration
prometheus_cpu_limit = "500m"
prometheus_memory_limit = "1Gi"
prometheus_storage_size = "20Gi"
```

### Query Performance

Optimize Prometheus queries:

- **Recording Rules**: Pre-compute expensive queries
- **Metric Relabeling**: Reduce cardinality by dropping unnecessary labels
- **Federation**: Aggregate metrics from multiple Prometheus instances
- **Remote Storage**: Use long-term storage backends like Thanos

### Recording Rules Example

```yaml
# Recording rules for frequently used queries
groups:
  - name: cluster_cpu
    rules:
      - record: cluster:cpu_usage_rate
        expr: 1 - avg(rate(node_cpu_seconds_total{mode="idle"}[5m]))
      
      - record: namespace:cpu_usage_rate
        expr: sum(rate(container_cpu_usage_seconds_total[5m])) by (namespace)
```

## Monitoring External Services

### Custom ServiceMonitor

```yaml
# Monitor external service
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: external-app
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: external-app
  endpoints:
  - port: metrics
    path: /metrics
    interval: 30s
```

### PodMonitor for Pods

```yaml
# Monitor pods directly
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  name: pod-metrics
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: my-app
  podMetricsEndpoints:
  - port: metrics
    path: /metrics
```

## Architecture Support

### ARM64 (Raspberry Pi)

```hcl
cpu_arch = "arm64"
prometheus_cpu_limit = "500m"
prometheus_memory_limit = "1Gi"
prometheus_storage_size = "20Gi"
```

### AMD64 (x86_64)

```hcl
cpu_arch = "amd64"
prometheus_cpu_limit = "2000m"
prometheus_memory_limit = "4Gi"
prometheus_storage_size = "100Gi"
```

## High Availability

### Prometheus HA Setup

```yaml
# HA Prometheus configuration
prometheus:
  prometheusSpec:
    replicas: 2
    retention: 30d
    retentionSize: 90GB
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: fast-ssd
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 100Gi
```

### Thanos Integration

For long-term storage and global view:

```yaml
# Thanos sidecar configuration
prometheus:
  thanosService:
    enabled: true
  thanosServiceMonitor:
    enabled: true
  prometheusSpec:
    thanos:
      image: quay.io/thanos/thanos:v0.32.5
      version: v0.32.5
      objectStorageConfig:
        key: thanos.yaml
        name: thanos-objstore-config
```

## Troubleshooting

### Common Issues

1. **Storage Full**: Monitor storage usage and adjust retention
2. **High Memory Usage**: Reduce scrape frequency or metric cardinality
3. **Query Timeouts**: Optimize queries or add recording rules
4. **Missing Metrics**: Check ServiceMonitor selectors and endpoints

### Debug Commands

```bash
# Check Prometheus targets
kubectl port-forward -n monitoring svc/prometheus-stack-prometheus 9090:9090
# Visit http://localhost:9090/targets

# Check Prometheus configuration
kubectl get prometheus -n monitoring -o yaml

# View Prometheus logs
kubectl logs -n monitoring prometheus-prometheus-stack-prometheus-0

# Check storage usage
kubectl exec -n monitoring prometheus-prometheus-stack-prometheus-0 -- df -h /prometheus
```

### Query Debugging

```promql
# Check metric ingestion rate
rate(prometheus_tsdb_symbol_table_size_bytes[5m])

# Monitor query performance
prometheus_engine_query_duration_seconds

# Check rule evaluation
prometheus_rule_evaluation_duration_seconds
```

## Security Considerations

- **RBAC**: Proper service account permissions for scraping
- **Network Policies**: Restrict access to monitoring components
- **TLS**: Enable TLS for scraping and web interfaces
- **Authentication**: Configure authentication for web UIs
- **Data Privacy**: Be mindful of sensitive data in metrics labels

## Integration Examples

### Custom Application Metrics

```go
// Example Go application with Prometheus metrics
package main

import (
    "github.com/prometheus/client_golang/prometheus"
    "github.com/prometheus/client_golang/prometheus/promhttp"
    "net/http"
)

var (
    requestsTotal = prometheus.NewCounterVec(
        prometheus.CounterOpts{
            Name: "http_requests_total",
            Help: "Total HTTP requests",
        },
        []string{"method", "status"},
    )
)

func init() {
    prometheus.MustRegister(requestsTotal)
}

func handler(w http.ResponseWriter, r *http.Request) {
    requestsTotal.WithLabelValues(r.Method, "200").Inc()
    w.Write([]byte("Hello, World!"))
}

func main() {
    http.HandleFunc("/", handler)
    http.Handle("/metrics", promhttp.Handler())
    http.ListenAndServe(":8080", nil)
}
```

### ServiceMonitor for Custom App

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: my-app
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: my-app
  endpoints:
  - port: metrics
    path: /metrics
    interval: 15s
    scrapeTimeout: 10s
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

MIT
