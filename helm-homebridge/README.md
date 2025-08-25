# Homebridge Helm Module

This module deploys [Homebridge](https://homebridge.io/) - a lightweight Node.js server that emulates the iOS HomeKit API, allowing you to integrate thousands of "smart home" devices with Apple's Home app.

## Features

- **🍎 HomeKit Integration**: Native Apple Home app compatibility
- **🔌 3000+ Plugins**: Extensive plugin ecosystem for device integration
- **🏠 Local Control**: Privacy-first local processing
- **📱 iOS/macOS Native**: Seamless integration with Apple ecosystem
- **🎙️ Siri Control**: Voice control through Siri
- **⚡ Lightweight**: Node.js based, perfect for Raspberry Pi

## Architecture Support

- **ARM64**: Optimized for Raspberry Pi deployments
- **AMD64**: Full support for x86 systems
- **Mixed Clusters**: Intelligent service placement

## Configuration

### Basic Usage

```hcl
services = {
  homebridge = true
}
```

### Advanced Configuration

```hcl
service_overrides = {
  homebridge = {
    # Architecture and deployment
    cpu_arch             = "arm64"
    storage_class        = "nfs-csi"
    persistent_disk_size = "2Gi"

    # Features
    enable_persistence  = true
    enable_host_network = true  # For HomeKit discovery
    enable_ingress      = true

    # Plugin management
    plugins = [
      "homebridge-config-ui-x",
      "homebridge-hue",
      "homebridge-nest",
      "homebridge-ring"
    ]

    # Resource limits (Node.js optimized)
    cpu_limit      = "500m"
    memory_limit   = "512Mi"
    cpu_request    = "250m"
    memory_request = "256Mi"

    # SSL certificate
    cert_resolver = "cloudflare"
  }
}
```

## HomeKit Discovery

For proper HomeKit functionality, enable host network:

```hcl
service_overrides = {
  homebridge = {
    enable_host_network = true
  }
}
```

## Plugin Management

Homebridge supports over 3000 plugins for device integration:

```hcl
service_overrides = {
  homebridge = {
    plugins = [
      "homebridge-config-ui-x",        # Web UI (required)
      "homebridge-hue",                # Philips Hue
      "homebridge-nest",               # Google Nest
      "homebridge-ring",               # Ring devices
      "homebridge-homeassistant",      # Home Assistant integration
      "homebridge-openhab2-complete"   # openHAB integration
    ]
  }
}
```

## Integration with Other Services

### Home Assistant + Homebridge
Perfect for adding HomeKit support to Home Assistant:

```hcl
services = {
  home_assistant = true
  homebridge     = true
}

service_overrides = {
  homebridge = {
    plugins = [
      "homebridge-config-ui-x",
      "homebridge-homeassistant"
    ]
  }
}
```

### openHAB + Homebridge
Enterprise automation with HomeKit integration:

```hcl
services = {
  openhab    = true
  homebridge = true
}

service_overrides = {
  homebridge = {
    plugins = [
      "homebridge-config-ui-x",
      "homebridge-openhab2-complete"
    ]
  }
}
```

## Access

After deployment, Homebridge will be available at:
- **Config UI**: `https://homebridge.{domain}`
- **HomeKit**: Discoverable in Apple Home app
- **Internal**: `http://homebridge.{namespace}.svc.cluster.local:8581`

## HomeKit Setup

1. **Open Apple Home App** on iOS/macOS
2. **Add Accessory** → **More Options**
3. **Scan QR Code** or enter setup code: `031-45-154`
4. **Configure** devices through Homebridge Config UI

## Storage

Homebridge requires persistent storage for:
- Configuration files
- Plugin data
- HomeKit pairing information
- Cached accessories

Default storage: 2Gi (configurable via `persistent_disk_size`)

## Security Considerations

- **Host Network**: Only enable if needed for device discovery
- **Config UI**: Secure the web interface with authentication
- **HomeKit Pairing**: Use unique bridge names and pins
- **SSL**: Always use HTTPS for external access

## Troubleshooting

### Common Issues

1. **HomeKit Discovery**: Enable host network mode
2. **Plugin Installation**: Check Config UI logs
3. **Device Pairing**: Reset HomeKit cache if needed
4. **Performance**: Monitor Node.js memory usage

### Logs

```bash
kubectl logs -f deployment/homebridge -n homebridge-system
```

### Config UI Access

```bash
# Port forward for local access
kubectl port-forward svc/homebridge 8581:8581 -n homebridge-system
# Access at http://localhost:8581
```

### Health Check

```bash
kubectl get pods -n homebridge-system
curl -k https://homebridge.{domain}
```

## Popular Plugins

- **homebridge-config-ui-x**: Web-based configuration UI
- **homebridge-hue**: Philips Hue integration
- **homebridge-nest**: Google Nest devices
- **homebridge-ring**: Ring doorbells and cameras
- **homebridge-homeassistant**: Home Assistant bridge
- **homebridge-camera-ffmpeg**: IP camera support
- **homebridge-mqtt**: MQTT device integration

## Resources

- [Homebridge Documentation](https://github.com/homebridge/homebridge/wiki)
- [Plugin Directory](https://www.npmjs.com/search?q=homebridge-plugin)
- [Config UI X](https://github.com/oznu/homebridge-config-ui-x)
- [Apple HomeKit](https://developer.apple.com/homekit/)
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
| <a name="input_chart_name"></a> [chart\_name](#input\_chart\_name) | Helm chart name | `string` | `"homebridge"` | no |
| <a name="input_chart_repo"></a> [chart\_repo](#input\_chart\_repo) | Helm chart repository URL | `string` | `"https://homebridge.github.io/helm-chart"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Helm chart version | `string` | `"2.0.0"` | no |
| <a name="input_cpu_arch"></a> [cpu\_arch](#input\_cpu\_arch) | CPU architecture for node selection | `string` | `"amd64"` | no |
| <a name="input_cpu_limit"></a> [cpu\_limit](#input\_cpu\_limit) | CPU limit for Homebridge containers | `string` | `"500m"` | no |
| <a name="input_cpu_request"></a> [cpu\_request](#input\_cpu\_request) | CPU request for Homebridge containers | `string` | `"250m"` | no |
| <a name="input_deployment_wait_timeout"></a> [deployment\_wait\_timeout](#input\_deployment\_wait\_timeout) | Timeout in seconds to wait for deployment to be ready | `number` | `300` | no |
| <a name="input_disable_arch_scheduling"></a> [disable\_arch\_scheduling](#input\_disable\_arch\_scheduling) | Disable architecture-based node scheduling | `bool` | `false` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Domain name for ingress resources | `string` | `".local"` | no |
| <a name="input_enable_host_network"></a> [enable\_host\_network](#input\_enable\_host\_network) | Enable host network for HomeKit discovery | `bool` | `false` | no |
| <a name="input_enable_ingress"></a> [enable\_ingress](#input\_enable\_ingress) | Enable ingress functionality for external access | `bool` | `true` | no |
| <a name="input_enable_persistence"></a> [enable\_persistence](#input\_enable\_persistence) | Enable persistent storage for Homebridge data | `bool` | `true` | no |
| <a name="input_helm_cleanup_on_fail"></a> [helm\_cleanup\_on\_fail](#input\_helm\_cleanup\_on\_fail) | Cleanup resources on failure | `bool` | `false` | no |
| <a name="input_helm_disable_webhooks"></a> [helm\_disable\_webhooks](#input\_helm\_disable\_webhooks) | Disable webhooks for Helm release | `bool` | `true` | no |
| <a name="input_helm_force_update"></a> [helm\_force\_update](#input\_helm\_force\_update) | Force resource updates if needed | `bool` | `false` | no |
| <a name="input_helm_replace"></a> [helm\_replace](#input\_helm\_replace) | Allow Helm to replace existing resources | `bool` | `false` | no |
| <a name="input_helm_skip_crds"></a> [helm\_skip\_crds](#input\_helm\_skip\_crds) | Skip CRDs for Helm release | `bool` | `false` | no |
| <a name="input_helm_timeout"></a> [helm\_timeout](#input\_helm\_timeout) | Timeout for Helm deployment in seconds | `number` | `600` | no |
| <a name="input_helm_wait"></a> [helm\_wait](#input\_helm\_wait) | Wait for Helm release to be ready | `bool` | `false` | no |
| <a name="input_helm_wait_for_jobs"></a> [helm\_wait\_for\_jobs](#input\_helm\_wait\_for\_jobs) | Wait for Helm jobs to complete | `bool` | `false` | no |
| <a name="input_memory_limit"></a> [memory\_limit](#input\_memory\_limit) | Memory limit for Homebridge containers | `string` | `"512Mi"` | no |
| <a name="input_memory_request"></a> [memory\_request](#input\_memory\_request) | Memory request for Homebridge containers | `string` | `"256Mi"` | no |
| <a name="input_name"></a> [name](#input\_name) | Helm release name for Homebridge | `string` | `"homebridge"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Kubernetes namespace for Homebridge deployment | `string` | `"homebridge-system"` | no |
| <a name="input_persistent_disk_size"></a> [persistent\_disk\_size](#input\_persistent\_disk\_size) | Size of persistent disk for Homebridge data | `string` | `"2Gi"` | no |
| <a name="input_plugins"></a> [plugins](#input\_plugins) | List of Homebridge plugins to install | `list(string)` | <pre>[<br/>  "homebridge-config-ui-x"<br/>]</pre> | no |
| <a name="input_storage_class"></a> [storage\_class](#input\_storage\_class) | Storage class for persistent volumes | `string` | `"hostpath"` | no |
| <a name="input_traefik_cert_resolver"></a> [traefik\_cert\_resolver](#input\_traefik\_cert\_resolver) | Traefik certificate resolver name | `string` | `"default"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_external_url"></a> [external\_url](#output\_external\_url) | External URL for Homebridge (when ingress is enabled) |
| <a name="output_helm_release_name"></a> [helm\_release\_name](#output\_helm\_release\_name) | Name of the Helm release |
| <a name="output_helm_release_namespace"></a> [helm\_release\_namespace](#output\_helm\_release\_namespace) | Namespace of the Helm release |
| <a name="output_helm_release_version"></a> [helm\_release\_version](#output\_helm\_release\_version) | Version of the deployed Helm chart |
| <a name="output_namespace"></a> [namespace](#output\_namespace) | Kubernetes namespace where Homebridge is deployed |
| <a name="output_persistent_volume_size"></a> [persistent\_volume\_size](#output\_persistent\_volume\_size) | Size of the persistent volume |
| <a name="output_plugins"></a> [plugins](#output\_plugins) | List of installed Homebridge plugins |
| <a name="output_service_name"></a> [service\_name](#output\_service\_name) | Name of the Homebridge Kubernetes service |
| <a name="output_service_port"></a> [service\_port](#output\_service\_port) | Port of the Homebridge service |
| <a name="output_storage_class"></a> [storage\_class](#output\_storage\_class) | Storage class used for persistent volumes |
| <a name="output_url"></a> [url](#output\_url) | Internal URL for Homebridge service |

<!-- END_TF_DOCS -->
