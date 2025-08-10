# Portainer Helm Module

This Terraform module deploys Portainer for container management and Kubernetes administration using the official Helm chart.

## Features

- **🐳 Container Management**: Visual interface for Docker and Kubernetes
- **📋 Kubernetes Dashboard**: Comprehensive cluster management UI
- **👥 Multi-User Support**: Role-based access control and team management
- **🎯 Application Templates**: Quick deployment of common applications
- **📊 Resource Monitoring**: Real-time container and cluster metrics
- **🔧 GitOps Integration**: Deploy applications from Git repositories
- **🛡️ Security Scanning**: Container image vulnerability scanning
- **📱 Mobile Friendly**: Responsive web interface for mobile devices

## Usage

### Basic Usage

```hcl
module "portainer" {
  source = "./helm-portainer"

  namespace = "portainer-system"

  admin_password = "secure-password"
  domain_name = "example.com"
}
```

### Advanced Configuration

```hcl
module "portainer" {
  source = "./helm-portainer"

  namespace     = "portainer-system"
  chart_version = "1.0.54"

  # Authentication
  admin_password = "secure-admin-password"

  # Ingress configuration
  domain_name          = "example.com"
  traefik_cert_resolver = "letsencrypt"

  # Resource configuration
  cpu_limit      = "500m"
  memory_limit   = "512Mi"
  cpu_request    = "250m"
  memory_request = "256Mi"

  # Storage configuration
  storage_class = "fast-ssd"
  storage_size  = "2Gi"

  # Features
  enable_edge_compute = true
  enable_analytics    = false
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
| kubernetes_persistent_volume_claim.portainer | resource |
| helm_release.this | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| namespace | Namespace for Portainer | `string` | `"portainer-system"` | no |
| name | Helm release name | `string` | `"portainer"` | no |
| chart_name | Helm chart name | `string` | `"portainer"` | no |
| chart_repo | Helm repository | `string` | `"https://portainer.github.io/k8s/"` | no |
| chart_version | Helm chart version | `string` | `"1.0.54"` | no |
| admin_password | Portainer admin password | `string` | `""` | no |
| storage_class | Storage class for Portainer | `string` | `"hostpath"` | no |
| storage_size | Storage size for Portainer | `string` | `"1Gi"` | no |
| cpu_limit | CPU limit for Portainer | `string` | `"300m"` | no |
| memory_limit | Memory limit for Portainer | `string` | `"300Mi"` | no |
| cpu_request | CPU request for Portainer | `string` | `"100m"` | no |
| memory_request | Memory request for Portainer | `string` | `"128Mi"` | no |
| cpu_arch | CPU architecture constraint | `string` | `"amd64"` | no |
| domain_name | Domain name for ingress | `string` | `".local"` | no |
| traefik_cert_resolver | Traefik certificate resolver | `string` | `"default"` | no |
| enable_edge_compute | Enable edge compute features | `bool` | `false` | no |
| enable_analytics | Enable analytics collection | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| namespace | Portainer namespace |
| portainer_url | Portainer web UI URL |
| admin_password | Generated admin password |

## Initial Setup

### First Login

After deployment, access Portainer to complete initial setup:

1. **Navigate** to the Portainer URL
2. **Create Admin User**: Set admin username and password
3. **Select Environment**: Choose Kubernetes environment
4. **Configure Access**: Portainer auto-detects cluster connection

### Admin Password

If not provided, a secure password is auto-generated:

```bash
# Retrieve auto-generated password
terraform output -raw admin_password

