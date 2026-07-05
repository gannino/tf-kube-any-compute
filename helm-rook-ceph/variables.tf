# ============================================================================
# SERVICE OVERRIDES - 5-Level Override Hierarchy
# ============================================================================
# Priority order (later overrides earlier):
#   1. System defaults (hardcoded in locals.tf)
#   2. Service defaults (variable defaults below)
#   3. User variables (passed from root module)
#   4. Service overrides (this variable - fine-grained control)
#   5. Auto-detection (runtime cluster analysis in locals.tf)
#
# Usage example in terraform.tfvars:
#   service_overrides = {
#     cpu_limit = "1000m"
#     enable_dashboard = true
#     csi = {
#       provisioner_replicas = 2
#       rbd_provisioner_cpu_limit = "500m"
#     }
#   }

variable "service_overrides" {
  description = "Fine-grained service configuration overrides (highest priority)"
  type = object({
    # Basic configuration
    name               = optional(string)
    namespace          = optional(string)
    chart_version      = optional(string)
    ceph_image_version = optional(string)

    # Resource configuration
    cpu_limit      = optional(string)
    memory_limit   = optional(string)
    cpu_request    = optional(string)
    memory_request = optional(string)

    # Feature toggles
    enable_ceph_cluster = optional(bool)
    enable_dashboard    = optional(bool)
    enable_ingress      = optional(bool)
    dashboard_ssl       = optional(bool)
    limit_range_enabled = optional(bool)

    # Ceph configuration
    monitor_count        = optional(number)
    csi_kubelet_dir_path = optional(string)

    # CSI configuration
    csi = optional(object({
      provisioner_replicas         = optional(number)
      rbd_provisioner_cpu_limit    = optional(string)
      rbd_provisioner_memory_limit = optional(string)
      rbd_plugin_cpu_limit         = optional(string)
      rbd_plugin_memory_limit      = optional(string)
    }))

    # Ingress configuration
    domain_name           = optional(string)
    traefik_cert_resolver = optional(string)

    # Helm configuration
    helm_timeout = optional(number)

    # Cleanup configuration
    cleanup_stale_data_on_deploy = optional(bool)
    force_namespace_cleanup      = optional(bool)
    cleanup_timeout              = optional(string)
  })
  default = {}
}

# ============================================================================
# BASIC CONFIGURATION
# ============================================================================

variable "name" {
  type        = string
  description = "Helm release name"
  default     = "rook-ceph"
}

variable "namespace" {
  type        = string
  description = "Namespace for Rook Ceph"
  default     = "rook-ceph"
}

variable "chart_name" {
  type        = string
  description = "Helm chart name"
  default     = "rook-ceph"
}

variable "chart_repo" {
  type        = string
  description = "Helm repository URL"
  default     = "https://charts.rook.io/release"
}

variable "chart_version" {
  type        = string
  description = "Helm chart version (use empty string for auto-detection based on architecture)"
  default     = "" # Empty triggers auto-detection in locals.tf
}

variable "cpu_arch" {
  description = "CPU architecture"
  type        = string
  default     = "amd64"
}

variable "disable_arch_scheduling" {
  description = "Disable architecture-based node scheduling"
  type        = bool
  default     = false
}

variable "cpu_limit" {
  description = "CPU limit for containers"
  type        = string
  default     = "500m"
}

variable "memory_limit" {
  description = "Memory limit for containers"
  type        = string
  default     = "512Mi"
}

variable "cpu_request" {
  description = "CPU request for containers"
  type        = string
  default     = "250m"
}

variable "memory_request" {
  description = "Memory request for containers"
  type        = string
  default     = "256Mi"
}

variable "limit_range_enabled" {
  description = "Enable limit range for namespace"
  type        = bool
  default     = true
}

variable "limit_range_container_max_cpu" {
  description = "Maximum CPU limit for containers"
  type        = string
  default     = null
}

variable "limit_range_container_max_memory" {
  description = "Maximum memory limit for containers"
  type        = string
  default     = null
}

