# Headlamp Module

[Headlamp](https://headlamp.dev/) is a modern, web-based Kubernetes user interface that provides an intuitive dashboard for managing Kubernetes clusters. It offers a cleaner alternative to the Kubernetes Dashboard with better usability and more features.

## Features

- **Modern UI**: Intuitive, responsive web interface
- **Multi-cluster Support**: Manage multiple Kubernetes clusters from one interface
- **Real-time Updates**: Live updates of cluster state
- **Plugin System**: Extensible architecture with plugins for:
  - KubeVirt (virtual machine management)
  - Helm (chart management)
  - Tekton (CI/CD pipelines)
  - ArgoCD (GitOps)
  - Custom plugins
- **Resource Management**: View and edit pods, deployments, services, and more
- **Logs & Terminal**: Built-in pod logs and terminal access
- **YAML Editor**: Edit Kubernetes resources directly

## Architecture Support

This module is optimized for:
- **ARM64**: Raspberry Pi, ARM-based servers
- **AMD64**: Intel/AMD servers and cloud instances
- **Mixed Clusters**: Automatic architecture detection and placement

## Variables

### Core Configuration

| Variable | Type | Default | Description |
|-----------|------|----------|-------------|
| `namespace` | string | `headlamp-system` | Kubernetes namespace |
| `name` | string | `headlamp` | Headlamp deployment name |
| `chart_repo` | string | `https://headlamp.k8s.io` | Helm chart repository |
| `chart_name` | string | `headlamp` | Helm chart name |
| `chart_version` | string | `0.39.0` | Helm chart version |
| `domain_name` | string | `local` | Base domain for ingress |
| `cpu_arch` | string | `""` | CPU architecture (auto-detect if empty) |

### Ingress Configuration

| Variable | Type | Default | Description |
|-----------|------|----------|-------------|
| `enable_headlamp_ingress` | bool | `true` | Enable Traefik ingress |
| `traefik_ingress_config` | object | `null` | Traefik ingress configuration |
| `cert_resolver` | string | `""` | Certificate resolver for SSL |
| `traefik_middleware` | list(string) | `[]` | Traefik middleware names |

### Storage Configuration

| Variable | Type | Default | Description |
|-----------|------|----------|-------------|
| `enable_persistence` | bool | `true` | Enable persistent storage |
| `storage_class` | string | `""` | Storage class (auto-detect if empty) |
| `persistent_disk_size` | string | `1Gi` | Persistent volume size |

### Plugin Configuration

| Variable | Type | Default | Description |
|-----------|------|----------|-------------|
| `enabled_plugins` | list(string) | `[]` | List of plugins to enable |
| `kubevirt_enabled` | bool | `false` | Auto-enable KubeVirt plugin |

### Resource Configuration

| Variable | Type | Default | Description |
|-----------|------|----------|-------------|
| `cpu_limit` | string | `200m` | CPU limit |
| `memory_limit` | string | `256Mi` | Memory limit |
| `cpu_request` | string | `100m` | CPU request |
| `memory_request` | string | `128Mi` | Memory request |

### Helm Configuration

| Variable | Type | Default | Description |
|-----------|------|----------|-------------|
| `helm_timeout` | number | `300` | Helm deployment timeout (seconds) |
| `helm_wait` | bool | `true` | Wait for deployment to complete |
| `helm_wait_for_jobs` | bool | `false` | Wait for jobs to complete |
| `helm_disable_webhooks` | bool | `true` | Disable Helm webhooks |
| `helm_skip_crds` | bool | `false` | Skip CRD installation |
| `helm_replace` | bool | `true` | Replace existing resources |
| `helm_force_update` | bool | `true` | Force update on release |
| `helm_cleanup_on_fail` | bool | `true` | Cleanup on failure |

### Advanced Configuration

| Variable | Type | Default | Description |
|-----------|------|----------|-------------|
| `disable_arch_scheduling` | bool | `false` | Disable architecture-based scheduling |
| `enable_resource_limits` | bool | `true` | Enable resource limits |

## Outputs

| Output | Description |
|--------|-------------|
| `namespace` | Kubernetes namespace |
| `name` | Headlamp release name |
| `url` | URL to access Headlamp UI |
| `cluster_ip` | Cluster service endpoint |
| `helm_status` | Helm release status |
| `enabled_plugins` | List of enabled plugins |
| `storage_enabled` | Whether persistence is enabled |
| `storage_class` | Storage class used |
| `cpu_arch` | CPU architecture used |
| `resource_limits` | Applied resource limits |
| `resource_requests` | Applied resource requests |
| `ingress_enabled` | Whether ingress is enabled |
| `traefik_middleware_applied` | Applied Traefik middleware |

## Usage Examples

### Basic Deployment

```hcl
module "headlamp" {
  source = "./modules/helm-headlamp"

  namespace = "headlamp-system"
  name      = "headlamp"
  domain_name = var.domain_name

  enable_persistence = true
}
```

### With Traefik Ingress

```hcl
module "headlamp" {
  source = "./modules/helm-headlamp"

  namespace = "headlamp-system"
  name      = "headlamp"
  domain_name = var.domain_name

  enable_headlamp_ingress = true
  traefik_ingress_config = {
    class_name = "traefik"
  }
  cert_resolver     = "hurricane"
  traefik_middleware = ["headlamp-auth"]
}
```

### With KubeVirt Plugin

```hcl
module "headlamp" {
  source = "./modules/helm-headlamp"

  namespace = "headlamp-system"
  name      = "headlamp"
  domain_name = var.domain_name

  kubevirt_enabled = true
  # KubeVirt plugin will be automatically enabled
}
```

### With Custom Plugins

```hcl
module "headlamp" {
  source = "./modules/helm-headlamp"

  namespace = "headlamp-system"
  name      = "headlamp"
  domain_name = var.domain_name

  enabled_plugins = [
    "helm",
    "tekton",
    "argocd"
  ]
}
```

### Resource-Optimized for Raspberry Pi

```hcl
module "headlamp" {
  source = "./modules/helm-headlamp"

  namespace = "headlamp-system"
  name      = "headlamp"
  domain_name = var.domain_name

  cpu_arch          = "arm64"
  cpu_limit         = "200m"
  memory_limit      = "256Mi"
  enable_persistence = true
  storage_class     = "hostpath"
}
```

### Production Configuration

```hcl
module "headlamp" {
  source = "./modules/helm-headlamp"

  namespace = "headlamp-system"
  name      = "headlamp"
  domain_name = "example.com"

  # Ingress with SSL
  enable_headlamp_ingress = true
  cert_resolver          = "cloudflare"
  traefik_middleware    = ["rate-limit", "ip-whitelist"]

  # Storage
  enable_persistence   = true
  storage_class       = "nfs-csi"
  persistent_disk_size = "2Gi"

  # Resources
  cpu_limit    = "500m"
  memory_limit = "512Mi"

  # Plugins
  kubevirt_enabled = true
  enabled_plugins = [
    "helm",
    "argocd"
  ]
}
```

## Accessing Headlamp

### Via Ingress

If ingress is enabled, access Headlamp at:
```
https://headlamp.{base_domain}
```

### Via Port Forwarding

```bash
kubectl port-forward -n headlamp-system svc/headlamp 8080:80
```

Then open `http://localhost:8080` in your browser.

### Via Service

```
http://headlamp.headlamp-system.svc.cluster.local:80
```

## Plugin System

Headlamp supports plugins to extend functionality. Common plugins include:

### KubeVirt Plugin
Enables virtual machine management within Headlamp. Automatically enabled when `kubevirt_enabled = true`.

### Helm Plugin
Provides Helm chart management capabilities.

```hcl
enabled_plugins = ["helm"]
```

### Tekton Plugin
Adds CI/CD pipeline management with Tekton.

```hcl
enabled_plugins = ["tekton"]
```

### ArgoCD Plugin
Integrates ArgoCD for GitOps workflows.

```hcl
enabled_plugins = ["argocd"]
```

### Custom Plugins
You can add custom plugins by specifying their names in `enabled_plugins`.

## Resource Recommendations

### Raspberry Pi (ARM64)
- **CPU Limit**: 200m-300m
- **Memory Limit**: 256Mi-384Mi
- **Storage**: 1Gi-2Gi
- **Architecture**: arm64

### AMD64 Homelab
- **CPU Limit**: 300m-500m
- **Memory Limit**: 384Mi-512Mi
- **Storage**: 1Gi-2Gi
- **Architecture**: amd64

### Production
- **CPU Limit**: 500m-1000m
- **Memory Limit**: 512Mi-1Gi
- **Storage**: 2Gi-5Gi
- **Architecture**: amd64 or auto-detect

## Troubleshooting

### Headlamp Not Starting

```bash
# Check pod status
kubectl get pods -n headlamp-system

# View logs
kubectl logs -n headlamp-system -l app.kubernetes.io/name=headlamp

# Describe pod
kubectl describe pod -n headlamp-system -l app.kubernetes.io/name=headlamp
```

### Storage Issues

```bash
# Check PVC status
kubectl get pvc -n headlamp-system

# Check storage class
kubectl get storageclass
```

### Ingress Issues

```bash
# Check Traefik ingress routes
kubectl get ingressroute -n headlamp-system

# Check TLS certificates
kubectl get secret -n headlamp-system
```

### Plugin Issues

```bash
# Check enabled plugins
kubectl get configmap -n headlamp-system headlamp-config -o yaml

# Verify plugin availability
kubectl logs -n headlamp-system -l app.kubernetes.io/name=headlamp | grep plugin
```

## Integration with Other Services

### KubeVirt Integration

When KubeVirt is enabled in the main configuration, Headlamp automatically enables the KubeVirt plugin:

```hcl
# In main.tf or locals.tf
kubevirt_enabled = try(var.services.kubevirt, false)

# Headlamp will auto-enable kubevirt plugin
```

### Prometheus Monitoring

Headlamp can be monitored with Prometheus. Ensure Prometheus CRDs are installed:

```hcl
module "prometheus_crds" {
  source = "./modules/helm-prometheus-stack-crds"
}
```

## Security Considerations

1. **Authentication**: Headlamp uses Kubernetes service account authentication. Ensure proper RBAC policies.
2. **Ingress**: Use Traefik middleware for additional security:
   - Basic authentication
   - LDAP integration
   - Rate limiting
   - IP whitelisting
3. **TLS**: Always enable SSL/TLS for production deployments.
4. **Resource Limits**: Apply appropriate resource limits to prevent resource exhaustion.

## Contributing

When contributing to this module:

1. Follow existing code patterns and conventions
2. Add comprehensive variable descriptions
3. Include validation rules where appropriate
4. Update this README with new features
5. Test on both ARM64 and AMD64 architectures

## License

This module is part of the tf-kube-any-compute project. See the main project LICENSE file for details.

## Support

For issues and questions:
- GitHub Issues: [tf-kube-any-compute/issues](https://github.com/gannino/tf-kube-any-compute/issues)
- Headlamp Documentation: [https://headlamp.dev/](https://headlamp.dev/)
<!-- BEGIN_TF_DOCS -->


## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.15.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.31.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | 3.1.1 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 3.0.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.this](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_ingress_v1.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/ingress_v1) | resource |
| [kubernetes_limit_range_v1.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/limit_range_v1) | resource |
| [kubernetes_namespace.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_service.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/service) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_chart_name"></a> [chart\_name](#input\_chart\_name) | Helm chart name for Headlamp. | `string` | `"headlamp"` | no |
| <a name="input_chart_repo"></a> [chart\_repo](#input\_chart\_repo) | Helm repository URL for Headlamp charts. | `string` | `"https://kubernetes-sigs.github.io/headlamp/"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Helm chart version for Headlamp. | `string` | `"0.39.0"` | no |
| <a name="input_cpu_arch"></a> [cpu\_arch](#input\_cpu\_arch) | CPU architecture for container images (amd64, arm64). | `string` | n/a | yes |
| <a name="input_cpu_limit"></a> [cpu\_limit](#input\_cpu\_limit) | CPU limit for Headlamp containers. | `string` | `"200m"` | no |
| <a name="input_cpu_request"></a> [cpu\_request](#input\_cpu\_request) | CPU request for Headlamp containers. | `string` | `"100m"` | no |
| <a name="input_disable_arch_scheduling"></a> [disable\_arch\_scheduling](#input\_disable\_arch\_scheduling) | Disable architecture-based node scheduling. | `bool` | `false` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Domain name for Headlamp ingress. | `string` | `".local"` | no |
| <a name="input_enable_headlamp_ingress"></a> [enable\_headlamp\_ingress](#input\_enable\_headlamp\_ingress) | Enable Headlamp ingress configuration. | `bool` | `true` | no |
| <a name="input_enable_persistence"></a> [enable\_persistence](#input\_enable\_persistence) | Enable persistent storage for Headlamp configuration. | `bool` | `true` | no |
| <a name="input_enabled_plugins"></a> [enabled\_plugins](#input\_enabled\_plugins) | List of Headlamp plugins to enable (e.g., ['kubevirt']). | `list(string)` | `[]` | no |
| <a name="input_helm_cleanup_on_fail"></a> [helm\_cleanup\_on\_fail](#input\_helm\_cleanup\_on\_fail) | Cleanup resources on deployment failure. | `bool` | `false` | no |
| <a name="input_helm_disable_webhooks"></a> [helm\_disable\_webhooks](#input\_helm\_disable\_webhooks) | Disable webhooks for Helm release. | `bool` | `false` | no |
| <a name="input_helm_force_update"></a> [helm\_force\_update](#input\_helm\_force\_update) | Force resource updates if needed. | `bool` | `false` | no |
| <a name="input_helm_replace"></a> [helm\_replace](#input\_helm\_replace) | Allow Helm to replace existing resources. | `bool` | `false` | no |
| <a name="input_helm_skip_crds"></a> [helm\_skip\_crds](#input\_helm\_skip\_crds) | Skip CRDs for Helm release. | `bool` | `false` | no |
| <a name="input_helm_timeout"></a> [helm\_timeout](#input\_helm\_timeout) | Timeout for Helm deployment in seconds. | `number` | `300` | no |
| <a name="input_helm_wait"></a> [helm\_wait](#input\_helm\_wait) | Wait for Helm release to be ready. | `bool` | `false` | no |
| <a name="input_helm_wait_for_jobs"></a> [helm\_wait\_for\_jobs](#input\_helm\_wait\_for\_jobs) | Wait for Helm jobs to complete. | `bool` | `false` | no |
| <a name="input_kubevirt_enabled"></a> [kubevirt\_enabled](#input\_kubevirt\_enabled) | Whether KubeVirt is enabled in the cluster (auto-enables KubeVirt plugin). | `bool` | `false` | no |
| <a name="input_memory_limit"></a> [memory\_limit](#input\_memory\_limit) | Memory limit for Headlamp containers. | `string` | `"256Mi"` | no |
| <a name="input_memory_request"></a> [memory\_request](#input\_memory\_request) | Memory request for Headlamp containers. | `string` | `"128Mi"` | no |
| <a name="input_name"></a> [name](#input\_name) | Helm release name for Headlamp. | `string` | `"headlamp"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace for Headlamp Kubernetes UI. | `string` | `"headlamp-system"` | no |
| <a name="input_oidc_config"></a> [oidc\_config](#input\_oidc\_config) | OIDC authentication configuration for Headlamp (Headlamp uses OIDC, not direct LDAP - see HEADLAMP-AUTHENTICATION-GUIDE.md) | <pre>object({<br/>    enabled              = optional(bool, false)<br/>    client_id            = optional(string, "")<br/>    client_secret        = optional(string, "")<br/>    issuer_url           = optional(string, "")<br/>    scopes               = optional(string, "profile,email")<br/>    use_access_token     = optional(bool, false)<br/>    validator_client_id  = optional(string, "")<br/>    validator_issuer_url = optional(string, "")<br/>  })</pre> | `{}` | no |
| <a name="input_persistent_disk_size"></a> [persistent\_disk\_size](#input\_persistent\_disk\_size) | Persistent disk size for Headlamp data storage. | `string` | `"1Gi"` | no |
| <a name="input_storage_class"></a> [storage\_class](#input\_storage\_class) | Storage class for Headlamp persistent volume. | `string` | `"hostpath"` | no |
| <a name="input_traefik_cert_resolver"></a> [traefik\_cert\_resolver](#input\_traefik\_cert\_resolver) | Traefik certificate resolver for TLS. | `string` | `"default"` | no |
| <a name="input_traefik_ingress_config"></a> [traefik\_ingress\_config](#input\_traefik\_ingress\_config) | Traefik ingress configuration from Traefik module | <pre>object({<br/>    class_name    = string<br/>    annotations   = map(string)<br/>    cert_resolver = string<br/>    domain_name   = string<br/>  })</pre> | `null` | no |
| <a name="input_traefik_middleware"></a> [traefik\_middleware](#input\_traefik\_middleware) | List of Traefik middleware names to apply to Headlamp ingress. | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_ip"></a> [cluster\_ip](#output\_cluster\_ip) | Cluster IP of Headlamp service (for LoadBalancer or NodePort). |
| <a name="output_cpu_arch"></a> [cpu\_arch](#output\_cpu\_arch) | CPU architecture used for Headlamp deployment. |
| <a name="output_enabled_plugins"></a> [enabled\_plugins](#output\_enabled\_plugins) | List of enabled Headlamp plugins. |
| <a name="output_helm_status"></a> [helm\_status](#output\_helm\_status) | Status information from Helm release. |
| <a name="output_ingress_enabled"></a> [ingress\_enabled](#output\_ingress\_enabled) | Whether ingress is enabled for Headlamp. |
| <a name="output_name"></a> [name](#output\_name) | Name of the Headlamp Helm release. |
| <a name="output_namespace"></a> [namespace](#output\_namespace) | Namespace where Headlamp is deployed. |
| <a name="output_resource_limits"></a> [resource\_limits](#output\_resource\_limits) | Resource limits applied to Headlamp containers. |
| <a name="output_resource_requests"></a> [resource\_requests](#output\_resource\_requests) | Resource requests applied to Headlamp containers. |
| <a name="output_service_account_name"></a> [service\_account\_name](#output\_service\_account\_name) | Name of the Headlamp service account. |
| <a name="output_service_account_token_command"></a> [service\_account\_token\_command](#output\_service\_account\_token\_command) | Command to generate a temporary service account token for Headlamp authentication. |
| <a name="output_storage_class"></a> [storage\_class](#output\_storage\_class) | Storage class used for Headlamp persistence. |
| <a name="output_storage_enabled"></a> [storage\_enabled](#output\_storage\_enabled) | Whether persistent storage is enabled for Headlamp. |
| <a name="output_traefik_middleware_applied"></a> [traefik\_middleware\_applied](#output\_traefik\_middleware\_applied) | Traefik middleware applied to Headlamp ingress. |
| <a name="output_url"></a> [url](#output\_url) | URL to access the Headlamp UI. |

<!-- END_TF_DOCS -->
