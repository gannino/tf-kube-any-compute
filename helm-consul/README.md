# Consul Helm Module

This Terraform module deploys HashiCorp Consul for service mesh and service discovery using the official Helm chart.

## Features

- **🔌 Service Discovery**: Automatic service registration and discovery
- **🔐 Service Mesh**: Secure service-to-service communication with mTLS
- **📊 Health Checking**: Built-in health monitoring for services
- **🔑 ACL Support**: Automatic ACL bootstrap and token management
- **🌐 Web UI**: Consul UI for visual management
- **⚡ KV Store**: Distributed key-value store for configuration
- **🏗️ Multi-Architecture**: ARM64 and AMD64 support

## Usage

### Basic Usage

```hcl
module "consul" {
  source = "./helm-consul"

  namespace = "consul-system"
  domain_name = "example.com"
}
```

### Advanced Configuration

```hcl
module "consul" {
  source = "./helm-consul"

  namespace     = "consul-system"
  chart_version = "1.8.0"

  # Server configuration
  server_replicas = 3
  client_replicas = 0  # DaemonSet mode

  # Storage configuration
  storage_class = "fast-ssd"
  persistent_disk_size = "10Gi"

  # Resource configuration
  cpu_limit      = "500m"
  memory_limit   = "512Mi"
  cpu_request    = "100m"
  memory_request = "256Mi"

  # Ingress configuration
  enable_ingress        = true
  domain_name          = "example.com"
  traefik_cert_resolver = "letsencrypt"

  # Monitoring
  enable_servicemonitor = true
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.14 |
| helm | ~> 3.0 |
| kubernetes | ~> 2.0 |
| random | ~> 3.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `namespace` | Kubernetes namespace for Consul | `string` | `"consul-stack"` | no |
| `name` | Helm release name | `string` | `"consul"` | no |
| `chart_version` | Helm chart version | `string` | `"1.8.0"` | no |
| `server_replicas` | Number of server replicas (min 2 for HA) | `number` | `2` | no |
| `storage_class` | Storage class for persistent data | `string` | `"hostpath"` | no |
| `cpu_arch` | CPU architecture (amd64, arm64) | `string` | `"amd64"` | no |
| `enable_ingress` | Enable Consul UI ingress | `bool` | `true` | no |
| `domain_name` | Domain name for ingress | `string` | `".local"` | no |

## Module Integration

### Using Module Outputs (Recommended)

Consul provides standardized outputs for module-to-module integration:

```hcl
module "consul" {
  source = "./helm-consul"
  namespace = "consul-system"
}

# Access Consul service information
output "consul_access" {
  value = {
    url          = module.consul[0].url
    service_host = module.consul[0].service_host
    service_port = module.consul[0].service_port
    namespace    = module.consul[0].namespace
  }
}

# ACL token for applications
output "consul_token" {
  value     = module.consul[0].token
  sensitive = true
}
```

### Integration with Applications

Connect applications to Consul for service discovery:

```hcl
# Example: Application using Consul for service discovery
resource "kubernetes_deployment" "app" {
  spec {
    template {
      spec {
        container {
          name  = "myapp"
          image = "myapp:latest"
          env {
            name  = "CONSUL_HTTP_ADDR"
            value = module.consul[0].service_host
          }
        }
      }
    }
  }
}
```

### Retrieving ACL Token

```bash
# Using the output command
terraform output -raw token

# Or using kubectl
kubectl get secret -n consul-system consul-bootstrap-acl-token -o jsonpath='{.data.token}' | base64 -d && echo
```

## Outputs

| Name | Description |
|------|-------------|
| `namespace` | Kubernetes namespace where Consul is deployed |
| `name` | Name of the Consul deployment |
| `url` | Consul server hostname (without port) |
| `uri` | Consul server URI with port (hostname:port format) |
| `service_host` | Consul service hostname (for connection strings) |
| `service_port` | Consul service port |
| `get_acl_secret` | Command to retrieve the ACL bootstrap token |
| `token` | Consul bootstrap token (sensitive) |
| `helm_release` | Helm release information |
| `chart_version` | Helm chart version deployed |
| `resource_limits` | Resource limits applied to Consul |
| `resource_requests` | Resource requests applied to Consul |

## Architecture Support

| Architecture | Status | Notes |
|--------------|--------|-------|
| AMD64 (x86_64) | ✅ Fully Supported | Standard for most servers |
| ARM64 | ✅ Fully Supported | Raspberry Pi, ARM servers |
| Mixed Clusters | ✅ Supported | Use `disable_arch_scheduling` |

## High Availability Configuration

For production deployments:

```hcl
server_replicas = 3  # Odd number recommended
enable_pod_anti_affinity = true  # Spread across nodes
storage_class = "fast-ssd"  # Use fast storage
```

## Service Mesh Features

### Service Registration

Services automatically register with Consul:

```yaml
# Kubernetes service with Consul annotation
apiVersion: v1
kind: Service
metadata:
  name: my-service
  annotations:
    "consul.hashicorp.com/service-sync": "true"