# Access Portainer
https://portainer.example.com
```

## Container Management

### Docker Container Operations

Through Portainer's interface:

- **Container Lifecycle**: Start, stop, restart, remove containers
- **Log Viewing**: Real-time and historical container logs
- **Resource Monitoring**: CPU, memory, network usage
- **Console Access**: Interactive shell access to containers
- **File Management**: Browse and edit container filesystems

### Kubernetes Workload Management

- **Pod Management**: View, restart, delete pods
- **Deployment Scaling**: Scale deployments up/down
- **Service Configuration**: Manage services and ingresses
- **ConfigMap/Secret Management**: Create and edit configurations
- **Namespace Operations**: Switch between namespaces

## Application Deployment

### Application Templates

Portainer includes templates for common applications:

- **Database**: PostgreSQL, MySQL, MongoDB templates
- **Web Servers**: Nginx, Apache, Traefik configurations
- **Monitoring**: Prometheus, Grafana, ElasticSearch stacks
- **CI/CD**: Jenkins, GitLab Runner, ArgoCD templates
- **Storage**: MinIO, NextCloud, NFS servers

### Custom Templates

Create custom application templates:

```json
{
  "version": "2",
  "templates": [
    {
      "type": 3,
      "title": "My Application",
      "description": "Custom application deployment",
      "note": "Deploy my custom application",
      "categories": ["Custom"],
      "platform": "linux",
      "repository": {
        "url": "https://github.com/myuser/my-app",
        "stackfile": "docker-compose.yml"
      }
    }
  ]
}
```

### GitOps Deployment

Deploy applications from Git repositories:

1. **Add Git Repository**: Configure repository access
2. **Select Compose File**: Choose docker-compose.yml or Kubernetes manifests
3. **Environment Variables**: Set deployment-specific variables
4. **Deploy**: Launch application stack
5. **Monitor**: Track deployment status and health

## Access Control

### User Management

Configure team-based access control:

```yaml
# User roles in Portainer
roles:
  - name: "developers"
    permissions:
      - "ContainerDeploy"
      - "ContainerView"
      - "ServiceView"

  - name: "operators"
    permissions:
      - "ContainerManage"
      - "ServiceManage"
      - "VolumeManage"
      - "NetworkManage"

  - name: "administrators"
    permissions:
      - "EndpointManage"
      - "UserManage"
      - "TeamManage"
      - "SettingsManage"
```

### RBAC Integration

Portainer respects Kubernetes RBAC:

```yaml
# ServiceAccount for Portainer
apiVersion: v1
kind: ServiceAccount
metadata:
  name: portainer-sa
  namespace: portainer-system
---
# ClusterRoleBinding for full access
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: portainer
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: portainer-sa
  namespace: portainer-system
```

## Monitoring & Observability

### Resource Monitoring

Portainer provides real-time monitoring:

- **Container Metrics**: CPU, memory, network, disk I/O
- **Cluster Overview**: Node status, resource allocation
- **Application Health**: Service availability and performance
- **Storage Usage**: Volume utilization and trends

### Integration with External Monitoring

Connect Portainer with existing monitoring:

```yaml
# Prometheus ServiceMonitor for Portainer
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: portainer
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: portainer
  endpoints:
  - port: http
    path: /metrics
    interval: 30s
```

## Security Features

### Security Scanning

Enable container image vulnerability scanning:

- **Image Analysis**: Scan images for known vulnerabilities
- **Policy Enforcement**: Block deployments with high-risk vulnerabilities
- **Compliance Reports**: Generate security compliance reports
- **Remediation Guidance**: Suggested fixes for identified issues

### Network Security

Portainer security best practices:

- **TLS Encryption**: Always use HTTPS for web interface
- **Network Policies**: Restrict Portainer pod network access
- **Secret Management**: Store sensitive data in Kubernetes secrets
- **Audit Logging**: Enable audit logs for compliance

## Edge Computing

### Edge Agent Deployment

For managing remote Kubernetes clusters:

```bash
# Deploy Portainer Edge Agent
kubectl apply -f https://downloads.portainer.io/agent/latest/portainer-agent-edge-k8s.yaml
```

### Edge Cluster Management

- **Remote Cluster Access**: Manage clusters across different networks
- **Asynchronous Communication**: Works with intermittent connectivity
- **Centralized Management**: Single pane of glass for all clusters
- **Secure Tunneling**: Encrypted communication channels

## Storage Management

### Persistent Storage

Portainer data includes:

- **User Configurations**: User accounts, teams, and settings
- **Application Templates**: Custom templates and configurations
- **Deployment History**: Stack deployment history and logs
- **Security Policies**: Access control and security configurations

### Backup and Migration

```bash
# Backup Portainer data
kubectl exec -n portainer-system portainer-0 -- tar -czf /backup/portainer-data.tar.gz /data

# Copy backup from pod
kubectl cp portainer-system/portainer-0:/backup/portainer-data.tar.gz ./portainer-backup.tar.gz

