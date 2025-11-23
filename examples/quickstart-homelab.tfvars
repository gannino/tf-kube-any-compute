# ============================================================================
# QUICK START: Home Lab with NFS Storage
# ============================================================================
# Standard homelab configuration with NFS shared storage
# Copy to terraform.tfvars and customize
# ============================================================================

# Basic Settings
base_domain   = "homelab.local"
platform_name = "k3s"
le_email      = "admin@homelab.local"

# Network
metallb_address_pool = "192.168.1.200-192.168.1.210"

# NFS Storage
use_nfs_storage    = true
nfs_server_address = "192.168.1.100"
nfs_server_path    = "/mnt/nfs/k8s"

# Full Monitoring Stack
services = {
  traefik                = true
  metallb                = true
  nfs_csi                = true
  prometheus             = true
  prometheus_crds        = true
  grafana                = true
  kube_state_metrics     = true
  portainer              = true
  consul                 = true
  vault                  = true
  node_feature_discovery = true

  # Optional
  loki       = false
  promtail   = false
  gatekeeper = false
}

# STEP 2: Enable authentication after first deployment
middleware_overrides = {
  enabled = false # Change to true after first deployment
}
