# Traefik Helm Module

This Terraform module deploys Traefik as a modern ingress controller and reverse proxy using the official Helm chart.

## Features

- **🌐 Modern Ingress Controller**: HTTP/HTTPS traffic management with automatic SSL
- **📋 Dashboard Access**: Built-in web UI for monitoring and configuration
- **🔒 Let's Encrypt Integration**: Automatic SSL certificate provisioning
- **⚖️ Load Balancing**: Advanced load balancing algorithms
- **🔍 Middleware Support**: Rate limiting, authentication, compression
- **📊 Metrics & Monitoring**: Prometheus metrics integration
- **🎯 Service Discovery**: Kubernetes API integration
- **⚡ High Performance**: Optimized for low latency and high throughput

## Usage

### Basic Usage

```hcl
module "traefik" {
  source = "./helm-traefik"

  namespace = "traefik-system"

  enable_dashboard = true
  dashboard_domain = "traefik.example.com"
}
```

### Advanced Configuration

```hcl
module "traefik" {
  source = "./helm-traefik"

  namespace     = "traefik-system"
  chart_version = "30.0.2"

  # Dashboard configuration
  enable_dashboard    = true
  dashboard_domain   = "traefik.example.com"
  dashboard_password = "secure-password"

  # SSL configuration
  cert_resolver = "letsencrypt"
  letsencrypt_email = "admin@example.com"

  # Resource limits
  cpu_limit      = "1000m"
  memory_limit   = "1Gi"
  cpu_request    = "500m"
  memory_request = "512Mi"

  # Storage configuration
  storage_class = "fast-ssd"
  storage_size  = "1Gi"
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
| htpasswd | >= 1.0 |

## Resources

| Name | Type |
|------|------|
| kubernetes_namespace.this | resource |
| kubernetes_persistent_volume_claim.traefik | resource |
| kubernetes_secret.dashboard_auth | resource |
| helm_release.this | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| namespace | Namespace for Traefik | `string` | `"traefik-system"` | no |
| name | Helm release name | `string` | `"traefik"` | no |
| chart_name | Helm chart name | `string` | `"traefik"` | no |
| chart_repo | Helm repository | `string` | `"https://traefik.github.io/charts"` | no |
| chart_version | Helm chart version | `string` | `"30.0.2"` | no |
| enable_dashboard | Enable Traefik dashboard | `bool` | `true` | no |
| dashboard_domain | Domain for dashboard access | `string` | `"traefik.local"` | no |
| dashboard_password | Dashboard authentication password | `string` | `""` | no |
| cert_resolver | Certificate resolver name | `string` | `"default"` | no |
| letsencrypt_email | Email for Let's Encrypt | `string` | `"admin@example.com"` | no |
| storage_class | Storage class for SSL certificates | `string` | `"hostpath"` | no |
| storage_size | Storage size for certificates | `string` | `"128Mi"` | no |
| cpu_limit | CPU limit for Traefik pods | `string` | `"300m"` | no |
| memory_limit | Memory limit for Traefik pods | `string` | `"300Mi"` | no |
| cpu_request | CPU request for Traefik pods | `string` | `"100m"` | no |
| memory_request | Memory request for Traefik pods | `string` | `"50Mi"` | no |
| cpu_arch | CPU architecture constraint | `string` | `"amd64"` | no |

## Outputs

| Name | Description |
|------|-------------|
| namespace | Traefik namespace |
| dashboard_url | Traefik dashboard URL |
| dashboard_password | Generated dashboard password |

## Dashboard Access

The Traefik dashboard provides a web interface for:

- **Route Visualization**: See all configured routes and services
- **Real-time Metrics**: Monitor traffic, response times, and errors
- **Middleware Management**: View applied middleware and configurations
- **Certificate Status**: Monitor SSL certificate status and renewal

### Dashboard Authentication

When `dashboard_password` is not provided, a secure password is auto-generated:

```bash
# Retrieve auto-generated password
terraform output -raw dashboard_password

# Access dashboard
https://traefik.example.com/dashboard/
```

## SSL Certificate Management

### Let's Encrypt Integration

Traefik automatically handles SSL certificates through Let's Encrypt:

```hcl
# Automatic SSL with HTTP challenge
cert_resolver = "letsencrypt"
letsencrypt_email = "your-email@domain.com"
```

### Certificate Storage

SSL certificates are stored in persistent volumes:

- **Storage Class**: Configurable storage backend
- **Size**: Default 128Mi (sufficient for certificates)
- **Persistence**: Survives pod restarts and updates

## Ingress Configuration

### Creating Ingress Routes

```yaml
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: my-app
  namespace: default
