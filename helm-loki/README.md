# Loki Helm Module

This Terraform module deploys Grafana Loki for log aggregation using the official Helm chart.

## Features

- **📋 Log Aggregation**: Centralized log collection and storage
- **🗄️ Flexible Storage**: Support for S3 and filesystem storage backends
- **⏰ Retention Policies**: Configurable log retention periods
- **🔍 LogQL**: Powerful query language for log analysis
- **📊 Monitoring**: Prometheus metrics integration
- **⚡ Performance**: Optimized for high-throughput log ingestion
- **🔧 Configurable**: Extensive configuration options

## Usage

### Basic Usage

```hcl
module "loki" {
  source = "./helm-loki"

  namespace = "monitoring"

  storage_class = "fast-ssd"
  storage_size  = "20Gi"
}
```

### Advanced Configuration

```hcl
module "loki" {
  source = "./helm-loki"

  namespace     = "monitoring"
  chart_version = "6.16.0"

  storage_class = "fast-ssd"
  storage_size  = "50Gi"

  # Resource configuration
  cpu_limit      = "1000m"
  memory_limit   = "2Gi"
  cpu_request    = "500m"
  memory_request = "1Gi"

  # Ingress configuration
  enable_ingress        = true
  domain_name          = "example.com"
  traefik_cert_resolver = "letsencrypt"
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

| Name | Type |
|------|------|
| kubernetes_namespace.this | resource |
| helm_release.this | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| namespace | Namespace for Loki | `string` | `"loki-system"` | no |
| name | Helm release name | `string` | `"loki"` | no |
| chart_name | Helm chart name | `string` | `"loki"` | no |
| chart_repo | Helm repository | `string` | `"https://grafana.github.io/helm-charts"` | no |
| chart_version | Helm chart version | `string` | `"6.16.0"` | no |
| storage_class | Storage class for Loki | `string` | `"hostpath"` | no |
| storage_size | Storage size for Loki | `string` | `"10Gi"` | no |
| cpu_limit | CPU limit for Loki | `string` | `"200m"` | no |
| memory_limit | Memory limit for Loki | `string` | `"256Mi"` | no |
| cpu_request | CPU request for Loki | `string` | `"50m"` | no |
| memory_request | Memory request for Loki | `string` | `"64Mi"` | no |
| cpu_arch | CPU architecture | `string` | `"amd64"` | no |
| domain_name | Domain name for ingress | `string` | `".local"` | no |
| traefik_cert_resolver | Traefik certificate resolver | `string` | `"default"` | no |
| enable_ingress | Enable Traefik ingress for Loki | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| namespace | Loki namespace |
| loki_url | Loki service URL |

## Storage Configuration

### Local Storage

For development and testing:

- Uses hostpath storage class
- Data stored on node filesystem
- Not suitable for production

### Persistent Storage

For production deployments:

- Use cloud storage classes (EBS, GCE-PD, etc.)
- Ensures data persistence across pod restarts
- Better performance and reliability

## Monitoring

Loki exposes metrics on port 3100 that can be scraped by Prometheus:

- `/metrics` - Loki metrics
- `/ready` - Readiness probe
- `/loki/api/v1/push` - Log ingestion endpoint

## Ingress Configuration

When `enable_ingress = true`, the module creates a Traefik IngressRoute:

- Exposes Loki API on `loki.{domain_name}`
- Automatic TLS with configured cert resolver
- Suitable for external log shipping

## Security Considerations

- Loki API is exposed without authentication by default
- Consider network policies to restrict access
- Use TLS for external exposure
- Regular backup of log data

## Troubleshooting

### Common Issues

1. **Storage Issues**: Ensure storage class exists and has sufficient capacity
2. **Memory Pressure**: Increase memory limits for high-volume logging
3. **Network Connectivity**: Verify ingress configuration and DNS resolution

### Debug Commands

```bash
# Check Loki pods
kubectl get pods -n {namespace} -l app=loki

