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
    authelia     = optional(string)
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
    authelia               = optional(string)
    consul                 = optional(string)
    gatekeeper             = optional(string)
    grafana                = optional(string)
    headlamp               = optional(string)
    home_assistant         = optional(string)
    homebridge             = optional(string)
    host_path              = optional(string)
    kubevirt               = optional(string)
    loki                   = optional(string)
    longhorn               = optional(string)
    metallb                = optional(string)
    metrics_server         = optional(string)
    n8n                    = optional(string)
    nfs_csi                = optional(string)
    node_feature_discovery = optional(string)
    node_red               = optional(string)
    openhab                = optional(string)
    portainer              = optional(string)
    prometheus             = optional(string)
    prometheus_crds        = optional(string)
    promtail               = optional(string)
    rook_ceph              = optional(string)
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
    authelia               = optional(bool, false)
    consul                 = optional(bool, false)
    gatekeeper             = optional(bool, false)
    grafana                = optional(bool, false)
    headlamp               = optional(bool, false)
    home_assistant         = optional(bool, false)
    homebridge             = optional(bool, false)
    host_path              = optional(bool, false)
    kube_state_metrics     = optional(bool, false)
    kubevirt               = optional(bool, false)
    loki                   = optional(bool, false)
    longhorn               = optional(bool, false)
    metallb                = optional(bool, false)
    metrics_server         = optional(bool, false)
    n8n                    = optional(bool, false)
    nfs_csi                = optional(bool, false)
    node_feature_discovery = optional(bool, false)
    node_red               = optional(bool, false)
    openhab                = optional(bool, false)
    portainer              = optional(bool, false)
    prometheus             = optional(bool, false)
    prometheus_crds        = optional(bool, false)
    promtail               = optional(bool, false)
    redis                  = optional(bool, false)
    rook_ceph              = optional(bool, false)
    s3_csi                 = optional(bool, false) # Disabled by default - requires S3 credentials
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
    authelia               = optional(number, 600) # 10 minutes - authentication server setup
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

variable "longhorn_backup_target" {
  description = "Longhorn backup target (NFS or S3) - e.g., 'nfs://192.168.1.100:/path' or 's3://bucket-name@region'"
  type        = string
  default     = ""
}

variable "longhorn_backup_target_credential_secret" {
  description = "Kubernetes secret name for Longhorn backup target credentials"
  type        = string
  default     = ""
}

variable "longhorn_default_data_path" {
  description = "Default data path for Longhorn volumes on nodes"
  type        = string
  default     = "/opt/longhorn"

  validation {
    condition     = can(regex("^(/[^/ ]*)+/?$", var.longhorn_default_data_path))
    error_message = "Data path must be a valid absolute path (starting with /)."
  }
}

variable "longhorn_replica_count" {
  description = "Default replica count for Longhorn volumes"
  type        = number
  default     = 3

  validation {
    condition     = var.longhorn_replica_count >= 1 && var.longhorn_replica_count <= 10
    error_message = "Replica count must be between 1 and 10."
  }
}

