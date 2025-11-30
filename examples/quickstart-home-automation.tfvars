# ============================================================================
# QUICK START: Home Automation Hub
# ============================================================================
# Configuration for home automation services
# Copy to terraform.tfvars and customize
# ============================================================================

# Basic Settings
base_domain   = "homelab.local"
platform_name = "k3s"
le_email      = "admin@homelab.local"

# Network
metallb_address_pool = "192.168.1.200-192.168.1.210"

# Storage
use_hostpath_storage = true
use_nfs_storage      = false

# Core + Home Automation Services
services = {
  traefik                = true
  metallb                = true
  host_path              = true
  prometheus             = true
  prometheus_crds        = true
  grafana                = true
  portainer              = true
  node_feature_discovery = true

  # Home Automation
  home_assistant = true
  openhab        = false # Enable if needed (higher resources)
  homebridge     = true
  node_red       = true
  n8n            = true

  # Optional
  nfs_csi    = false
  consul     = false
  vault      = false
  gatekeeper = false
}

# Home Automation Configuration
service_overrides = {
  home_assistant = {
    storage_size        = "5Gi"
    enable_host_network = true # For device discovery
    cpu_limit           = "1000m"
    memory_limit        = "1Gi"
  }

  homebridge = {
    storage_size        = "2Gi"
    enable_host_network = true # For HomeKit discovery
    plugins = [
      "homebridge-config-ui-x",
      "homebridge-hue",
    ]
  }

  node_red = {
    storage_size = "2Gi"
    palette_packages = [
      "node-red-contrib-home-assistant-websocket",
      "node-red-dashboard",
    ]
  }

  n8n = {
    storage_size = "5Gi"
    cpu_limit    = "1000m"
    memory_limit = "1Gi"
  }
}

# STEP 2: Enable authentication after first deployment
middleware_overrides = {
  enabled = false # Change to true after first deployment
}
