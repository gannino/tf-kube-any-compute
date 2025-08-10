# MetalLB Helm Module

## Overview

This module deploys MetalLB, a load-balancer implementation for bare metal Kubernetes clusters, using Helm. It supports both L2 and BGP modes with advanced configuration options.

## Features

- **L2 Mode**: Simple layer 2 load balancing (default)
- **BGP Mode**: Advanced BGP routing with peer configuration
- **Multi-Architecture**: ARM64/AMD64 support with intelligent scheduling
- **High Availability**: Controller and speaker replica configuration
- **Monitoring**: Prometheus metrics and ServiceMonitor support
- **Resource Management**: Configurable CPU/memory limits and requests

## Usage

### Basic L2 Configuration

```hcl
module "metallb" {
  source = "./helm-metallb"

  namespace    = "metallb-system"
  address_pool = "192.168.1.200-192.168.1.210"

  # Architecture-specific deployment
  cpu_arch                = "amd64"
  disable_arch_scheduling = false

  # Resource limits
  cpu_limit    = "100m"
  memory_limit = "64Mi"
}
```

### BGP Configuration

```hcl
module "metallb" {
  source = "./helm-metallb"

  namespace    = "metallb-system"
  address_pool = "10.0.0.100-10.0.0.110"

  # Enable BGP mode
  enable_bgp = true
  enable_frr = true

  bgp_peers = [
    {
      peer_address = "10.0.0.1"
      peer_asn     = 65001
      my_asn       = 65000
    }
  ]

  # Additional IP pools
  additional_ip_pools = [
    {
      name        = "production-pool"
      addresses   = ["10.0.1.100-10.0.1.110"]
      auto_assign = false
    }
  ]
}
```

### High Availability Setup

```hcl
module "metallb" {
  source = "./helm-metallb"

  # Multiple replicas for HA
  controller_replica_count = 3
  speaker_replica_count    = 5

  # Monitoring
  enable_prometheus_metrics = true
  service_monitor_enabled   = true

  # Logging
  log_level = "info"
}
```

## Configuration Options

### Core Settings

| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `namespace` | MetalLB namespace | `string` | `"metallb-system"` |
| `address_pool` | IP address range (IP1-IP2) | `string` | `"192.168.169.30-192.168.169.60"` |
| `cpu_arch` | CPU architecture (amd64/arm64) | `string` | `"arm64"` |

### BGP Configuration

| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `enable_bgp` | Enable BGP mode | `bool` | `false` |
| `enable_frr` | Enable FRR for advanced BGP | `bool` | `false` |
| `bgp_peers` | BGP peer configuration | `list(object)` | `[]` |

### Monitoring

| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `enable_prometheus_metrics` | Enable Prometheus metrics | `bool` | `true` |
| `service_monitor_enabled` | Enable ServiceMonitor | `bool` | `false` |
| `log_level` | Log level (debug/info/warn/error) | `string` | `"info"` |

## Outputs

| Output | Description |
|--------|-------------|
| `namespace` | MetalLB namespace |
| `address_pool` | Configured IP address pool |
| `load_balancer_class` | Load balancer class name |
| `helm_release_status` | Helm release status |

## Dependencies

- Kubernetes cluster
- Helm provider
- kubectl provider (for CRD management)

## Architecture Support

This module automatically detects and supports:
- **ARM64**: Raspberry Pi clusters
- **AMD64**: x86 servers and cloud instances
- **Mixed Clusters**: Intelligent service placement

## Troubleshooting

### Common Issues

1. **IP Pool Conflicts**: Ensure address pool doesn't conflict with existing network ranges
2. **BGP Connectivity**: Verify BGP peer configuration and network connectivity
3. **Architecture Scheduling**: Check node labels for proper architecture detection

### Debug Commands

```bash
# Check MetalLB pods
kubectl get pods -n metallb-system

# Check IP address pools
kubectl get ipaddresspool -n metallb-system

# Check BGP peers (if enabled)
kubectl get bgppeer -n metallb-system

# Check service logs
kubectl logs -n metallb-system -l app=metallb
```

## Version Compatibility

