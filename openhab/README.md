# openHAB Module

Native Kubernetes deployment for openHAB - vendor-neutral home automation platform.

## Features

- **🏢 Enterprise-Grade**: Java-based home automation platform
- **🔌 Device Support**: 400+ bindings for various protocols
- **🌐 Host Networking**: Enabled by default for device discovery
- **💾 Multi-Volume Storage**: Separate volumes for data, addons, and configuration
- **🏗️ Native Deployment**: Uses Kubernetes resources instead of Helm

## Default Configuration

- **Host Networking**: `enabled` (required for device discovery)
- **Persistent Storage**: `enabled` (3 volumes)
- **Architecture**: Auto-detected (ARM64/AMD64)
- **Karaf Console**: `disabled`

## Usage

### Basic Usage
```hcl
services = {
  openhab = true
}
```

### Advanced Configuration
```hcl
service_overrides = {
  openhab = {
    enable_host_network  = true   # Default: true (for device discovery)
    enable_persistence   = true   # Default: true
    enable_karaf_console = true   # Enable Karaf console access
    storage_class        = "nfs-csi"
    persistent_disk_size = "8Gi"  # Main data volume
    addons_disk_size     = "2Gi"  # Addons volume
    conf_disk_size       = "1Gi"  # Configuration volume
  }
}
```

## Host Networking

Host networking is **enabled by default** to support:
- Device discovery (UPnP, mDNS, SSDP)
- Protocol communication (Z-Wave, Zigbee, KNX)
- Network device access (IP cameras, smart switches)

To disable (not recommended for IoT):
```hcl
service_overrides = {
  openhab = {
    enable_host_network = false
  }
}
```

## Storage Volumes

openHAB uses three persistent volumes:
- **Data**: `/openhab/userdata` - Runtime data and logs
- **Addons**: `/openhab/addons` - Custom bindings and add-ons
- **Configuration**: `/openhab/conf` - Items, rules, and configuration

## Access

