###########################
#  Main project - Variables #
###########################

# ============================================================================
# CORE CONFIGURATION
# ============================================================================

variable "base_domain" {
  description = "Base domain name (e.g., 'example.com')"
  type        = string
  default     = "local"

  validation {
    condition     = can(regex("^[a-zA-Z0-9]([a-zA-Z0-9\\-]{0,61}[a-zA-Z0-9])?\\.[a-zA-Z]{2,}$|^local$", var.base_domain))
    error_message = "Base domain must be a valid FQDN format (e.g., 'example.com') or 'local'."
  }
}

variable "platform_name" {
  description = "Platform identifier (e.g., 'k3s', 'eks', 'gke', 'aks', 'microk8s')"
  type        = string
  default     = "k3s"

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9\\-]*[a-zA-Z0-9]$|^[a-zA-Z0-9]$", var.platform_name))
    error_message = "Platform name must contain only alphanumeric characters and hyphens."
  }

  validation {
    condition     = contains(["k3s", "k8s", "eks", "gke", "aks", "microk8s", "kubernetes"], var.platform_name)
    error_message = "Platform name must be one of: k3s, k8s, eks, gke, aks, microk8s, kubernetes."
  }
}

# Legacy domain_name variable for backward compatibility
variable "domain_name" {
  description = "DEPRECATED: Use base_domain and platform_name instead. Legacy domain name configuration"
  type        = string
  default     = null
}

variable "cpu_arch" {
  description = "CPU architecture for node selection (leave empty for auto-detection)"
  type        = string
  default     = ""

  validation {
    condition     = var.cpu_arch == "" || contains(["amd64", "arm64"], var.cpu_arch)
    error_message = "CPU architecture must be either 'amd64', 'arm64', or empty for auto-detection."
  }
}

variable "auto_mixed_cluster_mode" {
  description = "Automatically configure services for mixed architecture clusters"
  type        = bool
  default     = true
}

variable "cpu_arch_override" {
  description = "Per-service CPU architecture overrides for mixed clusters"
  type = object({
    traefik                = optional(string)
    metallb                = optional(string)
    nfs_csi                = optional(string)
    host_path              = optional(string)
    prometheus             = optional(string)
    prometheus_crds        = optional(string)
    grafana                = optional(string)
    loki                   = optional(string)
    promtail               = optional(string)
    consul                 = optional(string)
    vault                  = optional(string)
    gatekeeper             = optional(string)
    portainer              = optional(string)
    node_feature_discovery = optional(string)
  })
  default = {}

  validation {
    condition = alltrue([
      for service_name, arch in var.cpu_arch_override :
      arch == null || contains(["amd64", "arm64"], arch)
    ])
    error_message = "CPU architecture overrides must be either 'amd64' or 'arm64'."
  }
}

variable "disable_arch_scheduling" {
  description = "Disable architecture-based scheduling for specific services (useful for development)"
  type = object({
    traefik                = optional(bool, false)
    metallb                = optional(bool, false)
    nfs_csi                = optional(bool, false)
    host_path              = optional(bool, false)
    prometheus             = optional(bool, false)
    prometheus_crds        = optional(bool, false)
    grafana                = optional(bool, false)
    loki                   = optional(bool, false)
    promtail               = optional(bool, false)
    consul                 = optional(bool, false)
    vault                  = optional(bool, false)
    gatekeeper             = optional(bool, false)
    portainer              = optional(bool, false)
    node_feature_discovery = optional(bool, false)
  })
  default = {}
}

# ============================================================================
# SERVICE ENABLEMENT - Modular Service Configuration
# ============================================================================

variable "services" {
  description = "Service enablement configuration - choose your stack components"
  type = object({
    # Core infrastructure services
    traefik   = optional(bool, true)
    metallb   = optional(bool, true)
    nfs_csi   = optional(bool, true)
    host_path = optional(bool, true)

    # Monitoring and observability stack
    prometheus      = optional(bool, true)
    prometheus_crds = optional(bool, true)
    grafana         = optional(bool, true)
    loki            = optional(bool, true)
    promtail        = optional(bool, true)

    # Service mesh and security
    consul     = optional(bool, true)
    vault      = optional(bool, true)
    gatekeeper = optional(bool, false)

    # Management and discovery
    portainer              = optional(bool, true)
    node_feature_discovery = optional(bool, true)
  })
  default = {}
}