# Restore data (to new pod)
kubectl cp ./portainer-backup.tar.gz portainer-system/portainer-0:/backup/
kubectl exec -n portainer-system portainer-0 -- tar -xzf /backup/portainer-data.tar.gz -C /
```

## Architecture Support

### ARM64 (Raspberry Pi)

```hcl
cpu_arch = "arm64"
cpu_limit = "200m"
memory_limit = "256Mi"
storage_size = "1Gi"
```

### AMD64 (x86_64)

```hcl
cpu_arch = "amd64"
cpu_limit = "500m"
memory_limit = "512Mi"
storage_size = "2Gi"
```

## Integration Examples

### CI/CD Pipeline Integration

Use Portainer API for automated deployments:

```bash
# Deploy stack via API
curl -X POST "https://portainer.example.com/api/stacks" \
  -H "Authorization: Bearer $PORTAINER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "my-app",
    "swarmId": "",
    "repositoryUrl": "https://github.com/myuser/my-app",
    "repositoryReferenceName": "refs/heads/main",
    "composeFilePathInRepository": "docker-compose.yml"
  }'
```

### Webhook Deployments

Automatic deployment from Git webhooks:

```yaml
# Webhook configuration
webhooks:
  - id: "deploy-webhook"
    token: "secure-webhook-token"
    endpoint: "https://portainer.example.com/api/webhooks/deploy"
    events: ["push"]
    repository: "https://github.com/myuser/my-app"
```

## Performance Optimization

### Resource Tuning

```hcl
# Production environment
cpu_limit = "1000m"
memory_limit = "1Gi"
storage_size = "5Gi"

# Development environment
cpu_limit = "200m"
memory_limit = "256Mi"
storage_size = "1Gi"
```

### UI Performance

Optimize Portainer UI performance:

- **Reduce Polling Frequency**: Adjust refresh intervals
- **Filter Large Lists**: Use search and filters effectively
- **Limit Displayed Items**: Paginate large result sets
- **Disable Unnecessary Features**: Turn off unused functionality

## Troubleshooting

### Common Issues

1. **Access Denied**: Check RBAC permissions and service account
2. **Slow Performance**: Verify resource limits and cluster health
3. **Connection Issues**: Validate ingress configuration and DNS
4. **Storage Problems**: Check PVC status and storage class

### Debug Commands

```bash
# Check Portainer pods
kubectl get pods -n portainer-system -l app=portainer

# View Portainer logs
kubectl logs -n portainer-system -l app=portainer

# Check storage
kubectl get pvc -n portainer-system

# Test direct access
kubectl port-forward -n portainer-system svc/portainer 9000:9000
```

### API Troubleshooting

```bash
# Test Portainer API
curl -X GET "https://portainer.example.com/api/endpoints" \
  -H "Authorization: Bearer $PORTAINER_TOKEN"

# Check authentication
curl -X POST "https://portainer.example.com/api/auth" \
  -H "Content-Type: application/json" \
  -d '{"Username":"admin","Password":"password"}'
```

## Migration and Upgrades

### Version Upgrades

```bash
# Backup before upgrade
kubectl exec -n portainer-system portainer-0 -- tar -czf /backup/pre-upgrade.tar.gz /data

# Upgrade Helm chart
helm upgrade portainer portainer/portainer -n portainer-system

