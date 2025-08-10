# ============================================================================
# TERRAFORM KUBERNETES INFRASTRUCTURE - OUTPUT DEFINITIONS
# ============================================================================

# Architecture detection outputs for debugging and cluster analysis
output "detected_architecture" {
  description = "Auto-detected CPU architecture and cluster analysis"
  value       = local.cluster_architecture_info
}

# Service enablement summary - which services are actually deployed
output "enabled_services" {
  description = "Summary of enabled services and their status"
  value = {
    summary = {
      enabled_count   = length([for k, v in local.services_enabled : k if v])
      enabled_list    = [for k, v in local.services_enabled : k if v]
      total_available = length(local.services_enabled)
    }
    services = local.services_enabled
  }
}

# Consolidated module outputs - detailed information about each deployed service
output "service_outputs" {
  description = "Detailed outputs from all deployed services"
  sensitive   = true
  value = {
    traefik = {
      enabled = local.services_enabled.traefik
      outputs = local.services_enabled.traefik ? try(module.traefik[0], null) : null
      config  = local.services_enabled.traefik ? local.service_configs.traefik : null
    }

    metallb = {
      enabled = local.services_enabled.metallb
      outputs = local.services_enabled.metallb ? try(module.metallb[0], null) : null
      config  = local.services_enabled.metallb ? { address_pool = local.service_configs.metallb.address_pool } : null
    }

    nfs_csi = {
      enabled = local.services_enabled.nfs_csi
      outputs = local.services_enabled.nfs_csi ? try(module.nfs_csi[0], null) : null
      config = local.services_enabled.nfs_csi ? {
        nfs_server = local.nfs_server
        nfs_path   = local.nfs_path
        is_default = var.use_nfs_storage
      } : null
    }

    host_path = {
      enabled = local.services_enabled.host_path
      outputs = local.services_enabled.host_path ? try(module.host_path[0], null) : null
      config = local.services_enabled.host_path ? {
        is_default = !var.use_nfs_storage || !local.services_enabled.nfs_csi
      } : null
    }

    gatekeeper = {
      enabled = local.services_enabled.gatekeeper
      outputs = local.services_enabled.gatekeeper ? try(module.gatekeeper[0], null) : null
    }

    node_feature_discovery = {
      enabled = local.services_enabled.node_feature_discovery
      outputs = local.services_enabled.node_feature_discovery ? try(module.node_feature_discovery[0], null) : null
    }

    portainer = {
      enabled = local.services_enabled.portainer
      outputs = local.services_enabled.portainer ? try(module.portainer[0], null) : null
      config  = local.services_enabled.portainer ? local.service_configs.portainer : null
    }

    prometheus = {
      enabled = local.services_enabled.prometheus
      outputs = local.services_enabled.prometheus ? try(module.prometheus[0], null) : null
      config  = local.services_enabled.prometheus ? local.service_configs.prometheus : null
    }

    prometheus_crds = {
      enabled = local.services_enabled.prometheus_crds
      outputs = local.services_enabled.prometheus_crds ? try(module.prometheus_crds[0], null) : null
    }

    grafana = {
      enabled = local.services_enabled.grafana
      outputs = local.services_enabled.grafana ? try(module.grafana[0], null) : null
      config  = local.services_enabled.grafana ? local.service_configs.grafana : null
    }

    loki = {
      enabled = local.services_enabled.loki
      outputs = local.services_enabled.loki ? try(module.loki[0], null) : null
      config  = local.services_enabled.loki ? local.service_configs.loki : null
    }

    promtail = {
      enabled = local.services_enabled.promtail && local.services_enabled.loki
      outputs = (local.services_enabled.promtail && local.services_enabled.loki) ? try(module.promtail[0], null) : null
    }

    consul = {
      enabled = local.services_enabled.consul
      outputs = local.services_enabled.consul ? try(module.consul[0], null) : null
      config  = local.services_enabled.consul ? local.service_configs.consul : null
    }

    vault = {
      enabled = local.services_enabled.vault
      outputs = local.services_enabled.vault ? try(module.vault[0], null) : null
      config  = local.services_enabled.vault ? local.service_configs.vault : null
    }
  }
}

# Mixed cluster strategy and configuration recommendations
output "mixed_cluster_strategy" {
  description = "Strategy and recommendations for mixed architecture clusters"
  value = {
    is_mixed_cluster          = local.is_mixed_cluster
    recommended_approach      = local.is_mixed_cluster ? "Use service_overrides for service-specific placement" : "Single architecture detected"
    auto_mode_enabled         = var.auto_mixed_cluster_mode
    disable_arch_scheduling   = local.is_mixed_cluster ? local.final_disable_arch_scheduling : {}
    architecture_distribution = local.arch_counts
  }
}

# Cluster and infrastructure information
output "cluster_info" {
  description = "Cluster information and configuration summary"
  value = {
    workspace             = terraform.workspace
    domain                = local.domain
    k8s_distribution      = local.k8s_distribution
    primary_storage_class = local.primary_storage_class
    storage_strategy = {
      use_nfs_storage      = var.use_nfs_storage
      use_hostpath_storage = var.use_hostpath_storage
      nfs_server           = local.nfs_server
      nfs_path             = local.nfs_path
    }
    resource_limits_enabled = var.enable_resource_limits
  }
}