# ============================================================================
# STORAGE CONFIGURATION
# ============================================================================

variable "use_nfs_storage" {
  description = "Use NFS storage as primary storage backend"
  type        = bool
  default     = false
}

variable "use_hostpath_storage" {
  description = "Use hostPath storage (takes effect when use_nfs_storage is false)"
  type        = bool
  default     = true
}

variable "nfs_server_address" {
  description = "NFS server IP address for persistent storage"
  type        = string
  default     = "192.168.1.100"

  validation {
    condition     = can(regex("^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$", var.nfs_server_address))
    error_message = "NFS server address must be a valid IPv4 address."
  }
}

variable "nfs_server_path" {
  description = "NFS server path for persistent storage"
  type        = string
  default     = "/mnt/k8s-storage"

  validation {
    condition     = can(regex("^/[a-zA-Z0-9/_-]*$", var.nfs_server_path))
    error_message = "NFS server path must be a valid absolute path."
  }
}

variable "default_storage_class" {
  description = "Default storage class to use when not specified (empty = auto-detection)"
  type        = string
  default     = ""
}

# ============================================================================
# SECURITY AND ACCESS CONFIGURATION
# ============================================================================

variable "traefik_dashboard_password" {
  description = "Custom password for Traefik dashboard (empty = auto-generate)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "grafana_admin_password" {
  description = "Custom password for Grafana admin (empty = auto-generate)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "portainer_admin_password" {
  description = "Custom password for Portainer admin (empty = auto-generate)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "monitoring_admin_password" {
  description = "Custom password for monitoring services (Prometheus/AlertManager) admin (empty = auto-generate)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "le_email" {
  description = "Email address for Let's Encrypt certificate notifications"
  type        = string
  default     = ""

  validation {
    condition     = var.le_email == "" || can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.le_email))
    error_message = "Email must be a valid email address or empty."
  }
}

# ============================================================================
# SERVICE-SPECIFIC OVERRIDES
# ============================================================================