- **Terraform**: >= 1.0
- **Kubernetes**: >= 1.20
- **MetalLB**: >= 0.13.10
- **Helm**: >= 3.0
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 3.0 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | ~> 1.14 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | ~> 3.0 |
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | ~> 1.14 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | ~> 2.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.this](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubectl_manifest.metallb_additional_pools](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.metallb_bgp_advert](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.metallb_bgp_peers](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.metallb_ip_pool](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.metallb_l2_advert](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubernetes_limit_range.namespace_limits](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/limit_range) | resource |
| [kubernetes_namespace.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_ip_pools"></a> [additional\_ip\_pools](#input\_additional\_ip\_pools) | Additional IP address pools for MetalLB | <pre>list(object({<br/>    name        = string<br/>    addresses   = list(string)<br/>    auto_assign = optional(bool, true)<br/>  }))</pre> | `[]` | no |
| <a name="input_address_pool"></a> [address\_pool](#input\_address\_pool) | IP address range for MetalLB load balancer (format: IP1-IP2) | `string` | `"192.168.1.30-192.168.1.60"` | no |
| <a name="input_address_pool_name"></a> [address\_pool\_name](#input\_address\_pool\_name) | Name of the address pool for MetalLB | `string` | `"default-pool"` | no |
| <a name="input_bgp_peers"></a> [bgp\_peers](#input\_bgp\_peers) | BGP peer configuration for MetalLB | <pre>list(object({<br/>    peer_address = string<br/>    peer_asn     = number<br/>    my_asn       = number<br/>  }))</pre> | `[]` | no |
| <a name="input_controller_replica_count"></a> [controller\_replica\_count](#input\_controller\_replica\_count) | Number of replicas for the MetalLB controller (1-5 recommended) | `number` | `1` | no |
| <a name="input_cpu_arch"></a> [cpu\_arch](#input\_cpu\_arch) | CPU architecture for node selection (amd64, arm64) | `string` | `"arm64"` | no |
| <a name="input_cpu_limit"></a> [cpu\_limit](#input\_cpu\_limit) | CPU limit for the container | `string` | `"100m"` | no |
| <a name="input_cpu_request"></a> [cpu\_request](#input\_cpu\_request) | CPU request for the container | `string` | `"25m"` | no |
| <a name="input_disable_arch_scheduling"></a> [disable\_arch\_scheduling](#input\_disable\_arch\_scheduling) | Disable architecture-based node scheduling (useful for cluster-wide services) | `bool` | `false` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | n/a | `string` | `".local"` | no |
| <a name="input_enable_bgp"></a> [enable\_bgp](#input\_enable\_bgp) | Enable BGP mode for MetalLB (alternative to L2 mode) | `bool` | `false` | no |
| <a name="input_enable_frr"></a> [enable\_frr](#input\_enable\_frr) | Enable FRR (Free Range Routing) for advanced BGP features | `bool` | `false` | no |
| <a name="input_enable_ingress"></a> [enable\_ingress](#input\_enable\_ingress) | n/a | `bool` | `false` | no |
| <a name="input_enable_load_balancer_class"></a> [enable\_load\_balancer\_class](#input\_enable\_load\_balancer\_class) | Enable LoadBalancerClass for MetalLB | `bool` | `false` | no |
| <a name="input_enable_prometheus_metrics"></a> [enable\_prometheus\_metrics](#input\_enable\_prometheus\_metrics) | Enable Prometheus metrics for MetalLB | `bool` | `true` | no |
| <a name="input_helm_cleanup_on_fail"></a> [helm\_cleanup\_on\_fail](#input\_helm\_cleanup\_on\_fail) | Cleanup resources on failure | `bool` | `false` | no |
| <a name="input_helm_disable_webhooks"></a> [helm\_disable\_webhooks](#input\_helm\_disable\_webhooks) | Disable webhooks for Helm release | `bool` | `false` | no |
| <a name="input_helm_force_update"></a> [helm\_force\_update](#input\_helm\_force\_update) | Force resource updates if needed | `bool` | `false` | no |
| <a name="input_helm_replace"></a> [helm\_replace](#input\_helm\_replace) | Allow Helm to replace existing resources | `bool` | `false` | no |
| <a name="input_helm_skip_crds"></a> [helm\_skip\_crds](#input\_helm\_skip\_crds) | Skip CRDs for Helm release | `bool` | `false` | no |
| <a name="input_helm_timeout"></a> [helm\_timeout](#input\_helm\_timeout) | Timeout for Helm deployment in seconds | `number` | `300` | no |
| <a name="input_helm_wait"></a> [helm\_wait](#input\_helm\_wait) | Wait for Helm release to be ready | `bool` | `false` | no |
| <a name="input_helm_wait_for_jobs"></a> [helm\_wait\_for\_jobs](#input\_helm\_wait\_for\_jobs) | Wait for Helm jobs to complete | `bool` | `false` | no |
| <a name="input_ingress_gateway_chart_name"></a> [ingress\_gateway\_chart\_name](#input\_ingress\_gateway\_chart\_name) | Ingress Gateway Helm chart name. | `string` | `"metallb"` | no |
| <a name="input_ingress_gateway_chart_repo"></a> [ingress\_gateway\_chart\_repo](#input\_ingress\_gateway\_chart\_repo) | Ingress Gateway Helm repository name. | `string` | `"https://metallb.github.io/metallb"` | no |
| <a name="input_ingress_gateway_chart_version"></a> [ingress\_gateway\_chart\_version](#input\_ingress\_gateway\_chart\_version) | MetalLB Helm chart version. | `string` | `"0.15.2"` | no |
| <a name="input_ingress_gateway_name"></a> [ingress\_gateway\_name](#input\_ingress\_gateway\_name) | Ingress Gateway Helm chart name. | `string` | `"metallb"` | no |
| <a name="input_le_email"></a> [le\_email](#input\_le\_email) | n/a | `string` | `""` | no |
| <a name="input_load_balancer_class"></a> [load\_balancer\_class](#input\_load\_balancer\_class) | Load balancer class name for MetalLB | `string` | `"metallb"` | no |
| <a name="input_log_level"></a> [log\_level](#input\_log\_level) | Log level for MetalLB components (debug, info, warn, error) | `string` | `"debug"` | no |
| <a name="input_memory_limit"></a> [memory\_limit](#input\_memory\_limit) | Memory limit for the container | `string` | `"64Mi"` | no |
| <a name="input_memory_request"></a> [memory\_request](#input\_memory\_request) | Memory request for the container | `string` | `"32Mi"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Ingress Gateway namespace. | `string` | `"metallb-system"` | no |
| <a name="input_persistent_disc_size"></a> [persistent\_disc\_size](#input\_persistent\_disc\_size) | n/a | `string` | `"1"` | no |
| <a name="input_service_monitor_enabled"></a> [service\_monitor\_enabled](#input\_service\_monitor\_enabled) | Enable ServiceMonitor for Prometheus Operator | `bool` | `false` | no |
| <a name="input_speaker_replica_count"></a> [speaker\_replica\_count](#input\_speaker\_replica\_count) | Number of replicas for the MetalLB speaker (typically matches node count) | `number` | `1` | no |
| <a name="input_workspace"></a> [workspace](#input\_workspace) | n/a | `string` | `"set-me"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_address_pool"></a> [address\_pool](#output\_address\_pool) | MetalLB IP address pool configuration |
| <a name="output_controller_replica_count"></a> [controller\_replica\_count](#output\_controller\_replica\_count) | Number of MetalLB controller replicas |
| <a name="output_helm_release_name"></a> [helm\_release\_name](#output\_helm\_release\_name) | MetalLB Helm release name |
| <a name="output_helm_release_status"></a> [helm\_release\_status](#output\_helm\_release\_status) | MetalLB Helm release status |
| <a name="output_load_balancer_class"></a> [load\_balancer\_class](#output\_load\_balancer\_class) | MetalLB load balancer class |
| <a name="output_module_config"></a> [module\_config](#output\_module\_config) | Complete module configuration for debugging |
| <a name="output_namespace"></a> [namespace](#output\_namespace) | MetalLB namespace |
| <a name="output_speaker_replica_count"></a> [speaker\_replica\_count](#output\_speaker\_replica\_count) | Number of MetalLB speaker replicas |
<!-- END_TF_DOCS -->