spec:
  entryPoints:
    - websecure
  routes:
    - match: Host(`app.example.com`)
      kind: Rule
      services:
        - name: my-app-service
          port: 80
  tls:
    certResolver: letsencrypt
```

### Middleware Examples

```yaml
# Rate limiting middleware
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: rate-limit
spec:
  rateLimit:
    burst: 100
    period: 1m
---
# Authentication middleware
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: basic-auth
spec:
  basicAuth:
    secret: auth-secret
```

## Architecture Support

This module supports both ARM64 and AMD64 architectures:

### ARM64 (Raspberry Pi)

```hcl
cpu_arch = "arm64"
cpu_limit = "200m"      # Reduced for ARM64
memory_limit = "200Mi"  # Optimized for Pi
```

### AMD64 (x86_64)

```hcl
cpu_arch = "amd64"
cpu_limit = "300m"      # Default performance
memory_limit = "300Mi"
```

## Monitoring Integration

Traefik exposes metrics for Prometheus monitoring:

- **Metrics Endpoint**: `:8080/metrics`
- **Health Check**: `:8080/ping`
- **Dashboard**: `:8080/dashboard/`

### Prometheus Configuration

```yaml
scrape_configs:
  - job_name: 'traefik'
    static_configs:
      - targets: ['traefik.traefik-system.svc.cluster.local:8080']
```

## Load Balancer Integration

### MetalLB (Bare Metal)

```hcl
# Configure LoadBalancer service type
service_type = "LoadBalancer"
metallb_address_pool = "192.168.1.200-210"
```

### Cloud Load Balancers

Works automatically with cloud provider load balancers:

- **AWS**: Application Load Balancer (ALB)
- **GCP**: Google Cloud Load Balancer
- **Azure**: Azure Load Balancer

## Troubleshooting

### Common Issues

1. **Dashboard Access Denied**: Check authentication credentials
2. **Certificate Issues**: Verify DNS resolution and Let's Encrypt limits
3. **Pod Restart Loops**: Check resource limits and storage access
4. **Ingress Not Working**: Verify service endpoints and routing rules

### Debug Commands

```bash
# Check Traefik pods
kubectl get pods -n traefik-system -l app.kubernetes.io/name=traefik

# View Traefik logs
kubectl logs -n traefik-system -l app.kubernetes.io/name=traefik

# Check ingress routes
kubectl get ingressroute -A

# Test dashboard access
kubectl port-forward -n traefik-system svc/traefik 8080:8080
```

### Configuration Validation

```bash
# Check Traefik configuration
kubectl exec -n traefik-system deployment/traefik -- traefik version

# Validate ingress routes
kubectl describe ingressroute -n traefik-system traefik-dashboard
```

## Security Considerations

- **Dashboard Authentication**: Always use strong passwords
- **Network Policies**: Restrict access to Traefik pods
- **TLS Configuration**: Enforce HTTPS with proper certificates
- **Resource Limits**: Prevent resource exhaustion attacks
- **Regular Updates**: Keep Traefik version current for security patches

## Performance Tuning

### High Traffic Environments

```hcl
# Increased resources for high load
cpu_limit = "2000m"
memory_limit = "2Gi"
replica_count = 3

# Connection limits
max_connections_per_ip = 100
rate_limit_burst = 200
```

### Resource-Constrained Environments

```hcl
# Optimized for small clusters
cpu_limit = "100m"
memory_limit = "128Mi"
enable_metrics = false  # Reduce overhead
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

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ingress"></a> [ingress](#module\_ingress) | ./ingress | n/a |

## Resources

