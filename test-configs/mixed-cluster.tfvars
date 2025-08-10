# ============================================================================
# Mixed Architecture Cluster Configuration
# ============================================================================
#
# Configuration for clusters with both ARM64 and AMD64 nodes
# Optimizes service placement based on architecture capabilities
#
# ============================================================================

# Basic Configuration
base_domain   = "mixed.homelab.local"
platform_name = "k3s"

# Mixed Architecture Configuration
cpu_arch                = "" # Auto-detect
auto_mixed_cluster_mode = true
enable_microk8s_mode    = false

# Network Configuration
metallb_address_pool = "192.168.1.220-192.168.1.230"

# Storage Configuration - Use both NFS and local storage
use_nfs_storage      = true
use_hostpath_storage = true
nfs_server_address   = "192.168.1.100"
nfs_server_path      = "/mnt/k8s-storage"

# Service Selection - Full stack for mixed cluster
services = {
  # Core infrastructure
  traefik                = true
  metallb                = true
  host_path              = true
  nfs_csi                = true
  node_feature_discovery = true

  # Full monitoring stack
  prometheus      = true
  prometheus_crds = true
  grafana               = true
  loki                  = true
  promtail              = true

  # Service mesh and security
  consul = true
  vault  = true

  # Management
  portainer  = true
  gatekeeper = false # Disabled for compatibility
}

# Resource Configuration
enable_resource_limits = true
default_cpu_limit      = "1000m"
default_memory_limit   = "1Gi"

# Architecture-Specific Service Placement
cpu_arch_override = {
  # High-performance services on AMD64
  traefik    = "amd64"
  prometheus = "amd64"
  consul           = "amd64"
  vault            = "amd64"
  loki             = "amd64"

  # UI and management services on ARM64 (cost-effective)
  grafana   = "arm64"
  portainer = "arm64"
  promtail  = "arm64"
}

# Disable architecture constraints for cluster-wide services
disable_arch_scheduling = {
  metallb                = true
  nfs_csi                = true
  host_path              = true
  node_feature_discovery = true
}

# Service Overrides for Mixed Cluster
service_overrides = {
  traefik = {
    cpu_arch         = "amd64" # High-performance ingress
    storage_class    = "nfs-csi-fast"
    storage_size     = "2Gi"
    cpu_limit        = "500m"
    memory_limit     = "512Mi"
    enable_dashboard = false
    helm_timeout     = 300
  }

  prometheus = {
    cpu_arch         = "amd64" # Resource-intensive monitoring
    storage_class    = "nfs-csi-safe"
    storage_size     = "50Gi"
    retention_period = "30d"
    cpu_limit        = "2000m"
    memory_limit     = "4Gi"
    helm_timeout     = 900
  }

  grafana = {
    cpu_arch           = "arm64" # Efficient UI service
    storage_class      = "hostpath"
    enable_persistence = true
    cpu_limit          = "300m"
    memory_limit       = "512Mi"
  }

  consul = {
    cpu_arch      = "amd64" # Service mesh performance
    storage_class = "nfs-csi-safe"
    storage_size  = "10Gi"
    cpu_limit     = "500m"
    memory_limit  = "512Mi"
    helm_timeout  = 600
  }

  vault = {
    cpu_arch      = "amd64" # Security-critical workload
    storage_class = "nfs-csi-safe"
    storage_size  = "10Gi"
    cpu_limit     = "500m"
    memory_limit  = "512Mi"
    helm_timeout  = 600
  }

  loki = {
    cpu_arch         = "amd64" # Log processing performance
    storage_class    = "nfs-csi-safe"
    storage_size     = "20Gi"
    retention_period = "14d"
    cpu_limit        = "1000m"
    memory_limit     = "1Gi"
  }

  promtail = {
    cpu_arch     = "arm64" # Log collection efficiency
    cpu_limit    = "100m"
    memory_limit = "128Mi"
  }

  portainer = {
    cpu_arch      = "arm64" # Management UI
    storage_class = "hostpath"
    storage_size  = "2Gi"
    cpu_limit     = "200m"
    memory_limit  = "256Mi"
  }

  metallb = {
    # Runs on all nodes regardless of architecture
    cpu_limit    = "100m"
    memory_limit = "128Mi"
  }

  nfs_csi = {
    # Runs on all nodes for storage access
    cpu_limit    = "100m"
    memory_limit = "128Mi"
  }

  host_path = {
    # Runs on all nodes for local storage
    storage_class = "hostpath"
  }

  node_feature_discovery = {
    # Hardware detection on all nodes
    cpu_limit    = "50m"
    memory_limit = "64Mi"
  }
}

# Storage Class Overrides for Mixed Cluster
storage_class_override = {
  # Critical data on reliable NFS
  prometheus   = "nfs-csi-safe"
  alertmanager = "nfs-csi-safe"
  consul       = "nfs-csi-safe"
  vault        = "nfs-csi-safe"
  loki         = "nfs-csi-safe"

  # Fast access data on high-performance NFS
  traefik = "nfs-csi-fast"

  # UI data on local storage
  grafana   = "hostpath"
  portainer = "hostpath"
}

# Helm Configuration
default_helm_timeout = 600
default_helm_wait    = true

# Security Configuration
le_email = "admin@mixed.homelab.local"

# Development/Testing
enable_debug_outputs = true