variable "limit_range_pvc_max_storage" {
  description = "Maximum storage size for PVCs"
  type        = string
  default     = "100Gi"
}

variable "limit_range_pvc_min_storage" {
  description = "Minimum storage size for PVCs"
  type        = string
  default     = "1Gi"
}

variable "helm_timeout" {
  description = "Timeout for Helm deployment in seconds"
  type        = number
  default     = 600
}

variable "helm_disable_webhooks" {
  description = "Disable webhooks for Helm release"
  type        = bool
  default     = false
}

variable "helm_skip_crds" {
  description = "Skip CRDs for Helm release"
  type        = bool
  default     = false
}

variable "helm_replace" {
  description = "Allow Helm to replace existing resources"
  type        = bool
  default     = false
}

variable "helm_force_update" {
  description = "Force resource updates if needed"
  type        = bool
  default     = false
}

# ============================================================================
# WORKLOAD CONFIGURATION
# ============================================================================

variable "cleanup_image" {
  description = "Container image used for cleanup and storage preparation jobs"
  type        = string
  default     = "busybox:latest"
}

variable "storage_prep_cpu_limit" {
  description = "CPU limit for storage preparation DaemonSet containers"
  type        = string
  default     = "100m"
}

variable "storage_prep_memory_limit" {
  description = "Memory limit for storage preparation DaemonSet containers"
  type        = string
  default     = "64Mi"
}

variable "storage_prep_cpu_request" {
  description = "CPU request for storage preparation DaemonSet containers"
  type        = string
  default     = "50m"
}

variable "storage_prep_memory_request" {
  description = "Memory request for storage preparation DaemonSet containers"
  type        = string
  default     = "32Mi"
}

variable "cleanup_cpu_limit" {
  description = "CPU limit for cleanup Job containers"
  type        = string
  default     = "100m"
}

variable "cleanup_memory_limit" {
  description = "Memory limit for cleanup Job containers"
  type        = string
  default     = "64Mi"
}

variable "cleanup_cpu_request" {
  description = "CPU request for cleanup Job containers"
  type        = string
  default     = "50m"
}

variable "cleanup_memory_request" {
  description = "Memory request for cleanup Job containers"
  type        = string
  default     = "32Mi"
}

variable "helm_cleanup_on_fail" {
  description = "Cleanup resources on failure"
  type        = bool
  default     = true
}

variable "helm_wait" {
  description = "Wait for Helm release to be ready"
  type        = bool
  default     = true
}

variable "helm_wait_for_jobs" {
  description = "Wait for Helm jobs to complete"
  type        = bool
  default     = true
}

variable "enable_ceph_cluster" {
  description = "Deploy CephCluster resource (creates actual Ceph storage cluster)"
  type        = bool
  default     = true
}

variable "enable_dashboard" {
  description = "Enable Ceph Dashboard web interface"
  type        = bool
  default     = true
}

variable "dashboard_ssl" {
  description = "Enable SSL for Ceph Dashboard"
  type        = bool
  default     = false
}

variable "monitor_count" {
  description = "Number of Ceph monitors (must be odd number, typically 1, 3, or 5). For initial bootstrap, use 1, then scale up to 3 or 5 for high availability."
  type        = number
  default     = 3
  validation {
    condition     = var.monitor_count > 0 && var.monitor_count % 2 == 1
    error_message = "Monitor count must be a positive odd number (1, 3, 5, 7, etc.)"
  }
}

variable "ceph_image_version" {
  description = "Ceph image version (must be compatible with Rook operator version). Rook v1.15.x supports Ceph v18.2.4 (reef), which is stable on ARM64. See: https://github.com/rook/rook/releases"
  type        = string
  default     = "v18.2.4"
}

variable "osd_per_node" {
  description = "Number of OSDs to create per node (total OSDs = osd_per_node × number of nodes). For Raspberry Pi clusters, 1 OSD per node recommended due to resource constraints."
  type        = number
  default     = 1
  validation {
    condition     = var.osd_per_node > 0
    error_message = "OSDs per node must be greater than 0"
  }
}

