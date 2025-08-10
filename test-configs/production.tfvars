# ============================================================================
# Production Environment Configuration
# ============================================================================
#
# Production-ready configuration with full security, monitoring, and HA
# Optimized for cloud environments with enterprise features
#
# ============================================================================

# Basic Configuration
base_domain   = "prod.company.com"
platform_name = "k8s"

# Architecture Configuration
cpu_arch                = "amd64"
auto_mixed_cluster_mode = false
enable_microk8s_mode    = false

# Network Configuration - Production IP ranges
metallb_address_pool = "10.0.100.200-10.0.100.210"

# Storage Configuration - Enterprise NFS
use_nfs_storage      = true
use_hostpath_storage = false
nfs_server_address   = "prod-nfs.company.com"
nfs_server_path      = "/data/prod-k8s"

# Full Production Service Stack
services = {
  # Core infrastructure (required)
  traefik                = true
  metallb                = true
  host_path              = false
  nfs_csi                = true
  node_feature_discovery = true

  # Full monitoring stack (production)
  prometheus      = true
  prometheus_crds = true
  grafana               = true
  loki                  = true
  promtail              = true

  # Service mesh and security (production)
  consul     = true
  vault      = true
  gatekeeper = true

  # Management (production)
  portainer = true
}

# Production Resource Limits
enable_resource_limits = true
default_cpu_limit      = "1000m"
default_memory_limit   = "2Gi"

# Production Service Overrides
service_overrides = {
  traefik = {
    cpu_arch         = "amd64"
    storage_class    = "nfs-csi-fast"
    storage_size     = "5Gi"
    cpu_limit        = "1000m"
    memory_limit     = "1Gi"
    enable_dashboard = false # Security: disable in production
    helm_timeout     = 300
  }

  prometheus = {
    cpu_arch         = "amd64"
    storage_class    = "nfs-csi-safe"
    storage_size     = "100Gi"
    retention_period = "90d" # Long retention for production
    cpu_limit        = "4000m"
    memory_limit     = "8Gi"
    helm_timeout     = 900
  }

  grafana = {
    cpu_arch           = "amd64"
    storage_class      = "nfs-csi-safe"
    storage_size       = "10Gi"
    enable_persistence = true
    cpu_limit          = "500m"
    memory_limit       = "1Gi"
  }

  consul = {
    cpu_arch      = "amd64"
    storage_class = "nfs-csi-safe"
    storage_size  = "20Gi"
    cpu_limit     = "1000m"
    memory_limit  = "1Gi"
    helm_timeout  = 600
    replicas      = 3 # HA configuration
  }

  vault = {
    cpu_arch      = "amd64"
    storage_class = "nfs-csi-safe"
    storage_size  = "20Gi"
    cpu_limit     = "1000m"
    memory_limit  = "1Gi"
    helm_timeout  = 900
    ha_replicas   = 3 # HA configuration
  }

  loki = {
    cpu_arch         = "amd64"
    storage_class    = "nfs-csi-safe"
    storage_size     = "50Gi"
    retention_period = "30d"
    cpu_limit        = "2000m"
    memory_limit     = "2Gi"
  }

  promtail = {
    cpu_arch     = "amd64"
    cpu_limit    = "200m"
    memory_limit = "256Mi"
  }

  portainer = {
    cpu_arch      = "amd64"
    storage_class = "nfs-csi-safe"
    storage_size  = "5Gi"
    cpu_limit     = "500m"
    memory_limit  = "512Mi"
  }

  gatekeeper = {
    cpu_arch     = "amd64"
    cpu_limit    = "1000m"
    memory_limit = "512Mi"
  }

  metallb = {
    cpu_arch     = "amd64"
    cpu_limit    = "200m"
    memory_limit = "256Mi"
  }

  nfs_csi = {
    cpu_arch     = "amd64"
    cpu_limit    = "200m"
    memory_limit = "256Mi"
  }

  node_feature_discovery = {
    cpu_arch     = "amd64"
    cpu_limit    = "100m"
    memory_limit = "128Mi"
  }
}

# Production Storage Class Configuration
storage_class_override = {
  # Critical data on safe storage
  prometheus   = "nfs-csi-safe"
  alertmanager = "nfs-csi-safe"
  consul       = "nfs-csi-safe"
  vault        = "nfs-csi-safe"
  loki         = "nfs-csi-safe"
  grafana      = "nfs-csi-safe"
  portainer    = "nfs-csi-safe"

  # High-performance ingress
  traefik = "nfs-csi-fast"
}

# Production Helm Configuration
default_helm_timeout = 600
default_helm_wait    = true
default_helm_cleanup_on_fail = true

# Production Security Configuration
traefik_cert_resolver = "letsencrypt"
le_email              = "admin@company.com"

# Production Timeouts
vault_init_timeout      = "300s"
vault_readiness_timeout = "120s"
consul_join_timeout     = "180s"
healthcheck_interval    = "30s"
healthcheck_timeout     = "10s"

# Production NFS Configuration
nfs_timeout_default = 600
nfs_timeout_fast    = 300
nfs_timeout_safe    = 900
nfs_retrans_default = 3
nfs_retrans_fast    = 2
nfs_retrans_safe    = 5

# Production Features
enable_debug_outputs = false
