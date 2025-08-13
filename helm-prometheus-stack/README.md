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

<!-- BEGIN_TF_DOCS -->


## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.14 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 3.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | 3.0.2 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.38.0 |
| <a name="provider_null"></a> [null](#provider\_null) | 3.2.4 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.7.2 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.this](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_ingress_v1.alertmanager](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/ingress_v1) | resource |
| [kubernetes_ingress_v1.prometheus](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/ingress_v1) | resource |
| [kubernetes_limit_range.namespace_limits](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/limit_range) | resource |
| [kubernetes_manifest.monitoring_auth_middleware](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_namespace.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_secret.monitoring_auth](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [null_resource.wait_for_traefik_crds](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [random_password.monitoring_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [kubernetes_service.alertmanager](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/service) | data source |
| [kubernetes_service.prometheus](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/service) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alertmanager_storage_class"></a> [alertmanager\_storage\_class](#input\_alertmanager\_storage\_class) | Storage class for Alertmanager PVC (empty uses cluster default). | `string` | `""` | no |
| <a name="input_alertmanager_storage_size"></a> [alertmanager\_storage\_size](#input\_alertmanager\_storage\_size) | Storage size for Alertmanager persistent volume. | `string` | `"2Gi"` | no |
| <a name="input_chart_name"></a> [chart\_name](#input\_chart\_name) | Helm chart name for Prometheus stack. | `string` | `"kube-prometheus-stack"` | no |
| <a name="input_chart_repo"></a> [chart\_repo](#input\_chart\_repo) | Helm repository URL for Prometheus charts. | `string` | `"https://prometheus-community.github.io/helm-charts"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Helm chart version for Prometheus stack. | `string` | `"75.15.2"` | no |
| <a name="input_cpu_arch"></a> [cpu\_arch](#input\_cpu\_arch) | CPU architecture for container images (amd64, arm64). | `string` | `"arm64"` | no |
| <a name="input_cpu_limit"></a> [cpu\_limit](#input\_cpu\_limit) | CPU limit for containers in the namespace. | `string` | `"300m"` | no |
| <a name="input_cpu_request"></a> [cpu\_request](#input\_cpu\_request) | CPU request for containers in the namespace. | `string` | `"50m"` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Domain name for ingress resources. | `string` | `".local"` | no |
| <a name="input_enable_alertmanager_ingress"></a> [enable\_alertmanager\_ingress](#input\_enable\_alertmanager\_ingress) | Enable Alertmanager ingress configuration. | `bool` | `false` | no |
| <a name="input_enable_monitoring_auth"></a> [enable\_monitoring\_auth](#input\_enable\_monitoring\_auth) | Enable basic authentication for monitoring services (requires Traefik CRDs - enable after first apply) | `bool` | `false` | no |
| <a name="input_enable_node_selector"></a> [enable\_node\_selector](#input\_enable\_node\_selector) | Enable node selectors for component scheduling. | `bool` | `false` | no |
| <a name="input_enable_prometheus_ingress"></a> [enable\_prometheus\_ingress](#input\_enable\_prometheus\_ingress) | Enable Prometheus ingress configuration. | `bool` | `false` | no |
| <a name="input_enable_prometheus_ingress_route"></a> [enable\_prometheus\_ingress\_route](#input\_enable\_prometheus\_ingress\_route) | Enable Prometheus ingress route configuration. | `bool` | `false` | no |
| <a name="input_helm_cleanup_on_fail"></a> [helm\_cleanup\_on\_fail](#input\_helm\_cleanup\_on\_fail) | Cleanup resources on deployment failure. | `bool` | `false` | no |
| <a name="input_helm_disable_webhooks"></a> [helm\_disable\_webhooks](#input\_helm\_disable\_webhooks) | Disable webhooks for Helm release. | `bool` | `false` | no |
| <a name="input_helm_force_update"></a> [helm\_force\_update](#input\_helm\_force\_update) | Force resource updates if needed. | `bool` | `false` | no |
| <a name="input_helm_replace"></a> [helm\_replace](#input\_helm\_replace) | Allow Helm to replace existing resources. | `bool` | `false` | no |
| <a name="input_helm_skip_crds"></a> [helm\_skip\_crds](#input\_helm\_skip\_crds) | Skip CRDs for Helm release. | `bool` | `false` | no |
| <a name="input_helm_timeout"></a> [helm\_timeout](#input\_helm\_timeout) | Timeout for Helm deployment in seconds. | `number` | `600` | no |
| <a name="input_helm_wait"></a> [helm\_wait](#input\_helm\_wait) | Wait for Helm release to be ready. | `bool` | `false` | no |
| <a name="input_helm_wait_for_jobs"></a> [helm\_wait\_for\_jobs](#input\_helm\_wait\_for\_jobs) | Wait for Helm jobs to complete. | `bool` | `false` | no |
| <a name="input_memory_limit"></a> [memory\_limit](#input\_memory\_limit) | Memory limit for containers in the namespace. | `string` | `"256Mi"` | no |
| <a name="input_memory_request"></a> [memory\_request](#input\_memory\_request) | Memory request for containers in the namespace. | `string` | `"128Mi"` | no |
| <a name="input_monitoring_admin_password"></a> [monitoring\_admin\_password](#input\_monitoring\_admin\_password) | Custom password for monitoring services basic auth (empty = auto-generate) | `string` | `""` | no |
| <a name="input_name"></a> [name](#input\_name) | Helm release name for Prometheus stack. | `string` | `"kube-prometheus-stack"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace for Prometheus monitoring stack. | `string` | `"monitoring-system"` | no |
| <a name="input_prometheus_storage_class"></a> [prometheus\_storage\_class](#input\_prometheus\_storage\_class) | Storage class for Prometheus PVC (empty uses cluster default). | `string` | `""` | no |
| <a name="input_prometheus_storage_size"></a> [prometheus\_storage\_size](#input\_prometheus\_storage\_size) | Storage size for Prometheus persistent volume. | `string` | `"8Gi"` | no |
| <a name="input_prometheus_url"></a> [prometheus\_url](#input\_prometheus\_url) | External Prometheus URL if applicable. | `string` | `""` | no |
| <a name="input_traefik_cert_resolver"></a> [traefik\_cert\_resolver](#input\_traefik\_cert\_resolver) | Traefik certificate resolver for TLS. | `string` | `"wildcard"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alertmanager_ingress_url"></a> [alertmanager\_ingress\_url](#output\_alertmanager\_ingress\_url) | External ingress URL for AlertManager web UI |
| <a name="output_alertmanager_port"></a> [alertmanager\_port](#output\_alertmanager\_port) | AlertManager server port |
| <a name="output_alertmanager_service_name"></a> [alertmanager\_service\_name](#output\_alertmanager\_service\_name) | AlertManager service name |
| <a name="output_alertmanager_storage_class"></a> [alertmanager\_storage\_class](#output\_alertmanager\_storage\_class) | Storage class used for AlertManager persistence |
| <a name="output_alertmanager_storage_size"></a> [alertmanager\_storage\_size](#output\_alertmanager\_storage\_size) | Storage size allocated for AlertManager |
| <a name="output_alertmanager_url"></a> [alertmanager\_url](#output\_alertmanager\_url) | Internal service URL for AlertManager (cluster-local) |
| <a name="output_common_labels"></a> [common\_labels](#output\_common\_labels) | Common labels applied to all resources |
| <a name="output_environment_config"></a> [environment\_config](#output\_environment\_config) | Environment configuration summary |
| <a name="output_helm_chart_name"></a> [helm\_chart\_name](#output\_helm\_chart\_name) | Helm chart name |
| <a name="output_helm_chart_version"></a> [helm\_chart\_version](#output\_helm\_chart\_version) | Helm chart version deployed |
| <a name="output_helm_release_name"></a> [helm\_release\_name](#output\_helm\_release\_name) | Helm release name |
| <a name="output_kubectl_commands"></a> [kubectl\_commands](#output\_kubectl\_commands) | Useful kubectl commands for Prometheus stack operations |
| <a name="output_monitoring_admin_password"></a> [monitoring\_admin\_password](#output\_monitoring\_admin\_password) | Admin password for Prometheus and AlertManager basic auth |
| <a name="output_monitoring_admin_username"></a> [monitoring\_admin\_username](#output\_monitoring\_admin\_username) | Admin username for Prometheus and AlertManager basic auth |
| <a name="output_namespace"></a> [namespace](#output\_namespace) | Prometheus stack namespace |
| <a name="output_prometheus_ingress_url"></a> [prometheus\_ingress\_url](#output\_prometheus\_ingress\_url) | External ingress URL for Prometheus web UI |
| <a name="output_prometheus_port"></a> [prometheus\_port](#output\_prometheus\_port) | Prometheus server port |
| <a name="output_prometheus_service_name"></a> [prometheus\_service\_name](#output\_prometheus\_service\_name) | Prometheus service name |
| <a name="output_prometheus_storage_class"></a> [prometheus\_storage\_class](#output\_prometheus\_storage\_class) | Storage class used for Prometheus persistence |
| <a name="output_prometheus_storage_size"></a> [prometheus\_storage\_size](#output\_prometheus\_storage\_size) | Storage size allocated for Prometheus |
| <a name="output_prometheus_url"></a> [prometheus\_url](#output\_prometheus\_url) | Internal service URL for Prometheus (cluster-local) |

<!-- END_TF_DOCS -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.14 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 3.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | 3.0.2 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.38.0 |
| <a name="provider_null"></a> [null](#provider\_null) | 3.2.4 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.7.2 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.this](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_ingress_v1.alertmanager](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/ingress_v1) | resource |
| [kubernetes_ingress_v1.prometheus](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/ingress_v1) | resource |
| [kubernetes_limit_range.namespace_limits](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/limit_range) | resource |
| [kubernetes_manifest.monitoring_auth_middleware](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_namespace.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_secret.monitoring_auth](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [null_resource.wait_for_traefik_crds](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [random_password.monitoring_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [kubernetes_service.alertmanager](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/service) | data source |
| [kubernetes_service.prometheus](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/service) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alertmanager_storage_class"></a> [alertmanager\_storage\_class](#input\_alertmanager\_storage\_class) | Storage class for Alertmanager PVC (empty uses cluster default). | `string` | `""` | no |
| <a name="input_alertmanager_storage_size"></a> [alertmanager\_storage\_size](#input\_alertmanager\_storage\_size) | Storage size for Alertmanager persistent volume. | `string` | `"2Gi"` | no |
| <a name="input_chart_name"></a> [chart\_name](#input\_chart\_name) | Helm chart name for Prometheus stack. | `string` | `"kube-prometheus-stack"` | no |
| <a name="input_chart_repo"></a> [chart\_repo](#input\_chart\_repo) | Helm repository URL for Prometheus charts. | `string` | `"https://prometheus-community.github.io/helm-charts"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Helm chart version for Prometheus stack. | `string` | `"75.15.2"` | no |
| <a name="input_cpu_arch"></a> [cpu\_arch](#input\_cpu\_arch) | CPU architecture for container images (amd64, arm64). | `string` | `"arm64"` | no |
| <a name="input_cpu_limit"></a> [cpu\_limit](#input\_cpu\_limit) | CPU limit for containers in the namespace. | `string` | `"300m"` | no |
| <a name="input_cpu_request"></a> [cpu\_request](#input\_cpu\_request) | CPU request for containers in the namespace. | `string` | `"50m"` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Domain name for ingress resources. | `string` | `".local"` | no |
| <a name="input_enable_alertmanager_ingress"></a> [enable\_alertmanager\_ingress](#input\_enable\_alertmanager\_ingress) | Enable Alertmanager ingress configuration. | `bool` | `false` | no |
| <a name="input_enable_monitoring_auth"></a> [enable\_monitoring\_auth](#input\_enable\_monitoring\_auth) | Enable basic authentication for monitoring services (requires Traefik CRDs - enable after first apply) | `bool` | `false` | no |
| <a name="input_enable_node_selector"></a> [enable\_node\_selector](#input\_enable\_node\_selector) | Enable node selectors for component scheduling. | `bool` | `false` | no |
| <a name="input_enable_prometheus_ingress"></a> [enable\_prometheus\_ingress](#input\_enable\_prometheus\_ingress) | Enable Prometheus ingress configuration. | `bool` | `false` | no |
| <a name="input_enable_prometheus_ingress_route"></a> [enable\_prometheus\_ingress\_route](#input\_enable\_prometheus\_ingress\_route) | Enable Prometheus ingress route configuration. | `bool` | `false` | no |
| <a name="input_helm_cleanup_on_fail"></a> [helm\_cleanup\_on\_fail](#input\_helm\_cleanup\_on\_fail) | Cleanup resources on deployment failure. | `bool` | `false` | no |
| <a name="input_helm_disable_webhooks"></a> [helm\_disable\_webhooks](#input\_helm\_disable\_webhooks) | Disable webhooks for Helm release. | `bool` | `false` | no |
| <a name="input_helm_force_update"></a> [helm\_force\_update](#input\_helm\_force\_update) | Force resource updates if needed. | `bool` | `false` | no |
| <a name="input_helm_replace"></a> [helm\_replace](#input\_helm\_replace) | Allow Helm to replace existing resources. | `bool` | `false` | no |
| <a name="input_helm_skip_crds"></a> [helm\_skip\_crds](#input\_helm\_skip\_crds) | Skip CRDs for Helm release. | `bool` | `false` | no |
| <a name="input_helm_timeout"></a> [helm\_timeout](#input\_helm\_timeout) | Timeout for Helm deployment in seconds. | `number` | `600` | no |
| <a name="input_helm_wait"></a> [helm\_wait](#input\_helm\_wait) | Wait for Helm release to be ready. | `bool` | `false` | no |
| <a name="input_helm_wait_for_jobs"></a> [helm\_wait\_for\_jobs](#input\_helm\_wait\_for\_jobs) | Wait for Helm jobs to complete. | `bool` | `false` | no |
| <a name="input_memory_limit"></a> [memory\_limit](#input\_memory\_limit) | Memory limit for containers in the namespace. | `string` | `"256Mi"` | no |
| <a name="input_memory_request"></a> [memory\_request](#input\_memory\_request) | Memory request for containers in the namespace. | `string` | `"128Mi"` | no |
| <a name="input_monitoring_admin_password"></a> [monitoring\_admin\_password](#input\_monitoring\_admin\_password) | Custom password for monitoring services basic auth (empty = auto-generate) | `string` | `""` | no |
| <a name="input_name"></a> [name](#input\_name) | Helm release name for Prometheus stack. | `string` | `"kube-prometheus-stack"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace for Prometheus monitoring stack. | `string` | `"monitoring-system"` | no |
| <a name="input_prometheus_storage_class"></a> [prometheus\_storage\_class](#input\_prometheus\_storage\_class) | Storage class for Prometheus PVC (empty uses cluster default). | `string` | `""` | no |
| <a name="input_prometheus_storage_size"></a> [prometheus\_storage\_size](#input\_prometheus\_storage\_size) | Storage size for Prometheus persistent volume. | `string` | `"8Gi"` | no |
| <a name="input_prometheus_url"></a> [prometheus\_url](#input\_prometheus\_url) | External Prometheus URL if applicable. | `string` | `""` | no |
| <a name="input_traefik_cert_resolver"></a> [traefik\_cert\_resolver](#input\_traefik\_cert\_resolver) | Traefik certificate resolver for TLS. | `string` | `"wildcard"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alertmanager_ingress_url"></a> [alertmanager\_ingress\_url](#output\_alertmanager\_ingress\_url) | External ingress URL for AlertManager web UI |
| <a name="output_alertmanager_port"></a> [alertmanager\_port](#output\_alertmanager\_port) | AlertManager server port |
| <a name="output_alertmanager_service_name"></a> [alertmanager\_service\_name](#output\_alertmanager\_service\_name) | AlertManager service name |
| <a name="output_alertmanager_storage_class"></a> [alertmanager\_storage\_class](#output\_alertmanager\_storage\_class) | Storage class used for AlertManager persistence |
| <a name="output_alertmanager_storage_size"></a> [alertmanager\_storage\_size](#output\_alertmanager\_storage\_size) | Storage size allocated for AlertManager |
| <a name="output_alertmanager_url"></a> [alertmanager\_url](#output\_alertmanager\_url) | Internal service URL for AlertManager (cluster-local) |
| <a name="output_common_labels"></a> [common\_labels](#output\_common\_labels) | Common labels applied to all resources |
| <a name="output_environment_config"></a> [environment\_config](#output\_environment\_config) | Environment configuration summary |
| <a name="output_helm_chart_name"></a> [helm\_chart\_name](#output\_helm\_chart\_name) | Helm chart name |
| <a name="output_helm_chart_version"></a> [helm\_chart\_version](#output\_helm\_chart\_version) | Helm chart version deployed |
| <a name="output_helm_release_name"></a> [helm\_release\_name](#output\_helm\_release\_name) | Helm release name |
| <a name="output_kubectl_commands"></a> [kubectl\_commands](#output\_kubectl\_commands) | Useful kubectl commands for Prometheus stack operations |
| <a name="output_monitoring_admin_password"></a> [monitoring\_admin\_password](#output\_monitoring\_admin\_password) | Admin password for Prometheus and AlertManager basic auth |
| <a name="output_monitoring_admin_username"></a> [monitoring\_admin\_username](#output\_monitoring\_admin\_username) | Admin username for Prometheus and AlertManager basic auth |
| <a name="output_namespace"></a> [namespace](#output\_namespace) | Prometheus stack namespace |
| <a name="output_prometheus_ingress_url"></a> [prometheus\_ingress\_url](#output\_prometheus\_ingress\_url) | External ingress URL for Prometheus web UI |
| <a name="output_prometheus_port"></a> [prometheus\_port](#output\_prometheus\_port) | Prometheus server port |
| <a name="output_prometheus_service_name"></a> [prometheus\_service\_name](#output\_prometheus\_service\_name) | Prometheus service name |
| <a name="output_prometheus_storage_class"></a> [prometheus\_storage\_class](#output\_prometheus\_storage\_class) | Storage class used for Prometheus persistence |
| <a name="output_prometheus_storage_size"></a> [prometheus\_storage\_size](#output\_prometheus\_storage\_size) | Storage size allocated for Prometheus |
| <a name="output_prometheus_url"></a> [prometheus\_url](#output\_prometheus\_url) | Internal service URL for Prometheus (cluster-local) |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
