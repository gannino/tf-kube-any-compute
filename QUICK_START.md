# 🚀 Quick Start Guide

Get tf-kube-any-compute running in 5 minutes!

## Prerequisites

```bash
# Required tools
terraform >= 1.12.2
kubectl
helm >= 3.0

# Verify cluster access
kubectl cluster-info
```

## 1. Clone and Configure

```bash
git clone https://github.com/gannino/tf-kube-any-compute.git
cd tf-kube-any-compute

# Copy example configuration
cp terraform.tfvars.example terraform.tfvars
```

## 2. Basic Configuration

Edit `terraform.tfvars`:

```hcl
# Essential settings
base_domain   = "your-domain.com"
platform_name = "homelab"

# Enable core services
services = {
  traefik   = true
  metallb   = true
  host_path = true
  prometheus = true
  grafana   = true
}

# MetalLB IP range (adjust for your network)
service_overrides = {
  metallb = {
    address_pool = "192.168.1.200-192.168.1.210"
  }
}
```

## 3. Deploy

```bash
# Initialize and deploy
make init
make plan
make apply
```

## 4. Access Services

After deployment:
- **Traefik Dashboard**: `https://traefik.homelab.your-domain.com`
- **Grafana**: `https://grafana.homelab.your-domain.com`

Get passwords:
```bash
terraform output service_urls
```

## 🎯 Next Steps

- [Full Documentation](README.md)
- [Configuration Examples](examples/)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Contributing](CONTRIBUTING.md)

## 💡 Common Scenarios

**Raspberry Pi Cluster:**
```hcl
cpu_arch = "arm64"
enable_microk8s_mode = true
use_hostpath_storage = true
```

**Production Cloud:**
```hcl
cpu_arch = "amd64"
use_nfs_storage = true
enable_gatekeeper = true
```

Need help? Check our [GitHub Discussions](https://github.com/gannino/tf-kube-any-compute/discussions)!