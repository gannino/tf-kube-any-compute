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
| `chart_repo` | string | `"https://kubernetes-sigs.github.io/headlamp/"` | Helm chart repository |
| `chart_name` | string | `headlamp` | Helm chart name |
| `chart_version` | string | `0.40.0` | Helm chart version |
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

### OIDC Configuration

| Variable | Type | Default | Description |
|-----------|------|----------|-------------|
| `oidc_config.enabled` | bool | `false` | Enable OIDC authentication |
| `oidc_config.client_id` | string | `""` | OIDC client ID |
| `oidc_config.client_secret` | string | `""` | OIDC client secret |
| `oidc_config.issuer_url` | string | `""` | OIDC issuer URL |
| `oidc_config.scopes` | list(string) | - | OIDC scopes (openid, profile, email, groups) |
| `oidc_config.use_access_token` | bool | `false` | Use access token for API authentication |

> **Note**: See [HEADLAMP-AUTHENTICATION-GUIDE.md](HEADLAMP-AUTHENTICATION-GUIDE.md) for comprehensive OIDC setup, LDAP integration, and troubleshooting known issues.

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

### Namespace Cleanup Configuration

| Variable | Type | Default | Description |
|-----------|------|----------|-------------|
| `force_namespace_cleanup` | bool | `false` | Force cleanup of namespace if deletion gets stuck (WARNING: Only use when namespace is stuck in Terminating phase) |
| `cleanup_timeout` | string | `10m` | Timeout for namespace cleanup operations (e.g., 5m, 10m, 30s) |
| `workspace_prefix` | string | `""` | Workspace prefix for kubeconfig file selection (e.g., 'prod', 'sit', 'dev'). Matches main provider.tf logic. |
| `ci_mode` | bool | `false` | Running in CI mode (kubeconfig handled externally). |
| `kubeconfig_path` | string | `""` | Explicit kubeconfig path (overrides automatic detection). Leave empty to use workspace-based or default kubeconfig. |

#### Kubeconfig Detection Logic

The module automatically detects the correct kubeconfig file using the same logic as the main Terraform provider:

1. **Explicit Path**: If `kubeconfig_path` is provided, it's used directly
2. **CI Mode**: If `ci_mode` is `true`, kubeconfig is handled externally (set to `null`)
3. **Workspace-based**: Checks for `~/.kube/${workspace_prefix}-config` (e.g., `~/.kube/prod-config`)
4. **Default**: Falls back to `~/.kube/config` if no workspace-specific config exists

This ensures consistent kubeconfig selection across all modules and providers in your Terraform workspace.

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

### Authentication Issues

#### Problem: "Lost connection to cluster" with OIDC

**Symptoms**: After logging in via OIDC (e.g., Authelia), you can access the Headlamp UI for ~2 minutes, then see "Lost connection to cluster" errors.

**Root Cause**: This is a **known Headlamp bug** with OIDC token refresh. The initial OIDC access token expires after ~2 minutes and Headlamp fails to refresh it, resulting in 401 Unauthorized errors when accessing the Kubernetes API.

