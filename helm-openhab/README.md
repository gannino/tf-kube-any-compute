# openHAB Helm Module

This module deploys [openHAB](https://www.openhab.org/) - a vendor-neutral, open-source home automation platform that runs on Java and provides enterprise-grade reliability.

## Features

- **🏢 Enterprise-Grade**: Java-based with Apache Karaf OSGi runtime
- **🔧 Vendor-Neutral**: Over 400 technology integrations supporting thousands of devices
- **⚡ Powerful Rules Engine**: Time and event-based triggers with advanced logic
- **🌐 REST API**: Complete REST API for external integrations
- **📊 Persistence**: Multiple database backends for historical data
- **🎯 Semantic Model**: Advanced item modeling and metadata

## Architecture Support

- **ARM64**: Optimized for Raspberry Pi deployments
- **AMD64**: Full support for x86 systems with higher memory allocation
- **Mixed Clusters**: Intelligent service placement

## Configuration

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
    # Architecture and deployment
    cpu_arch             = "amd64"
    storage_class        = "nfs-csi"
    persistent_disk_size = "10Gi"
    addons_disk_size     = "3Gi"
    conf_disk_size       = "2Gi"

    # Features
    enable_persistence   = true
    enable_privileged    = true  # For USB device access
    enable_host_network  = true  # For device discovery
    enable_karaf_console = true  # For debugging
    enable_ingress       = true

    # Resource limits (Java needs more memory)
    cpu_limit      = "2000m"
    memory_limit   = "2Gi"
    cpu_request    = "1000m"
    memory_request = "1Gi"

    # SSL certificate
    cert_resolver = "cloudflare"
  }
}
```

## Storage Volumes

openHAB uses three separate persistent volumes:

1. **Data Volume** (`/openhab/userdata`): Runtime data, logs, cache
2. **Addons Volume** (`/openhab/addons`): Custom bindings and add-ons
3. **Configuration Volume** (`/openhab/conf`): Items, rules, sitemaps

## Device Access

For USB devices (Zigbee, Z-Wave dongles):

```hcl
service_overrides = {
  openhab = {
    enable_privileged = true
  }
}
```

For network device discovery:

```hcl
service_overrides = {
  openhab = {
    enable_host_network = true
  }
}
```

## Karaf Console Access

Enable console for debugging and administration:

```hcl
service_overrides = {
  openhab = {
    enable_karaf_console = true
  }
}
```

Access via: `https://openhab-karaf.{domain}` (SSH over HTTPS tunnel)

## Integration with Other Services

### Node-RED Integration
Excellent integration for visual rule creation:

```hcl
services = {
  openhab  = true
  node_red = true
}

service_overrides = {
  node_red = {
    palette_packages = [
      "node-red-contrib-openhab3",
      "node-red-dashboard"
    ]
  }
}
```

### Monitoring Integration
Monitor openHAB with Prometheus:

```hcl
services = {
  openhab    = true
  prometheus = true
  grafana    = true
}
```

## Access

After deployment, openHAB will be available at:
- **Main UI**: `https://openhab.{domain}`
- **REST API**: `https://openhab.{domain}/rest/`
- **Karaf Console**: `https://openhab-karaf.{domain}` (if enabled)
- **Internal**: `http://openhab.{namespace}.svc.cluster.local:8080`

## Java Configuration

openHAB includes optimized JVM settings:
- **Memory**: `-Xms512m -Xmx1536m` (adjustable via resources)
- **GC**: G1 garbage collector with string deduplication
- **Container**: Optimized for Kubernetes deployment

## Performance Considerations

- **Startup Time**: 3-5 minutes for full initialization
- **Memory**: Minimum 1Gi recommended, 2Gi for production
- **CPU**: Java benefits from multiple cores
- **Storage**: Separate volumes prevent I/O conflicts

## Security Considerations

- **Privileged Mode**: Only enable for USB device access
- **Host Network**: Only enable for device discovery
- **Karaf Console**: Disable in production environments
- **Authentication**: Configure openHAB's built-in authentication

## Troubleshooting

### Common Issues

1. **Long Startup**: openHAB takes time to initialize all bindings
2. **Memory Issues**: Increase memory limits for large configurations
3. **Device Access**: Ensure privileged mode for USB devices
4. **Binding Issues**: Check Karaf console for binding status

### Logs

```bash
# Main application logs
kubectl logs -f deployment/openhab -n openhab-system

# Karaf console access
kubectl port-forward svc/openhab 8101:8101 -n openhab-system
ssh -p 8101 openhab@localhost
```

### Health Check

```bash
kubectl get pods -n openhab-system
curl -k https://openhab.{domain}/rest/
```

### Karaf Console Commands

```bash
# List all bindings
bundle:list | grep binding

# Check thing status
openhab:things list

# View logs
log:tail
```

## Resources