# View Loki logs
kubectl logs -n {namespace} -l app=loki

# Test Loki API
curl http://loki.{domain_name}/loki/api/v1/label
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
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 3.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.20 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | ~> 3.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | ~> 2.20 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.this](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_ingress_v1.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/ingress_v1) | resource |
| [kubernetes_limit_range.namespace_limits](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/limit_range) | resource |
| [kubernetes_namespace.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_service.gateway](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/service) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_chart_name"></a> [chart\_name](#input\_chart\_name) | Helm chart name | `string` | `"loki"` | no |
| <a name="input_chart_repo"></a> [chart\_repo](#input\_chart\_repo) | Helm repository | `string` | `"https://grafana.github.io/helm-charts"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Helm chart version | `string` | `"6.16.0"` | no |
| <a name="input_cpu_arch"></a> [cpu\_arch](#input\_cpu\_arch) | CPU architecture | `string` | `"amd64"` | no |
| <a name="input_cpu_limit"></a> [cpu\_limit](#input\_cpu\_limit) | CPU limit for Loki | `string` | `"200m"` | no |
| <a name="input_cpu_request"></a> [cpu\_request](#input\_cpu\_request) | CPU request for Loki | `string` | `"50m"` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Domain name for ingress | `string` | `".local"` | no |
| <a name="input_enable_ingress"></a> [enable\_ingress](#input\_enable\_ingress) | Enable Traefik ingress for Loki | `bool` | `false` | no |
| <a name="input_helm_cleanup_on_fail"></a> [helm\_cleanup\_on\_fail](#input\_helm\_cleanup\_on\_fail) | Cleanup on fail | `bool` | `true` | no |
| <a name="input_helm_disable_webhooks"></a> [helm\_disable\_webhooks](#input\_helm\_disable\_webhooks) | Disable webhooks | `bool` | `true` | no |
| <a name="input_helm_force_update"></a> [helm\_force\_update](#input\_helm\_force\_update) | Force update | `bool` | `true` | no |
| <a name="input_helm_replace"></a> [helm\_replace](#input\_helm\_replace) | Replace resources | `bool` | `false` | no |
| <a name="input_helm_skip_crds"></a> [helm\_skip\_crds](#input\_helm\_skip\_crds) | Skip CRDs | `bool` | `false` | no |
| <a name="input_helm_timeout"></a> [helm\_timeout](#input\_helm\_timeout) | Helm timeout | `number` | `600` | no |
| <a name="input_helm_wait"></a> [helm\_wait](#input\_helm\_wait) | Wait for deployment | `bool` | `true` | no |
| <a name="input_helm_wait_for_jobs"></a> [helm\_wait\_for\_jobs](#input\_helm\_wait\_for\_jobs) | Wait for jobs | `bool` | `true` | no |
| <a name="input_memory_limit"></a> [memory\_limit](#input\_memory\_limit) | Memory limit for Loki | `string` | `"256Mi"` | no |
| <a name="input_memory_request"></a> [memory\_request](#input\_memory\_request) | Memory request for Loki | `string` | `"64Mi"` | no |
| <a name="input_name"></a> [name](#input\_name) | Helm release name | `string` | `"loki"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace for Loki | `string` | `"loki-system"` | no |
| <a name="input_storage_class"></a> [storage\_class](#input\_storage\_class) | Storage class for Loki | `string` | `"hostpath"` | no |
| <a name="input_storage_size"></a> [storage\_size](#input\_storage\_size) | Storage size for Loki | `string` | `"10Gi"` | no |
| <a name="input_traefik_cert_resolver"></a> [traefik\_cert\_resolver](#input\_traefik\_cert\_resolver) | Traefik certificate resolver | `string` | `"default"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_loki_url"></a> [loki\_url](#output\_loki\_url) | n/a |
| <a name="output_namespace"></a> [namespace](#output\_namespace) | n/a |
<!-- END_TF_DOCS -->
