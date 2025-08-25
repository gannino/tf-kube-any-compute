###########################
#  Main project - Variables #
###########################



# ============================================================================
# VARIABLES IN ALPHABETICAL ORDER
# ============================================================================

variable "auth_override" {
  description = "Override authentication method for specific services (DEPRECATED: use middleware_overrides)"
  type = object({
    alertmanager = optional(string)
    consul       = optional(string)
    grafana      = optional(string)
    portainer    = optional(string)
    prometheus   = optional(string)
    traefik      = optional(string)
    vault        = optional(string)
  })
  default = {}

  validation {
    condition = alltrue([
      for service, auth_method in var.auth_override :
      auth_method == null || (auth_method != null && contains(["basic", "ldap", "default"], auth_method))
    ])
    error_message = "Auth overrides must be 'basic', 'ldap', or 'default'."
  }
}

variable "auto_mixed_cluster_mode" {
  description = "Automatically configure services for mixed architecture clusters"
  type        = bool
  default     = true
}

variable "base_domain" {
  description = "Base domain name (e.g., 'example.com')"
  type        = string
  default     = "local"

  validation {
    condition     = can(regex("^([a-zA-Z0-9]([a-zA-Z0-9\\-]{0,61}[a-zA-Z0-9])?\\.)+[a-zA-Z]{2,}$|^local$", var.base_domain))
    error_message = "Base domain must be a valid FQDN format (e.g., 'example.com', 'sub.example.com') or 'local'."
  }
}

