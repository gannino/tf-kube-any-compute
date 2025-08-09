# Raspberry Pi Homelab Configuration for CI Testing
base_domain    = "pi.local"
platform_name  = "microk8s"
workspace_name = "pi-cluster"

# ARM64 Architecture
cpu_arch = "arm64"

# Pi-optimized services
services = {
  traefik                = true
  metallb                = true
  host_path              = true
  prometheus             = true
  grafana                = true
  loki                   = false # Memory intensive
  promtail               = true
  consul                 = false # Memory intensive
  vault                  = false # Memory intensive
  portainer              = true
  gatekeeper             = false # Can be resource heavy
  nfs_csi                = false
  node_feature_discovery = true
}

# Storage optimized for Pi
use_hostpath_storage = true
use_nfs_storage      = false

# Pi cluster networking
metallb_address_pool = "192.168.1.200-192.168.1.210"
cert_manager_email   = "admin@pi.local"

# Resource constraints for Pi
resource_limits = {
  prometheus = {
    memory = "2Gi"
    cpu    = "1000m"
  }
  grafana = {
    memory = "512Mi"
    cpu    = "500m"
  }
}
