# Grafana Helm Module

This Terraform module deploys Grafana for visualization and monitoring dashboards using the official Helm chart.

## Features

- **📊 Visualization Platform**: Create beautiful dashboards and graphs
- **🔍 Multi-Source Support**: Prometheus, Loki, InfluxDB, and more
- **🎨 Rich Dashboard Library**: Pre-built dashboards and templates
- **👥 User Management**: Role-based access control and authentication
- **📱 Alerting**: Notification channels and alert rules
- **🔧 Extensible**: Plugin ecosystem for additional functionality
- **📋 Data Exploration**: Query builder and data investigation tools
- **⚡ Performance**: Optimized for large-scale monitoring deployments

## Usage

### Basic Usage

```hcl
module "grafana" {
  source = "./helm-grafana"
  
  namespace = "monitoring"
  
  admin_password = "secure-password"
  domain_name   = "example.com"
}
```

### Advanced Configuration

```hcl
module "grafana" {
  source = "./helm-grafana"
  
  namespace     = "monitoring"
  chart_version = "8.5.2"
  
  # Authentication
  admin_password = "secure-admin-password"
  
  # Ingress configuration
  domain_name          = "example.com"
  traefik_cert_resolver = "letsencrypt"
  
  # Resource configuration
  cpu_limit      = "1000m"
  memory_limit   = "1Gi"
  cpu_request    = "500m"
  memory_request = "512Mi"
  
  # Storage configuration
  storage_class = "fast-ssd"
  storage_size  = "5Gi"
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
| namespace | Namespace for Grafana | `string` | `"grafana-system"` | no |
| name | Helm release name | `string` | `"grafana"` | no |
| chart_name | Helm chart name | `string` | `"grafana"` | no |
| chart_repo | Helm repository | `string` | `"https://grafana.github.io/helm-charts"` | no |
| chart_version | Helm chart version | `string` | `"8.5.2"` | no |
| admin_password | Grafana admin password | `string` | `""` | no |
| storage_class | Storage class for Grafana | `string` | `"hostpath"` | no |
| storage_size | Storage size for Grafana | `string` | `"2Gi"` | no |
| cpu_limit | CPU limit for Grafana | `string` | `"200m"` | no |
| memory_limit | Memory limit for Grafana | `string` | `"256Mi"` | no |
| cpu_request | CPU request for Grafana | `string` | `"100m"` | no |
| memory_request | Memory request for Grafana | `string` | `"128Mi"` | no |
| cpu_arch | CPU architecture constraint | `string` | `"amd64"` | no |
| domain_name | Domain name for ingress | `string` | `".local"` | no |
| traefik_cert_resolver | Traefik certificate resolver | `string` | `"default"` | no |

## Outputs

| Name | Description |
|------|-------------|
| namespace | Grafana namespace |
| grafana_url | Grafana dashboard URL |
| admin_password | Generated admin password |

## Data Sources Configuration

### Prometheus Integration

Grafana automatically connects to Prometheus for metrics visualization:

```yaml
# Prometheus data source configuration
datasources:
  - name: Prometheus
    type: prometheus
    url: http://prometheus.monitoring.svc.cluster.local:9090
    access: proxy
    isDefault: true
```

### Loki Integration

For log visualization and correlation:

```yaml
# Loki data source configuration
datasources:
  - name: Loki
    type: loki
    url: http://loki.loki-system.svc.cluster.local:3100
    access: proxy
```

## Dashboard Management

### Pre-installed Dashboards

The module includes popular monitoring dashboards:

- **Kubernetes Overview**: Cluster-wide metrics and health
- **Node Metrics**: CPU, memory, disk, and network utilization
- **Pod Monitoring**: Application-level metrics and logs
- **Ingress Monitoring**: Traefik traffic and performance

### Custom Dashboard Import

```bash
# Import dashboard via UI
1. Navigate to Dashboards > Browse
2. Click "Import"
3. Enter dashboard ID or upload JSON
4. Configure data source mappings
```

### Dashboard as Code

```hcl
# Add custom dashboards via ConfigMap
resource "kubernetes_config_map" "custom_dashboards" {
  metadata {
    name      = "custom-dashboards"
    namespace = var.namespace
    labels = {
      grafana_dashboard = "1"
    }
  }
  
  data = {
    "custom-dashboard.json" = file("${path.module}/dashboards/custom.json")
  }
}
```

## Authentication & Security

### Admin Access

Default admin credentials:

- **Username**: `admin`
- **Password**: Auto-generated or custom via `admin_password`

### Role-Based Access Control

Configure user roles and permissions:

```yaml
# Grafana RBAC configuration
rbac:
  create: true
  permissions:
    - action: "dashboards:read"
      scope: "dashboards:*"
    - action: "datasources:read"
      scope: "datasources:*"