variable "osd_data_size" {
  description = "Storage size for each OSD PVC. Adjust based on available storage. For Raspberry Pi with SD cards, 5-10Gi recommended. For USB/NVMe storage, can be larger."
  type        = string
  default     = "10Gi"
}

variable "storage_class_name" {
  description = "StorageClass for OSD PVCs (must support block mode). Use 'hostpath' for local storage, 'nfs-csi-fast' for network storage (not recommended for production OSDs)."
  type        = string
  default     = "hostpath"
}

# ============================================================================
# STORAGE PATH CONFIGURATION
# ============================================================================

variable "rook_data_dir_host_path" {
  description = "Directory on host where Rook stores data (mon, OSD, etc.)"
  type        = string
  default     = "/opt/rook"
}

variable "storage_prep_host_path" {
  description = "Base host path for local storage provisioner (where OSD PVCs will be created)"
  type        = string
  default     = "/opt/local-path-provisioner"
}

variable "osd_storage_subdir" {
  description = "Subdirectory within storage_prep_host_path for OSD data (relative path)"
  type        = string
  default     = "rook-storage"
}

variable "csi_kubelet_dir_path" {
  description = "Kubelet directory path for CSI drivers (MicroK8s: /var/snap/microk8s/common/var/lib/kubelet, K3s: /var/lib/rancher/k3s/agent, Standard: /var/lib/kubelet)"
  type        = string
  default     = "" # Empty triggers auto-detection in locals.tf
}

variable "enable_ingress" {
  description = "Enable Traefik ingress for Ceph Dashboard"
  type        = bool
  default     = true
}

variable "domain_name" {
  description = "Domain name for ingress"
  type        = string
  default     = "local"
}

variable "traefik_cert_resolver" {
  description = "Traefik certificate resolver"
  type        = string
  default     = "default"
}

variable "traefik_ingress_config" {
  description = "Traefik ingress configuration"
  type        = any
  default     = null
}

variable "rook_csi_provisioner_replicas" {
  description = "Number of CSI provisioner replicas"
  type        = number
  default     = 1
}

variable "rook_csi_rbd_provisioner_cpu_limit" {
  description = "CPU limit for RBD provisioner"
  type        = string
  default     = "200m"
}

variable "rook_csi_rbd_provisioner_memory_limit" {
  description = "Memory limit for RBD provisioner"
  type        = string
  default     = "256Mi"
}

variable "rook_csi_rbd_plugin_cpu_limit" {
  description = "CPU limit for RBD plugin"
  type        = string
  default     = "200m"
}

variable "rook_csi_rbd_plugin_memory_limit" {
  description = "Memory limit for RBD plugin"
  type        = string
  default     = "512Mi"
}

# ============================================================================
# CLEANUP CONFIGURATION
# ============================================================================

variable "cleanup_stale_data_on_deploy" {
  description = "Clean up stale Rook data on host paths before deployment (prevents keyring mismatch on redeployment)"
  type        = bool
  default     = true
}

variable "force_namespace_cleanup" {
  description = "Force cleanup of namespace and Rook-Ceph resources if deletion gets stuck (WARNING: Only use when namespace is stuck in Terminating phase)"
  type        = bool
  default     = false
}

variable "cleanup_timeout" {
  description = "Timeout for namespace cleanup operations (e.g., 5m, 10m, 30s)"
  type        = string
  default     = "5m"

  validation {
    condition     = can(regex("^[0-9]+(s|m|h)$", var.cleanup_timeout))
    error_message = "Cleanup timeout must be in format like '5m', '10m', '30s'."
  }
}

variable "workspace_prefix" {
  description = "Workspace prefix for kubeconfig file selection (e.g., 'prod', 'sit', 'dev'). Matches main provider.tf logic."
  type        = string
  default     = ""
}

variable "ci_mode" {
  description = "Running in CI mode (kubeconfig handled externally)"
  type        = bool
  default     = false
}

variable "kubeconfig_path" {
  description = "Explicit kubeconfig path (overrides automatic detection). Leave empty to use workspace-based or default kubeconfig."
  type        = string
  default     = ""
}