**Status**: Being tracked upstream:
- [GitHub Issue #4481: Allow OIDC authentication for kubeconfig clusters when inCluster](https://github.com/kubernetes-sigs/headlamp/issues/4481)
- [GitHub Issue #4198: OIDC In-Cluster Mode - Impersonation Not Working](https://github.com/kubernetes-sigs/headlamp/issues/4198)
- [GitHub Issue #3918: Session expires in ~2 minutes when you log in via OIDC](https://github.com/kubernetes-sigs/headlamp/issues/3918)
- [GitHub Issue #3143: OIDC token refresh is not working](https://github.com/kubernetes-sigs/headlamp/issues/3143)

#### Solution: Use Service Account Token

The recommended workaround is to use Kubernetes service account token authentication instead of OIDC:

```bash
# Generate a 24-hour service account token
terraform output -raw module.headlamp.service_account_token_command

# Example output:
# kubectl create token headlamp-admin -n prod-headlamp-system --duration=24h

# Copy the token and use "Login with token" in Headlamp UI
```

#### Step-by-Step: Service Account Token Login

1. **Generate Token**:
   ```bash
   kubectl create token headlamp-admin -n <workspace>-headlamp-system --duration=24h
   ```

2. **Access Headlamp**: Open `https://headlamp.<your-domain>`

3. **Choose Login Method**: Click "Login with token" (not "Sign in with OIDC")

4. **Enter Token**: Paste the token generated in step 1

5. **Stable Connection**: The token is valid for 24 hours and won't suffer from OIDC refresh issues

#### Alternative: Disable OIDC

If you prefer to not see the OIDC login option, disable it in configuration:

```hcl
service_overrides = {
  headlamp = {
    oidc_config = {
      enabled = false  # Disable OIDC login
    }
  }
}
```

#### Checking Authentication Status

To verify which authentication methods are available:

```bash
terraform output -raw module.headlamp.authentication_methods
```

This outputs:
```json
{
  "oidc": {
    "enabled": true,
    "status": "Known limitation: Token refresh fails after ~2 minutes",
    "recommended": false
  },
  "service_account_token": {
    "enabled": true,
    "status": "Fully supported",
    "recommended": true
  }
}
```

### Namespace Cleanup Issues

#### Stuck Namespace in Terminating Phase

If Headlamp namespace gets stuck in `Terminating` phase (common with KubeVirt subresources), you can use the force cleanup feature:

```hcl
module "headlamp" {
  source = "./helm-headlamp"

  # Enable force cleanup for stuck namespace
  force_namespace_cleanup = true
  cleanup_timeout          = "10m"
}
```

Then run:

```bash
terraform apply
terraform destroy  # This will trigger force cleanup
```

The cleanup script automatically handles:
- **KubeVirt stale subresources**: Removes stuck `subresources.kubevirt.io/v1` and `v1alpha3` API services
- **Namespace finalizers**: Removes blocking finalizers preventing deletion
- **Namespace verification**: Confirms successful cleanup

#### Manual Cleanup (if Terraform cleanup fails)

```bash
# Get namespace JSON
kubectl get namespace headlamp-system -o json > ns.json

# Remove finalizers
jq 'del(.spec.finalizers)' ns.json > ns-cleaned.json

# Apply cleaned namespace
kubectl replace --raw "/api/v1/namespaces/headlamp-system/finalize" -f ns-cleaned.json

# Clean up KubeVirt subresources
kubectl delete apiservice v1alpha3.subresources.kubevirt.io --ignore-not-found=true
kubectl delete apiservice v1.subresources.kubevirt.io --ignore-not-found=true

# Wait for deletion
kubectl wait --for=delete namespace/headlamp-system --timeout=10m
```

#### KubeVirt Subresource Issues

The error message indicating KubeVirt subresource issues:

```
DiscoveryFailed: unable to retrieve the complete list of server APIs:
subresources.kubevirt.io/v1: stale GroupVersion discovery
```

**Solution**: Enable force cleanup as shown above, which automatically handles these stale subresources.

## Integration with Other Services

### KubeVirt Integration

When KubeVirt is enabled in the main configuration, Headlamp automatically enables the KubeVirt plugin:

```hcl
# In main.tf or locals.tf
kubevirt_enabled = try(var.services.kubevirt, false)

# Headlamp will auto-enable kubevirt plugin
```

### OIDC Auto-Configuration with Authelia

When both Authelia and Headlamp are enabled, Headlamp can automatically configure OIDC using Authelia as the identity provider:

```hcl
services = {
  traefik  = true
  authelia = true
  headlamp = true
}

service_overrides = {
  authelia = {
    oidc_enabled = true
    # Headlamp OIDC client is auto-configured
    oidc_clients = {
      headlamp = {
        client_id     = "headlamp"
        client_secret = "your-secure-secret-here"
        redirect_uris = ["https://headlamp.example.com/oauth2/callback"]
      }
    }
  }
  # Headlamp oidc_config is auto-configured - no manual configuration needed!
}
```

**Auto-Configuration Behavior**:

- If `service_overrides.headlamp.oidc_config` is explicitly provided, it takes precedence
- If Authelia is enabled with `oidc_enabled = true`, Headlamp automatically configures:
  - `issuer_url`: Derived from Authelia's URL
  - `client_id`: Set to "headlamp"
  - `client_secret`: Retrieved from Authelia's `oidc_clients.headlamp.client_secret`
  - `scopes`: Set to "openid,profile,email,groups"

**Manual OIDC Configuration** (to override auto-configuration):

```hcl
service_overrides = {
  headlamp = {
    oidc_config = {
      enabled         = true
      issuer_url      = "https://custom-oidc.example.com"
      client_id       = "custom-client"
      client_secret   = "custom-secret"
      scopes          = ["openid", "profile", "email"]
      use_access_token = false
    }
  }
}
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
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 3.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.31.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_helm"></a> [helm](#provider\_helm) | 3.1.1 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 3.0.1 |
| <a name="provider_null"></a> [null](#provider\_null) | 3.2.4 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [helm_release.this](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_cluster_role.headlamp](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cluster_role) | resource |
| [kubernetes_cluster_role_binding.headlamp_admin](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cluster_role_binding) | resource |
| [kubernetes_config_map.plugin_installer](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_ingress_v1.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/ingress_v1) | resource |
| [kubernetes_job.plugin_installer](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/job) | resource |
| [kubernetes_limit_range_v1.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/limit_range_v1) | resource |
| [kubernetes_namespace.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_persistent_volume_claim.plugins](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume_claim) | resource |
| [kubernetes_service_account.headlamp_admin](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account) | resource |
| [null_resource.force_namespace_cleanup](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [kubernetes_service.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/service) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_chart_name"></a> [chart\_name](#input\_chart\_name) | Helm chart name for Headlamp. | `string` | `"headlamp"` | no |
| <a name="input_chart_repo"></a> [chart\_repo](#input\_chart\_repo) | Helm repository URL for Headlamp charts. | `string` | `"https://kubernetes-sigs.github.io/headlamp/"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Helm chart version for Headlamp. | `string` | `"0.40.0"` | no |
| <a name="input_ci_mode"></a> [ci\_mode](#input\_ci\_mode) | Running in CI mode (kubeconfig handled externally). | `bool` | `false` | no |
| <a name="input_cleanup_timeout"></a> [cleanup\_timeout](#input\_cleanup\_timeout) | Timeout for namespace cleanup operations (e.g., 5m, 10m, 30s). | `string` | `"10m"` | no |
| <a name="input_cpu_arch"></a> [cpu\_arch](#input\_cpu\_arch) | CPU architecture for container images (amd64, arm64). | `string` | n/a | yes |
| <a name="input_cpu_limit"></a> [cpu\_limit](#input\_cpu\_limit) | CPU limit for Headlamp containers. | `string` | `"200m"` | no |
| <a name="input_cpu_request"></a> [cpu\_request](#input\_cpu\_request) | CPU request for Headlamp containers. | `string` | `"100m"` | no |
| <a name="input_disable_arch_scheduling"></a> [disable\_arch\_scheduling](#input\_disable\_arch\_scheduling) | Disable architecture-based node scheduling. | `bool` | `false` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Domain name for Headlamp ingress. | `string` | `".local"` | no |
| <a name="input_enable_cluster_tls_verification"></a> [enable\_cluster\_tls\_verification](#input\_enable\_cluster\_tls\_verification) | Enable TLS verification for cluster API connections. When true, validates cluster certificates. When false, allows man-in-the-middle attacks (not recommended for production). | `bool` | `true` | no |
| <a name="input_enable_headlamp_ingress"></a> [enable\_headlamp\_ingress](#input\_enable\_headlamp\_ingress) | Enable Headlamp ingress configuration. | `bool` | `true` | no |
| <a name="input_enable_oidc_tls_verification"></a> [enable\_oidc\_tls\_verification](#input\_enable\_oidc\_tls\_verification) | Enable TLS verification for OIDC provider connections. When true, validates OIDC provider certificates. When false, allows man-in-the-middle attacks (not recommended for production). | `bool` | `true` | no |
| <a name="input_enable_persistence"></a> [enable\_persistence](#input\_enable\_persistence) | Enable persistent storage for Headlamp configuration. | `bool` | `true` | no |
| <a name="input_enabled_plugins"></a> [enabled\_plugins](#input\_enabled\_plugins) | List of Headlamp plugins to enable (e.g., ['kubevirt']). | `list(string)` | `[]` | no |
| <a name="input_force_namespace_cleanup"></a> [force\_namespace\_cleanup](#input\_force\_namespace\_cleanup) | Force cleanup of namespace if deletion gets stuck. WARNING: Only use when namespace is stuck in Terminating phase. | `bool` | `false` | no |
| <a name="input_helm_cleanup_on_fail"></a> [helm\_cleanup\_on\_fail](#input\_helm\_cleanup\_on\_fail) | Cleanup resources on deployment failure. | `bool` | `false` | no |
| <a name="input_helm_disable_webhooks"></a> [helm\_disable\_webhooks](#input\_helm\_disable\_webhooks) | Disable webhooks for Helm release. | `bool` | `false` | no |
| <a name="input_helm_force_update"></a> [helm\_force\_update](#input\_helm\_force\_update) | Force resource updates if needed. | `bool` | `false` | no |
| <a name="input_helm_replace"></a> [helm\_replace](#input\_helm\_replace) | Allow Helm to replace existing resources. | `bool` | `false` | no |
| <a name="input_helm_skip_crds"></a> [helm\_skip\_crds](#input\_helm\_skip\_crds) | Skip CRDs for Helm release. | `bool` | `false` | no |
| <a name="input_helm_timeout"></a> [helm\_timeout](#input\_helm\_timeout) | Timeout for Helm deployment in seconds. | `number` | `300` | no |
| <a name="input_helm_wait"></a> [helm\_wait](#input\_helm\_wait) | Wait for Helm release to be ready. | `bool` | `false` | no |
| <a name="input_helm_wait_for_jobs"></a> [helm\_wait\_for\_jobs](#input\_helm\_wait\_for\_jobs) | Wait for Helm jobs to complete. | `bool` | `false` | no |
| <a name="input_kubeconfig_path"></a> [kubeconfig\_path](#input\_kubeconfig\_path) | Explicit kubeconfig path (overrides automatic detection). Leave empty to use workspace-based or default kubeconfig. | `string` | `""` | no |
| <a name="input_kubevirt_enabled"></a> [kubevirt\_enabled](#input\_kubevirt\_enabled) | Whether KubeVirt is enabled in the cluster (auto-enables KubeVirt plugin). | `bool` | `false` | no |
| <a name="input_memory_limit"></a> [memory\_limit](#input\_memory\_limit) | Memory limit for Headlamp containers. | `string` | `"256Mi"` | no |
| <a name="input_memory_request"></a> [memory\_request](#input\_memory\_request) | Memory request for Headlamp containers. | `string` | `"128Mi"` | no |
| <a name="input_name"></a> [name](#input\_name) | Helm release name for Headlamp. | `string` | `"headlamp"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace for Headlamp Kubernetes UI. | `string` | `"headlamp-system"` | no |
| <a name="input_oidc_config"></a> [oidc\_config](#input\_oidc\_config) | OIDC authentication configuration for Headlamp (Headlamp uses OIDC, not direct LDAP - see HEADLAMP-AUTHENTICATION-GUIDE.md) | <pre>object({<br/>    enabled              = optional(bool, false)<br/>    client_id            = optional(string, "")<br/>    client_secret        = optional(string, "")<br/>    issuer_url           = optional(string, "")<br/>    scopes               = optional(string, "profile,email")<br/>    use_access_token     = optional(bool, false)<br/>    validator_client_id  = optional(string, "")<br/>    validator_issuer_url = optional(string, "")<br/>  })</pre> | `{}` | no |
| <a name="input_persistent_disk_size"></a> [persistent\_disk\_size](#input\_persistent\_disk\_size) | Persistent disk size for Headlamp data storage. | `string` | `"1Gi"` | no |
| <a name="input_prometheus_enabled"></a> [prometheus\_enabled](#input\_prometheus\_enabled) | Enable Prometheus integration in Headlamp. | `bool` | `false` | no |
| <a name="input_prometheus_url"></a> [prometheus\_url](#input\_prometheus\_url) | Prometheus server URL for metrics integration. | `string` | `""` | no |
| <a name="input_rbac_permission_level"></a> [rbac\_permission\_level](#input\_rbac\_permission\_level) | RBAC permission level for Headlamp service account: 'cluster-admin' (full cluster access), 'admin' (full namespace access + cluster-wide read), 'edit' (modify namespace resources), 'view' (read-only). WARNING: 'cluster-admin' gives full control over the cluster. | `string` | `"cluster-admin"` | no |
| <a name="input_storage_class"></a> [storage\_class](#input\_storage\_class) | Storage class for Headlamp persistent volume. | `string` | `"hostpath"` | no |
| <a name="input_traefik_cert_resolver"></a> [traefik\_cert\_resolver](#input\_traefik\_cert\_resolver) | Traefik certificate resolver for TLS. | `string` | `"default"` | no |
| <a name="input_traefik_ingress_config"></a> [traefik\_ingress\_config](#input\_traefik\_ingress\_config) | Traefik ingress configuration from Traefik module | <pre>object({<br/>    class_name    = string<br/>    annotations   = map(string)<br/>    cert_resolver = string<br/>    domain_name   = string<br/>  })</pre> | `null` | no |
| <a name="input_traefik_middleware"></a> [traefik\_middleware](#input\_traefik\_middleware) | List of Traefik middleware names to apply to Headlamp ingress. | `list(string)` | `[]` | no |
| <a name="input_workspace_prefix"></a> [workspace\_prefix](#input\_workspace\_prefix) | Workspace prefix for kubeconfig file selection (e.g., 'prod', 'sit', 'dev'). | `string` | `""` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_authentication_methods"></a> [authentication\_methods](#output\_authentication\_methods) | Available authentication methods for Headlamp and their status. |
| <a name="output_cluster_ip"></a> [cluster\_ip](#output\_cluster\_ip) | Cluster IP of Headlamp service (for LoadBalancer or NodePort). |
| <a name="output_cpu_arch"></a> [cpu\_arch](#output\_cpu\_arch) | CPU architecture used for Headlamp deployment. |
| <a name="output_enabled_plugins"></a> [enabled\_plugins](#output\_enabled\_plugins) | List of enabled Headlamp plugins. |
| <a name="output_helm_status"></a> [helm\_status](#output\_helm\_status) | Status information from Helm release. |
| <a name="output_ingress_enabled"></a> [ingress\_enabled](#output\_ingress\_enabled) | Whether ingress is enabled for Headlamp. |
| <a name="output_name"></a> [name](#output\_name) | Name of the Headlamp Helm release. |
| <a name="output_namespace"></a> [namespace](#output\_namespace) | Namespace where Headlamp is deployed. |
| <a name="output_prometheus_service_address"></a> [prometheus\_service\_address](#output\_prometheus\_service\_address) | Prometheus service address for Headlamp UI (format: namespace/service:port). Configure this in Headlamp Settings > Prometheus. |
| <a name="output_resource_limits"></a> [resource\_limits](#output\_resource\_limits) | Resource limits applied to Headlamp containers. |
| <a name="output_resource_requests"></a> [resource\_requests](#output\_resource\_requests) | Resource requests applied to Headlamp containers. |
| <a name="output_service_account_name"></a> [service\_account\_name](#output\_service\_account\_name) | Name of the Headlamp service account. |
| <a name="output_service_account_token_command"></a> [service\_account\_token\_command](#output\_service\_account\_token\_command) | Command to generate a temporary service account token for Headlamp authentication. This is the RECOMMENDED authentication method due to OIDC token refresh limitations (see README). |
| <a name="output_storage_class"></a> [storage\_class](#output\_storage\_class) | Storage class used for Headlamp persistence. |
| <a name="output_storage_enabled"></a> [storage\_enabled](#output\_storage\_enabled) | Whether persistent storage is enabled for Headlamp. |
| <a name="output_traefik_middleware_applied"></a> [traefik\_middleware\_applied](#output\_traefik\_middleware\_applied) | Traefik middleware applied to Headlamp ingress. |
| <a name="output_url"></a> [url](#output\_url) | URL to access the Headlamp UI. |
<!-- END_TF_DOCS -->