variable "service_overrides" {
  description = "Service-specific configuration overrides for fine-grained control"
  type = object({
    traefik = optional(object({
      # Core configuration
      cpu_arch      = optional(string)
      chart_version = optional(string)
      storage_class = optional(string)
      storage_size  = optional(string)

      # Service-specific settings
      enable_dashboard   = optional(bool)
      dashboard_password = optional(string)
      cert_resolver      = optional(string)

      # Resource limits
      cpu_limit      = optional(string)
      memory_limit   = optional(string)
      cpu_request    = optional(string)
      memory_request = optional(string)

      # Helm deployment options
      helm_timeout          = optional(number)
      helm_wait             = optional(bool)
      helm_wait_for_jobs    = optional(bool)
      helm_disable_webhooks = optional(bool)
      helm_skip_crds        = optional(bool)
      helm_replace          = optional(bool)
      helm_force_update     = optional(bool)
      helm_cleanup_on_fail  = optional(bool)
    }))

    prometheus = optional(object({
      # Core configuration
      cpu_arch      = optional(string)
      chart_version = optional(string)
      storage_class = optional(string)
      storage_size  = optional(string)

      # Service-specific settings
      enable_ingress              = optional(bool)
      enable_alertmanager_ingress = optional(bool)
      retention_period            = optional(string)
      monitoring_admin_password   = optional(string)

      # Resource limits
      cpu_limit      = optional(string)
      memory_limit   = optional(string)
      cpu_request    = optional(string)
      memory_request = optional(string)

      # Helm deployment options
      helm_timeout          = optional(number)
      helm_wait             = optional(bool)
      helm_wait_for_jobs    = optional(bool)
      helm_disable_webhooks = optional(bool)
      helm_skip_crds        = optional(bool)
      helm_replace          = optional(bool)
      helm_force_update     = optional(bool)
      helm_cleanup_on_fail  = optional(bool)
    }))

    grafana = optional(object({
      # Core configuration
      cpu_arch      = optional(string)
      chart_version = optional(string)
      storage_class = optional(string)
      storage_size  = optional(string)

      # Service-specific settings
      enable_persistence = optional(bool)
      node_name          = optional(string)
      admin_user         = optional(string)
      admin_password     = optional(string)

      # Resource limits
      cpu_limit      = optional(string)
      memory_limit   = optional(string)
      cpu_request    = optional(string)
      memory_request = optional(string)

      # Helm deployment options
      helm_timeout          = optional(number)
      helm_wait             = optional(bool)
      helm_wait_for_jobs    = optional(bool)
      helm_disable_webhooks = optional(bool)
      helm_skip_crds        = optional(bool)
      helm_replace          = optional(bool)
      helm_force_update     = optional(bool)
      helm_cleanup_on_fail  = optional(bool)
    }))

    metallb = optional(object({
      # Service-specific settings
      address_pool = optional(string)

      # Resource limits
      cpu_limit      = optional(string)
      memory_limit   = optional(string)
      cpu_request    = optional(string)
      memory_request = optional(string)

      # Helm deployment options
      helm_timeout          = optional(number)
      helm_wait             = optional(bool)
      helm_wait_for_jobs    = optional(bool)
      helm_disable_webhooks = optional(bool)
      helm_skip_crds        = optional(bool)
      helm_replace          = optional(bool)
      helm_force_update     = optional(bool)
      helm_cleanup_on_fail  = optional(bool)
    }))

    vault = optional(object({
      # Core configuration
      cpu_arch      = optional(string)
      chart_version = optional(string)
      storage_class = optional(string)
      storage_size  = optional(string)

      # Resource limits
      cpu_limit      = optional(string)
      memory_limit   = optional(string)
      cpu_request    = optional(string)
      memory_request = optional(string)

      # Helm deployment options
      helm_timeout          = optional(number)
      helm_wait             = optional(bool)
      helm_wait_for_jobs    = optional(bool)
      helm_disable_webhooks = optional(bool)
      helm_skip_crds        = optional(bool)
      helm_replace          = optional(bool)
      helm_force_update     = optional(bool)
      helm_cleanup_on_fail  = optional(bool)
    }))

    consul = optional(object({
      # Core configuration
      cpu_arch      = optional(string)
      chart_version = optional(string)
      storage_class = optional(string)
      storage_size  = optional(string)

      # Resource limits
      cpu_limit      = optional(string)
      memory_limit   = optional(string)
      cpu_request    = optional(string)
      memory_request = optional(string)

      # Helm deployment options
      helm_timeout          = optional(number)
      helm_wait             = optional(bool)
      helm_wait_for_jobs    = optional(bool)
      helm_disable_webhooks = optional(bool)
      helm_skip_crds        = optional(bool)
      helm_replace          = optional(bool)
      helm_force_update     = optional(bool)
      helm_cleanup_on_fail  = optional(bool)
    }))

    portainer = optional(object({
      # Core configuration
      cpu_arch      = optional(string)
      chart_version = optional(string)
      storage_class = optional(string)
      storage_size  = optional(string)

      # Service-specific settings
      admin_password = optional(string)

      # Resource limits
      cpu_limit      = optional(string)
      memory_limit   = optional(string)
      cpu_request    = optional(string)
      memory_request = optional(string)

      # Helm deployment options
      helm_timeout          = optional(number)
      helm_wait             = optional(bool)
      helm_wait_for_jobs    = optional(bool)
      helm_disable_webhooks = optional(bool)
      helm_skip_crds        = optional(bool)
      helm_replace          = optional(bool)
      helm_force_update     = optional(bool)
      helm_cleanup_on_fail  = optional(bool)
    }))

    loki = optional(object({
      # Core configuration
      cpu_arch      = optional(string)
      chart_version = optional(string)
      storage_class = optional(string)
      storage_size  = optional(string)

      # Resource limits
      cpu_limit      = optional(string)
      memory_limit   = optional(string)
      cpu_request    = optional(string)
      memory_request = optional(string)

      # Helm deployment options
      helm_timeout          = optional(number)
      helm_wait             = optional(bool)
      helm_wait_for_jobs    = optional(bool)
      helm_disable_webhooks = optional(bool)
      helm_skip_crds        = optional(bool)
      helm_replace          = optional(bool)
      helm_force_update     = optional(bool)
      helm_cleanup_on_fail  = optional(bool)
    }))

    nfs_csi = optional(object({
      # Helm deployment options
      helm_timeout          = optional(number)
      helm_wait             = optional(bool)
      helm_wait_for_jobs    = optional(bool)
      helm_disable_webhooks = optional(bool)
      helm_skip_crds        = optional(bool)
      helm_replace          = optional(bool)
      helm_force_update     = optional(bool)
      helm_cleanup_on_fail  = optional(bool)
    }))

    host_path = optional(object({
      # Helm deployment options
      helm_timeout          = optional(number)
      helm_wait             = optional(bool)
      helm_wait_for_jobs    = optional(bool)
      helm_disable_webhooks = optional(bool)
      helm_skip_crds        = optional(bool)
      helm_replace          = optional(bool)
      helm_force_update     = optional(bool)
      helm_cleanup_on_fail  = optional(bool)
    }))

    node_feature_discovery = optional(object({
      # Helm deployment options
      helm_timeout          = optional(number)
      helm_wait             = optional(bool)
      helm_wait_for_jobs    = optional(bool)
      helm_disable_webhooks = optional(bool)
      helm_skip_crds        = optional(bool)
      helm_replace          = optional(bool)
      helm_force_update     = optional(bool)
      helm_cleanup_on_fail  = optional(bool)
    }))

    gatekeeper = optional(object({
      # Gatekeeper-specific options
      gatekeeper_version = optional(string)
      # Helm deployment options
      helm_timeout          = optional(number)
      helm_wait             = optional(bool)
      helm_wait_for_jobs    = optional(bool)
      helm_disable_webhooks = optional(bool)
      helm_skip_crds        = optional(bool)
      helm_replace          = optional(bool)
      helm_force_update     = optional(bool)
      helm_cleanup_on_fail  = optional(bool)
    }))

    prometheus_crds = optional(object({
      # Helm deployment options
      helm_timeout          = optional(number)
      helm_wait             = optional(bool)
      helm_wait_for_jobs    = optional(bool)
      helm_disable_webhooks = optional(bool)
      helm_skip_crds        = optional(bool)
      helm_replace          = optional(bool)
      helm_force_update     = optional(bool)
      helm_cleanup_on_fail  = optional(bool)
    }))

    promtail = optional(object({
      # Helm deployment options
      helm_timeout          = optional(number)
      helm_wait             = optional(bool)
      helm_wait_for_jobs    = optional(bool)
      helm_disable_webhooks = optional(bool)
      helm_skip_crds        = optional(bool)
      helm_replace          = optional(bool)
      helm_force_update     = optional(bool)
      helm_cleanup_on_fail  = optional(bool)
    }))
  })
  default = {}

  validation {
    condition = alltrue([
      for service_name, service_config in var.service_overrides :
      service_config == null || (
        try(service_config.cpu_arch, null) == null ||
        contains(["amd64", "arm64"], service_config.cpu_arch)
      )
    ])
    error_message = "CPU architecture in service overrides must be either 'amd64' or 'arm64'."
  }
}

