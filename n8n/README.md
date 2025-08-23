# Native Terraform n8n Module

Enterprise-grade workflow automation platform deployed using native Terraform resources.

## Features

- **Native Terraform**: No Helm dependencies, pure Kubernetes resources
- **Enterprise Security**: Proper security contexts and resource limits
- **ARM64/AMD64 Support**: Multi-architecture deployment
- **Persistent Storage**: Data persistence with configurable storage classes
- **Traefik Integration**: Automatic SSL certificates and ingress
- **Health Checks**: Comprehensive liveness and readiness probes
- **Resource Management**: Configurable CPU/memory limits for homelab environments

## Configuration

### Basic Usage

```hcl
module "n8n" {
  source = "./n8n"

  name      = "n8n"
  namespace = "n8n-system"

  # Domain configuration
  domain_name           = ".homelab.local"
  traefik_cert_resolver = "letsencrypt"

  # Storage
  enable_persistence   = true
  storage_class        = "nfs-csi"
  persistent_disk_size = "5Gi"
}
```

### Advanced Configuration

```hcl
module "n8n" {
  source = "./n8n"

  # Architecture-specific deployment
  cpu_arch                = "arm64"
  disable_arch_scheduling = false

  # Higher resources for workflow processing
  cpu_limit      = "1000m"
  memory_limit   = "1Gi"
  cpu_request    = "500m"
  memory_request = "512Mi"

  # Database configuration
  enable_database = false  # Use SQLite for simplicity
}
```

## Outputs

- `namespace`: Deployment namespace
- `service_name`: Kubernetes service name
- `service_url`: Internal cluster URL
- `ingress_url`: External HTTPS URL
- `webhook_url`: Webhook endpoint URL
- `n8n_config`: Configuration summary

## Access

After deployment, n8n is available at:
- **External**: `https://n8n.{domain}`
- **Webhooks**: `https://n8n.{domain}/webhook`
- **Internal**: `http://n8n.n8n-system.svc.cluster.local:5678`

## Implementation Details

### Native Kubernetes Resources

This module uses native Terraform Kubernetes resources:
- `kubernetes_deployment` - Main n8n application
- `kubernetes_service` - ClusterIP service
- `kubernetes_config_map` - Configuration management
- `kubernetes_secret` - Encryption key storage
- `kubernetes_persistent_volume_claim` - Data persistence
- `kubernetes_ingress_v1` - Traefik integration

### Security Features

- **Non-root execution**: Runs as user 1000
- **Read-only filesystem**: Enhanced security
- **Dropped capabilities**: Minimal privileges
- **Security contexts**: Pod and container level
- **Resource limits**: Prevent resource exhaustion

### Health Monitoring

- **Liveness probe**: `/healthz` endpoint monitoring
- **Readiness probe**: Service availability checks
- **Configurable timeouts**: Flexible health check timing

## Database Options

- **SQLite** (default): Single-file database, good for homelab deployments
- **PostgreSQL**: External database for production workloads (requires separate PostgreSQL deployment)

<!-- BEGIN_TF_DOCS -->


## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.38.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.7.2 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [kubernetes_config_map.n8n_config](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_deployment.n8n](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment) | resource |
| [kubernetes_ingress_v1.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/ingress_v1) | resource |
| [kubernetes_namespace.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_persistent_volume_claim.data_storage](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume_claim) | resource |
| [kubernetes_secret.n8n_secret](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_service.n8n](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service) | resource |
| [random_password.encryption_key](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cpu_arch"></a> [cpu\_arch](#input\_cpu\_arch) | CPU architecture for node selection | `string` | `"amd64"` | no |
| <a name="input_cpu_limit"></a> [cpu\_limit](#input\_cpu\_limit) | CPU limit for n8n containers | `string` | `"1000m"` | no |
| <a name="input_cpu_request"></a> [cpu\_request](#input\_cpu\_request) | CPU request for n8n containers | `string` | `"500m"` | no |
| <a name="input_disable_arch_scheduling"></a> [disable\_arch\_scheduling](#input\_disable\_arch\_scheduling) | Disable architecture-based node scheduling | `bool` | `false` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Domain name for ingress resources | `string` | `".local"` | no |
| <a name="input_enable_database"></a> [enable\_database](#input\_enable\_database) | Enable external database (PostgreSQL) instead of SQLite | `bool` | `false` | no |
| <a name="input_enable_ingress"></a> [enable\_ingress](#input\_enable\_ingress) | Enable ingress functionality for external access | `bool` | `true` | no |
| <a name="input_enable_persistence"></a> [enable\_persistence](#input\_enable\_persistence) | Enable persistent storage for n8n data | `bool` | `true` | no |
| <a name="input_memory_limit"></a> [memory\_limit](#input\_memory\_limit) | Memory limit for n8n containers | `string` | `"1Gi"` | no |
| <a name="input_memory_request"></a> [memory\_request](#input\_memory\_request) | Memory request for n8n containers | `string` | `"512Mi"` | no |
| <a name="input_name"></a> [name](#input\_name) | Deployment name for n8n | `string` | `"n8n"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Kubernetes namespace for n8n deployment | `string` | `"n8n-system"` | no |
| <a name="input_persistent_disk_size"></a> [persistent\_disk\_size](#input\_persistent\_disk\_size) | Size of persistent disk for n8n data | `string` | `"5Gi"` | no |
| <a name="input_storage_class"></a> [storage\_class](#input\_storage\_class) | Storage class for persistent volumes | `string` | `"hostpath"` | no |
| <a name="input_traefik_cert_resolver"></a> [traefik\_cert\_resolver](#input\_traefik\_cert\_resolver) | Traefik certificate resolver name | `string` | `"default"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_deployment_name"></a> [deployment\_name](#output\_deployment\_name) | The name of the n8n deployment |
| <a name="output_deployment_status"></a> [deployment\_status](#output\_deployment\_status) | The status of the n8n deployment |
| <a name="output_ingress_url"></a> [ingress\_url](#output\_ingress\_url) | External ingress URL for n8n (when ingress is enabled) |
| <a name="output_n8n_config"></a> [n8n\_config](#output\_n8n\_config) | n8n configuration summary |
| <a name="output_n8n_version"></a> [n8n\_version](#output\_n8n\_version) | The version of n8n deployed |
| <a name="output_namespace"></a> [namespace](#output\_namespace) | The namespace where n8n is deployed |
| <a name="output_service_name"></a> [service\_name](#output\_service\_name) | The name of the n8n service |
| <a name="output_service_url"></a> [service\_url](#output\_service\_url) | Internal service URL for n8n |
| <a name="output_webhook_url"></a> [webhook\_url](#output\_webhook\_url) | Webhook URL for n8n workflows |

<!-- END_TF_DOCS -->
