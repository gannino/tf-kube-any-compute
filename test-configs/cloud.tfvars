# Cloud Deployment Configuration for CI Testing
base_domain   = "cloud.example.com"
platform_name = "eks"

# Cloud-optimized architecture
cpu_arch = "amd64"

# Full enterprise service stack
services = {
  traefik                = true
  metallb                = false # Use cloud load balancer
  host_path              = false # Use cloud storage
  prometheus             = true
  grafana                = true
  loki                   = true
  promtail               = true
  consul                 = true
  vault                  = true
  portainer              = true
  gatekeeper             = true
  nfs_csi                = false # Use cloud native storage
  node_feature_discovery = true
}

# Cloud storage configuration
use_hostpath_storage = false
use_nfs_storage      = false # Use cloud native storage classes

# Cloud networking (no MetalLB needed)
le_email = "devops@example.com"

# Enterprise security configurations
enable_pod_security_policies = true
enable_network_policies      = true

service_overrides = {
  # Traefik with enhanced port configuration
  traefik = {
    # Enhanced port configuration
    enable_dashboard = false
  }
}

# Resource quotas for cloud billing optimization
namespace_resource_quotas = {
  monitoring = {
    requests_cpu    = "2"
    requests_memory = "4Gi"
    limits_cpu      = "4"
    limits_memory   = "8Gi"
  }
  service_mesh = {
    requests_cpu    = "1"
    requests_memory = "2Gi"
    limits_cpu      = "2"
    limits_memory   = "4Gi"
  }
}
