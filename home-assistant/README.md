# Home Assistant Helm Module

This module deploys [Home Assistant](https://www.home-assistant.io/) - an open-source home automation platform that puts local control and privacy first.

## Features

- **🏠 Complete Home Automation**: Over 1,000 integrations for devices and services
- **🔒 Privacy-First**: All data processing happens locally
- **⚡ Energy Management**: Built-in energy monitoring and management
- **🎙️ Voice Control**: Assist voice assistant with Alexa/Google integration
- **📱 Mobile Apps**: Native iOS and Android applications
- **🔧 Automation Engine**: Powerful automation with triggers, conditions, and actions

## Architecture Support

- **ARM64**: Optimized for Raspberry Pi deployments
- **AMD64**: Full support for x86 systems
- **Mixed Clusters**: Intelligent service placement

## Configuration

### Basic Usage

```hcl
services = {
  home_assistant = true
}
```

### Advanced Configuration

```hcl
service_overrides = {
  home_assistant = {
    # Architecture and deployment
    cpu_arch             = "arm64"
    storage_class        = "nfs-csi"
    persistent_disk_size = "10Gi"

    # Features
    enable_persistence  = true
    enable_privileged   = true  # For USB device access
    enable_host_network = true  # For device discovery
    enable_ingress      = true

    # Resource limits
    cpu_limit      = "1000m"
    memory_limit   = "1Gi"
    cpu_request    = "500m"
    memory_request = "512Mi"

    # SSL certificate
    cert_resolver = "cloudflare"
  }
}
```

## Device Access

For USB devices (Zigbee, Z-Wave dongles):

```hcl
service_overrides = {
  home_assistant = {
    enable_privileged = true
  }
}
```

For network device discovery (enabled by default):

```hcl
service_overrides = {
  home_assistant = {
    enable_host_network = true  # Default: true (for device discovery)
  }
}

# To disable host networking (not recommended for IoT):
service_overrides = {
  home_assistant = {
    enable_host_network = false
  }
}
```

## Integration with Other Services

### Node-RED Integration
Perfect companion for visual automation flows:

```hcl
services = {
  home_assistant = true
  node_red       = true
}

service_overrides = {
  node_red = {
    palette_packages = [
      "node-red-contrib-home-assistant-websocket",
      "node-red-dashboard"
    ]
  }
}
```

### Monitoring Integration
Monitor Home Assistant with Prometheus:

```hcl
services = {
  home_assistant = true
  prometheus     = true
  grafana        = true
}
```

## Access

After deployment, Home Assistant will be available at:
- **Internal**: `http://home-assistant.{namespace}.svc.cluster.local:8123`
- **External**: `https://home-assistant.{domain}` (when ingress enabled)

## Storage

Home Assistant requires persistent storage for:
- Configuration files
- Database (SQLite by default)
- Custom components
- Media files

Default storage: 5Gi (configurable via `persistent_disk_size`)

## Security Considerations

- **Privileged Mode**: Only enable if you need USB device access
- **Host Network**: Only enable if you need device discovery
- **SSL**: Always use HTTPS in production (automatic with ingress)
- **Authentication**: Home Assistant has built-in user management

## Troubleshooting

### Common Issues

1. **Startup Time**: Home Assistant can take 2-3 minutes to fully start
2. **Device Access**: Ensure privileged mode for USB devices
3. **Discovery**: Enable host network for automatic device discovery
4. **Storage**: Ensure sufficient storage for database growth

### Logs

```bash
kubectl logs -f deployment/home-assistant -n home-assistant-system
```

### Health Check

```bash
kubectl get pods -n home-assistant-system
curl -k https://home-assistant.{domain}/api/
```

## Resources

- [Home Assistant Documentation](https://www.home-assistant.io/docs/)
- [Home Assistant Community](https://community.home-assistant.io/)
- [Integration List](https://www.home-assistant.io/integrations/)
- [Automation Examples](https://www.home-assistant.io/docs/automation/)
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 3.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.38.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [kubernetes_config_map.http_config](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_deployment.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment) | resource |
| [kubernetes_ingress_v1.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/ingress_v1) | resource |
| [kubernetes_namespace.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_persistent_volume_claim.data_storage](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume_claim) | resource |
| [kubernetes_service.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_chart_name"></a> [chart\_name](#input\_chart\_name) | Helm chart name | `string` | `"home-assistant"` | no |
| <a name="input_chart_repo"></a> [chart\_repo](#input\_chart\_repo) | Helm chart repository URL | `string` | `"https://pajikos.github.io/home-assistant-helm-chart/"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Helm chart version | `string` | `"0.2.63"` | no |
| <a name="input_cpu_arch"></a> [cpu\_arch](#input\_cpu\_arch) | CPU architecture for node selection | `string` | `"amd64"` | no |
| <a name="input_cpu_limit"></a> [cpu\_limit](#input\_cpu\_limit) | CPU limit for Home Assistant containers | `string` | `"1000m"` | no |
| <a name="input_cpu_request"></a> [cpu\_request](#input\_cpu\_request) | CPU request for Home Assistant containers | `string` | `"500m"` | no |
| <a name="input_disable_arch_scheduling"></a> [disable\_arch\_scheduling](#input\_disable\_arch\_scheduling) | Disable architecture-based node scheduling | `bool` | `false` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Domain name for ingress resources | `string` | `".local"` | no |
| <a name="input_enable_host_network"></a> [enable\_host\_network](#input\_enable\_host\_network) | Enable host network for device discovery (enabled by default for IoT device access) | `bool` | `true` | no |
| <a name="input_enable_ingress"></a> [enable\_ingress](#input\_enable\_ingress) | Enable ingress functionality for external access | `bool` | `true` | no |
| <a name="input_enable_persistence"></a> [enable\_persistence](#input\_enable\_persistence) | Enable persistent storage for Home Assistant data | `bool` | `true` | no |
| <a name="input_enable_privileged"></a> [enable\_privileged](#input\_enable\_privileged) | Enable privileged mode for device access (USB, GPIO) | `bool` | `false` | no |
| <a name="input_image_version"></a> [image\_version](#input\_image\_version) | Home Assistant container image version | `string` | `"latest"` | no |
| <a name="input_memory_limit"></a> [memory\_limit](#input\_memory\_limit) | Memory limit for Home Assistant containers | `string` | `"1Gi"` | no |
| <a name="input_memory_request"></a> [memory\_request](#input\_memory\_request) | Memory request for Home Assistant containers | `string` | `"512Mi"` | no |
| <a name="input_name"></a> [name](#input\_name) | Helm release name for Home Assistant | `string` | `"home-assistant"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Kubernetes namespace for Home Assistant deployment | `string` | `"home-assistant-system"` | no |
| <a name="input_nfs_fs_group"></a> [nfs\_fs\_group](#input\_nfs\_fs\_group) | File system group ID for NFS storage compatibility | `number` | `1000` | no |
| <a name="input_persistent_disk_size"></a> [persistent\_disk\_size](#input\_persistent\_disk\_size) | Size of persistent disk for Home Assistant data | `string` | `"5Gi"` | no |
| <a name="input_storage_class"></a> [storage\_class](#input\_storage\_class) | Storage class for persistent volumes | `string` | `"hostpath"` | no |
| <a name="input_timezone"></a> [timezone](#input\_timezone) | Timezone for Home Assistant container | `string` | `"UTC"` | no |
| <a name="input_traefik_cert_resolver"></a> [traefik\_cert\_resolver](#input\_traefik\_cert\_resolver) | Traefik certificate resolver name | `string` | `"default"` | no |
| <a name="input_traefik_ingress_config"></a> [traefik\_ingress\_config](#input\_traefik\_ingress\_config) | Traefik ingress configuration from Traefik module | <pre>object({<br/>    class_name    = string<br/>    annotations   = map(string)<br/>    cert_resolver = string<br/>    domain_name   = string<br/>  })</pre> | `null` | no |
| <a name="input_trusted_proxies"></a> [trusted\_proxies](#input\_trusted\_proxies) | List of trusted proxy networks for reverse proxy setup | `list(string)` | <pre>[<br/>  "10.0.0.0/8",<br/>  "172.16.0.0/12",<br/>  "192.168.0.0/16"<br/>]</pre> | no |
| <a name="input_use_x_forwarded_for"></a> [use\_x\_forwarded\_for](#input\_use\_x\_forwarded\_for) | Enable X-Forwarded-For header processing for reverse proxies | `bool` | `true` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_deployment_name"></a> [deployment\_name](#output\_deployment\_name) | Name of the Kubernetes deployment |
| <a name="output_deployment_namespace"></a> [deployment\_namespace](#output\_deployment\_namespace) | Namespace of the Kubernetes deployment |
| <a name="output_image"></a> [image](#output\_image) | Container image used for Home Assistant |
| <a name="output_ingress_url"></a> [ingress\_url](#output\_ingress\_url) | External URL for Home Assistant (when ingress is enabled) |
| <a name="output_namespace"></a> [namespace](#output\_namespace) | Kubernetes namespace where Home Assistant is deployed |
| <a name="output_persistent_volume_size"></a> [persistent\_volume\_size](#output\_persistent\_volume\_size) | Size of the persistent volume |
| <a name="output_service_name"></a> [service\_name](#output\_service\_name) | Name of the Home Assistant Kubernetes service |
| <a name="output_service_port"></a> [service\_port](#output\_service\_port) | Port of the Home Assistant service |
| <a name="output_service_url"></a> [service\_url](#output\_service\_url) | Internal URL for Home Assistant service |
| <a name="output_storage_class"></a> [storage\_class](#output\_storage\_class) | Storage class used for persistent volumes |
<!-- END_TF_DOCS -->
