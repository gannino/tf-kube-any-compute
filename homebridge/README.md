# Homebridge Module

Native Kubernetes deployment for Homebridge - Apple HomeKit bridge for smart home devices.

## Features

- **🍎 HomeKit Integration**: Bridge non-HomeKit devices to Apple HomeKit
- **🔌 Plugin Support**: 3000+ plugins for device integration
- **🌐 Host Networking**: Enabled by default for HomeKit device discovery
- **💾 Persistent Storage**: Configuration and plugin data persistence
- **🏗️ Native Deployment**: Uses Kubernetes resources instead of Helm

## Default Configuration

- **Host Networking**: `enabled` (required for HomeKit discovery)
- **Persistent Storage**: `enabled`
- **Architecture**: Auto-detected (ARM64/AMD64)

## Usage

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
    enable_host_network = true   # Default: true (for HomeKit discovery)
    enable_persistence  = true   # Default: true
    storage_class      = "nfs-csi"
    persistent_disk_size = "2Gi"
    plugins = [
      "homebridge-config-ui-x",
      "homebridge-hue",
      "homebridge-nest"
    ]
  }
}
```

## Host Networking

Host networking is **enabled by default** to support:
- HomeKit device discovery (mDNS/Bonjour)
- Direct network access for device communication
- Proper IP address exposure for HomeKit accessories

To disable (not recommended):
```hcl
service_overrides = {
  homebridge = {
    enable_host_network = false
  }
}
```

## Access

- **Web UI**: `https://homebridge.{domain}`
- **Default Port**: 8581
- **Setup**: Access web interface for initial configuration

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
| [kubernetes_deployment.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment) | resource |
| [kubernetes_ingress_v1.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/ingress_v1) | resource |
| [kubernetes_namespace.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_persistent_volume_claim.data_storage](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume_claim) | resource |
| [kubernetes_service.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_cpu_arch"></a> [cpu\_arch](#input\_cpu\_arch) | CPU architecture for node selection | `string` | `"amd64"` | no |
| <a name="input_cpu_limit"></a> [cpu\_limit](#input\_cpu\_limit) | CPU limit for Homebridge containers | `string` | `"500m"` | no |
| <a name="input_cpu_request"></a> [cpu\_request](#input\_cpu\_request) | CPU request for Homebridge containers | `string` | `"250m"` | no |
| <a name="input_disable_arch_scheduling"></a> [disable\_arch\_scheduling](#input\_disable\_arch\_scheduling) | Disable architecture-based node scheduling | `bool` | `false` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Domain name for ingress resources | `string` | `".local"` | no |
| <a name="input_enable_host_network"></a> [enable\_host\_network](#input\_enable\_host\_network) | Enable host network for HomeKit discovery (enabled by default for device discovery) | `bool` | `true` | no |
| <a name="input_enable_ingress"></a> [enable\_ingress](#input\_enable\_ingress) | Enable ingress functionality for external access | `bool` | `true` | no |
| <a name="input_enable_persistence"></a> [enable\_persistence](#input\_enable\_persistence) | Enable persistent storage for Homebridge data | `bool` | `true` | no |
| <a name="input_image_version"></a> [image\_version](#input\_image\_version) | Homebridge container image version | `string` | `"latest"` | no |
| <a name="input_memory_limit"></a> [memory\_limit](#input\_memory\_limit) | Memory limit for Homebridge containers | `string` | `"512Mi"` | no |
| <a name="input_memory_request"></a> [memory\_request](#input\_memory\_request) | Memory request for Homebridge containers | `string` | `"256Mi"` | no |
| <a name="input_name"></a> [name](#input\_name) | Helm release name for Homebridge | `string` | `"homebridge"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Kubernetes namespace for Homebridge deployment | `string` | `"homebridge-system"` | no |
| <a name="input_nfs_fs_group"></a> [nfs\_fs\_group](#input\_nfs\_fs\_group) | File system group ID for NFS storage compatibility | `number` | `1000` | no |
| <a name="input_persistent_disk_size"></a> [persistent\_disk\_size](#input\_persistent\_disk\_size) | Size of persistent disk for Homebridge data | `string` | `"2Gi"` | no |
| <a name="input_plugins"></a> [plugins](#input\_plugins) | List of Homebridge plugins to install | `list(string)` | <pre>[<br/>  "homebridge-config-ui-x"<br/>]</pre> | no |
| <a name="input_storage_class"></a> [storage\_class](#input\_storage\_class) | Storage class for persistent volumes | `string` | `"hostpath"` | no |
| <a name="input_traefik_cert_resolver"></a> [traefik\_cert\_resolver](#input\_traefik\_cert\_resolver) | Traefik certificate resolver name | `string` | `"default"` | no |
| <a name="input_traefik_ingress_config"></a> [traefik\_ingress\_config](#input\_traefik\_ingress\_config) | Traefik ingress configuration from Traefik module | <pre>object({<br/>    class_name    = string<br/>    annotations   = map(string)<br/>    cert_resolver = string<br/>    domain_name   = string<br/>  })</pre> | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_external_url"></a> [external\_url](#output\_external\_url) | External URL for Homebridge (when ingress is enabled) |
| <a name="output_helm_release_name"></a> [helm\_release\_name](#output\_helm\_release\_name) | Name of the deployment |
| <a name="output_helm_release_namespace"></a> [helm\_release\_namespace](#output\_helm\_release\_namespace) | Namespace of the deployment |
| <a name="output_helm_release_version"></a> [helm\_release\_version](#output\_helm\_release\_version) | Version of the deployment |
| <a name="output_namespace"></a> [namespace](#output\_namespace) | Kubernetes namespace where Homebridge is deployed |
| <a name="output_persistent_volume_size"></a> [persistent\_volume\_size](#output\_persistent\_volume\_size) | Size of the persistent volume |
| <a name="output_plugins"></a> [plugins](#output\_plugins) | List of installed Homebridge plugins |
| <a name="output_service_name"></a> [service\_name](#output\_service\_name) | Name of the Homebridge Kubernetes service |
| <a name="output_service_port"></a> [service\_port](#output\_service\_port) | Port of the Homebridge service |
| <a name="output_storage_class"></a> [storage\_class](#output\_storage\_class) | Storage class used for persistent volumes |
| <a name="output_url"></a> [url](#output\_url) | Internal URL for Homebridge service |
<!-- END_TF_DOCS -->