# ============================================================================
# PERFORMANCE AND RESOURCE CONFIGURATION
# ============================================================================

variable "default_helm_timeout" {
  description = "Default timeout for Helm deployments in seconds"
  type        = number
  default     = 600

  validation {
    condition     = var.default_helm_timeout >= 60 && var.default_helm_timeout <= 3600
    error_message = "Helm timeout must be between 60 and 3600 seconds."
  }
}

variable "enable_resource_limits" {
  description = "Enable resource limits for resource-constrained environments"
  type        = bool
  default     = true
}

variable "default_cpu_limit" {
  description = "Default CPU limit for containers when resource limits are enabled"
  type        = string
  default     = "500m"
}

variable "default_memory_limit" {
  description = "Default memory limit for containers when resource limits are enabled"
  type        = string
  default     = "512Mi"
}

# ============================================================================
# NETWORKING CONFIGURATION
# ============================================================================

variable "metallb_address_pool" {
  description = "IP address range for MetalLB load balancer"
  type        = string
  default     = "192.168.1.200-192.168.1.210"

  validation {
    condition     = can(regex("^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)-((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$", var.metallb_address_pool))
    error_message = "MetalLB address pool must be in format 'IP1-IP2' with valid IPv4 addresses."
  }
}

# ============================================================================
# LEGACY COMPATIBILITY VARIABLES (Backward Compatibility)
# ============================================================================

