# Node-RED Helm Module

Visual programming tool for IoT and automation workflows.

## Features

- **Visual Programming**: Flow-based development for IoT and automation
- **ARM64/AMD64 Support**: Multi-architecture deployment
- **Persistent Storage**: Optional data persistence with configurable storage classes
- **Traefik Integration**: Automatic SSL certificates and ingress
- **Resource Management**: Configurable CPU/memory limits for homelab environments

## Configuration

### Basic Usage

```hcl
module "node_red" {
  source = "./helm-node-red"

  name      = "node-red"
  namespace = "node-red-system"

  # Domain configuration
  domain_name           = ".homelab.local"
  traefik_cert_resolver = "letsencrypt"

  # Storage
  enable_persistence   = true
  storage_class        = "nfs-csi"
  persistent_disk_size = "2Gi"
}
```

### Advanced Configuration

```hcl
module "node_red" {
  source = "./helm-node-red"

  # Architecture-specific deployment
  cpu_arch                = "arm64"
  disable_arch_scheduling = false

  # Resource limits for Raspberry Pi
  cpu_limit      = "500m"
  memory_limit   = "512Mi"
  cpu_request    = "250m"
  memory_request = "256Mi"

  # Helm deployment options
  helm_timeout = 600
  helm_wait    = true
}
```

## Outputs

- `namespace`: Deployment namespace
- `service_name`: Kubernetes service name
- `service_url`: Internal cluster URL
- `ingress_url`: External HTTPS URL
- `node_red_config`: Configuration summary

## Access

After deployment, Node-RED is available at:
- **External**: `https://node-red.{domain}`
- **Internal**: `http://node-red.node-red-system.svc.cluster.local:1880`

## Chart Information

