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

<!-- BEGIN_TF_DOCS -->


## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | >= 2.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >= 2.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.this](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_cluster_role.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cluster_role) | resource |
| [kubernetes_cluster_role_binding.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cluster_role_binding) | resource |
| [kubernetes_limit_range.namespace_limits](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/limit_range) | resource |
| [kubernetes_namespace.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_service_account.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_scrape_configs"></a> [additional\_scrape\_configs](#input\_additional\_scrape\_configs) | Additional scrape configurations for Promtail | <pre>list(object({<br/>    job_name = string<br/>    static_configs = list(object({<br/>      targets = list(string)<br/>      labels  = map(string)<br/>    }))<br/>    pipeline_stages = optional(list(any), [])<br/>  }))</pre> | `[]` | no |
| <a name="input_affinity"></a> [affinity](#input\_affinity) | Affinity rules for Promtail pods | `any` | `{}` | no |
| <a name="input_chart_name"></a> [chart\_name](#input\_chart\_name) | Helm chart name | `string` | `"promtail"` | no |
| <a name="input_chart_repo"></a> [chart\_repo](#input\_chart\_repo) | Helm repository URL | `string` | `"https://grafana.github.io/helm-charts"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Helm chart version for Promtail | `string` | `"6.16.6"` | no |
| <a name="input_container_default_cpu"></a> [container\_default\_cpu](#input\_container\_default\_cpu) | Default CPU for containers | `string` | `"200m"` | no |
| <a name="input_container_default_memory"></a> [container\_default\_memory](#input\_container\_default\_memory) | Default memory for containers | `string` | `"256Mi"` | no |
| <a name="input_container_max_cpu"></a> [container\_max\_cpu](#input\_container\_max\_cpu) | Maximum CPU for containers | `string` | `"1000m"` | no |
| <a name="input_container_max_memory"></a> [container\_max\_memory](#input\_container\_max\_memory) | Maximum memory for containers | `string` | `"1Gi"` | no |
| <a name="input_container_request_cpu"></a> [container\_request\_cpu](#input\_container\_request\_cpu) | Default CPU request for containers | `string` | `"50m"` | no |
| <a name="input_container_request_memory"></a> [container\_request\_memory](#input\_container\_request\_memory) | Default memory request for containers | `string` | `"64Mi"` | no |
| <a name="input_cpu_arch"></a> [cpu\_arch](#input\_cpu\_arch) | [DEPRECATED] CPU architecture - use node\_selector instead | `string` | `"amd64"` | no |
| <a name="input_cpu_limit"></a> [cpu\_limit](#input\_cpu\_limit) | [DEPRECATED] CPU limit - use resource\_limits instead | `string` | `"100m"` | no |
| <a name="input_cpu_request"></a> [cpu\_request](#input\_cpu\_request) | [DEPRECATED] CPU request - use resource\_limits instead | `string` | `"50m"` | no |
| <a name="input_helm_cleanup_on_fail"></a> [helm\_cleanup\_on\_fail](#input\_helm\_cleanup\_on\_fail) | Cleanup on fail | `bool` | `true` | no |
| <a name="input_helm_disable_webhooks"></a> [helm\_disable\_webhooks](#input\_helm\_disable\_webhooks) | Disable webhooks | `bool` | `true` | no |
| <a name="input_helm_force_update"></a> [helm\_force\_update](#input\_helm\_force\_update) | Force update | `bool` | `true` | no |
| <a name="input_helm_replace"></a> [helm\_replace](#input\_helm\_replace) | Replace resources | `bool` | `false` | no |
| <a name="input_helm_skip_crds"></a> [helm\_skip\_crds](#input\_helm\_skip\_crds) | Skip CRDs | `bool` | `false` | no |
| <a name="input_helm_timeout"></a> [helm\_timeout](#input\_helm\_timeout) | Helm timeout | `number` | `300` | no |
| <a name="input_helm_wait"></a> [helm\_wait](#input\_helm\_wait) | Wait for deployment | `bool` | `true` | no |
| <a name="input_helm_wait_for_jobs"></a> [helm\_wait\_for\_jobs](#input\_helm\_wait\_for\_jobs) | Wait for jobs | `bool` | `true` | no |
| <a name="input_limit_range_enabled"></a> [limit\_range\_enabled](#input\_limit\_range\_enabled) | Enable limit range for the namespace | `bool` | `true` | no |
| <a name="input_log_level"></a> [log\_level](#input\_log\_level) | Log level for Promtail | `string` | `"info"` | no |
| <a name="input_loki_url"></a> [loki\_url](#input\_loki\_url) | Loki endpoint URL for log forwarding | `string` | `"http://loki:3100"` | no |
| <a name="input_memory_limit"></a> [memory\_limit](#input\_memory\_limit) | [DEPRECATED] Memory limit - use resource\_limits instead | `string` | `"128Mi"` | no |
| <a name="input_memory_request"></a> [memory\_request](#input\_memory\_request) | [DEPRECATED] Memory request - use resource\_limits instead | `string` | `"64Mi"` | no |
| <a name="input_name"></a> [name](#input\_name) | Helm release name | `string` | `"promtail"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Kubernetes namespace for Promtail deployment | `string` | `"loki-system"` | no |
| <a name="input_node_selector"></a> [node\_selector](#input\_node\_selector) | Node selector for Promtail pods | `map(string)` | `{}` | no |
| <a name="input_persistence"></a> [persistence](#input\_persistence) | Persistence configuration for Promtail positions | <pre>object({<br/>    enabled       = optional(bool, true)<br/>    size          = optional(string, "10Gi")<br/>    storage_class = optional(string, "")<br/>  })</pre> | <pre>{<br/>  "enabled": true,<br/>  "size": "10Gi",<br/>  "storage_class": ""<br/>}</pre> | no |
| <a name="input_pvc_max_storage"></a> [pvc\_max\_storage](#input\_pvc\_max\_storage) | Maximum storage for PVCs | `string` | `"100Gi"` | no |
| <a name="input_pvc_min_storage"></a> [pvc\_min\_storage](#input\_pvc\_min\_storage) | Minimum storage for PVCs | `string` | `"1Gi"` | no |
| <a name="input_resource_limits"></a> [resource\_limits](#input\_resource\_limits) | Resource limits and requests for Promtail pods | <pre>object({<br/>    requests = object({<br/>      cpu    = string<br/>      memory = string<br/>    })<br/>    limits = object({<br/>      cpu    = string<br/>      memory = string<br/>    })<br/>  })</pre> | <pre>{<br/>  "limits": {<br/>    "cpu": "100m",<br/>    "memory": "128Mi"<br/>  },<br/>  "requests": {<br/>    "cpu": "50m",<br/>    "memory": "64Mi"<br/>  }<br/>}</pre> | no |
| <a name="input_security_context"></a> [security\_context](#input\_security\_context) | Security context for Promtail containers | <pre>object({<br/>    run_as_user               = optional(number, 0)<br/>    run_as_group              = optional(number, 0)<br/>    run_as_non_root           = optional(bool, true)<br/>    read_only_root_filesystem = optional(bool, true)<br/>    privileged                = optional(bool, false)<br/>  })</pre> | <pre>{<br/>  "privileged": false,<br/>  "read_only_root_filesystem": true,<br/>  "run_as_group": 0,<br/>  "run_as_non_root": true,<br/>  "run_as_user": 0<br/>}</pre> | no |
| <a name="input_service_monitor_enabled"></a> [service\_monitor\_enabled](#input\_service\_monitor\_enabled) | Enable ServiceMonitor for Prometheus scraping | `bool` | `true` | no |
| <a name="input_service_overrides"></a> [service\_overrides](#input\_service\_overrides) | Override default service configuration for backward compatibility | <pre>object({<br/>    helm_config = optional(object({<br/>      name      = optional(string)<br/>      namespace = optional(string)<br/>      resource_limits = optional(object({<br/>        requests = optional(object({<br/>          cpu    = optional(string)<br/>          memory = optional(string)<br/>        }))<br/>        limits = optional(object({<br/>          cpu    = optional(string)<br/>          memory = optional(string)<br/>        }))<br/>      }))<br/>    }))<br/>    labels          = optional(map(string))<br/>    template_values = optional(map(any))<br/>  })</pre> | `{}` | no |
| <a name="input_tolerations"></a> [tolerations](#input\_tolerations) | Tolerations for Promtail pods | <pre>list(object({<br/>    key      = optional(string)<br/>    operator = optional(string, "Equal")<br/>    value    = optional(string)<br/>    effect   = optional(string)<br/>  }))</pre> | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_app_version"></a> [app\_version](#output\_app\_version) | App version of the deployed Promtail (if available) |
| <a name="output_chart_metadata"></a> [chart\_metadata](#output\_chart\_metadata) | Metadata of the deployed chart |
| <a name="output_cluster_role_name"></a> [cluster\_role\_name](#output\_cluster\_role\_name) | Name of the created ClusterRole |
| <a name="output_loki_endpoint"></a> [loki\_endpoint](#output\_loki\_endpoint) | Configured Loki endpoint |
| <a name="output_monitoring_labels"></a> [monitoring\_labels](#output\_monitoring\_labels) | Labels used for monitoring and service discovery |
| <a name="output_namespace"></a> [namespace](#output\_namespace) | Namespace where Promtail is deployed |
| <a name="output_release_name"></a> [release\_name](#output\_release\_name) | Name of the Helm release |
| <a name="output_release_namespace"></a> [release\_namespace](#output\_release\_namespace) | Namespace of the Promtail deployment |
| <a name="output_release_status"></a> [release\_status](#output\_release\_status) | Status of the Helm release |
| <a name="output_release_version"></a> [release\_version](#output\_release\_version) | Version of the deployed Helm chart |
| <a name="output_service_account_name"></a> [service\_account\_name](#output\_service\_account\_name) | Name of the created ServiceAccount |

<!-- END_TF_DOCS -->