variable "cert_resolver_override" {
  description = "Override the default cert resolver for specific services"
  type = object({
    alertmanager = optional(string)
    consul       = optional(string)
    grafana      = optional(string)
    portainer    = optional(string)
    prometheus   = optional(string)
    traefik      = optional(string)
    vault        = optional(string)
  })
  default = {}
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

variable "cpu_arch_override" {
  description = "Per-service CPU architecture overrides for mixed clusters"
  type = object({
    consul                 = optional(string)
    gatekeeper             = optional(string)
    grafana                = optional(string)
    home_assistant         = optional(string)
    host_path              = optional(string)
    loki                   = optional(string)
    metallb                = optional(string)
    n8n                    = optional(string)
    nfs_csi                = optional(string)
    node_feature_discovery = optional(string)
    node_red               = optional(string)
    openhab                = optional(string)
    portainer              = optional(string)
    prometheus             = optional(string)
    prometheus_crds        = optional(string)
    promtail               = optional(string)
    traefik                = optional(string)
    vault                  = optional(string)
  })
  default = {}
}

variable "default_cpu_limit" {
  description = "Default CPU limit for containers when resource limits are enabled"
  type        = string
  default     = "200m"
}

variable "default_helm_cleanup_on_fail" {
  description = "Default value for Helm cleanup on fail"
  type        = bool
  default     = true
}

variable "default_helm_disable_webhooks" {
  description = "Default value for Helm disable webhooks"
  type        = bool
  default     = true
}

variable "default_helm_force_update" {
  description = "Default value for Helm force update"
  type        = bool
  default     = true
}

variable "default_helm_replace" {
  description = "Default value for Helm replace"
  type        = bool
  default     = false
}

variable "default_helm_skip_crds" {
  description = "Default value for Helm skip CRDs"
  type        = bool
  default     = false
}

variable "default_helm_timeout" {
  description = "Default timeout for Helm deployments in seconds"
  type        = number
  default     = 600

  validation {
    condition     = var.default_helm_timeout >= 60 && var.default_helm_timeout <= 3600
    error_message = "Helm timeout must be between 60 and 3600 seconds."
  }
}

variable "default_helm_wait" {
  description = "Default value for Helm wait"
  type        = bool
  default     = true
}

variable "default_helm_wait_for_jobs" {
  description = "Default value for Helm wait for jobs"
  type        = bool
  default     = true
}

variable "default_memory_limit" {
  description = "Default memory limit for containers when resource limits are enabled"
  type        = string
  default     = "256Mi"
}

variable "default_storage_class" {
  description = "Default storage class to use when not specified (empty = auto-detection)"
  type        = string
  default     = ""
}

variable "disable_arch_scheduling" {
  description = "Disable architecture-based scheduling for specific services (useful for development)"
  type = object({
    consul                 = optional(bool, false)
    gatekeeper             = optional(bool, false)
    grafana                = optional(bool, false)
    home_assistant         = optional(bool, false)
    host_path              = optional(bool, false)
    kube_state_metrics     = optional(bool, false)
    loki                   = optional(bool, false)
    metallb                = optional(bool, false)
    n8n                    = optional(bool, false)
    nfs_csi                = optional(bool, false)
    node_feature_discovery = optional(bool, false)
    node_red               = optional(bool, false)
    openhab                = optional(bool, false)
    portainer              = optional(bool, false)
    prometheus             = optional(bool, false)
    prometheus_crds        = optional(bool, false)
    promtail               = optional(bool, false)
    traefik                = optional(bool, false)
    vault                  = optional(bool, false)
  })
  default = {}
}

variable "domain_name" {
  description = "DEPRECATED: Use base_domain and platform_name instead. Legacy domain name configuration"
  type        = string
  default     = null
}

variable "enable_consul" {
  description = "Enable Consul service mesh (DEPRECATED: use services.consul)"
  type        = bool
  default     = null
}

variable "enable_debug_outputs" {
  description = "Enable debug outputs for troubleshooting"
  type        = bool
  default     = false
}

variable "enable_gatekeeper" {
  description = "Enable Gatekeeper policy engine (DEPRECATED: use services.gatekeeper)"
  type        = bool
  default     = false
}

variable "enable_grafana" {
  description = "Enable standalone Grafana dashboard (DEPRECATED: use services.grafana)"
  type        = bool
  default     = null
}

variable "enable_grafana_persistence" {
  description = "Enable persistent storage for Grafana (DEPRECATED: use service_overrides.grafana.enable_persistence)"
  type        = bool
  default     = null
}

variable "enable_kube_state_metrics" {
  description = "Enable kube-state-metrics for Kubernetes metrics (DEPRECATED: use services.kube_state_metrics)"
  type        = bool
  default     = null
}

variable "enable_host_path" {
  description = "Enable host path CSI driver (DEPRECATED: use services.host_path)"
  type        = bool
  default     = null
}

variable "enable_loki" {
  description = "Enable Loki log aggregation (DEPRECATED: use services.loki)"
  type        = bool
  default     = null
}

variable "enable_metallb" {
  description = "Enable MetalLB load balancer (DEPRECATED: use services.metallb)"
  type        = bool
  default     = null
}

variable "enable_microk8s_mode" {
  description = "Enable MicroK8s mode with smaller resource footprint"
  type        = bool
  default     = true
}

variable "enable_nfs_csi" {
  description = "Enable NFS CSI driver (DEPRECATED: use services.nfs_csi)"
  type        = bool
  default     = null
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

variable "enable_prometheus_ingress_route" {
  description = "Enable Prometheus ingress route (DEPRECATED: use service_overrides.prometheus.enable_ingress)"
  type        = bool
  default     = null
}

variable "enable_promtail" {
  description = "Enable Promtail log collection (DEPRECATED: use services.promtail)"
  type        = bool
  default     = null
}

variable "enable_resource_limits" {
  description = "Enable resource limits for resource-constrained environments"
  type        = bool
  default     = true
}

variable "enable_traefik" {
  description = "Enable Traefik ingress controller (DEPRECATED: use services.traefik)"
  type        = bool
  default     = null
}

variable "enable_vault" {
  description = "Enable Vault secrets management (DEPRECATED: use services.vault)"
  type        = bool
  default     = null
}

variable "grafana_admin_password" {
  description = "Custom password for Grafana admin (empty = auto-generate)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "grafana_node_name" {
  description = "Specific node name to run Grafana (DEPRECATED: use service_overrides.grafana.node_name)"
  type        = string
  default     = ""
}

variable "helm_timeouts" {
  description = "Custom timeout values for specific Helm deployments (advanced users only)"
  type = object({
    consul                 = optional(number, 600) # 10 minutes - service mesh setup
    gatekeeper             = optional(number, 300) # 5 minutes - policy engine
    grafana                = optional(number, 600) # 10 minutes - dashboard setup + persistence
    host_path              = optional(number, 180) # 3 minutes - storage driver
    loki                   = optional(number, 300) # 5 minutes - log aggregation setup
    metallb                = optional(number, 300) # 5 minutes - load balancer setup
    nfs_csi                = optional(number, 300) # 5 minutes - storage driver setup
    node_feature_discovery = optional(number, 180) # 3 minutes - node labeling
    portainer              = optional(number, 300) # 5 minutes - container management UI
    prometheus_stack       = optional(number, 900) # 15 minutes - complex monitoring stack
    prometheus_stack_crds  = optional(number, 300) # 5 minutes - CRD installation
    promtail               = optional(number, 180) # 3 minutes - log collection daemonset
    traefik                = optional(number, 600) # 10 minutes - ingress controller needs time
    vault                  = optional(number, 600) # 10 minutes - secrets management setup
  })
  default = {}
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

variable "letsencrypt_email" {
  description = "Email address for Let's Encrypt certificate notifications (DEPRECATED: use le_email)"
  type        = string
  default     = ""
}

variable "metallb_address_pool" {
  description = "IP address range for MetalLB load balancer"
  type        = string
  default     = "192.168.1.200-192.168.1.210"

  validation {
    condition     = can(regex("^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)-((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$", var.metallb_address_pool))
    error_message = "MetalLB address pool must be in format 'IP1-IP2' with valid IPv4 addresses."
  }
}

variable "middleware_overrides" {
  description = "Per-service middleware selection - choose which middlewares to apply to each service"
  type = object({
    # Master enable/disable switch for all middleware functionality
    enabled = optional(bool, false)

    # Global middleware settings (applied to all services unless overridden)
    all = optional(object({
      enable_rate_limit   = optional(bool, false)
      enable_ip_whitelist = optional(bool, false)
      custom_middlewares  = optional(list(string), [])
    }), {})

    # Per-service middleware overrides
    alertmanager = optional(object({
      disable_auth        = optional(bool, false)
      enable_rate_limit   = optional(bool)
      enable_ip_whitelist = optional(bool)
      custom_middlewares  = optional(list(string), [])
    }), {})

    consul = optional(object({
      enable_rate_limit   = optional(bool)
      enable_ip_whitelist = optional(bool)
      custom_middlewares  = optional(list(string), [])
    }), {})

    grafana = optional(object({
      enable_rate_limit   = optional(bool)
      enable_ip_whitelist = optional(bool)
      custom_middlewares  = optional(list(string), [])
    }), {})

    portainer = optional(object({
      enable_rate_limit   = optional(bool)
      enable_ip_whitelist = optional(bool)
      custom_middlewares  = optional(list(string), [])
    }), {})

    prometheus = optional(object({
      disable_auth        = optional(bool, false)
      enable_rate_limit   = optional(bool)
      enable_ip_whitelist = optional(bool)
      custom_middlewares  = optional(list(string), [])
    }), {})

    traefik = optional(object({
      disable_auth        = optional(bool, false) # Disable auth for unprotected service
      enable_rate_limit   = optional(bool)        # Override global setting
      enable_ip_whitelist = optional(bool)        # Override global setting
      custom_middlewares  = optional(list(string), [])
    }), {})

    vault = optional(object({
      enable_rate_limit   = optional(bool)
      enable_ip_whitelist = optional(bool)
      custom_middlewares  = optional(list(string), [])
    }), {})
  })
  default = {}
}

variable "monitoring_admin_password" {
  description = "Custom password for monitoring services (Prometheus/AlertManager) admin (empty = auto-generate)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "nfs_path" {
  description = "NFS server path (DEPRECATED: use nfs_server_path)"
  type        = string
  default     = ""
}

variable "nfs_server" {
  description = "NFS server IP address (DEPRECATED: use nfs_server_address)"
  type        = string
  default     = ""
}

variable "nfs_server_address" {
  description = "NFS server IP address or hostname for persistent storage"
  type        = string
  default     = "192.168.1.100"

  validation {
    condition     = can(regex("^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$", var.nfs_server_address)) || can(regex("^([a-zA-Z0-9]([a-zA-Z0-9\\-]{0,61}[a-zA-Z0-9])?\\.)*[a-zA-Z0-9]([a-zA-Z0-9\\-]{0,61}[a-zA-Z0-9])?$", var.nfs_server_address))
    error_message = "NFS server address must be a valid IPv4 address or hostname/FQDN."
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

variable "portainer_admin_password" {
  description = "Custom password for Portainer admin (empty = auto-generate)"
  type        = string
  default     = ""
  sensitive   = true
}

# Note: service_overrides is very large, continuing in next part...
variable "service_overrides" {
  description = "Service-specific configuration overrides for fine-grained control"
  type = object({
    consul = optional(object({
      # Core configuration
      cpu_arch      = optional(string)
      chart_version = optional(string)
      storage_class = optional(string)
      storage_size  = optional(string)
      cert_resolver = optional(string)

      # HA configuration
      server_replicas = optional(number)
      client_replicas = optional(number)

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

    gatekeeper = optional(object({
      # Core configuration
      cpu_arch      = optional(string)
      chart_version = optional(string)

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
      cert_resolver = optional(string)

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

    host_path = optional(object({
      # Core configuration
      cpu_arch      = optional(string)
      chart_version = optional(string)

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

    kube_state_metrics = optional(object({
      # Core configuration
      cpu_arch      = optional(string)
      chart_version = optional(string)

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

    metallb = optional(object({
      # Core configuration
      cpu_arch      = optional(string)
      chart_version = optional(string)

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

    nfs_csi = optional(object({
      # Core configuration
      cpu_arch      = optional(string)
      chart_version = optional(string)

      # Service-specific settings
      nfs_server_address = optional(string)
      nfs_server_path    = optional(string)

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

    node_feature_discovery = optional(object({
      # Core configuration
      cpu_arch      = optional(string)
      chart_version = optional(string)

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
      cert_resolver = optional(string)

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

    prometheus = optional(object({
      # Core configuration
      cpu_arch      = optional(string)
      chart_version = optional(string)
      storage_class = optional(string)
      storage_size  = optional(string)
      cert_resolver = optional(string)

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

    prometheus_crds = optional(object({
      # Core configuration
      cpu_arch      = optional(string)
      chart_version = optional(string)

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
      # Core configuration
      cpu_arch      = optional(string)
      chart_version = optional(string)

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

      # Middleware configuration - streamlined structure
      middleware_config = optional(object({
        # Basic Authentication
        basic_auth = optional(object({
          enabled         = optional(bool, false)
          secret_name     = optional(string, "")
          realm           = optional(string, "Authentication Required")
          static_password = optional(string, "")
          username        = optional(string, "admin")
          }), {
          enabled         = false
          secret_name     = ""
          realm           = "Authentication Required"
          static_password = ""
          username        = "admin"
        })

        # LDAP Authentication
        ldap_auth = optional(object({
          enabled       = optional(bool, false)
          method        = optional(string, "forwardauth") # "plugin" or "forwardauth"
          log_level     = optional(string, "INFO")
          url           = optional(string, "")
          port          = optional(number, 389)
          base_dn       = optional(string, "")
          attribute     = optional(string, "uid")
          bind_dn       = optional(string, "")
          bind_password = optional(string, "")
          search_filter = optional(string, "")
          }), {
          enabled       = false
          method        = "forwardauth"
          log_level     = "INFO"
          url           = ""
          port          = 389
          base_dn       = ""
          attribute     = "uid"
          bind_dn       = ""
          bind_password = ""
          search_filter = ""
        })

        # Rate Limiting
        rate_limit = optional(object({
          enabled = optional(bool, false)
          average = optional(number, 100)
          burst   = optional(number, 200)
          }), {
          enabled = false
          average = 100
          burst   = 200
        })

        # IP Whitelist
        ip_whitelist = optional(object({
          enabled       = optional(bool, false)
          source_ranges = optional(list(string), ["127.0.0.1/32"])
          }), {
          enabled       = false
          source_ranges = ["127.0.0.1/32"]
        })

        # Default Authentication (priority: LDAP > Basic)
        default_auth = optional(object({
          enabled       = optional(bool, false)
          ldap_override = optional(bool, false) # Set to true to use LDAP instead of basic
          basic_config = optional(object({
            secret_name     = optional(string, "")
            realm           = optional(string, "Authentication Required")
            static_password = optional(string, "")
            username        = optional(string, "admin")
            }), {
            secret_name     = ""
            realm           = "Authentication Required"
            static_password = ""
            username        = "admin"
          })
          ldap_config = optional(object({
            method        = optional(string, "forwardauth") # "plugin" or "forwardauth"
            log_level     = optional(string, "INFO")
            url           = optional(string, "")
            port          = optional(number, 389)
            base_dn       = optional(string, "")
            attribute     = optional(string, "uid")
            bind_dn       = optional(string, "")
            bind_password = optional(string, "")
            search_filter = optional(string, "")
            }), {
            method        = "forwardauth"
            log_level     = "INFO"
            url           = ""
            port          = 389
            base_dn       = ""
            attribute     = "uid"
            bind_dn       = ""
            bind_password = ""
            search_filter = ""
          })
          }), {
          enabled       = false
          ldap_override = false
          basic_config = {
            secret_name     = ""
            realm           = "Authentication Required"
            static_password = ""
            username        = "admin"
          }
          ldap_config = {
            log_level     = "INFO"
            url           = ""
            port          = 389
            base_dn       = ""
            attribute     = "uid"
            bind_dn       = ""
            bind_password = ""
            search_filter = ""
          }
        })
        }), {
        basic_auth = {
          enabled         = false
          secret_name     = ""
          realm           = "Authentication Required"
          static_password = ""
          username        = "admin"
        }
        ldap_auth = {
          enabled       = false
          method        = "forwardauth"
          log_level     = "INFO"
          url           = ""
          port          = 389
          base_dn       = ""
          attribute     = "uid"
          bind_dn       = ""
          bind_password = ""
          search_filter = ""
        }
        rate_limit = {
          enabled = false
          average = 100
          burst   = 200
        }
        ip_whitelist = {
          enabled       = false
          source_ranges = ["127.0.0.1/32"]
        }
        default_auth = {
          enabled       = false
          ldap_override = false
          basic_config = {
            secret_name     = ""
            realm           = "Authentication Required"
            static_password = ""
            username        = "admin"
          }
          ldap_config = {
            method        = "forwardauth"
            log_level     = "INFO"
            url           = ""
            port          = 389
            base_dn       = ""
            attribute     = "uid"
            bind_dn       = ""
            bind_password = ""
            search_filter = ""
          }
        }
      })

      # Dashboard middleware - use centralized middleware names
      dashboard_middleware = optional(list(string), [])

      # DNS provider configuration
      dns_providers = optional(object({
        primary = optional(object({
          name   = string
          config = optional(map(string), {})
        }))
        additional = optional(list(object({
          name   = string
          config = map(string)
        })), [])
      }))

      dns_challenge_config = optional(object({
        resolvers                 = optional(list(string))
        delay_before_check        = optional(string)
        disable_propagation_check = optional(bool)
        polling_interval          = optional(string)
        propagation_timeout       = optional(string)
        sequence_interval         = optional(string)
        http_timeout              = optional(string)
      }))

      cert_resolvers = optional(object({
        default = optional(object({
          challenge_type = optional(string)
          dns_provider   = optional(string)
        }))
        wildcard = optional(object({
          challenge_type = optional(string)
          dns_provider   = optional(string)
        }))
        custom = optional(map(object({
          challenge_type = string
          dns_provider   = optional(string)
        })), {})
      }))

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
      cert_resolver = optional(string)

      # HA configuration
      ha_replicas = optional(number)

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

    node_red = optional(object({
      # Core configuration
      cpu_arch             = optional(string)
      chart_version        = optional(string)
      storage_class        = optional(string)
      persistent_disk_size = optional(string)
      cert_resolver        = optional(string)

      # Service-specific settings
      enable_persistence = optional(bool)
      palette_packages   = optional(list(string))

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

    n8n = optional(object({
      # Core configuration
      cpu_arch             = optional(string)
      chart_version        = optional(string)
      storage_class        = optional(string)
      persistent_disk_size = optional(string)
      cert_resolver        = optional(string)

      # Service-specific settings
      enable_persistence = optional(bool)
      enable_database    = optional(bool)

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

    home_assistant = optional(object({
      # Core configuration
      cpu_arch             = optional(string)
      chart_version        = optional(string)
      storage_class        = optional(string)
      persistent_disk_size = optional(string)
      cert_resolver        = optional(string)

      # Service-specific settings
      enable_persistence  = optional(bool)
      enable_privileged   = optional(bool)
      enable_host_network = optional(bool)
      enable_ingress      = optional(bool)

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

    openhab = optional(object({
      # Core configuration
      cpu_arch             = optional(string)
      chart_version        = optional(string)
      storage_class        = optional(string)
      persistent_disk_size = optional(string)
      addons_disk_size     = optional(string)
      conf_disk_size       = optional(string)
      cert_resolver        = optional(string)

      # Service-specific settings
      enable_persistence   = optional(bool)
      enable_privileged    = optional(bool)
      enable_host_network  = optional(bool)
      enable_karaf_console = optional(bool)
      enable_ingress       = optional(bool)

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
  })
  default = {}

  validation {
    condition = alltrue([
      for service_name, service_config in var.service_overrides :
      service_config == null || (
        try(service_config.cpu_arch, null) == null ||
        try(service_config.cpu_arch, "") == "" ||
        (try(service_config.cpu_arch, null) != null && try(service_config.cpu_arch, "") != "" && contains(["amd64", "arm64"], try(service_config.cpu_arch, "")))
      )
    ])
    error_message = "CPU architecture in service overrides must be either 'amd64', 'arm64', or empty string for auto-detection."
  }

  validation {
    condition = try(var.service_overrides.traefik.middleware_config.ldap_auth.enabled, false) == false || (
      try(var.service_overrides.traefik.middleware_config.ldap_auth.url, "") != "" &&
      try(var.service_overrides.traefik.middleware_config.ldap_auth.base_dn, "") != ""
    )
    error_message = "When LDAP authentication is enabled, both 'url' and 'base_dn' must be provided."
  }

  validation {
    condition = try(var.service_overrides.traefik.middleware_config.default_auth.enabled, false) == false || (
      try(var.service_overrides.traefik.middleware_config.default_auth.ldap_override, false) == false || (
        try(var.service_overrides.traefik.middleware_config.default_auth.ldap_config.url, "") != "" &&
        try(var.service_overrides.traefik.middleware_config.default_auth.ldap_config.base_dn, "") != ""
      )
    )
    error_message = "When default auth LDAP override is enabled, both 'url' and 'base_dn' must be provided in ldap_config."
  }

  validation {
    condition = alltrue([
      for log_level in [
        try(var.service_overrides.traefik.middleware_config.ldap_auth.log_level, "INFO"),
        try(var.service_overrides.traefik.middleware_config.default_auth.ldap_config.log_level, "INFO")
      ] : contains(["DEBUG", "INFO", "WARN", "ERROR"], log_level)
    ])
    error_message = "LDAP log level must be one of: DEBUG, INFO, WARN, ERROR."
  }

  validation {
    condition = alltrue([
      for method in [
        try(var.service_overrides.traefik.middleware_config.ldap_auth.method, "forwardauth"),
        try(var.service_overrides.traefik.middleware_config.default_auth.ldap_config.method, "forwardauth")
      ] : contains(["plugin", "forwardauth"], method)
    ])
    error_message = "LDAP method must be either 'plugin' or 'forwardauth'."
  }
}

variable "services" {
  description = "Service enablement configuration - choose your stack components"
  type = object({
    # Core infrastructure services
    consul                 = optional(bool, false) # Disabled by default - complex setup
    gatekeeper             = optional(bool, false)
    grafana                = optional(bool, true)
    home_assistant         = optional(bool, false) # Open-source home automation platform
    host_path              = optional(bool, true)
    kube_state_metrics     = optional(bool, true)  # Kubernetes metrics for Prometheus
    loki                   = optional(bool, false) # Disabled by default - resource intensive
    metallb                = optional(bool, true)
    n8n                    = optional(bool, false) # Workflow automation platform
    nfs_csi                = optional(bool, false) # Disabled by default - requires NFS server
    node_feature_discovery = optional(bool, true)
    node_red               = optional(bool, false) # Visual programming for IoT and automation
    openhab                = optional(bool, false) # Vendor-neutral home automation platform
    portainer              = optional(bool, true)
    prometheus             = optional(bool, true)
    prometheus_crds        = optional(bool, true)
    promtail               = optional(bool, false) # Disabled by default - typically used with Loki, but can operate independently as a log shipper
    traefik                = optional(bool, true)
    vault                  = optional(bool, false) # Disabled by default - requires manual unsealing
  })
  default = {}
}

variable "storage_class_override" {
  description = "Override storage class for services (DEPRECATED: use service_overrides.{service}.storage_class)"
  type = object({
    alertmanager = optional(string)
    consul       = optional(string)
    grafana      = optional(string)
    loki         = optional(string)
    portainer    = optional(string)
    prometheus   = optional(string)
    traefik      = optional(string)
    vault        = optional(string)
  })
  default = {}
}

variable "system_defaults" {
  description = "System-wide default values for consistent configuration"
  type = object({
    # Network defaults
    nfs_server_address   = optional(string, "192.168.1.100")
    nfs_server_path      = optional(string, "/mnt/k8s-storage")
    metallb_address_pool = optional(string, "192.168.1.200-192.168.1.210")

    # Resource defaults
    cpu_limit_default      = optional(string, "200m")
    memory_limit_default   = optional(string, "256Mi")
    cpu_request_default    = optional(string, "100m")
    memory_request_default = optional(string, "128Mi")

    # Resource defaults for high-performance services
    cpu_limit_high      = optional(string, "1000m")
    memory_limit_high   = optional(string, "2Gi")
    cpu_request_high    = optional(string, "500m")
    memory_request_high = optional(string, "1Gi")

    # Resource defaults for lightweight services
    cpu_limit_light      = optional(string, "100m")
    memory_limit_light   = optional(string, "64Mi")
    cpu_request_light    = optional(string, "25m")
    memory_request_light = optional(string, "32Mi")

    # Storage size defaults
    storage_size_small  = optional(string, "1Gi")
    storage_size_medium = optional(string, "2Gi")
    storage_size_large  = optional(string, "4Gi")
    storage_size_xlarge = optional(string, "8Gi")

    # MicroK8s optimized defaults
    microk8s_cpu_limit      = optional(string, "200m")
    microk8s_memory_limit   = optional(string, "256Mi")
    microk8s_storage_small  = optional(string, "1Gi")
    microk8s_storage_medium = optional(string, "2Gi")
    microk8s_storage_large  = optional(string, "4Gi")

    # Helm timeout defaults
    helm_timeout_short  = optional(number, 180)
    helm_timeout_medium = optional(number, 300)
    helm_timeout_long   = optional(number, 600)
    helm_timeout_xllong = optional(number, 900)

    # Authentication defaults
    ldap_port_default  = optional(number, 389)
    rate_limit_average = optional(number, 100)
    rate_limit_burst   = optional(number, 200)

    # Service replica defaults
    ha_replicas_default = optional(number, 2)
    ha_replicas_high    = optional(number, 3)
  })
  default = {}
}

variable "traefik_cert_resolver" {
  description = "Default certificate resolver for Traefik SSL certificates"
  type        = string
  default     = "wildcard"

  validation {
    condition = contains([
      "default", "wildcard", "letsencrypt", "letsencrypt-staging",
      "hurricane", "cloudflare", "route53", "digitalocean", "gandi",
      "namecheap", "godaddy", "ovh", "linode", "vultr", "hetzner"
    ], var.traefik_cert_resolver)
    error_message = "Certificate resolver must be a valid resolver name (default, wildcard, letsencrypt, letsencrypt-staging, or a DNS provider name)."
  }
}

variable "use_hostpath_storage" {
  description = "Use hostPath storage (takes effect when use_nfs_storage is false)"
  type        = bool
  default     = true
}

variable "use_nfs_storage" {
  description = "Use NFS storage as primary storage backend"
  type        = bool
  default     = false
}