variable "longhorn_set_as_default_storage_class" {
  description = "Set Longhorn as the default Kubernetes storage class"
  type        = bool
  default     = true
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

variable "nfs_fs_group" {
  description = "File system group ID for NFS storage compatibility"
  type        = number
  default     = 1000
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
    authelia = optional(object({
      # Core configuration
      cpu_arch               = optional(string)
      chart_version          = optional(string)
      storage_class          = optional(string)
      storage_size           = optional(string)
      cert_resolver          = optional(string)
      nfs_storage_class_type = optional(string, "reliable")

      # Authentication backends
      default_policy = optional(string, "one_factor")
      ldap_enabled   = optional(bool, false)
      oidc_enabled   = optional(bool, false)
      totp_enabled   = optional(bool, true)
      duo_enabled    = optional(bool, false)

      # LDAP configuration
      ldap_url                = optional(string)
      ldap_base_dn            = optional(string)
      ldap_bind_dn            = optional(string)
      ldap_bind_password      = optional(string)
      ldap_user_filter        = optional(string)
      ldap_group_filter       = optional(string)
      ldap_username_attribute = optional(string)

      # OIDC configuration
      oidc_client_id     = optional(string)
      oidc_client_secret = optional(string)

      # Redis configuration (for HA)
      redis_enabled          = optional(bool, false)
      redis_address          = optional(string)
      redis_module_reference = optional(string)
      replica_count          = optional(number, 1)

      # Duo Security configuration
      duo_api_hostname    = optional(string)
      duo_integration_key = optional(string)
      duo_secret_key      = optional(string)

      # OIDC provider configuration (for Headlamp, Grafana, etc.)
      oidc_clients = optional(map(object({
        client_id            = string
        client_secret        = string
        redirect_uris        = list(string)
        authorization_policy = optional(string, "two_factor")
        scopes               = optional(list(string), ["openid", "profile", "email", "groups"])
      })))

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
      cpu_arch               = optional(string)
      chart_version          = optional(string)
      storage_class          = optional(string)
      storage_size           = optional(string)
      cert_resolver          = optional(string)
      nfs_storage_class_type = optional(string, "reliable")

      # HA configuration
      server_replicas = optional(number)
      client_replicas = optional(number)

      # Monitoring
      enable_servicemonitor = optional(bool)

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
      cpu_arch               = optional(string)
      chart_version          = optional(string)
      storage_class          = optional(string)
      storage_size           = optional(string)
      cert_resolver          = optional(string)
      nfs_storage_class_type = optional(string, "reliable")

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

    headlamp = optional(object({
      # Core configuration
      cpu_arch               = optional(string)
      chart_version          = optional(string)
      storage_class          = optional(string)
      storage_size           = optional(string)
      nfs_storage_class_type = optional(string, "reliable")

      # Service-specific settings
      enable_persistence = optional(bool)
      enabled_plugins    = optional(list(string), [])

      # OIDC authentication configuration
      oidc_config = optional(object({
        enabled          = optional(bool, false)
        issuer_url       = optional(string)
        client_id        = optional(string)
        client_secret    = optional(string)
        scopes           = optional(string, "openid,profile,email")
        use_access_token = optional(bool, false)
      }), {})

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
      cpu_arch               = optional(string)
      chart_version          = optional(string)
      storage_class          = optional(string)
      storage_size           = optional(string)
      nfs_storage_class_type = optional(string, "reliable")

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

    longhorn = optional(object({
      # Core configuration
      cpu_arch                     = optional(string)
      chart_version                = optional(string)
      set_as_default_storage_class = optional(bool)
      replica_count                = optional(number)

      # Backup configuration
      backup_target            = optional(string)
      backup_credential_secret = optional(string)
      default_data_path        = optional(string)
      disable_arch_scheduling  = optional(bool)

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
      cpu_arch               = optional(string)
      chart_version          = optional(string)
      storage_class          = optional(string)
      storage_size           = optional(string)
      cert_resolver          = optional(string)
      nfs_storage_class_type = optional(string, "reliable")

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
      cpu_arch               = optional(string)
      chart_version          = optional(string)
      storage_class          = optional(string)
      storage_size           = optional(string)
      cert_resolver          = optional(string)
      nfs_storage_class_type = optional(string, "reliable")

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

    redis = optional(object({
      # Core configuration
      cpu_arch      = optional(string)
      chart_version = optional(string)

      # Storage configuration
      storage_class      = optional(string)
      storage_size       = optional(string)
      enable_persistence = optional(bool)

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

    rook_ceph = optional(object({
      # Core configuration
      cpu_arch      = optional(string)
      chart_version = optional(string)

      # Cluster and dashboard configuration
      enable_ceph_cluster = optional(bool)
      enable_dashboard    = optional(bool)
      dashboard_ssl       = optional(bool)
      monitor_count       = optional(number)
      enable_ingress      = optional(bool)
      cert_resolver       = optional(string)

      # OSD storage configuration (PVC-based)
      osd_per_node       = optional(number)
      osd_data_size      = optional(string)
      storage_class_name = optional(string)

      # Storage path configuration
      rook_data_dir_host_path = optional(string)
      storage_prep_host_path  = optional(string)
      osd_storage_subdir      = optional(string)

      # Workload configuration
      cleanup_image               = optional(string)
      storage_prep_cpu_limit      = optional(string)
      storage_prep_memory_limit   = optional(string)
      storage_prep_cpu_request    = optional(string)
      storage_prep_memory_request = optional(string)
      cleanup_cpu_limit           = optional(string)
      cleanup_memory_limit        = optional(string)
      cleanup_cpu_request         = optional(string)
      cleanup_memory_request      = optional(string)

      # Resource limits
      cpu_limit      = optional(string)
      memory_limit   = optional(string)
      cpu_request    = optional(string)
      memory_request = optional(string)

      # CSI configuration
      csi_kubelet_dir_path = optional(string)

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

    s3_csi = optional(object({
      # Core configuration
      cpu_arch      = optional(string)
      chart_version = optional(string)

      # S3 credentials (required)
      s3_endpoint          = optional(string)
      s3_access_key_id     = optional(string)
      s3_secret_access_key = optional(string)
      s3_bucket            = optional(string)
      s3_region            = optional(string)

      # Mounter configuration
      mounter         = optional(string)
      mounter_options = optional(string)

      # Storage class configuration
      storage_class_name           = optional(string)
      set_as_default_storage_class = optional(bool)
      reclaim_policy               = optional(string)
      volume_binding_mode          = optional(string)
      allow_volume_expansion       = optional(bool)

      # Secret management
      secret_name   = optional(string)
      create_secret = optional(bool)

      # Resource limits
      cpu_limit      = optional(string)
      memory_limit   = optional(string)
      cpu_request    = optional(string)
      memory_request = optional(string)

      # Limit range configuration
      limit_range_enabled              = optional(bool)
      limit_range_container_max_cpu    = optional(string)
      limit_range_container_max_memory = optional(string)
      limit_range_pvc_max_storage      = optional(string)
      limit_range_pvc_min_storage      = optional(string)

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
      enable_dashboard        = optional(bool)
      dashboard_password      = optional(string)
      cert_resolver           = optional(string)
      enable_metrics          = optional(bool)
      enable_tracing          = optional(bool)
      tracing_backend         = optional(string)
      http_port               = optional(number)
      https_port              = optional(number)
      dashboard_port          = optional(number)
      metrics_port            = optional(number)
      deployment_wait_timeout = optional(number)

      # Monitoring
      enable_servicemonitor = optional(bool)

      # Middleware configuration
      middleware_config = optional(object({
        # Basic Authentication
        basic_auth = optional(object({
          enabled         = optional(bool, false)
          secret_name     = optional(string, "")
          realm           = optional(string, "Authentication Required")
          static_password = optional(string, "")
          username        = optional(string, "admin")
        }), {})

        # LDAP Authentication
        ldap_auth = optional(object({
          enabled       = optional(bool, false)
          method        = optional(string, "forwardauth")
          log_level     = optional(string, "INFO")
          url           = optional(string, "")
          port          = optional(number, 389)
          base_dn       = optional(string, "")
          attribute     = optional(string, "uid")
          bind_dn       = optional(string, "")
          bind_password = optional(string, "")
          search_filter = optional(string, "")
        }), {})

        # Rate Limiting
        rate_limit = optional(object({
          enabled = optional(bool, false)
          average = optional(number, 100)
          burst   = optional(number, 200)
        }), {})

        # IP Whitelist
        ip_whitelist = optional(object({
          enabled       = optional(bool, false)
          source_ranges = optional(list(string), ["127.0.0.1/32"])
        }), {})

        # Default Authentication
        default_auth = optional(object({
          enabled       = optional(bool, false)
          ldap_override = optional(bool, false)
          basic_config = optional(object({
            secret_name     = optional(string, "")
            realm           = optional(string, "Authentication Required")
            static_password = optional(string, "")
            username        = optional(string, "admin")
          }), {})
          ldap_config = optional(object({
            method        = optional(string, "forwardauth")
            log_level     = optional(string, "INFO")
            url           = optional(string, "")
            port          = optional(number, 389)
            base_dn       = optional(string, "")
            attribute     = optional(string, "uid")
            bind_dn       = optional(string, "")
            bind_password = optional(string, "")
            search_filter = optional(string, "")
          }), {})
        }), {})
      }), {})

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
      cpu_arch               = optional(string)
      chart_version          = optional(string)
      storage_class          = optional(string)
      storage_size           = optional(string)
      cert_resolver          = optional(string)
      nfs_storage_class_type = optional(string, "reliable")

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
      cpu_arch               = optional(string)
      chart_version          = optional(string)
      storage_class          = optional(string)
      persistent_disk_size   = optional(string)
      cert_resolver          = optional(string)
      nfs_storage_class_type = optional(string, "reliable")

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
      cpu_arch               = optional(string)
      chart_version          = optional(string)
      storage_class          = optional(string)
      persistent_disk_size   = optional(string)
      cert_resolver          = optional(string)
      nfs_storage_class_type = optional(string, "reliable")

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
      cpu_arch               = optional(string)
      chart_version          = optional(string)
      storage_class          = optional(string)
      persistent_disk_size   = optional(string)
      cert_resolver          = optional(string)
      nfs_storage_class_type = optional(string, "reliable")

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
      cpu_arch               = optional(string)
      chart_version          = optional(string)
      storage_class          = optional(string)
      persistent_disk_size   = optional(string)
      addons_disk_size       = optional(string)
      conf_disk_size         = optional(string)
      cert_resolver          = optional(string)
      nfs_storage_class_type = optional(string, "reliable")

      # Service-specific settings
      enable_persistence      = optional(bool)
      enable_privileged       = optional(bool)
      enable_host_network     = optional(bool)
      enable_karaf_console    = optional(bool)
      enable_ingress          = optional(bool)
      deployment_wait_timeout = optional(number)

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

    homebridge = optional(object({
      # Core configuration
      cpu_arch               = optional(string)
      chart_version          = optional(string)
      storage_class          = optional(string)
      persistent_disk_size   = optional(string)
      cert_resolver          = optional(string)
      nfs_storage_class_type = optional(string, "reliable")

      # Service-specific settings
      enable_persistence  = optional(bool)
      enable_host_network = optional(bool)
      enable_ingress      = optional(bool)
      plugins             = optional(list(string))

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

    kubevirt = optional(object({
      # Core configuration
      cpu_arch      = optional(string)
      chart_version = optional(string)
      cdi_version   = optional(string)

      # Feature configuration
      enable_emulation      = optional(bool)
      enable_servicemonitor = optional(bool)

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
    authelia               = optional(bool, false) # Authentication and authorization server (SSO/2FA)
    consul                 = optional(bool, false) # Disabled by default - complex setup
    gatekeeper             = optional(bool, false)
    grafana                = optional(bool, true)
    headlamp               = optional(bool, false) # Kubernetes web UI (modern alternative to dashboard)
    home_assistant         = optional(bool, false) # Open-source home automation platform
    homebridge             = optional(bool, false) # Apple HomeKit bridge for smart home devices
    host_path              = optional(bool, true)
    kube_state_metrics     = optional(bool, true)  # Kubernetes metrics for Prometheus
    kubevirt               = optional(bool, false) # Virtual machine management
    loki                   = optional(bool, false) # Disabled by default - resource intensive
    longhorn               = optional(bool, false) # Disabled by default - requires open-iscsi on nodes
    metallb                = optional(bool, true)
    metrics_server         = optional(bool, true)  # Kubernetes metrics API (kubectl top)
    n8n                    = optional(bool, false) # Workflow automation platform
    nfs_csi                = optional(bool, false) # Disabled by default - requires NFS server
    node_feature_discovery = optional(bool, true)
    node_red               = optional(bool, false) # Visual programming for IoT and automation
    openhab                = optional(bool, false) # Vendor-neutral home automation platform
    portainer              = optional(bool, true)
    prometheus             = optional(bool, true)
    prometheus_crds        = optional(bool, true)
    promtail               = optional(bool, false) # Disabled by default - typically used with Loki, but can operate independently as a log shipper
    redis                  = optional(bool, false) # In-memory data structure store (caching, sessions)
    rook_ceph              = optional(bool, false) # Disabled by default - requires block devices
    s3_csi                 = optional(bool, false) # Disabled by default - requires S3 credentials
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

variable "nfs_storage_class_config" {
  description = "NFS storage class configuration templates for different deployment types"
  type = object({
    # Default NFS storage class configuration
    default = optional(object({
      mount_options = optional(list(string), [
        "hard",
        "retrans=5",
        "rsize=65536",
        "sync",
        "timeo=900",
        "vers=4.1",
        "wsize=65536"
      ])
      reclaim_policy = optional(string, "Retain")
      access_modes   = optional(list(string), ["ReadWriteMany"])
    }), {})

    # High-performance NFS configuration
    performance = optional(object({
      mount_options = optional(list(string), [
        "hard",
        "retrans=3",
        "rsize=1048576",
        "async",
        "timeo=600",
        "vers=4.1",
        "wsize=1048576",
        "proto=tcp"
      ])
      reclaim_policy = optional(string, "Retain")
      access_modes   = optional(list(string), ["ReadWriteMany"])
    }), {})

    # Reliability-focused NFS configuration
    reliable = optional(object({
      mount_options = optional(list(string), [
        "hard",
        "retrans=10",
        "rsize=32768",
        "sync",
        "timeo=1200",
        "vers=4.1",
        "wsize=32768",
        "intr"
      ])
      reclaim_policy = optional(string, "Retain")
      access_modes   = optional(list(string), ["ReadWriteMany"])
    }), {})

    # Low-latency NFS configuration
    low_latency = optional(object({
      mount_options = optional(list(string), [
        "hard",
        "retrans=2",
        "rsize=65536",
        "async",
        "timeo=300",
        "vers=4.1",
        "wsize=65536",
        "proto=tcp",
        "noatime"
      ])
      reclaim_policy = optional(string, "Delete")
      access_modes   = optional(list(string), ["ReadWriteMany"])
    }), {})
  })
  default = {}
}

variable "enable_coredns_hpa" {
  description = "Enable CoreDNS HorizontalPodAutoscaler to prevent scaling to 0 replicas"
  type        = bool
  default     = false
}

variable "coredns_min_replicas" {
  description = "Minimum number of CoreDNS replicas (prevents DNS outages)"
  type        = number
  default     = 2

  validation {
    condition     = var.coredns_min_replicas >= 1 && var.coredns_min_replicas <= 10
    error_message = "CoreDNS minimum replicas must be between 1 and 10."
  }
}

variable "coredns_max_replicas" {
  description = "Maximum number of CoreDNS replicas"
  type        = number
  default     = 5

  validation {
    condition     = var.coredns_max_replicas >= var.coredns_min_replicas && var.coredns_max_replicas <= 20
    error_message = "CoreDNS maximum replicas must be >= minimum replicas and <= 20."
  }
}

variable "coredns_cpu_target" {
  description = "CPU utilization target for CoreDNS autoscaling"
  type        = number
  default     = 70

  validation {
    condition     = var.coredns_cpu_target >= 10 && var.coredns_cpu_target <= 95
    error_message = "CoreDNS CPU target must be between 10 and 95 percent."
  }
}

variable "coredns_memory_target" {
  description = "Memory utilization target for CoreDNS autoscaling"
  type        = number
  default     = 80

  validation {
    condition     = var.coredns_memory_target >= 10 && var.coredns_memory_target <= 95
    error_message = "CoreDNS memory target must be between 10 and 95 percent."
  }
}

# ============================================================================
# WORKSPACE-AWARE KUBECONFIG CONFIGURATION
# ============================================================================

variable "workspace_prefix" {
  description = "Workspace prefix for kubeconfig file selection (e.g., 'prod' uses ~/.kube/prod-config). Also used for namespacing."
  type        = string
  default     = ""

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", var.workspace_prefix)) || var.workspace_prefix == ""
    error_message = "Workspace prefix must be a valid Kubernetes resource name or empty."
  }
}

variable "ci_mode" {
  description = "Running in CI mode (kubeconfig handled externally via KUBECONFIG env var instead of workspace-based detection)"
  type        = bool
  default     = false
}

variable "kubeconfig_path" {
  description = "Explicit kubeconfig path (overrides automatic workspace-based detection). Use null for default detection."
  type        = string
  default     = ""
}