# Individual service enable variables (mapped to services object)
variable "enable_traefik" {
  description = "Enable Traefik ingress controller (DEPRECATED: use services.traefik)"
  type        = bool
  default     = null
}

variable "enable_metallb" {
  description = "Enable MetalLB load balancer (DEPRECATED: use services.metallb)"
  type        = bool
  default     = null
}

variable "enable_nfs_csi" {
  description = "Enable NFS CSI driver (DEPRECATED: use services.nfs_csi)"
  type        = bool
  default     = null
}

variable "enable_host_path" {
  description = "Enable host path CSI driver (DEPRECATED: use services.host_path)"
  type        = bool
  default     = null
}

variable "enable_gatekeeper" {
  description = "Enable Gatekeeper policy engine (DEPRECATED: use services.gatekeeper)"
  type        = bool
  default     = false # Explicitly false for security - enable only when ready
}

variable "enable_node_feature_discovery" {
  description = "Enable Node Feature Discovery (DEPRECATED: use services.node_feature_discovery)"
  type        = bool
  default     = null
}

variable "enable_portainer" {
  description = "Enable Portainer container management (DEPRECATED: use services.portainer)"
  type        = bool
  default     = null
}

variable "enable_prometheus" {
  description = "Enable Prometheus monitoring stack (DEPRECATED: use services.prometheus)"
  type        = bool
  default     = null
}

variable "enable_prometheus_crds" {
  description = "Enable Prometheus CRDs (DEPRECATED: use services.prometheus_crds)"
  type        = bool
  default     = null
}

variable "enable_consul" {
  description = "Enable Consul service mesh (DEPRECATED: use services.consul)"
  type        = bool
  default     = null
}

variable "enable_vault" {
  description = "Enable Vault secrets management (DEPRECATED: use services.vault)"
  type        = bool
  default     = null
}

variable "enable_grafana" {
  description = "Enable standalone Grafana dashboard (DEPRECATED: use services.grafana)"
  type        = bool
  default     = null
}

variable "enable_loki" {
  description = "Enable Loki log aggregation (DEPRECATED: use services.loki)"
  type        = bool
  default     = null
}

variable "enable_promtail" {
  description = "Enable Promtail log collection (DEPRECATED: use services.promtail)"
  type        = bool
  default     = null
}

# Removed: domain_name_legacy - Use base_domain + platform_name instead

# Legacy compatibility variables continued


variable "traefik_cert_resolver" {
  description = "Default certificate resolver for Traefik SSL certificates"
  type        = string
  default     = "wildcard"
}

variable "letsencrypt_email" {
  description = "Email address for Let's Encrypt certificate notifications (DEPRECATED: use le_email)"
  type        = string
  default     = ""
}

variable "grafana_node_name" {
  description = "Specific node name to run Grafana (DEPRECATED: use service_overrides.grafana.node_name)"
  type        = string
  default     = ""
}

variable "enable_grafana_persistence" {
  description = "Enable persistent storage for Grafana (DEPRECATED: use service_overrides.grafana.enable_persistence)"
  type        = bool
  default     = null
}