- **Web UI**: `https://openhab.{domain}`
- **Default Port**: 8080
- **Karaf Console**: Port 8101 (if enabled)

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
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.38.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [kubernetes_deployment.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment) | resource |
| [kubernetes_ingress_v1.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/ingress_v1) | resource |
| [kubernetes_namespace.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_persistent_volume_claim.addons_storage](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume_claim) | resource |
| [kubernetes_persistent_volume_claim.conf_storage](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume_claim) | resource |
| [kubernetes_persistent_volume_claim.data_storage](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume_claim) | resource |
| [kubernetes_service.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_addons_disk_size"></a> [addons\_disk\_size](#input\_addons\_disk\_size) | Size of persistent disk for openHAB addons | `string` | `"2Gi"` | no |
| <a name="input_chart_name"></a> [chart\_name](#input\_chart\_name) | Helm chart name | `string` | `"openhab"` | no |
| <a name="input_chart_repo"></a> [chart\_repo](#input\_chart\_repo) | Helm chart repository URL | `string` | `"https://openhab.github.io/openhab-helm-chart/"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Helm chart version | `string` | `"1.2.1"` | no |
| <a name="input_conf_disk_size"></a> [conf\_disk\_size](#input\_conf\_disk\_size) | Size of persistent disk for openHAB configuration | `string` | `"1Gi"` | no |
| <a name="input_cpu_arch"></a> [cpu\_arch](#input\_cpu\_arch) | CPU architecture for node selection | `string` | `"amd64"` | no |
| <a name="input_cpu_limit"></a> [cpu\_limit](#input\_cpu\_limit) | CPU limit for openHAB containers | `string` | `"2000m"` | no |
| <a name="input_cpu_request"></a> [cpu\_request](#input\_cpu\_request) | CPU request for openHAB containers | `string` | `"1000m"` | no |
| <a name="input_deployment_timeout"></a> [deployment\_timeout](#input\_deployment\_timeout) | Timeout for deployment operations in seconds | `number` | `600` | no |
| <a name="input_disable_arch_scheduling"></a> [disable\_arch\_scheduling](#input\_disable\_arch\_scheduling) | Disable architecture-based node scheduling | `bool` | `false` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Domain name for ingress resources | `string` | `"local"` | no |
| <a name="input_enable_host_network"></a> [enable\_host\_network](#input\_enable\_host\_network) | Enable host network for device discovery (enabled by default for IoT device access) | `bool` | `true` | no |
| <a name="input_enable_ingress"></a> [enable\_ingress](#input\_enable\_ingress) | Enable ingress functionality for external access | `bool` | `true` | no |
| <a name="input_enable_karaf_console"></a> [enable\_karaf\_console](#input\_enable\_karaf\_console) | Enable Karaf console access | `bool` | `false` | no |
| <a name="input_enable_persistence"></a> [enable\_persistence](#input\_enable\_persistence) | Enable persistent storage for openHAB data | `bool` | `true` | no |
| <a name="input_enable_privileged"></a> [enable\_privileged](#input\_enable\_privileged) | Enable privileged mode for device access (USB, GPIO) | `bool` | `false` | no |
| <a name="input_image_version"></a> [image\_version](#input\_image\_version) | openHAB container image version | `string` | `"4.2.3"` | no |
| <a name="input_memory_limit"></a> [memory\_limit](#input\_memory\_limit) | Memory limit for openHAB containers | `string` | `"2Gi"` | no |
| <a name="input_memory_request"></a> [memory\_request](#input\_memory\_request) | Memory request for openHAB containers | `string` | `"1Gi"` | no |
| <a name="input_name"></a> [name](#input\_name) | Helm release name for openHAB | `string` | `"openhab"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Kubernetes namespace for openHAB deployment | `string` | `"openhab-system"` | no |
| <a name="input_nfs_fs_group"></a> [nfs\_fs\_group](#input\_nfs\_fs\_group) | File system group ID for NFS storage compatibility | `number` | `1000` | no |
| <a name="input_persistent_disk_size"></a> [persistent\_disk\_size](#input\_persistent\_disk\_size) | Size of persistent disk for openHAB data | `string` | `"8Gi"` | no |
| <a name="input_storage_class"></a> [storage\_class](#input\_storage\_class) | Storage class for persistent volumes | `string` | `"nfs-csi-safe"` | no |
| <a name="input_traefik_cert_resolver"></a> [traefik\_cert\_resolver](#input\_traefik\_cert\_resolver) | Traefik certificate resolver name | `string` | `"default"` | no |
| <a name="input_traefik_ingress_config"></a> [traefik\_ingress\_config](#input\_traefik\_ingress\_config) | Traefik ingress configuration from Traefik module | <pre>object({<br/>    class_name    = string<br/>    annotations   = map(string)<br/>    cert_resolver = string<br/>    domain_name   = string<br/>  })</pre> | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_deployment_name"></a> [deployment\_name](#output\_deployment\_name) | Name of the Kubernetes deployment |
| <a name="output_helm_release_name"></a> [helm\_release\_name](#output\_helm\_release\_name) | Name of the deployment |
| <a name="output_helm_release_namespace"></a> [helm\_release\_namespace](#output\_helm\_release\_namespace) | Namespace of the deployment |
| <a name="output_helm_release_version"></a> [helm\_release\_version](#output\_helm\_release\_version) | Version of the deployment |
| <a name="output_ingress_url"></a> [ingress\_url](#output\_ingress\_url) | External URL for openHAB (when ingress is enabled) |
| <a name="output_karaf_external_url"></a> [karaf\_external\_url](#output\_karaf\_external\_url) | External URL for Karaf console (when ingress and console are enabled) |
| <a name="output_karaf_port"></a> [karaf\_port](#output\_karaf\_port) | Port of the Karaf console (if enabled) |
| <a name="output_namespace"></a> [namespace](#output\_namespace) | Kubernetes namespace where openHAB is deployed |
| <a name="output_persistent_volumes"></a> [persistent\_volumes](#output\_persistent\_volumes) | Information about persistent volumes |
| <a name="output_service_name"></a> [service\_name](#output\_service\_name) | Name of the openHAB Kubernetes service |
| <a name="output_service_port"></a> [service\_port](#output\_service\_port) | Port of the openHAB service |
| <a name="output_service_url"></a> [service\_url](#output\_service\_url) | Internal URL for openHAB service |
| <a name="output_storage_class"></a> [storage\_class](#output\_storage\_class) | Storage class used for persistent volumes |

<!-- END_TF_DOCS -->
