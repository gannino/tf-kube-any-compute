# Kube-State-Metrics Helm Module

This module deploys [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics) to provide comprehensive Kubernetes cluster metrics for Prometheus monitoring.

## Features

- **Comprehensive Metrics**: Exposes detailed metrics about Kubernetes objects
- **Architecture Support**: ARM64/AMD64 with intelligent scheduling
- **Resource Management**: Configurable resource limits and requests
- **High Availability**: Pod disruption budgets and anti-affinity rules
- **Security**: Non-root containers with security contexts
- **Prometheus Integration**: ServiceMonitor for automatic discovery

## Metrics Provided

Kube-state-metrics exposes metrics for:

- **Workloads**: Deployments, StatefulSets, DaemonSets, Jobs, CronJobs
- **Pods**: Pod status, resource usage, conditions
- **Nodes**: Node status, capacity, allocatable resources
- **Storage**: PersistentVolumes, PersistentVolumeClaims, StorageClasses
- **Networking**: Services, Ingresses, NetworkPolicies
- **Configuration**: ConfigMaps, Secrets, ResourceQuotas
- **RBAC**: ServiceAccounts, Roles, RoleBindings
- **Autoscaling**: HorizontalPodAutoscalers

## Usage

```hcl
module "kube_state_metrics" {
  source = "./helm-kube-state-metrics"

  name      = "kube-state-metrics"
  namespace = "kube-state-metrics-system"

  # Architecture configuration
  cpu_arch = "arm64"

  # Resource configuration
  cpu_limit      = "100m"
  memory_limit   = "128Mi"
  cpu_request    = "50m"
  memory_request = "64Mi"
}
```

## Configuration

### Basic Configuration

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `name` | Helm release name | `kube-state-metrics` | No |
| `namespace` | Kubernetes namespace | `kube-state-metrics-system` | No |
| `cpu_arch` | CPU architecture (amd64/arm64) | `amd64` | No |

### Resource Configuration

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `cpu_limit` | CPU limit | `100m` | No |
| `memory_limit` | Memory limit | `128Mi` | No |
| `cpu_request` | CPU request | `50m` | No |
| `memory_request` | Memory request | `64Mi` | No |

### Helm Configuration

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `chart_version` | Helm chart version | `5.15.2` | No |
| `helm_timeout` | Deployment timeout (seconds) | `300` | No |
| `helm_wait` | Wait for deployment | `false` | No |

## Outputs

| Output | Description |
|--------|-------------|
| `namespace` | Deployment namespace |
| `service_name` | Service name |
| `service_port` | Service port |
| `metrics_endpoint` | Metrics endpoint URL |
| `helm_release_name` | Helm release name |
| `helm_release_status` | Helm release status |

## Architecture Support

This module supports both ARM64 and AMD64 architectures with intelligent node scheduling:

- **ARM64**: Optimized for Raspberry Pi clusters
- **AMD64**: Standard x86_64 deployments
- **Mixed Clusters**: Automatic architecture detection

## Security

- Non-root containers (UID 65534)
- Security contexts enabled
- RBAC with minimal required permissions
- Pod security contexts

## Monitoring Integration

The module automatically configures:

- ServiceMonitor for Prometheus Operator
- Prometheus annotations for scraping
- Comprehensive metric collection
- Self-monitoring capabilities

## High Availability

- Pod disruption budgets
- Anti-affinity rules
- Tolerations for control plane nodes
- Health checks and probes

## Troubleshooting

### Common Issues

1. **Metrics not appearing**: Check ServiceMonitor configuration
2. **High memory usage**: Adjust collectors or metric allowlists
3. **Permission errors**: Verify RBAC configuration

### Debug Commands

```bash
# Check pod status
kubectl get pods -n kube-state-metrics-system

# Check metrics endpoint
kubectl port-forward -n kube-state-metrics-system svc/kube-state-metrics 8080:8080
curl http://localhost:8080/metrics

# Check ServiceMonitor
kubectl get servicemonitor -n kube-state-metrics-system
```

## Contributing

Please follow the project's contribution guidelines when making changes to this module.

<!-- BEGIN_TF_DOCS -->


## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.14 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 3.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | 3.0.2 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.38.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.this](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_limit_range.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/limit_range) | resource |
| [kubernetes_namespace.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_chart_name"></a> [chart\_name](#input\_chart\_name) | Helm chart name for kube-state-metrics. | `string` | `"kube-state-metrics"` | no |
| <a name="input_chart_repo"></a> [chart\_repo](#input\_chart\_repo) | Helm repository URL for kube-state-metrics charts. | `string` | `"https://prometheus-community.github.io/helm-charts"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Helm chart version for kube-state-metrics. | `string` | `"5.15.2"` | no |
| <a name="input_cpu_arch"></a> [cpu\_arch](#input\_cpu\_arch) | CPU architecture for container images (amd64, arm64). | `string` | `"amd64"` | no |
| <a name="input_cpu_limit"></a> [cpu\_limit](#input\_cpu\_limit) | CPU limit for kube-state-metrics containers. | `string` | `"100m"` | no |
| <a name="input_cpu_request"></a> [cpu\_request](#input\_cpu\_request) | CPU request for kube-state-metrics containers. | `string` | `"50m"` | no |
| <a name="input_disable_arch_scheduling"></a> [disable\_arch\_scheduling](#input\_disable\_arch\_scheduling) | Disable architecture-based scheduling (useful for development). | `bool` | `false` | no |
| <a name="input_helm_cleanup_on_fail"></a> [helm\_cleanup\_on\_fail](#input\_helm\_cleanup\_on\_fail) | Cleanup resources on deployment failure. | `bool` | `false` | no |
| <a name="input_helm_disable_webhooks"></a> [helm\_disable\_webhooks](#input\_helm\_disable\_webhooks) | Disable webhooks for Helm release. | `bool` | `false` | no |
| <a name="input_helm_force_update"></a> [helm\_force\_update](#input\_helm\_force\_update) | Force resource updates if needed. | `bool` | `false` | no |
| <a name="input_helm_replace"></a> [helm\_replace](#input\_helm\_replace) | Allow Helm to replace existing resources. | `bool` | `false` | no |
| <a name="input_helm_skip_crds"></a> [helm\_skip\_crds](#input\_helm\_skip\_crds) | Skip CRDs for Helm release. | `bool` | `false` | no |
| <a name="input_helm_timeout"></a> [helm\_timeout](#input\_helm\_timeout) | Timeout for Helm deployment in seconds. | `number` | `300` | no |
| <a name="input_helm_wait"></a> [helm\_wait](#input\_helm\_wait) | Wait for Helm release to be ready. | `bool` | `false` | no |
| <a name="input_helm_wait_for_jobs"></a> [helm\_wait\_for\_jobs](#input\_helm\_wait\_for\_jobs) | Wait for Helm jobs to complete. | `bool` | `false` | no |
| <a name="input_memory_limit"></a> [memory\_limit](#input\_memory\_limit) | Memory limit for kube-state-metrics containers. | `string` | `"128Mi"` | no |
| <a name="input_memory_request"></a> [memory\_request](#input\_memory\_request) | Memory request for kube-state-metrics containers. | `string` | `"64Mi"` | no |
| <a name="input_name"></a> [name](#input\_name) | Helm release name for kube-state-metrics. | `string` | `"kube-state-metrics"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace for kube-state-metrics. | `string` | `"kube-state-metrics-system"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_helm_release_name"></a> [helm\_release\_name](#output\_helm\_release\_name) | Helm release name |
| <a name="output_helm_release_status"></a> [helm\_release\_status](#output\_helm\_release\_status) | Helm release status |
| <a name="output_metrics_endpoint"></a> [metrics\_endpoint](#output\_metrics\_endpoint) | Metrics endpoint for kube-state-metrics |
| <a name="output_namespace"></a> [namespace](#output\_namespace) | Namespace where kube-state-metrics is deployed |
| <a name="output_service_name"></a> [service\_name](#output\_service\_name) | Service name for kube-state-metrics |
| <a name="output_service_port"></a> [service\_port](#output\_service\_port) | Service port for kube-state-metrics |

<!-- END_TF_DOCS -->
