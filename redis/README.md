# Redis Module

A Terraform module for deploying Redis on Kubernetes using native Kubernetes resources (Deployment, Service, ConfigMap, PVC). This module provides a lightweight, production-ready Redis deployment with support for persistent storage, Prometheus monitoring, and multi-architecture (ARM64/AMD64) clusters.

## Features

- **Native Kubernetes Deployment**: Uses `redis:7.2-alpine` Docker image directly
- **Multi-Architecture Support**: ARM64 and AMD64 with auto-detection
- **Persistent Storage**: Optional PVC with configurable storage class
- **Prometheus Integration**: Optional ServiceMonitor for metrics
- **Resource Limits**: Configurable CPU and memory constraints
- **Security Hardened**: Runs as non-root user with proper security contexts
- **Health Checks**: Built-in liveness and readiness probes
- **Standalone Mode**: Single-instance deployment (no clustering overhead)

## Requirements

| Name | Version |
|------|----------|
| Terraform | >= 1.0 |
| Kubernetes Provider | ~> 2.31 |

## Usage

### Basic Deployment

```hcl
module "redis" {
  source = "./redis"

  enable_persistence = true
  storage_class      = "nfs-csi-safe"
  storage_size       = "8Gi"
}
```

### With Prometheus Monitoring

```hcl
module "redis" {
  source = "./redis"

  enable_persistence    = true
  enable_servicemonitor = true
  servicemonitor_namespace = "monitoring"
}
```

### Resource-Constrained Deployment

```hcl
module "redis" {
  source = "./redis"

  cpu_limit      = "200m"
  memory_limit   = "256Mi"
  cpu_request    = "50m"
  memory_request = "64Mi"
  storage_size    = "4Gi"
}
```

### ARM64-Specific Deployment

