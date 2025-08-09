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