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
