# Minimal Homelab Configuration
# Bare minimum services for resource-constrained environments

base_domain   = "homelab.local"
platform_name = "k3s"
cpu_arch      = "amd64"

# Minimal service set - only essential infrastructure
services = {
  traefik                = true
  metallb                = true
  host_path              = true
  nfs_csi                = false
  prometheus             = false
  prometheus_crds        = false
  grafana                = false
  loki                   = false
  promtail               = false
  consul                 = false
  vault                  = false
  gatekeeper             = false
  portainer              = false
  node_feature_discovery = true
}

# Local storage only
use_hostpath_storage = true
use_nfs_storage      = false

# Resource constraints for minimal setup
enable_resource_limits = true
container_max_cpu      = "200m"
container_max_memory   = "256Mi"

# Basic networking
metallb_address_pool = "192.168.1.200-192.168.1.205"

# Service overrides - disable dashboard for CI
service_overrides = {
  traefik = {
    enable_dashboard = false
  }
}