```hcl
module "redis" {
  source = "./redis"

  cpu_arch = "arm64"
  enable_persistence = true
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `namespace` | Kubernetes namespace for Redis | `string` | `"redis-system"` | no |
| `name` | Resource name for Redis deployment | `string` | `"redis"` | no |
| `enable_persistence` | Enable persistent storage for Redis data | `bool` | `true` | no |
| `storage_class` | Storage class for Redis PVC (auto-detect if empty) | `string` | `""` | no |
| `storage_size` | Persistent volume size for Redis data | `string` | `"8Gi"` | no |
| `cpu_limit` | CPU limit for Redis containers | `string` | `"300m"` | no |
| `memory_limit` | Memory limit for Redis containers | `string` | `"512Mi"` | no |
| `cpu_request` | CPU request for Redis containers | `string` | `"100m"` | no |
| `memory_request` | Memory request for Redis containers | `string` | `"128Mi"` | no |
| `cpu_arch` | CPU architecture for node scheduling (auto-detect if empty) | `string` | `""` | no |
| `disable_arch_scheduling` | Disable architecture-based node scheduling | `bool` | `false` | no |
| `enable_servicemonitor` | Enable Prometheus ServiceMonitor for Redis metrics | `bool` | `false` | no |
| `servicemonitor_namespace` | Namespace for ServiceMonitor resource | `string` | `"monitoring"` | no |

## Outputs

| Name | Description |
|------|-------------|
| `namespace` | Kubernetes namespace where Redis is deployed |
| `deployment_name` | Redis deployment name |
| `service_name` | Redis service name (for connection strings) |
| `service_host` | Redis service host (for connection strings) |
| `service_port` | Redis service port |
| `connection_string` | Full Redis connection string (host:port) |
| `configmap_name` | Redis ConfigMap name |
| `pvc_name` | Persistent volume claim name (if enabled) |
| `storage_enabled` | Whether persistent storage is enabled |
| `storage_class` | Storage class used for PVC |
| `cpu_arch` | CPU architecture for node scheduling |
| `resource_limits` | Resource limits applied to Redis |
| `resource_requests` | Resource requests applied to Redis |
| `redis_image` | Redis Docker image used |
| `servicemonitor_enabled` | Whether Prometheus ServiceMonitor is enabled |

## Connecting to Redis

### From Within the Cluster

Use the `connection_string` output:

```hcl
redis_addr = module.redis[0].connection_string
# Result: redis.redis-system.svc.cluster.local:6379
```

### Example: Authelia Integration

```hcl
service_overrides = {
  authelia = {
    redis_enabled = true
    redis_address = "redis://${module.redis[0].service_host}:${module.redis[0].service_port}"
  }
}
```

### Example: Custom Application

```bash
REDIS_ADDR=$(terraform output -raw redis_connection_string)
# Connect: redis-cli -h $REDIS_ADDR
```

## Storage Considerations

- **Single-Node Clusters**: Use `hostpath` storage class for best performance
- **Multi-Node Clusters**: Use NFS CSI or other network storage for data availability
- **Persistent Volume Claims**: Created with `Retain` policy for data safety

## Architecture Support

| Architecture | Status | Notes |
|--------------|--------|-------|
| AMD64 (x86_64) | ✅ Fully Supported | Native performance |
| ARM64 | ✅ Fully Supported | Redis Alpine images support ARM64 |
| Mixed Clusters | ✅ Supported | Use `cpu_arch` for node pinning |

## Resource Recommendations

| Use Case | CPU Limit | Memory Limit | Storage |
|----------|-----------|--------------|---------|
| Development/Lab | 200m | 256Mi | 4Gi |
| Production | 500m | 1Gi | 8Gi+ |
| High-Traffic | 1000m | 2Gi | 16Gi+ |

## Monitoring

When `enable_servicemonitor = true`, a Prometheus ServiceMonitor is created for Redis metrics collection.

**Note**: The native Redis image does not include a metrics exporter. To enable full metrics collection, consider:

1. **Using a sidecar container** with redis_exporter
2. **Deploying a separate redis_exporter** ServiceMonitor
3. **Enabling Redis INFO command** monitoring through custom probes

The ServiceMonitor created by this module expects metrics to be available on the Redis service port.

For complete metrics support, consider using the Bitnami Redis chart which includes redis_exporter by default.

## Troubleshooting

### Redis Pod Not Starting

```bash
kubectl get pods -n redis-system
kubectl describe pod <redis-pod-name> -n redis-system
kubectl logs <redis-pod-name> -n redis-system
```

### Connection Refused

Verify the service and port:

```bash
kubectl get svc redis -n redis-system
kubectl exec -it <pod-name> -n redis-system -- redis-cli ping
```

### Storage Issues

Check PVC binding:

```bash
kubectl get pvc -n redis-system
kubectl describe pvc redis-redis-0 -n redis-system
```

## Maintenance

### Upgrading Redis Version

To upgrade to a newer Redis version, modify the image tag in `main.tf`:

```hcl
image = "redis:7.2-alpine"  # Change to newer version like "redis:7.4-alpine"
```

Then apply the changes:

```bash
terraform plan
terraform apply
```

### Backup and Restore

For persistence-enabled deployments:

```bash
# Backup
kubectl exec -n redis-system deployment/redis -- redis-cli SAVE
kubectl cp redis-system/<redis-pod>:/data/dump.rdb ./backup.rdb

# Restore
kubectl cp ./backup.rdb redis-system/<redis-pod>:/data/dump.rdb
kubectl exec -n redis-system deployment/redis -- redis-cli FLUSHALL
kubectl exec -n redis-system deployment/redis -- redis-cli DEBUG RELOAD
```

## License

This module is part of the tf-kube-any-compute project.

## Additional Resources

- [Redis Official Docker Image](https://hub.docker.com/_/redis)
- [Redis Documentation](https://redis.io/documentation/)
- [Redis Exporter for Prometheus](https://github.com/oliver006/redis_exporter)
- [tf-kube-any-compute Documentation](../../README.md)

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