spec:
  ports:
  - port: 8080
```

### Health Checking

Consul provides automatic health checking:

- TCP health checks for services
- HTTP health check endpoints
- Custom health check scripts

## Troubleshooting

### Common Issues

1. **Server Not Starting**
   - Check storage class exists
   - Verify resource limits are sufficient
   - Check pod anti-affinity rules

2. **ACL Token Issues**
   - Token is auto-generated on first deploy
   - Retrieve with `terraform output -raw token`

3. **Service Discovery Not Working**
   - Verify Consul DNS is configured
   - Check service annotations

### Debug Commands

```bash
# Check Consul pods
kubectl get pods -n consul-system

# View Consul server logs
kubectl logs -n consul-system -l component=server

# Test Consul API
kubectl exec -n consul-system deployment/consul-server -- consul members

# Check ACL token
kubectl get secret -n consul-system consul-bootstrap-acl-token
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

APACHE

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.14 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 3.0 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | ~> 1.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_helm"></a> [helm](#provider\_helm) | 3.0.2 |
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | 1.19.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.38.0 |
| <a name="provider_null"></a> [null](#provider\_null) | 3.2.4 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.7.2 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [helm_release.this](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubectl_manifest.consul_servicemonitor](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubernetes_ingress_v1.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/ingress_v1) | resource |
| [kubernetes_limit_range.namespace_limits](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/limit_range) | resource |
| [kubernetes_namespace.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_secret.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [null_resource.pre_upgrade_cleanup](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [random_bytes.gossip_encryption_key](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/bytes) | resource |
| [kubernetes_secret.token](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/secret) | data source |
| [kubernetes_service.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/service) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_chart_name"></a> [chart\_name](#input\_chart\_name) | Helm name. | `string` | `"consul"` | no |
| <a name="input_chart_repo"></a> [chart\_repo](#input\_chart\_repo) | Helm repository name. | `string` | `"https://helm.releases.hashicorp.com"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Helm version. | `string` | `"1.9.3"` | no |
| <a name="input_ci_mode"></a> [ci\_mode](#input\_ci\_mode) | Running in CI mode (kubeconfig handled externally via KUBECONFIG env var) | `bool` | `false` | no |
| <a name="input_client_replicas"></a> [client\_replicas](#input\_client\_replicas) | Number of Consul client replicas (typically matches node count or use DaemonSet) | `number` | `0` | no |
| <a name="input_consul_image_version"></a> [consul\_image\_version](#input\_consul\_image\_version) | Consul image version | `string` | `"1.19.1"` | no |
| <a name="input_consul_k8s_image_version"></a> [consul\_k8s\_image\_version](#input\_consul\_k8s\_image\_version) | Consul K8S image version | `string` | `"1.4.1"` | no |
| <a name="input_cpu_arch"></a> [cpu\_arch](#input\_cpu\_arch) | CPU architecture for node selection (amd64, arm64) | `string` | `"amd64"` | no |
| <a name="input_cpu_limit"></a> [cpu\_limit](#input\_cpu\_limit) | Default CPU limit for containers | `string` | `"200m"` | no |
| <a name="input_cpu_request"></a> [cpu\_request](#input\_cpu\_request) | Default CPU request for containers | `string` | `"50m"` | no |
| <a name="input_disable_arch_scheduling"></a> [disable\_arch\_scheduling](#input\_disable\_arch\_scheduling) | Disable architecture-based node scheduling (useful for cluster-wide services) | `bool` | `false` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Domain name for the Consul deployment. | `string` | `".local"` | no |
| <a name="input_enable_ingress"></a> [enable\_ingress](#input\_enable\_ingress) | Enable ingress for the Consul deployment. | `bool` | `true` | no |
| <a name="input_enable_pod_anti_affinity"></a> [enable\_pod\_anti\_affinity](#input\_enable\_pod\_anti\_affinity) | Enable pod anti-affinity rules to spread servers across nodes (disable for small clusters) | `bool` | `true` | no |
| <a name="input_enable_servicemonitor"></a> [enable\_servicemonitor](#input\_enable\_servicemonitor) | Enable ServiceMonitor for Prometheus metrics collection (requires prometheus-operator CRDs). | `bool` | `false` | no |
| <a name="input_helm_cleanup_on_fail"></a> [helm\_cleanup\_on\_fail](#input\_helm\_cleanup\_on\_fail) | Cleanup resources on failure | `bool` | `false` | no |
| <a name="input_helm_disable_webhooks"></a> [helm\_disable\_webhooks](#input\_helm\_disable\_webhooks) | Disable webhooks for Helm release | `bool` | `true` | no |
| <a name="input_helm_force_update"></a> [helm\_force\_update](#input\_helm\_force\_update) | Force resource updates if needed | `bool` | `true` | no |
| <a name="input_helm_replace"></a> [helm\_replace](#input\_helm\_replace) | Allow Helm to replace existing resources | `bool` | `true` | no |
| <a name="input_helm_skip_crds"></a> [helm\_skip\_crds](#input\_helm\_skip\_crds) | Skip CRDs for Helm release | `bool` | `false` | no |
| <a name="input_helm_timeout"></a> [helm\_timeout](#input\_helm\_timeout) | Timeout for Helm deployment in seconds | `number` | `300` | no |
| <a name="input_helm_wait"></a> [helm\_wait](#input\_helm\_wait) | Wait for Helm release to be ready | `bool` | `false` | no |
| <a name="input_helm_wait_for_jobs"></a> [helm\_wait\_for\_jobs](#input\_helm\_wait\_for\_jobs) | Wait for Helm jobs to complete | `bool` | `false` | no |
| <a name="input_kubeconfig_path"></a> [kubeconfig\_path](#input\_kubeconfig\_path) | Explicit kubeconfig path (overrides automatic detection) | `string` | `""` | no |
| <a name="input_memory_limit"></a> [memory\_limit](#input\_memory\_limit) | Default memory limit for containers | `string` | `"256Mi"` | no |
| <a name="input_memory_request"></a> [memory\_request](#input\_memory\_request) | Default memory request for containers | `string` | `"128Mi"` | no |
| <a name="input_name"></a> [name](#input\_name) | Helm name. | `string` | `"consul"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace. | `string` | `"consul-stack"` | no |
| <a name="input_persistent_disk_size"></a> [persistent\_disk\_size](#input\_persistent\_disk\_size) | Persistent disk size for Consul storage in GB. | `string` | `"1"` | no |
| <a name="input_server_replicas"></a> [server\_replicas](#input\_server\_replicas) | Number of Consul server replicas (minimum 2 for HA, recommended 3 for production) | `number` | `2` | no |
| <a name="input_service_overrides"></a> [service\_overrides](#input\_service\_overrides) | Override default service configuration | <pre>object({<br/>    helm_config = optional(object({<br/>      chart_name       = optional(string)<br/>      chart_repo       = optional(string)<br/>      chart_version    = optional(string)<br/>      timeout          = optional(number)<br/>      disable_webhooks = optional(bool)<br/>      skip_crds        = optional(bool)<br/>      replace          = optional(bool)<br/>      force_update     = optional(bool)<br/>      cleanup_on_fail  = optional(bool)<br/>      wait             = optional(bool)<br/>      wait_for_jobs    = optional(bool)<br/>    }), {})<br/>    labels          = optional(map(string), {})<br/>    template_values = optional(map(any), {})<br/>  })</pre> | <pre>{<br/>  "helm_config": {},<br/>  "labels": {},<br/>  "template_values": {}<br/>}</pre> | no |
| <a name="input_storage_class"></a> [storage\_class](#input\_storage\_class) | Storage class to use for Consul persistent storage. | `string` | `"hostpath"` | no |
| <a name="input_traefik_cert_resolver"></a> [traefik\_cert\_resolver](#input\_traefik\_cert\_resolver) | Traefik certificate resolver to use for ingress. | `string` | `"default"` | no |
| <a name="input_traefik_ingress_config"></a> [traefik\_ingress\_config](#input\_traefik\_ingress\_config) | Traefik ingress configuration from Traefik module | <pre>object({<br/>    class_name    = string<br/>    annotations   = map(string)<br/>    cert_resolver = string<br/>    domain_name   = string<br/>  })</pre> | `null` | no |
| <a name="input_workspace_prefix"></a> [workspace\_prefix](#input\_workspace\_prefix) | Workspace prefix for kubeconfig file selection (e.g., 'prod' uses ~/.kube/prod-config) | `string` | `""` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_chart_version"></a> [chart\_version](#output\_chart\_version) | Helm chart version deployed |
| <a name="output_get_acl_secret"></a> [get\_acl\_secret](#output\_get\_acl\_secret) | Command to retrieve the ACL bootstrap token from the Kubernetes secret |
| <a name="output_helm_release"></a> [helm\_release](#output\_helm\_release) | Helm release information |
| <a name="output_name"></a> [name](#output\_name) | Name of the Consul deployment |
| <a name="output_namespace"></a> [namespace](#output\_namespace) | Kubernetes namespace where Consul is deployed |
| <a name="output_resource_limits"></a> [resource\_limits](#output\_resource\_limits) | Resource limits applied to Consul |
| <a name="output_resource_requests"></a> [resource\_requests](#output\_resource\_requests) | Resource requests applied to Consul |
| <a name="output_service_host"></a> [service\_host](#output\_service\_host) | Consul service hostname (for connection strings) |
| <a name="output_service_port"></a> [service\_port](#output\_service\_port) | Consul service port |
| <a name="output_token"></a> [token](#output\_token) | Consul bootstrap token |
| <a name="output_uri"></a> [uri](#output\_uri) | Consul server URI with port (hostname:port format) |
| <a name="output_url"></a> [url](#output\_url) | Consul server hostname (without port) |
<!-- END_TF_DOCS -->
