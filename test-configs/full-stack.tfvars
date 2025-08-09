# ============================================================================
# Test Configuration Template - Full Stack Deployment
# ============================================================================
#
# This template enables all available services for comprehensive testing
# of the complete infrastructure stack.
#
# Usage:
#   cp test-configs/full-stack.tfvars terraform.tfvars
#   terraform plan
#   terraform apply
#
# Services Included:
#   - All ingress, storage, monitoring, security, and utility services
#   - Full observability stack (Prometheus, Grafana, Loki, Promtail)
#   - Service mesh components (Consul, Vault)
#   - Security enforcement (Gatekeeper)
#   - Development tools (Portainer)
#
# Warning: This configuration requires significant resources
#
# ============================================================================

# Cluster Configuration (Full Stack)
cluster_name       = "test-full-stack"
cluster_domain     = "fullstack.test.local"
node_count         = 3
instance_size      = "g3.large" # Larger instances for full stack
kubernetes_version = "v1.28.2+k3s1"

# Network Configuration
civo_network                   = "default"
firewall_create_outbound_rules = true

# SSH Configuration
ssh_public_key_path = "~/.ssh/id_rsa.pub"

# Storage Configuration (Host Path for Testing)
use_hostpath_storage = true
enable_host_path     = true
use_nfs_storage      = false

# Core Infrastructure Services
enable_traefik = true
enable_metallb = true

# Monitoring and Observability Stack
enable_prometheus      = true
enable_prometheus_crds = true
enable_grafana         = true
enable_loki            = true
enable_promtail        = true

# Service Mesh and Security
enable_vault      = true
enable_consul     = true
enable_gatekeeper = true

# Development and Management Tools
enable_portainer              = true
enable_node_feature_discovery = true

# Storage Services
enable_nfs_csi = false # Disabled for host path testing

# Extended Timeouts for Complex Deployment
default_helm_timeout = 900 # 15 minutes
default_helm_wait    = true
default_helm_atomic  = true
healthcheck_interval = "30s"
healthcheck_timeout  = "10s"

# Service-Specific Timeouts
service_overrides = {
  vault = {
    helm_timeout = 1200 # 20 minutes
    helm_wait    = true
    helm_atomic  = true
  }
  consul = {
    helm_timeout = 1200 # 20 minutes
    helm_wait    = true
    helm_atomic  = true
  }
  prometheus = {
    helm_timeout = 1500 # 25 minutes
    helm_wait    = true
    helm_atomic  = true
  }
  loki = {
    helm_timeout = 900 # 15 minutes
    helm_wait    = true
  }
  gatekeeper = {
    helm_timeout = 900 # 15 minutes for CRD installation
    helm_wait    = true
  }
}

# Vault Configuration
vault_replicas          = 3
vault_auto_unseal       = false
vault_storage_class     = "hostpath"
vault_storage_size      = "5Gi"
vault_port              = 8200
vault_readiness_timeout = "120s"

# Consul Configuration
consul_replicas          = 3
consul_enable_acl        = true
consul_storage_class     = "hostpath"
consul_storage_size      = "5Gi"
consul_port              = 8500
consul_readiness_timeout = "90s"

# Prometheus Configuration
prometheus_storage_class  = "hostpath"
prometheus_storage_size   = "20Gi"
prometheus_retention_time = "15d"

# AlertManager Configuration
alertmanager_storage_class = "hostpath"
alertmanager_storage_size  = "5Gi"

# Grafana Configuration
grafana_storage_class = "hostpath"
grafana_storage_size  = "5Gi"
grafana_admin_user    = "admin"

# Loki Configuration
loki_storage_class   = "hostpath"
loki_storage_size    = "10Gi"
loki_retention_hours = 168 # 7 days

# Traefik Configuration
traefik_web_port            = 8080
traefik_websecure_port      = 8443
traefik_cert_resolver       = "letsencrypt"
enable_traefik_dashboard    = true
traefik_dashboard_auth_user = "admin"

# Portainer Configuration
portainer_port          = 9000
portainer_storage_class = "hostpath"
portainer_storage_size  = "2Gi"

# Gatekeeper Configuration
gatekeeper_timeout_default      = "60s"
gatekeeper_timeout_crd_creation = "120s"

# CRD Wait Configuration
crd_wait_timeout_minutes = 30

# Domain and Ingress Configuration
domain_name    = ".fullstack.test.local"
enable_ingress = true

# Full Service Map
services = {
  traefik                = true
  metallb                = true
  host_path              = true
  prometheus             = true
  prometheus_crds        = true
  grafana                = true
  loki                   = true
  promtail               = true
  vault                  = true
  consul                 = true
  gatekeeper             = true
  portainer              = true
  node_feature_discovery = true
}

# Comprehensive Labels
common_tags = {
  Environment  = "test"
  Deployment   = "full-stack"
  Purpose      = "comprehensive-testing"
  Architecture = "standard"
}

# Resource Quotas (Full Stack)
default_namespace_cpu_limit     = "4000m"
default_namespace_memory_limit  = "8Gi"
default_namespace_storage_limit = "100Gi"
