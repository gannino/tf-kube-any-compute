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

For network device discovery:

```hcl
service_overrides = {
  home_assistant = {
    enable_host_network = true
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
- [Automation Examples](https://www.home-assistant.io/docs/automation/examples/)
<!-- BEGIN_TF_DOCS -->


## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 3.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | 3.0.2 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.38.0 |
| <a name="provider_null"></a> [null](#provider\_null) | 3.2.4 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.this](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_manifest.ingress_route](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_namespace.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_persistent_volume_claim.data_storage](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume_claim) | resource |
| [null_resource.wait_for_deployment](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [kubernetes_service.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/service) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_chart_name"></a> [chart\_name](#input\_chart\_name) | Helm chart name | `string` | `"home-assistant"` | no |
| <a name="input_chart_repo"></a> [chart\_repo](#input\_chart\_repo) | Helm chart repository URL | `string` | `"https://pajikos.github.io/home-assistant-helm-chart/"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Helm chart version | `string` | `"0.2.63"` | no |
| <a name="input_cpu_arch"></a> [cpu\_arch](#input\_cpu\_arch) | CPU architecture for node selection | `string` | `"amd64"` | no |
| <a name="input_cpu_limit"></a> [cpu\_limit](#input\_cpu\_limit) | CPU limit for Home Assistant containers | `string` | `"1000m"` | no |
| <a name="input_cpu_request"></a> [cpu\_request](#input\_cpu\_request) | CPU request for Home Assistant containers | `string` | `"500m"` | no |
| <a name="input_deployment_wait_timeout"></a> [deployment\_wait\_timeout](#input\_deployment\_wait\_timeout) | Timeout in seconds to wait for deployment to be ready | `number` | `300` | no |
| <a name="input_disable_arch_scheduling"></a> [disable\_arch\_scheduling](#input\_disable\_arch\_scheduling) | Disable architecture-based node scheduling | `bool` | `false` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Domain name for ingress resources | `string` | `".local"` | no |
| <a name="input_enable_host_network"></a> [enable\_host\_network](#input\_enable\_host\_network) | Enable host network for device discovery | `bool` | `false` | no |
| <a name="input_enable_ingress"></a> [enable\_ingress](#input\_enable\_ingress) | Enable ingress functionality for external access | `bool` | `true` | no |
| <a name="input_enable_persistence"></a> [enable\_persistence](#input\_enable\_persistence) | Enable persistent storage for Home Assistant data | `bool` | `true` | no |
| <a name="input_enable_privileged"></a> [enable\_privileged](#input\_enable\_privileged) | Enable privileged mode for device access (USB, GPIO) | `bool` | `false` | no |
| <a name="input_helm_cleanup_on_fail"></a> [helm\_cleanup\_on\_fail](#input\_helm\_cleanup\_on\_fail) | Cleanup resources on failure | `bool` | `false` | no |
| <a name="input_helm_disable_webhooks"></a> [helm\_disable\_webhooks](#input\_helm\_disable\_webhooks) | Disable webhooks for Helm release | `bool` | `true` | no |
| <a name="input_helm_force_update"></a> [helm\_force\_update](#input\_helm\_force\_update) | Force resource updates if needed | `bool` | `false` | no |
| <a name="input_helm_replace"></a> [helm\_replace](#input\_helm\_replace) | Allow Helm to replace existing resources | `bool` | `false` | no |
| <a name="input_helm_skip_crds"></a> [helm\_skip\_crds](#input\_helm\_skip\_crds) | Skip CRDs for Helm release | `bool` | `false` | no |
| <a name="input_helm_timeout"></a> [helm\_timeout](#input\_helm\_timeout) | Timeout for Helm deployment in seconds | `number` | `600` | no |
| <a name="input_helm_wait"></a> [helm\_wait](#input\_helm\_wait) | Wait for Helm release to be ready | `bool` | `false` | no |
| <a name="input_helm_wait_for_jobs"></a> [helm\_wait\_for\_jobs](#input\_helm\_wait\_for\_jobs) | Wait for Helm jobs to complete | `bool` | `false` | no |
| <a name="input_memory_limit"></a> [memory\_limit](#input\_memory\_limit) | Memory limit for Home Assistant containers | `string` | `"1Gi"` | no |
| <a name="input_memory_request"></a> [memory\_request](#input\_memory\_request) | Memory request for Home Assistant containers | `string` | `"512Mi"` | no |
| <a name="input_name"></a> [name](#input\_name) | Helm release name for Home Assistant | `string` | `"home-assistant"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Kubernetes namespace for Home Assistant deployment | `string` | `"home-assistant-system"` | no |
| <a name="input_persistent_disk_size"></a> [persistent\_disk\_size](#input\_persistent\_disk\_size) | Size of persistent disk for Home Assistant data | `string` | `"5Gi"` | no |
| <a name="input_storage_class"></a> [storage\_class](#input\_storage\_class) | Storage class for persistent volumes | `string` | `"hostpath"` | no |
| <a name="input_traefik_cert_resolver"></a> [traefik\_cert\_resolver](#input\_traefik\_cert\_resolver) | Traefik certificate resolver name | `string` | `"default"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_external_url"></a> [external\_url](#output\_external\_url) | External URL for Home Assistant (when ingress is enabled) |
| <a name="output_helm_release_name"></a> [helm\_release\_name](#output\_helm\_release\_name) | Name of the Helm release |
| <a name="output_helm_release_namespace"></a> [helm\_release\_namespace](#output\_helm\_release\_namespace) | Namespace of the Helm release |
| <a name="output_helm_release_version"></a> [helm\_release\_version](#output\_helm\_release\_version) | Version of the deployed Helm chart |
| <a name="output_namespace"></a> [namespace](#output\_namespace) | Kubernetes namespace where Home Assistant is deployed |
| <a name="output_persistent_volume_size"></a> [persistent\_volume\_size](#output\_persistent\_volume\_size) | Size of the persistent volume |
| <a name="output_service_name"></a> [service\_name](#output\_service\_name) | Name of the Home Assistant Kubernetes service |
| <a name="output_service_port"></a> [service\_port](#output\_service\_port) | Port of the Home Assistant service |
| <a name="output_storage_class"></a> [storage\_class](#output\_storage\_class) | Storage class used for persistent volumes |
| <a name="output_url"></a> [url](#output\_url) | Internal URL for Home Assistant service |

<!-- END_TF_DOCS -->