# Verify upgrade
kubectl get pods -n portainer-system
```

### Data Migration

Moving from Docker Swarm to Kubernetes:

1. **Export Configurations**: Extract templates and settings
2. **Recreate Users**: Set up user accounts and teams
3. **Import Templates**: Apply custom application templates
4. **Reconfigure Access**: Update RBAC and permissions

## Best Practices

### Security
- Use strong admin passwords
- Enable TLS for all connections
- Implement proper RBAC
- Regular security updates
- Audit user access regularly

### Operations
- Monitor resource usage
- Regular data backups
- Document custom templates
- Test disaster recovery procedures
- Keep deployment configurations in version control

### Performance
- Right-size resource limits
- Use appropriate storage classes
- Monitor API response times
- Optimize dashboard queries
- Regular maintenance schedules

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

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | ~> 3.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | ~> 2.0 |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.this](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_limit_range.namespace_limits](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/limit_range) | resource |
| [kubernetes_manifest.portainer_ingress](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_namespace.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_persistent_volume_claim.portainer](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume_claim) | resource |
| [random_password.portainer_admin](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [kubernetes_service.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/service) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_chart_name"></a> [chart\_name](#input\_chart\_name) | Helm chart name for Portainer. | `string` | `"portainer"` | no |
| <a name="input_chart_repo"></a> [chart\_repo](#input\_chart\_repo) | Helm repository URL for Portainer charts. | `string` | `"https://portainer.github.io/k8s/"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Helm chart version for Portainer. | `string` | `"1.0.69"` | no |
| <a name="input_cpu_arch"></a> [cpu\_arch](#input\_cpu\_arch) | CPU architecture for container images (amd64, arm64). | `string` | n/a | yes |
| <a name="input_cpu_limit"></a> [cpu\_limit](#input\_cpu\_limit) | CPU limit for Portainer containers. | `string` | `"200m"` | no |
| <a name="input_cpu_request"></a> [cpu\_request](#input\_cpu\_request) | CPU request for Portainer containers. | `string` | `"25m"` | no |
| <a name="input_disable_arch_scheduling"></a> [disable\_arch\_scheduling](#input\_disable\_arch\_scheduling) | Disable architecture-based node scheduling. | `bool` | `false` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Domain name for Portainer ingress. | `string` | `".local"` | no |
| <a name="input_enable_portainer_ingress"></a> [enable\_portainer\_ingress](#input\_enable\_portainer\_ingress) | Enable Portainer ingress configuration. | `bool` | `false` | no |
| <a name="input_enable_portainer_ingress_route"></a> [enable\_portainer\_ingress\_route](#input\_enable\_portainer\_ingress\_route) | Enable Portainer ingress route configuration. | `bool` | `false` | no |
| <a name="input_helm_cleanup_on_fail"></a> [helm\_cleanup\_on\_fail](#input\_helm\_cleanup\_on\_fail) | Cleanup resources on deployment failure. | `bool` | `false` | no |
| <a name="input_helm_disable_webhooks"></a> [helm\_disable\_webhooks](#input\_helm\_disable\_webhooks) | Disable webhooks for Helm release. | `bool` | `false` | no |
| <a name="input_helm_force_update"></a> [helm\_force\_update](#input\_helm\_force\_update) | Force resource updates if needed. | `bool` | `false` | no |
| <a name="input_helm_replace"></a> [helm\_replace](#input\_helm\_replace) | Allow Helm to replace existing resources. | `bool` | `false` | no |
| <a name="input_helm_skip_crds"></a> [helm\_skip\_crds](#input\_helm\_skip\_crds) | Skip CRDs for Helm release. | `bool` | `false` | no |
| <a name="input_helm_timeout"></a> [helm\_timeout](#input\_helm\_timeout) | Timeout for Helm deployment in seconds. | `number` | `300` | no |
| <a name="input_helm_wait"></a> [helm\_wait](#input\_helm\_wait) | Wait for Helm release to be ready. | `bool` | `false` | no |
| <a name="input_helm_wait_for_jobs"></a> [helm\_wait\_for\_jobs](#input\_helm\_wait\_for\_jobs) | Wait for Helm jobs to complete. | `bool` | `false` | no |
| <a name="input_memory_limit"></a> [memory\_limit](#input\_memory\_limit) | Memory limit for Portainer containers. | `string` | `"128Mi"` | no |
| <a name="input_memory_request"></a> [memory\_request](#input\_memory\_request) | Memory request for Portainer containers. | `string` | `"64Mi"` | no |
| <a name="input_name"></a> [name](#input\_name) | Helm release name for Portainer. | `string` | `"portainer"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace for Portainer container management system. | `string` | `"portainer-stack"` | no |
| <a name="input_persistent_disk_size"></a> [persistent\_disk\_size](#input\_persistent\_disk\_size) | Persistent disk size for Portainer data storage. | `string` | `"4Gi"` | no |
| <a name="input_portainer_admin_password"></a> [portainer\_admin\_password](#input\_portainer\_admin\_password) | Custom password for Portainer admin (empty = auto-generate). | `string` | `""` | no |
| <a name="input_storage_class"></a> [storage\_class](#input\_storage\_class) | Storage class for Portainer persistent volume. | `string` | `"hostpath"` | no |
| <a name="input_traefik_cert_resolver"></a> [traefik\_cert\_resolver](#input\_traefik\_cert\_resolver) | Traefik certificate resolver for TLS. | `string` | `"default"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_portainer"></a> [portainer](#output\_portainer) | n/a |
<!-- END_TF_DOCS -->