| Name | Type |
|------|------|
| [helm_release.this](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_limit_range.namespace_limits](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/limit_range) | resource |
| [kubernetes_manifest.traefik_ingress_class](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_namespace.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_persistent_volume_claim.traefik](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume_claim) | resource |
| [kubernetes_secret.he_dns_token](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [null_resource.wait_for_traefik_crds](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.wait_for_traefik_deployment](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [random_password.hurricane_token](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [kubernetes_service.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/service) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_chart_name"></a> [chart\_name](#input\_chart\_name) | Helm chart name | `string` | `"traefik"` | no |
| <a name="input_chart_repo"></a> [chart\_repo](#input\_chart\_repo) | Helm chart repository URL | `string` | `"https://helm.traefik.io/traefik"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Helm chart version | `string` | `"37.0.0"` | no |
| <a name="input_consul_url"></a> [consul\_url](#input\_consul\_url) | Consul URL for service discovery and service mesh integration | `string` | `""` | no |
| <a name="input_cpu_arch"></a> [cpu\_arch](#input\_cpu\_arch) | CPU architecture for node selection | `string` | `"amd64"` | no |
| <a name="input_cpu_limit"></a> [cpu\_limit](#input\_cpu\_limit) | CPU limit for Traefik containers | `string` | `"200m"` | no |
| <a name="input_cpu_request"></a> [cpu\_request](#input\_cpu\_request) | CPU request for Traefik containers | `string` | `"100m"` | no |
| <a name="input_dashboard_port"></a> [dashboard\_port](#input\_dashboard\_port) | Dashboard port for Traefik web UI | `number` | `8080` | no |
| <a name="input_deployment_wait_timeout"></a> [deployment\_wait\_timeout](#input\_deployment\_wait\_timeout) | Timeout in seconds to wait for Traefik deployment to be ready | `number` | `300` | no |
| <a name="input_disable_arch_scheduling"></a> [disable\_arch\_scheduling](#input\_disable\_arch\_scheduling) | Disable architecture-based node scheduling (useful for cluster-wide services) | `bool` | `false` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Domain name for ingress resources | `string` | `".local"` | no |
| <a name="input_enable_ingress"></a> [enable\_ingress](#input\_enable\_ingress) | Enable ingress functionality for external access | `bool` | `false` | no |
| <a name="input_helm_cleanup_on_fail"></a> [helm\_cleanup\_on\_fail](#input\_helm\_cleanup\_on\_fail) | Cleanup resources on failure | `bool` | `false` | no |
| <a name="input_helm_disable_webhooks"></a> [helm\_disable\_webhooks](#input\_helm\_disable\_webhooks) | Disable webhooks for Helm release | `bool` | `true` | no |
| <a name="input_helm_force_update"></a> [helm\_force\_update](#input\_helm\_force\_update) | Force resource updates if needed | `bool` | `false` | no |
| <a name="input_helm_replace"></a> [helm\_replace](#input\_helm\_replace) | Allow Helm to replace existing resources | `bool` | `false` | no |
| <a name="input_helm_skip_crds"></a> [helm\_skip\_crds](#input\_helm\_skip\_crds) | Skip CRDs for Helm release | `bool` | `false` | no |
| <a name="input_helm_timeout"></a> [helm\_timeout](#input\_helm\_timeout) | Timeout for Helm deployment in seconds | `number` | `600` | no |
| <a name="input_helm_wait"></a> [helm\_wait](#input\_helm\_wait) | Wait for Helm release to be ready | `bool` | `false` | no |
| <a name="input_helm_wait_for_jobs"></a> [helm\_wait\_for\_jobs](#input\_helm\_wait\_for\_jobs) | Wait for Helm jobs to complete | `bool` | `false` | no |
| <a name="input_http_port"></a> [http\_port](#input\_http\_port) | HTTP port for Traefik entrypoint | `number` | `80` | no |
| <a name="input_https_port"></a> [https\_port](#input\_https\_port) | HTTPS port for Traefik entrypoint | `number` | `443` | no |
| <a name="input_ingress_api_version"></a> [ingress\_api\_version](#input\_ingress\_api\_version) | API version for ingress resources | `string` | `"networking.k8s.io/v1"` | no |
| <a name="input_le_email"></a> [le\_email](#input\_le\_email) | Email address for Let's Encrypt certificate notifications | `string` | `""` | no |
| <a name="input_memory_limit"></a> [memory\_limit](#input\_memory\_limit) | Memory limit for Traefik containers | `string` | `"256Mi"` | no |
| <a name="input_memory_request"></a> [memory\_request](#input\_memory\_request) | Memory request for Traefik containers | `string` | `"128Mi"` | no |
| <a name="input_metrics_port"></a> [metrics\_port](#input\_metrics\_port) | Metrics port for Traefik Prometheus metrics | `number` | `9100` | no |
| <a name="input_name"></a> [name](#input\_name) | Helm release name for Traefik | `string` | `"traefik"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Kubernetes namespace for Traefik deployment | `string` | `"traefik-ingress-controller"` | no |
| <a name="input_persistent_disk_size"></a> [persistent\_disk\_size](#input\_persistent\_disk\_size) | Size of persistent disk for Traefik data | `string` | `"1Gi"` | no |
| <a name="input_storage_class"></a> [storage\_class](#input\_storage\_class) | Storage class for persistent volumes | `string` | `"hostpath"` | no |
| <a name="input_traefik_cert_resolver"></a> [traefik\_cert\_resolver](#input\_traefik\_cert\_resolver) | Traefik certificate resolver name | `string` | `"default"` | no |
| <a name="input_traefik_dashboard_password"></a> [traefik\_dashboard\_password](#input\_traefik\_dashboard\_password) | Custom password for Traefik dashboard (empty = auto-generate) | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_chart_version"></a> [chart\_version](#output\_chart\_version) | Helm chart version used |
| <a name="output_dashboard_password"></a> [dashboard\_password](#output\_dashboard\_password) | Traefik dashboard password |
| <a name="output_dashboard_url"></a> [dashboard\_url](#output\_dashboard\_url) | Traefik dashboard URL |
| <a name="output_he_dns_config"></a> [he\_dns\_config](#output\_he\_dns\_config) | Hurricane Electric DNS configuration for ACME wildcard certificates |
| <a name="output_loadbalancer_ip"></a> [loadbalancer\_ip](#output\_loadbalancer\_ip) | LoadBalancer IP address for Traefik service |
| <a name="output_namespace"></a> [namespace](#output\_namespace) | Kubernetes namespace where Traefik is deployed |
| <a name="output_service_name"></a> [service\_name](#output\_service\_name) | Traefik service name |
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

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ingress"></a> [ingress](#module\_ingress) | ./ingress | n/a |

## Resources

| Name | Type |
|------|------|
| [helm_release.this](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_limit_range.namespace_limits](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/limit_range) | resource |
| [kubernetes_manifest.traefik_ingress_class](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_namespace.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_persistent_volume_claim.traefik](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume_claim) | resource |
| [kubernetes_secret.he_dns_token](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [null_resource.wait_for_traefik_crds](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.wait_for_traefik_deployment](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [random_password.hurricane_token](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [kubernetes_service.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/service) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_chart_name"></a> [chart\_name](#input\_chart\_name) | Helm chart name | `string` | `"traefik"` | no |
| <a name="input_chart_repo"></a> [chart\_repo](#input\_chart\_repo) | Helm chart repository URL | `string` | `"https://helm.traefik.io/traefik"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Helm chart version | `string` | `"37.0.0"` | no |
| <a name="input_consul_url"></a> [consul\_url](#input\_consul\_url) | Consul URL for service discovery and service mesh integration | `string` | `""` | no |
| <a name="input_cpu_arch"></a> [cpu\_arch](#input\_cpu\_arch) | CPU architecture for node selection | `string` | `"amd64"` | no |
| <a name="input_cpu_limit"></a> [cpu\_limit](#input\_cpu\_limit) | CPU limit for Traefik containers | `string` | `"200m"` | no |
| <a name="input_cpu_request"></a> [cpu\_request](#input\_cpu\_request) | CPU request for Traefik containers | `string` | `"100m"` | no |
| <a name="input_dashboard_port"></a> [dashboard\_port](#input\_dashboard\_port) | Dashboard port for Traefik web UI | `number` | `8080` | no |
| <a name="input_deployment_wait_timeout"></a> [deployment\_wait\_timeout](#input\_deployment\_wait\_timeout) | Timeout in seconds to wait for Traefik deployment to be ready | `number` | `300` | no |
| <a name="input_disable_arch_scheduling"></a> [disable\_arch\_scheduling](#input\_disable\_arch\_scheduling) | Disable architecture-based node scheduling (useful for cluster-wide services) | `bool` | `false` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Domain name for ingress resources | `string` | `".local"` | no |
| <a name="input_enable_ingress"></a> [enable\_ingress](#input\_enable\_ingress) | Enable ingress functionality for external access | `bool` | `false` | no |
| <a name="input_helm_cleanup_on_fail"></a> [helm\_cleanup\_on\_fail](#input\_helm\_cleanup\_on\_fail) | Cleanup resources on failure | `bool` | `false` | no |
| <a name="input_helm_disable_webhooks"></a> [helm\_disable\_webhooks](#input\_helm\_disable\_webhooks) | Disable webhooks for Helm release | `bool` | `true` | no |
| <a name="input_helm_force_update"></a> [helm\_force\_update](#input\_helm\_force\_update) | Force resource updates if needed | `bool` | `false` | no |
| <a name="input_helm_replace"></a> [helm\_replace](#input\_helm\_replace) | Allow Helm to replace existing resources | `bool` | `false` | no |
| <a name="input_helm_skip_crds"></a> [helm\_skip\_crds](#input\_helm\_skip\_crds) | Skip CRDs for Helm release | `bool` | `false` | no |
| <a name="input_helm_timeout"></a> [helm\_timeout](#input\_helm\_timeout) | Timeout for Helm deployment in seconds | `number` | `600` | no |
| <a name="input_helm_wait"></a> [helm\_wait](#input\_helm\_wait) | Wait for Helm release to be ready | `bool` | `false` | no |
| <a name="input_helm_wait_for_jobs"></a> [helm\_wait\_for\_jobs](#input\_helm\_wait\_for\_jobs) | Wait for Helm jobs to complete | `bool` | `false` | no |
| <a name="input_http_port"></a> [http\_port](#input\_http\_port) | HTTP port for Traefik entrypoint | `number` | `80` | no |
| <a name="input_https_port"></a> [https\_port](#input\_https\_port) | HTTPS port for Traefik entrypoint | `number` | `443` | no |
| <a name="input_ingress_api_version"></a> [ingress\_api\_version](#input\_ingress\_api\_version) | API version for ingress resources | `string` | `"networking.k8s.io/v1"` | no |
| <a name="input_le_email"></a> [le\_email](#input\_le\_email) | Email address for Let's Encrypt certificate notifications | `string` | `""` | no |
| <a name="input_memory_limit"></a> [memory\_limit](#input\_memory\_limit) | Memory limit for Traefik containers | `string` | `"256Mi"` | no |
| <a name="input_memory_request"></a> [memory\_request](#input\_memory\_request) | Memory request for Traefik containers | `string` | `"128Mi"` | no |
| <a name="input_metrics_port"></a> [metrics\_port](#input\_metrics\_port) | Metrics port for Traefik Prometheus metrics | `number` | `9100` | no |
| <a name="input_name"></a> [name](#input\_name) | Helm release name for Traefik | `string` | `"traefik"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Kubernetes namespace for Traefik deployment | `string` | `"traefik-ingress-controller"` | no |
| <a name="input_persistent_disk_size"></a> [persistent\_disk\_size](#input\_persistent\_disk\_size) | Size of persistent disk for Traefik data | `string` | `"1Gi"` | no |
| <a name="input_storage_class"></a> [storage\_class](#input\_storage\_class) | Storage class for persistent volumes | `string` | `"hostpath"` | no |
| <a name="input_traefik_cert_resolver"></a> [traefik\_cert\_resolver](#input\_traefik\_cert\_resolver) | Traefik certificate resolver name | `string` | `"default"` | no |
| <a name="input_traefik_dashboard_password"></a> [traefik\_dashboard\_password](#input\_traefik\_dashboard\_password) | Custom password for Traefik dashboard (empty = auto-generate) | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_chart_version"></a> [chart\_version](#output\_chart\_version) | Helm chart version used |
| <a name="output_dashboard_password"></a> [dashboard\_password](#output\_dashboard\_password) | Traefik dashboard password |
| <a name="output_dashboard_url"></a> [dashboard\_url](#output\_dashboard\_url) | Traefik dashboard URL |
| <a name="output_he_dns_config"></a> [he\_dns\_config](#output\_he\_dns\_config) | Hurricane Electric DNS configuration for ACME wildcard certificates |
| <a name="output_loadbalancer_ip"></a> [loadbalancer\_ip](#output\_loadbalancer\_ip) | LoadBalancer IP address for Traefik service |
| <a name="output_namespace"></a> [namespace](#output\_namespace) | Kubernetes namespace where Traefik is deployed |
| <a name="output_service_name"></a> [service\_name](#output\_service\_name) | Traefik service name |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