# Storage configuration and recommendations
output "storage_configuration" {
  description = "Storage configuration details and available storage classes"
  value = {
    primary_storage_class     = local.primary_storage_class
    available_storage_classes = local.storage_classes
    storage_sizes             = local.storage_sizes
    nfs_configuration = {
      enabled = var.use_nfs_storage && local.services_enabled.nfs_csi
      server  = local.nfs_server
      path    = local.nfs_path
    }
    hostpath_configuration = {
      enabled    = local.services_enabled.host_path
      is_default = !var.use_nfs_storage || !local.services_enabled.nfs_csi
    }
  }
}

# Service configuration overrides that were applied
output "applied_service_configs" {
  description = "Applied service configurations showing override hierarchy results"
  value = var.enable_debug_outputs ? {
    service_configs   = local.service_configs
    cpu_architectures = local.cpu_architectures
    cert_resolvers    = local.cert_resolvers
    helm_configs      = local.helm_configs
  } : null
  sensitive = true
}

# Quick access URLs for deployed services (when ingress is enabled)
output "service_urls" {
  description = "Quick access URLs for deployed services"
  value = {
    traefik_dashboard = local.services_enabled.traefik ? (
      "https://traefik.${local.domain}"
    ) : null

    grafana = local.services_enabled.grafana ? (
      "https://grafana.${local.domain}"
    ) : null

    prometheus = (local.services_enabled.prometheus && local.service_configs.prometheus.enable_ingress) ? (
      "https://prometheus.${local.domain}"
    ) : null

    alertmanager = (local.services_enabled.prometheus && local.service_configs.prometheus.enable_alertmanager_ingress) ? (
      "https://alertmanager.${local.domain}"
    ) : null

    portainer = local.services_enabled.portainer ? (
      "https://portainer.${local.domain}"
    ) : null

    consul = local.services_enabled.consul ? (
      "https://consul.${local.domain}"
    ) : null

    vault = local.services_enabled.vault ? (
      "https://vault.${local.domain}"
    ) : null
  }
}

output "debug_storage_config" {
  sensitive = true
  value = {
    use_nfs_storage       = var.use_nfs_storage
    enable_nfs_csi        = var.enable_nfs_csi
    use_hostpath_storage  = var.use_hostpath_storage
    enable_host_path      = var.enable_host_path
    primary_storage_class = local.primary_storage_class
    storage_classes       = local.storage_classes
  }
}

output "storage_debug" {
  sensitive = true
  value = {
    # Variables from tfvars
    use_nfs_storage      = var.use_nfs_storage
    enable_nfs_csi       = local.services_enabled.nfs_csi
    use_hostpath_storage = var.use_hostpath_storage
    enable_host_path     = local.services_enabled.host_path

    # Computed locals
    primary_storage_class = local.primary_storage_class
    storage_classes       = local.storage_classes

    # Module storage classes
    traefik_storage    = local.services_enabled.traefik ? coalesce(var.storage_class_override.traefik, local.storage_classes.default, "hostpath") : "disabled"
    portainer_storage  = local.services_enabled.portainer ? coalesce(var.storage_class_override.portainer, local.storage_classes.default, "hostpath") : "disabled"
    consul_storage     = local.services_enabled.consul ? coalesce(var.storage_class_override.consul, local.storage_classes.default, "hostpath") : "disabled"
    vault_storage      = local.services_enabled.vault ? coalesce(var.storage_class_override.vault, local.storage_classes.default, "hostpath") : "disabled"
    prometheus_storage = local.services_enabled.prometheus ? coalesce(var.storage_class_override.prometheus, local.storage_classes.default, "hostpath") : "disabled"
    grafana_storage    = local.services_enabled.grafana ? coalesce(var.storage_class_override.grafana, local.storage_classes.grafana, "hostpath") : "disabled"
  }
}

output "helm_debug" {
  sensitive = true
  value = {
    # Default Helm configurations
    defaults = {
      timeout          = var.default_helm_timeout
      disable_webhooks = var.default_helm_disable_webhooks
      skip_crds        = var.default_helm_skip_crds
      replace          = var.default_helm_replace
      force_update     = var.default_helm_force_update
      cleanup_on_fail  = var.default_helm_cleanup_on_fail
      wait             = var.default_helm_wait
      wait_for_jobs    = var.default_helm_wait_for_jobs
    }

    # All service Helm configurations from locals
    service_configs = local.helm_configs
  }
}

output "cert_resolver_debug" {
  sensitive = true
  value = {
    # Default cert resolver
    default_cert_resolver = var.traefik_cert_resolver

    # Computed cert resolvers
    cert_resolvers = local.cert_resolvers

    # Service-specific cert resolvers
    traefik_cert_resolver    = local.cert_resolvers.traefik
    portainer_cert_resolver  = local.cert_resolvers.portainer
    prometheus_cert_resolver = local.cert_resolvers.prometheus
    grafana_cert_resolver    = local.cert_resolvers.grafana
    consul_cert_resolver     = local.cert_resolvers.consul
    vault_cert_resolver      = local.cert_resolvers.vault
  }
}

output "cpu_arch_debug" {
  sensitive = true
  value = {
    # Detected architecture
    detected_arch = local.cpu_arch
    cluster_info  = local.cluster_architecture_info

    # All service CPU architectures
    service_architectures = local.cpu_architectures

    # Mixed cluster overrides and final arch scheduling
    mixed_cluster_overrides       = local.mixed_cluster_overrides
    final_disable_arch_scheduling = local.final_disable_arch_scheduling
  }
}
