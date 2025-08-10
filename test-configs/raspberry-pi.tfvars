# ============================================================================
# Raspberry Pi ARM64 Cluster Configuration
# ============================================================================
# 
# Optimized configuration for Raspberry Pi clusters with ARM64 architecture
# Focus on resource efficiency and ARM64-compatible services
#
# ============================================================================

# Basic Configuration
base_domain   = "homelab.local"
platform_name = "k3s"

# Architecture Configuration
cpu_arch                = "arm64"
enable_microk8s_mode    = false
auto_mixed_cluster_mode = false

# Network Configuration
metallb_address_pool = "192.168.1.200-210"

# Storage Configuration - Prefer local storage for Pi clusters
use_nfs_storage      = false
use_hostpath_storage = true

# Service Selection - Lightweight services for ARM64
services = {
  # Core infrastructure (essential)
  traefik                = true
  metallb                = true
  host_path              = true
  node_feature_discovery = true

  # Storage (local only)
  nfs_csi = false

  # Monitoring (lightweight)
  prometheus_stack      = true
  prometheus_stack_crds = true
  grafana               = true

  # Optional services (disabled for resource efficiency)
  loki       = false
  promtail   = false
  consul     = false
  vault      = false
  portainer  = true
  gatekeeper = false
}

# Resource Optimization for ARM64
enable_resource_limits = true
container_max_cpu      = "500m"
container_max_memory   = "512Mi"

# Service Overrides for ARM64 Optimization
service_overrides = {
  traefik = {
    cpu_arch         = "arm64"
    storage_class    = "hostpath"
    storage_size     = "1Gi"
    cpu_limit        = "300m"
    memory_limit     = "256Mi"
    enable_dashboard = false
    helm_timeout     = 300
  }

  prometheus_stack = {
    cpu_arch         = "arm64"
    storage_class    = "hostpath"
    storage_size     = "10Gi"
    retention_period = "7d" # Shorter retention for storage efficiency
    cpu_limit        = "1000m"
    memory_limit     = "1Gi"
    helm_timeout     = 600
  }

  grafana = {
    cpu_arch           = "arm64"
    storage_class      = "hostpath"
    enable_persistence = true
    cpu_limit          = "200m"
    memory_limit       = "256Mi"
  }

  portainer = {
    cpu_arch      = "arm64"
    storage_class = "hostpath"
    storage_size  = "1Gi"
    cpu_limit     = "200m"
    memory_limit  = "256Mi"
  }

  metallb = {
    cpu_arch     = "arm64"
    cpu_limit    = "100m"
    memory_limit = "128Mi"
  }

  host_path = {
    cpu_arch      = "arm64"
    storage_class = "hostpath"
  }

  node_feature_discovery = {
    cpu_arch     = "arm64"
    cpu_limit    = "50m"
    memory_limit = "64Mi"
  }
}

# Helm Configuration - Conservative timeouts for Pi clusters
default_helm_timeout = 300
helm_wait            = true

# Security Configuration
letsencrypt_email = "admin@homelab.local"

# Development/Testing
enable_debug_mode = false