- [openHAB Documentation](https://www.openhab.org/docs/)
- [openHAB Community](https://community.openhab.org/)
- [Binding List](https://www.openhab.org/addons/)
- [REST API Documentation](https://www.openhab.org/docs/configuration/restdocs.html)
- [Karaf Console Reference](https://karaf.apache.org/manual/latest/)
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
| [kubernetes_manifest.karaf_ingress_route](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_namespace.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_persistent_volume_claim.addons_storage](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume_claim) | resource |
| [kubernetes_persistent_volume_claim.conf_storage](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume_claim) | resource |
| [kubernetes_persistent_volume_claim.data_storage](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume_claim) | resource |
| [null_resource.wait_for_deployment](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [kubernetes_service.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/service) | data source |

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
| <a name="input_deployment_wait_timeout"></a> [deployment\_wait\_timeout](#input\_deployment\_wait\_timeout) | Timeout in seconds to wait for deployment to be ready | `number` | `300` | no |
| <a name="input_disable_arch_scheduling"></a> [disable\_arch\_scheduling](#input\_disable\_arch\_scheduling) | Disable architecture-based node scheduling | `bool` | `false` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Domain name for ingress resources | `string` | `".local"` | no |
| <a name="input_enable_host_network"></a> [enable\_host\_network](#input\_enable\_host\_network) | Enable host network for device discovery | `bool` | `false` | no |
| <a name="input_enable_ingress"></a> [enable\_ingress](#input\_enable\_ingress) | Enable ingress functionality for external access | `bool` | `true` | no |
| <a name="input_enable_karaf_console"></a> [enable\_karaf\_console](#input\_enable\_karaf\_console) | Enable Karaf console access | `bool` | `false` | no |
| <a name="input_enable_persistence"></a> [enable\_persistence](#input\_enable\_persistence) | Enable persistent storage for openHAB data | `bool` | `true` | no |
| <a name="input_enable_privileged"></a> [enable\_privileged](#input\_enable\_privileged) | Enable privileged mode for device access (USB, GPIO) | `bool` | `false` | no |
| <a name="input_helm_cleanup_on_fail"></a> [helm\_cleanup\_on\_fail](#input\_helm\_cleanup\_on\_fail) | Cleanup resources on failure | `bool` | `false` | no |
| <a name="input_helm_disable_webhooks"></a> [helm\_disable\_webhooks](#input\_helm\_disable\_webhooks) | Disable webhooks for Helm release | `bool` | `true` | no |
| <a name="input_helm_force_update"></a> [helm\_force\_update](#input\_helm\_force\_update) | Force resource updates if needed | `bool` | `false` | no |
| <a name="input_helm_replace"></a> [helm\_replace](#input\_helm\_replace) | Allow Helm to replace existing resources | `bool` | `false` | no |
| <a name="input_helm_skip_crds"></a> [helm\_skip\_crds](#input\_helm\_skip\_crds) | Skip CRDs for Helm release | `bool` | `false` | no |
| <a name="input_helm_timeout"></a> [helm\_timeout](#input\_helm\_timeout) | Timeout for Helm deployment in seconds | `number` | `600` | no |
| <a name="input_helm_wait"></a> [helm\_wait](#input\_helm\_wait) | Wait for Helm release to be ready | `bool` | `false` | no |
| <a name="input_helm_wait_for_jobs"></a> [helm\_wait\_for\_jobs](#input\_helm\_wait\_for\_jobs) | Wait for Helm jobs to complete | `bool` | `false` | no |
| <a name="input_memory_limit"></a> [memory\_limit](#input\_memory\_limit) | Memory limit for openHAB containers | `string` | `"2Gi"` | no |
| <a name="input_memory_request"></a> [memory\_request](#input\_memory\_request) | Memory request for openHAB containers | `string` | `"1Gi"` | no |
| <a name="input_name"></a> [name](#input\_name) | Helm release name for openHAB | `string` | `"openhab"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Kubernetes namespace for openHAB deployment | `string` | `"openhab-system"` | no |
| <a name="input_persistent_disk_size"></a> [persistent\_disk\_size](#input\_persistent\_disk\_size) | Size of persistent disk for openHAB data | `string` | `"8Gi"` | no |
| <a name="input_storage_class"></a> [storage\_class](#input\_storage\_class) | Storage class for persistent volumes | `string` | `"hostpath"` | no |
| <a name="input_traefik_cert_resolver"></a> [traefik\_cert\_resolver](#input\_traefik\_cert\_resolver) | Traefik certificate resolver name | `string` | `"default"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_external_url"></a> [external\_url](#output\_external\_url) | External URL for openHAB (when ingress is enabled) |
| <a name="output_helm_release_name"></a> [helm\_release\_name](#output\_helm\_release\_name) | Name of the Helm release |
| <a name="output_helm_release_namespace"></a> [helm\_release\_namespace](#output\_helm\_release\_namespace) | Namespace of the Helm release |
| <a name="output_helm_release_version"></a> [helm\_release\_version](#output\_helm\_release\_version) | Version of the deployed Helm chart |
| <a name="output_karaf_external_url"></a> [karaf\_external\_url](#output\_karaf\_external\_url) | External URL for Karaf console (when ingress and console are enabled) |
| <a name="output_karaf_port"></a> [karaf\_port](#output\_karaf\_port) | Port of the Karaf console (if enabled) |
| <a name="output_namespace"></a> [namespace](#output\_namespace) | Kubernetes namespace where openHAB is deployed |
| <a name="output_persistent_volumes"></a> [persistent\_volumes](#output\_persistent\_volumes) | Information about persistent volumes |
| <a name="output_service_name"></a> [service\_name](#output\_service\_name) | Name of the openHAB Kubernetes service |
| <a name="output_service_port"></a> [service\_port](#output\_service\_port) | Port of the openHAB service |
| <a name="output_storage_class"></a> [storage\_class](#output\_storage\_class) | Storage class used for persistent volumes |
| <a name="output_url"></a> [url](#output\_url) | Internal URL for openHAB service |

<!-- END_TF_DOCS -->
