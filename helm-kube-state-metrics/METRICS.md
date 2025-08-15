# Kube-State-Metrics Available Metrics

This document lists the key metrics exposed by kube-state-metrics that are used in the Grafana dashboards.

## Core Kubernetes Object Metrics

### Node Metrics
- `kube_node_info` - Node information (OS, kernel, kubelet version)
- `kube_node_status_condition` - Node conditions (Ready, OutOfDisk, etc.)
- `kube_node_status_capacity` - Node capacity (CPU, memory, pods)
- `kube_node_status_allocatable` - Node allocatable resources

### Pod Metrics
- `kube_pod_info` - Pod information (namespace, node, etc.)
- `kube_pod_status_phase` - Pod phase (Pending, Running, Succeeded, Failed)
- `kube_pod_container_status_ready` - Container ready status
- `kube_pod_container_resource_requests` - Resource requests
- `kube_pod_container_resource_limits` - Resource limits

### Deployment Metrics
- `kube_deployment_status_replicas` - Deployment replica counts
- `kube_deployment_status_replicas_available` - Available replicas
- `kube_deployment_status_replicas_unavailable` - Unavailable replicas

### Service Metrics
- `kube_service_info` - Service information
- `kube_service_spec_type` - Service type (ClusterIP, NodePort, LoadBalancer)

### Namespace Metrics
- `kube_namespace_status_phase` - Namespace phase
- `kube_namespace_labels` - Namespace labels

### Persistent Volume Metrics
- `kube_persistentvolume_info` - PV information
- `kube_persistentvolume_status_phase` - PV phase
- `kube_persistentvolumeclaim_info` - PVC information

## Dashboard Compatibility

The following Grafana dashboards are specifically designed to work with these metrics:

### Working Dashboards (Verified)
- **7249** - Kubernetes Cluster Monitoring (Main overview)
- **1860** - Node Exporter Full (Node metrics)
- **8588** - Kubernetes Cluster Overview (Resource usage)
- **6417** - Kubernetes Pods (Pod monitoring)
- **13646** - Kubernetes Persistent Volumes (Storage)

### Monitoring Stack Dashboards
- **3662** - Prometheus 2.0 Overview
- **9578** - AlertManager Overview
- **3590** - Grafana Overview

### Application Dashboards
- **11462** - Traefik 2.0 Dashboard
- **4475** - Traefik Official Dashboard

## Troubleshooting Missing Data

If dashboards show "No data" or missing metrics:

1. **Check kube-state-metrics is running:**
   ```bash
   kubectl get pods -n kube-state-metrics-system
   ```

2. **Verify metrics endpoint:**
   ```bash
   kubectl port-forward -n kube-state-metrics-system svc/kube-state-metrics 8080:8080
   curl http://localhost:8080/metrics | grep kube_
   ```

3. **Check Prometheus is scraping:**
   ```bash
   # In Prometheus UI, check targets
   # Look for kube-state-metrics target
   ```

4. **Verify ServiceMonitor:**
   ```bash
   kubectl get servicemonitor -n kube-state-metrics-system
   ```

## Common Query Examples

### Cluster Resource Usage
```promql
# CPU usage by node
100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory usage by node
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# Pod count by namespace
count by (namespace) (kube_pod_info)
```

### Pod Resource Monitoring
```promql
# Pods by phase
count by (phase) (kube_pod_status_phase)

# Container restarts
increase(kube_pod_container_status_restarts_total[1h])

# Resource requests vs limits
kube_pod_container_resource_requests{resource="cpu"}
kube_pod_container_resource_limits{resource="cpu"}
```

## Dashboard Folders

Dashboards are organized into folders:

- **Default** - Main overview dashboards
- **Kubernetes** - Kubernetes-specific monitoring
- **Infrastructure** - Monitoring stack and applications

This organization helps users find relevant dashboards quickly and provides a better out-of-the-box experience.
