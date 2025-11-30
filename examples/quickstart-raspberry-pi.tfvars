# ============================================================================
# QUICK START: Raspberry Pi Cluster
# ============================================================================
# Minimal configuration for Raspberry Pi ARM64 clusters
# Copy to terraform.tfvars and customize
# ============================================================================

# Basic Settings
base_domain   = "homelab.local"
platform_name = "k3s"
cpu_arch      = "arm64"
le_email      = "admin@homelab.local"

# Network
metallb_address_pool = "192.168.1.200-192.168.1.210"

# Storage - Local only for Pi
use_hostpath_storage = true
use_nfs_storage      = false

# Essential Services Only
services = {
  traefik                = true
  metallb                = true
  host_path              = true
  prometheus             = true
  prometheus_crds        = true
  grafana                = true
  portainer              = true
  node_feature_discovery = true

  # Disabled for resource efficiency
  nfs_csi    = false
  loki       = false
  promtail   = false
  consul     = false
  vault      = false
  gatekeeper = false
}

# Resource Limits for Pi
enable_resource_limits = true
default_cpu_limit      = "500m"
default_memory_limit   = "512Mi"

# STEP 2: Enable authentication after first deployment
middleware_overrides = {
  enabled = false # Change to true after first deployment
}