```

### External Authentication

Support for OAuth, LDAP, and SAML:

```yaml
# OAuth configuration example
auth:
  oauth:
    github:
      enabled: true
      client_id: "your-client-id"
      client_secret: "your-client-secret"
      scopes: "user:email,read:org"
      auth_url: "https://github.com/login/oauth/authorize"
      token_url: "https://github.com/login/oauth/access_token"
```

## Storage Configuration

### Persistent Storage

Grafana uses persistent storage for:

- **Dashboards**: Custom dashboard configurations
- **Users & Settings**: User accounts and preferences  
- **Plugins**: Installed plugins and data
- **Annotations**: Dashboard annotations and events

### Storage Classes

- **Production**: Use network storage (NFS, EBS, etc.)
- **Development**: HostPath storage acceptable
- **High Availability**: Use ReadWriteMany storage classes

## Monitoring & Alerting

### Grafana Metrics

Grafana exposes metrics for self-monitoring:

```yaml
# Prometheus scrape config for Grafana
scrape_configs:
  - job_name: 'grafana'
    static_configs:
      - targets: ['grafana.monitoring.svc.cluster.local:3000']
    metrics_path: '/metrics'
```

### Alert Notifications

Configure notification channels:

```yaml
# Email notification channel
notifiers:
  - name: email-alerts
    type: email
    settings:
      addresses: "admin@example.com"
      subject: "Grafana Alert"
```

## Performance Optimization

### Resource Tuning

For different deployment sizes:

```hcl
# Small deployment
cpu_limit = "200m"
memory_limit = "256Mi"
storage_size = "1Gi"

# Medium deployment  
cpu_limit = "500m"
memory_limit = "512Mi"
storage_size = "5Gi"

# Large deployment
cpu_limit = "1000m"
memory_limit = "2Gi"
storage_size = "20Gi"
```

### Query Performance

Optimize dashboard queries:

- **Use recording rules** for complex calculations
- **Limit time ranges** for expensive queries
- **Cache data sources** for frequently accessed data
- **Use variables** for dynamic dashboard filtering

## Architecture Support

### ARM64 (Raspberry Pi)

```hcl
cpu_arch = "arm64"
cpu_limit = "200m"
memory_limit = "256Mi"
```

### AMD64 (x86_64)

```hcl
cpu_arch = "amd64"
cpu_limit = "500m"
memory_limit = "512Mi"
```

## Troubleshooting

### Common Issues

1. **Login Problems**: Check admin password and user credentials
2. **Dashboard Loading**: Verify data source connectivity
3. **Storage Issues**: Check PVC status and storage class
4. **Performance**: Monitor resource usage and query complexity

### Debug Commands

```bash
# Check Grafana pods
kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana

# View Grafana logs
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana

# Access Grafana directly
kubectl port-forward -n monitoring svc/grafana 3000:80

# Check storage
kubectl get pvc -n monitoring
```

### Configuration Validation

```bash
# Check Grafana configuration
kubectl exec -n monitoring deployment/grafana -- grafana-cli admin stats

# Test data source connectivity
curl -u admin:password http://grafana.example.com/api/datasources
```

## Plugin Management

### Installing Plugins

```yaml
# Grafana plugins configuration
plugins:
  - grafana-piechart-panel
  - grafana-worldmap-panel
  - grafana-clock-panel
```

### Plugin Development

Create custom panels and data sources:

```bash
# Plugin development setup
npm install -g @grafana/toolkit
grafana-toolkit plugin:create my-plugin
```

## Backup & Recovery

### Dashboard Backup

```bash
# Export all dashboards
curl -u admin:password http://grafana.example.com/api/search | \
  jq -r '.[] | select(.type == "dash-db") | .uid' | \
  xargs -I {} curl -u admin:password http://grafana.example.com/api/dashboards/uid/{}
```

### Data Migration

```bash
# Backup Grafana database
kubectl exec -n monitoring grafana-0 -- sqlite3 /var/lib/grafana/grafana.db .dump > backup.sql

# Restore from backup
kubectl cp backup.sql monitoring/grafana-0:/tmp/
kubectl exec -n monitoring grafana-0 -- sqlite3 /var/lib/grafana/grafana.db < /tmp/backup.sql
```

## Security Considerations

- **Change Default Password**: Always set custom admin password
- **Use HTTPS**: Enable TLS for all dashboard access
- **Regular Updates**: Keep Grafana version current
- **Access Control**: Implement proper user roles and permissions
- **Network Policies**: Restrict pod-to-pod communication

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

MIT