- **Chart**: `node-red` from `https://schwarzit.github.io/node-red-chart/`
- **Version**: `0.35.0`
- **Image**: `nodered/node-red:latest`

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
| [kubernetes_config_map.palette_installer_script](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_ingress_v1.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/ingress_v1) | resource |
| [kubernetes_job_v1.palette_installer](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/job_v1) | resource |
| [kubernetes_namespace.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_persistent_volume_claim.data_storage](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume_claim) | resource |
| [null_resource.wait_for_deployment](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [kubernetes_service.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/service) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_chart_name"></a> [chart\_name](#input\_chart\_name) | Helm chart name | `string` | `"node-red"` | no |
| <a name="input_chart_repo"></a> [chart\_repo](#input\_chart\_repo) | Helm chart repository URL | `string` | `"https://schwarzit.github.io/node-red-chart/"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Helm chart version | `string` | `"0.35.0"` | no |
| <a name="input_cpu_arch"></a> [cpu\_arch](#input\_cpu\_arch) | CPU architecture for node selection | `string` | `"amd64"` | no |
| <a name="input_cpu_limit"></a> [cpu\_limit](#input\_cpu\_limit) | CPU limit for Node-RED containers | `string` | `"500m"` | no |
| <a name="input_cpu_request"></a> [cpu\_request](#input\_cpu\_request) | CPU request for Node-RED containers | `string` | `"250m"` | no |
| <a name="input_deployment_wait_timeout"></a> [deployment\_wait\_timeout](#input\_deployment\_wait\_timeout) | Timeout in seconds to wait for deployment to be ready | `number` | `300` | no |
| <a name="input_disable_arch_scheduling"></a> [disable\_arch\_scheduling](#input\_disable\_arch\_scheduling) | Disable architecture-based node scheduling | `bool` | `false` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Domain name for ingress resources | `string` | `".local"` | no |
| <a name="input_enable_ingress"></a> [enable\_ingress](#input\_enable\_ingress) | Enable ingress functionality for external access | `bool` | `true` | no |
| <a name="input_enable_persistence"></a> [enable\_persistence](#input\_enable\_persistence) | Enable persistent storage for Node-RED data | `bool` | `true` | no |
| <a name="input_helm_cleanup_on_fail"></a> [helm\_cleanup\_on\_fail](#input\_helm\_cleanup\_on\_fail) | Cleanup resources on failure | `bool` | `false` | no |
| <a name="input_helm_disable_webhooks"></a> [helm\_disable\_webhooks](#input\_helm\_disable\_webhooks) | Disable webhooks for Helm release | `bool` | `true` | no |
| <a name="input_helm_force_update"></a> [helm\_force\_update](#input\_helm\_force\_update) | Force resource updates if needed | `bool` | `false` | no |
| <a name="input_helm_replace"></a> [helm\_replace](#input\_helm\_replace) | Allow Helm to replace existing resources | `bool` | `false` | no |
| <a name="input_helm_skip_crds"></a> [helm\_skip\_crds](#input\_helm\_skip\_crds) | Skip CRDs for Helm release | `bool` | `false` | no |
| <a name="input_helm_timeout"></a> [helm\_timeout](#input\_helm\_timeout) | Timeout for Helm deployment in seconds | `number` | `600` | no |
| <a name="input_helm_wait"></a> [helm\_wait](#input\_helm\_wait) | Wait for Helm release to be ready | `bool` | `false` | no |
| <a name="input_helm_wait_for_jobs"></a> [helm\_wait\_for\_jobs](#input\_helm\_wait\_for\_jobs) | Wait for Helm jobs to complete | `bool` | `false` | no |
| <a name="input_memory_limit"></a> [memory\_limit](#input\_memory\_limit) | Memory limit for Node-RED containers | `string` | `"512Mi"` | no |
| <a name="input_memory_request"></a> [memory\_request](#input\_memory\_request) | Memory request for Node-RED containers | `string` | `"256Mi"` | no |
| <a name="input_name"></a> [name](#input\_name) | Helm release name for Node-RED | `string` | `"node-red"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Kubernetes namespace for Node-RED deployment | `string` | `"node-red-system"` | no |
| <a name="input_palette_packages"></a> [palette\_packages](#input\_palette\_packages) | List of Node-RED palette packages to install during deployment | `list(string)` | <pre>[<br/>  "node-red-contrib-home-assistant-websocket",<br/>  "node-red-dashboard",<br/>  "node-red-contrib-influxdb",<br/>  "node-red-contrib-mqtt-broker",<br/>  "node-red-node-pi-gpio",<br/>  "node-red-contrib-modbus"<br/>]</pre> | no |
| <a name="input_persistent_disk_size"></a> [persistent\_disk\_size](#input\_persistent\_disk\_size) | Size of persistent disk for Node-RED data | `string` | `"2Gi"` | no |
| <a name="input_storage_class"></a> [storage\_class](#input\_storage\_class) | Storage class for persistent volumes | `string` | `"hostpath"` | no |
| <a name="input_traefik_cert_resolver"></a> [traefik\_cert\_resolver](#input\_traefik\_cert\_resolver) | Traefik certificate resolver name | `string` | `"default"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_chart_version"></a> [chart\_version](#output\_chart\_version) | The version of the Helm chart deployed |
| <a name="output_helm_release_name"></a> [helm\_release\_name](#output\_helm\_release\_name) | The name of the Helm release |
| <a name="output_helm_release_status"></a> [helm\_release\_status](#output\_helm\_release\_status) | The status of the Helm release |
| <a name="output_ingress_url"></a> [ingress\_url](#output\_ingress\_url) | External ingress URL for Node-RED (when ingress is enabled) |
| <a name="output_namespace"></a> [namespace](#output\_namespace) | The namespace where Node-RED is deployed |
| <a name="output_node_red_config"></a> [node\_red\_config](#output\_node\_red\_config) | Node-RED configuration summary |
| <a name="output_service_name"></a> [service\_name](#output\_service\_name) | The name of the Node-RED service |
| <a name="output_service_url"></a> [service\_url](#output\_service\_url) | Internal service URL for Node-RED |

<!-- END_TF_DOCS -->