variable "cert_resolver_override" {
  description = "Override the default cert resolver for specific services"
  type = object({
    traefik      = optional(string)
    prometheus   = optional(string)
    grafana      = optional(string)
    alertmanager = optional(string)
    consul       = optional(string)
    vault        = optional(string)
    portainer    = optional(string)
  })
  default = {}
}

variable "nfs_server" {
  description = "NFS server IP address (DEPRECATED: use nfs_server_address)"
  type        = string
  default     = ""
}

variable "nfs_path" {
  description = "NFS server path (DEPRECATED: use nfs_server_path)"
  type        = string
  default     = ""
}

variable "enable_microk8s_mode" {
  description = "Enable MicroK8s mode"
  type        = bool
  default     = false
}

variable "enable_prometheus_ingress_route" {
  description = "Enable Prometheus ingress route (DEPRECATED: use service_overrides.prometheus.enable_ingress)"
  type        = bool
  default     = null
}

# Removed: enable_longhorn_ingress_route - Longhorn not implemented in this version

variable "storage_class_override" {
  description = "Override the default storage class selection logic"
  type = object({
    prometheus   = optional(string)
    grafana      = optional(string)
    loki         = optional(string)
    alertmanager = optional(string)
    consul       = optional(string)
    vault        = optional(string)
    traefik      = optional(string)
    portainer    = optional(string)
  })
  default = {}
}

# ============================================================================
# HELM CONFIGURATION (Advanced)
# ============================================================================

variable "default_helm_disable_webhooks" {
  description = "Default value for Helm disable webhooks"
  type        = bool
  default     = true # Disabled for compatibility with ARM64 and mixed clusters
}

variable "default_helm_skip_crds" {
  description = "Default value for Helm skip CRDs"
  type        = bool
  default     = false # Keep CRDs for proper functionality
}

variable "default_helm_replace" {
  description = "Default value for Helm replace"
  type        = bool
  default     = false # Disabled to prevent upgrade conflicts
}

variable "default_helm_force_update" {
  description = "Default value for Helm force update"
  type        = bool
  default     = true # Force updates for consistent state
}

variable "default_helm_cleanup_on_fail" {
  description = "Default value for Helm cleanup on fail"
  type        = bool
  default     = true # Clean up failed deployments
}

variable "default_helm_wait" {
  description = "Default value for Helm wait"
  type        = bool
  default     = true # Wait for deployments to be ready
}

variable "default_helm_wait_for_jobs" {
  description = "Default value for Helm wait for jobs"
  type        = bool
  default     = true # Wait for jobs to complete
}

variable "helm_timeouts" {
  description = "Custom timeout values for specific Helm deployments (advanced users only)"
  type = object({
    traefik                = optional(number, 600) # 10 minutes - ingress controller needs time
    metallb                = optional(number, 300) # 5 minutes - load balancer setup
    nfs_csi                = optional(number, 300) # 5 minutes - storage driver setup
    host_path              = optional(number, 180) # 3 minutes - storage driver
    prometheus_stack       = optional(number, 900) # 15 minutes - complex monitoring stack
    prometheus_stack_crds  = optional(number, 300) # 5 minutes - CRD installation
    grafana                = optional(number, 600) # 10 minutes - dashboard setup + persistence
    consul                 = optional(number, 600) # 10 minutes - service mesh setup
    vault                  = optional(number, 600) # 10 minutes - secrets management setup
    portainer              = optional(number, 300) # 5 minutes - container management UI
    gatekeeper             = optional(number, 300) # 5 minutes - policy engine
    node_feature_discovery = optional(number, 180) # 3 minutes - node labeling
    loki                   = optional(number, 300) # 5 minutes - log aggregation setup
    promtail               = optional(number, 180) # 3 minutes - log collection daemonset
  })
  default = {}
}

# ============================================================================
# DEBUG AND DEVELOPMENT
# ============================================================================

variable "enable_debug_outputs" {
  description = "Enable debug outputs for troubleshooting"
  type        = bool
  default     = false
}
