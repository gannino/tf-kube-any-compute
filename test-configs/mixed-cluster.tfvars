# Mixed Architecture Cluster Configuration for CI Testing
base_domain   = "mixed.local"
platform_name = "k3s"

# Mixed architecture with intelligent placement
cpu_arch                = "amd64"
auto_mixed_cluster_mode = true

# Full service portfolio with strategic placement
services = {
  traefik                = true
  metallb                = true
  host_path              = true
  prometheus             = true
  grafana                = true
  loki                   = true
  promtail               = true
  consul                 = true
  vault                  = true
  portainer              = true
  gatekeeper             = true
  nfs_csi                = true
  node_feature_discovery = true
}

# Architecture overrides for optimal placement
cpu_arch_override = {
  traefik    = "amd64" # Performance critical ingress
  prometheus = "amd64" # Resource intensive monitoring
  consul     = "amd64" # Service mesh requires performance
  vault      = "amd64" # Security service on reliable arch
  grafana    = "arm64" # UI can run efficiently on ARM64
  portainer  = "arm64" # Management UI on ARM64
  loki       = "amd64" # Log aggregation needs performance
  # promtail omitted - will use auto-detection
}

# Both storage types for testing
use_hostpath_storage = true
use_nfs_storage      = true

# Networking
metallb_address_pool = "192.168.1.220-192.168.1.230"
le_email             = "admin@mixed.local"

# NFS configuration
nfs_server = "192.168.1.100"
nfs_path   = "/mnt/k8s-storage"

service_overrides = {
  # Traefik with enhanced port configuration
  traefik = {
    # Enhanced port configuration
    enable_dashboard = false
  }
}
