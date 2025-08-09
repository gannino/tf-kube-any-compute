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
