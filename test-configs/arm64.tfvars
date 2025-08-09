# ============================================================================
# Test Configuration Template - ARM64 Raspberry Pi Deployment
# ============================================================================
#
# This template provides configuration optimized for ARM64 architecture
# deployments, particularly suitable for Raspberry Pi clusters.
#
# Usage:
#   cp test-configs/arm64.tfvars terraform.tfvars
#   terraform plan
#   terraform apply
#
# ARM64 Optimizations:
#   - Smaller instance sizes
#   - Extended timeouts for ARM64 image pulls
#   - Memory-optimized service configurations
#   - ARM64-compatible service selection
#
# ============================================================================

# Cluster Configuration (ARM64 Optimized)
cluster_name       = "test-arm64"
cluster_domain     = "arm64.test.local"
architecture       = "arm64"
node_count         = 3
instance_size      = "g3.small" # Smaller instances for ARM64
kubernetes_version = "v1.28.2+k3s1"

# Network Configuration
civo_network                   = "default"
firewall_create_outbound_rules = true

# SSH Configuration
ssh_public_key_path = "~/.ssh/id_rsa.pub"

# Storage Configuration (ARM64 Optimized)
use_hostpath_storage = true
enable_host_path     = true
use_nfs_storage      = false

# Core Services (ARM64 Compatible)
enable_traefik                = true
enable_metallb                = true
enable_portainer              = true
enable_node_feature_discovery = true # Useful for ARM64 node identification

# Monitoring Stack (ARM64 Optimized)
enable_prometheus      = true
enable_prometheus_crds = true
enable_grafana         = true
enable_loki            = false # Can be resource intensive on ARM64
enable_promtail        = false

# Security Services (ARM64 Compatible)
enable_vault      = false # Can be resource intensive
enable_consul     = false
enable_gatekeeper = true # Lightweight policy engine

# NFS (Disabled for basic ARM64 test)
enable_nfs_csi = false

# Extended Timeouts for ARM64 (slower image pulls)
default_helm_timeout = 600 # 10 minutes
default_helm_wait    = true
healthcheck_interval = "45s"
healthcheck_timeout  = "15s"

# ARM64-Specific Service Overrides
service_overrides = {
  prometheus = {
    helm_timeout = 900 # 15 minutes for ARM64
    helm_wait    = true
  }
  grafana = {
    helm_timeout = 600 # 10 minutes for ARM64
    helm_wait    = true
  }
  traefik = {
    helm_timeout = 450 # 7.5 minutes
  }
  gatekeeper = {
    helm_timeout = 600 # 10 minutes for CRD installation
  }
}

# ARM64 Performance Configuration
prometheus_storage_size = "5Gi" # Smaller storage for ARM64
grafana_storage_size    = "2Gi" # Smaller storage for ARM64

# Traefik Configuration (ARM64 Optimized)
traefik_web_port            = 8080
traefik_websecure_port      = 8443
enable_traefik_dashboard    = true
traefik_dashboard_auth_user = "admin"

# Portainer Configuration
portainer_port = 9000

# Prometheus Configuration (ARM64 Optimized)
prometheus_retention_time = "7d" # Shorter retention for ARM64

# Resource-Conscious Service Selection
services = {
  traefik                = true
  metallb                = true
  portainer              = true
  host_path              = true
  prometheus             = true
  grafana                = true
  gatekeeper             = true
  node_feature_discovery = true
}

# ARM64 Architecture Detection
locals {
  is_arm64                    = var.architecture == "arm64"
  arm64_optimizations_enabled = local.is_arm64
}
