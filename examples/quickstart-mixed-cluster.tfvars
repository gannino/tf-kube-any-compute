# ============================================================================
# QUICK START: Mixed Architecture Cluster (ARM64 + AMD64)
# ============================================================================
# Configuration for clusters with both ARM64 and AMD64 nodes
# Copy to terraform.tfvars and customize
# ============================================================================

# Basic Settings
base_domain   = "homelab.local"
platform_name = "k3s"
le_email      = "admin@homelab.local"

# Mixed Architecture
auto_mixed_cluster_mode = true
cpu_arch                = "" # Auto-detect

# Network
metallb_address_pool = "192.168.1.200-192.168.1.210"

# Storage
use_nfs_storage    = true
nfs_server_address = "192.168.1.100"
nfs_server_path    = "/mnt/nfs/k8s"

# Full Stack
services = {
  traefik                = true
  metallb                = true
  nfs_csi                = true
  prometheus             = true
  prometheus_crds        = true
  grafana                = true
  kube_state_metrics     = true
  consul                 = true
  vault                  = true
  portainer              = true
  node_feature_discovery = true
}

# Architecture Placement Strategy
cpu_arch_override = {
  # Performance-critical on AMD64
  prometheus = "amd64"
  traefik    = "amd64"
  vault      = "amd64"

  # UI services on ARM64
  grafana   = "arm64"
  portainer = "arm64"
}

# STEP 2: Enable authentication after first deployment
middleware_overrides = {
  enabled = false # Change to true after first deployment
}
