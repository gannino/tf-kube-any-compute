# Cloud Provider Configuration
# Optimized for EKS/GKE/AKS deployments

base_domain   = "cloud.example.com"
platform_name = "k8s"
cpu_arch      = "amd64"

# Cloud-native service stack
services = {
  traefik                = true
  metallb                = false # Use cloud load balancer
  host_path              = false
  nfs_csi                = true
  prometheus             = true
  prometheus_crds        = true
  grafana                = true
  loki                   = true
  promtail               = true
  consul                 = true
  vault                  = true
  gatekeeper             = true
  portainer              = true
  node_feature_discovery = true
}

# Cloud storage
use_nfs_storage      = true
use_hostpath_storage = false
nfs_server_address   = "nfs.cloud.internal"
nfs_server_path      = "/shared/k8s"

# Production resource limits
enable_resource_limits = true
default_cpu_limit      = "2000m"
default_memory_limit   = "4Gi"

# SSL configuration
traefik_cert_resolver = "letsencrypt"
le_email              = "admin@example.com"

# Cloud-optimized overrides
service_overrides = {
  # Disable dashboard for CI compatibility
  traefik = {
    enable_dashboard = false
  }

  # No MetalLB needed in cloud
  metallb = {
    address_pool = ""
  }

  # High-performance monitoring
  prometheus = {
    storage_size = "50Gi"
    cpu_limit    = "2000m"
    memory_limit = "8Gi"
  }

  # Secure vault configuration
  vault = {
    helm_timeout = 900
    storage_size = "10Gi"
  }
}
