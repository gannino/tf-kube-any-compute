# ============================================================================
# Test Configuration Template - Basic Deployment
# ============================================================================
#
# This template provides a minimal configuration for testing basic
# functionality with core services only.
#
# Usage:
#   cp test-configs/basic.tfvars terraform.tfvars
#   terraform plan
#   terraform apply
#
# Services Included:
#   - Traefik (ingress controller)
#   - Host Path (local storage)
#   - MetalLB (load balancer)
#   - Portainer (container management)
#
# ============================================================================

# Cluster Configuration
cluster_name       = "test-basic"
cluster_domain     = "test.local"
node_count         = 1
instance_size      = "g3.medium"
kubernetes_version = "v1.28.2+k3s1"

# Network Configuration
civo_network                   = "default"
firewall_create_outbound_rules = true

# SSH Configuration
ssh_public_key_path = "~/.ssh/id_rsa.pub"

# Storage Configuration
use_hostpath_storage = true
enable_host_path     = true
use_nfs_storage      = false

# Core Services
enable_traefik   = true
enable_metallb   = true
enable_portainer = true

# Disabled Services (for minimal deployment)
enable_prometheus             = false
enable_prometheus_crds        = false
enable_grafana                = false
enable_loki                   = false
enable_promtail               = false
enable_vault                  = false
enable_consul                 = false
enable_gatekeeper             = false
enable_nfs_csi                = false
enable_node_feature_discovery = false

# Service Configuration
default_helm_timeout = 300
default_helm_wait    = true
healthcheck_interval = "30s"
healthcheck_timeout  = "10s"

# Traefik Configuration
traefik_web_port            = 8080
traefik_websecure_port      = 8443
enable_traefik_dashboard    = true
traefik_dashboard_auth_user = "admin"

# Portainer Configuration
portainer_port = 9000

# Resource Limits (minimal)
services = {
  traefik   = true
  metallb   = true
  portainer = true
  host_path = true
}
