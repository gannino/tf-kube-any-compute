# 📋 Complete Variable Reference

## 🎯 Core Configuration Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `base_domain` | string | `"local"` | Base domain name (e.g., 'example.com') |
| `platform_name` | string | `"k3s"` | Platform identifier (k3s, eks, gke, aks, microk8s) |
| `cpu_arch` | string | `""` | CPU architecture (`""` = auto-detect, `"amd64"`, `"arm64"`) |
| `auto_mixed_cluster_mode` | bool | `true` | Automatically configure services for mixed architecture clusters |

## 🏗️ Architecture Management Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `cpu_arch_override` | object | `{}` | Per-service CPU architecture overrides |
| `disable_arch_scheduling` | object | `{}` | Disable architecture-based scheduling for specific services |

## 🛠️ Service Enablement Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `services.traefik` | bool | `true` | Enable Traefik ingress controller |
| `services.metallb` | bool | `true` | Enable MetalLB load balancer |
| `services.nfs_csi` | bool | `true` | Enable NFS CSI storage driver |
| `services.host_path` | bool | `true` | Enable HostPath storage driver |
| `services.prometheus` | bool | `true` | Enable Prometheus monitoring |
| `services.prometheus_crds` | bool | `true` | Enable Prometheus CRDs |
| `services.grafana` | bool | `true` | Enable Grafana dashboards |
| `services.loki` | bool | `true` | Enable Loki log aggregation |
| `services.promtail` | bool | `true` | Enable Promtail log collection |
| `services.consul` | bool | `true` | Enable Consul service discovery |
| `services.vault` | bool | `true` | Enable Vault secrets management |
| `services.gatekeeper` | bool | `false` | Enable Gatekeeper policy engine |
| `services.portainer` | bool | `true` | Enable Portainer management UI |
| `services.node_feature_discovery` | bool | `true` | Enable Node Feature Discovery |

## 💾 Storage Configuration Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `use_nfs_storage` | bool | `false` | Use NFS storage as primary backend |
| `use_hostpath_storage` | bool | `true` | Use hostPath storage |
| `nfs_server_address` | string | `"192.168.1.100"` | NFS server IP address |
| `nfs_server_path` | string | `"/mnt/k8s-storage"` | NFS server path |
| `default_storage_class` | string | `""` | Default storage class (empty = auto-detect) |

## 🔒 Security & Access Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `traefik_dashboard_password` | string | `""` | Traefik dashboard password (empty = auto-generate) |
| `grafana_admin_password` | string | `""` | Grafana admin password (empty = auto-generate) |
| `portainer_admin_password` | string | `""` | Portainer admin password (empty = auto-generate) |
| `le_email` | string | `""` | Let's Encrypt email for certificates |

## ⚙️ Performance & Resource Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `enable_resource_limits` | bool | `true` | Enable resource limits on all services |
| `default_cpu_limit` | string | `"500m"` | Default CPU limit per container |
| `default_memory_limit` | string | `"512Mi"` | Default memory limit per container |
| `default_helm_timeout` | number | `600` | Default Helm deployment timeout (seconds) |

## 🎛️ Service Override Variables

The `service_overrides` variable provides fine-grained control over individual services:

| Service | Available Overrides |
|---------|-------------------|
| `traefik` | cpu_arch, chart_version, storage_class, storage_size, enable_dashboard, dashboard_password, cert_resolver, cpu_limit, memory_limit, cpu_request, memory_request, helm_* |
| `prometheus` | cpu_arch, chart_version, storage_class, storage_size, enable_ingress, retention_period, cpu_limit, memory_limit, cpu_request, memory_request, helm_* |
| `grafana` | cpu_arch, chart_version, storage_class, storage_size, enable_persistence, node_name, admin_user, admin_password, cpu_limit, memory_limit, cpu_request, memory_request, helm_* |
| `metallb` | address_pool, cpu_limit, memory_limit, cpu_request, memory_request, helm_* |
| `vault` | storage_class, storage_size, cpu_limit, memory_limit, cpu_request, memory_request, helm_* |
| `consul` | storage_class, storage_size, cpu_limit, memory_limit, cpu_request, memory_request, helm_* |
| `portainer` | storage_class, storage_size, admin_password, cpu_limit, memory_limit, cpu_request, memory_request, helm_* |
| `loki` | storage_class, storage_size, cpu_limit, memory_limit, cpu_request, memory_request, helm_* |

## 📁 Configuration Scenarios

### Scenario 1: Raspberry Pi Homelab

```hcl
base_domain = "local"
platform_name = "k3s"
cpu_arch = "arm64"
use_nfs_storage = false
use_hostpath_storage = true

services = {
  traefik = true
  metallb = true
  host_path = true
  prometheus = true
  grafana = true
  loki = false      # Disable resource-intensive services
  consul = false
  vault = false
  portainer = true
}
```

### Scenario 2: Mixed Architecture Production

```hcl
base_domain = "example.com"
platform_name = "k3s"
cpu_arch = ""                     # Auto-detect
auto_mixed_cluster_mode = true
use_nfs_storage = true
le_email = "admin@example.com"

cpu_arch_override = {
  traefik = "amd64"              # Performance critical
  prometheus = "amd64"           # Resource intensive
  grafana = "arm64"              # UI services
  portainer = "arm64"
}

# All services enabled for production
services = {
  traefik = true
  metallb = true
  nfs_csi = true
  prometheus = true
  grafana = true
  loki = true
  consul = true
  vault = true
  portainer = true
}
```

### Scenario 3: Cloud Development

```hcl
base_domain = "dev.example.com"
platform_name = "eks"
cpu_arch = ""
use_nfs_storage = false           # Use cloud storage
le_email = "dev-team@example.com"

services = {
  traefik = true
  metallb = false                 # Use cloud load balancer
  prometheus = true
  grafana = true
  loki = true
  consul = true
  vault = true
  gatekeeper = false              # Disable policies in dev
  portainer = true
}
```
