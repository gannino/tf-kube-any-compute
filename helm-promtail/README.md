# Promtail Helm Module

This Terraform module deploys Promtail using the official Grafana Helm chart for log collection and forwarding to Loki.

## Features

- **🚀 Helm Chart Deployment**: Uses official Grafana Helm charts
- **⚙️ Configurable Resources**: CPU and memory limits/requests with validation
- **🔧 Custom Scrape Configs**: Support for additional log sources
- **📍 Node Scheduling**: Node selectors, tolerations, and affinity rules
- **🔒 Security**: Read-only filesystem and configurable security context
- **📊 Monitoring**: ServiceMonitor for Prometheus integration
- **🎯 Production Ready**: Lifecycle management and error handling
- **🔄 RBAC**: Proper ServiceAccount, ClusterRole, and ClusterRoleBinding setup

## Usage

### Basic Usage

```hcl
module "promtail" {
  source = "./helm-promtail"
  
  namespace = "monitoring"
  loki_url  = "http://loki.monitoring.svc.cluster.local:3100"
}
```

### Advanced Configuration

```hcl
module "promtail" {
  source = "./helm-promtail"
  
  namespace     = "monitoring"
  chart_version = "6.16.6"
  loki_url      = "http://loki.monitoring.svc.cluster.local:3100"
  
  resource_limits = {
    requests = {
      cpu    = "100m"
      memory = "128Mi"
    }
    limits = {
      cpu    = "200m"
      memory = "256Mi"
    }
  }
  
  additional_scrape_configs = [
    {
      job_name = "custom-app"
      static_configs = [{
        targets = ["localhost:8080"]
        labels  = {
          app = "custom-app"
          env = "production"
        }
      }]
      pipeline_stages = []
    }
  ]
  
  security_context = {
    run_as_user                = 0
    run_as_group               = 0
    run_as_non_root           = true
    read_only_root_filesystem = true
    privileged                = false
  }
  
  persistence = {
    enabled       = true
    size          = "10Gi"
    storage_class = "fast-ssd"
  }
  
  log_level = "debug"
  service_monitor_enabled = true
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

| Type | Name |
|------|------|
| kubernetes_namespace.this | Namespace for Promtail (conditional) |
| kubernetes_service_account.this | ServiceAccount for Promtail |
| kubernetes_cluster_role.this | ClusterRole for log access |
| kubernetes_cluster_role_binding.this | ClusterRoleBinding |
| helm_release.this | Promtail Helm release |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| namespace | Kubernetes namespace for Promtail deployment | `string` | `"loki-system"` | no |
| name | Helm release name | `string` | `"promtail"` | no |
| chart_name | Helm chart name | `string` | `"promtail"` | no |
| chart_repo | Helm repository URL | `string` | `"https://grafana.github.io/helm-charts"` | no |
| chart_version | Helm chart version | `string` | `"6.16.6"` | no |
| loki_url | Loki endpoint URL for log forwarding | `string` | `"http://loki:3100"` | no |
| additional_scrape_configs | Additional scrape configurations | `list(object)` | `[]` | no |
| resource_limits | Resource limits and requests | `object` | See variables.tf | no |
| node_selector | Node selector for pod scheduling | `map(string)` | `{}` | no |
| tolerations | Tolerations for pod scheduling | `list(object)` | `[]` | no |
| affinity | Affinity rules for pod scheduling | `any` | `{}` | no |
| service_monitor_enabled | Enable ServiceMonitor for Prometheus | `bool` | `true` | no |
| security_context | Security context for containers | `object` | See variables.tf | no |
| log_level | Log level for Promtail | `string` | `"info"` | no |
| persistence | Persistence configuration | `object` | See variables.tf | no |

## Outputs

| Name | Description |
|------|-------------|
| namespace | Namespace where Promtail is deployed |
| release_name | Name of the Helm release |
| release_namespace | Namespace of the deployment |
| release_version | Version of the deployed chart |
| release_status | Status of the Helm release |
| app_version | App version of deployed Promtail (if available) |
| chart_metadata | Complete chart metadata |
| service_account_name | Name of the created ServiceAccount |
| cluster_role_name | Name of the created ClusterRole |
| loki_endpoint | Configured Loki endpoint (sensitive) |
| monitoring_labels | Labels used for monitoring |

## Configuration Details

### Resource Limits

The module accepts resource limits in standard Kubernetes format:

```hcl
resource_limits = {
  requests = {
    cpu    = "100m"     # 100 millicores
    memory = "128Mi"    # 128 mebibytes
  }
  limits = {
    cpu    = "500m"     # 500 millicores
    memory = "512Mi"    # 512 mebibytes
  }
}
```

### Security Context

Configurable security settings:

```hcl
security_context = {
  run_as_user                = 1000
  run_as_group               = 1000
  run_as_non_root           = true
  read_only_root_filesystem = true
  privileged                = false
}
```

### RBAC

The module creates:

- **ServiceAccount**: For Promtail pods
- **ClusterRole**: With permissions to read pods, services, nodes
- **ClusterRoleBinding**: Binds the ServiceAccount to ClusterRole

## Migration from Legacy Variables

If you're using the deprecated variables, migrate as follows:

```hcl
# Old way (deprecated)
cpu_arch       = "amd64"
cpu_limit      = "200m"
memory_limit   = "256Mi"
cpu_request    = "100m"
memory_request = "128Mi"

# New way (recommended)
node_selector = {
  "kubernetes.io/arch" = "amd64"
}
resource_limits = {
  requests = {
    cpu    = "100m"
    memory = "128Mi"
  }
  limits = {
    cpu    = "200m"
    memory = "256Mi"
  }
}
```

## Troubleshooting

### Common Issues

1. **Permission Denied Errors**: Ensure the security context allows reading log files
2. **Pod Scheduling Issues**: Check node selectors and tolerations
3. **Connection to Loki Failed**: Verify the `loki_url` is correct and accessible
4. **High Memory Usage**: Adjust resource limits and review scrape configurations

### Debug Mode

Enable debug logging:

```hcl
log_level = "debug"
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

MIT
