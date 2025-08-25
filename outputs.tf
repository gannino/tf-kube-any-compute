# ============================================================================
# TERRAFORM KUBERNETES INFRASTRUCTURE - OUTPUT DEFINITIONS
# ============================================================================

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

# Certificate resolver debugging information
output "cert_resolver_debug" {
  description = "Certificate resolver debugging information"
  sensitive   = true
  value = var.enable_debug_outputs ? {
    # Default cert resolver
    default_cert_resolver = var.traefik_cert_resolver
    dns_provider_name     = local.dns_provider_name

    # Computed cert resolvers
    cert_resolvers = local.cert_resolvers

    # Service-specific cert resolver inputs (what user configured)
    service_cert_resolver_inputs = {
      traefik    = try(var.service_overrides.traefik.cert_resolver, null)
      prometheus = try(var.service_overrides.prometheus.cert_resolver, null)
      grafana    = try(var.service_overrides.grafana.cert_resolver, null)
      consul     = try(var.service_overrides.consul.cert_resolver, null)
      vault      = try(var.service_overrides.vault.cert_resolver, null)
      portainer  = try(var.service_overrides.portainer.cert_resolver, null)
    }

    # Legacy cert resolver inputs
    legacy_cert_resolver_inputs = {
      traefik      = try(var.cert_resolver_override.traefik, null)
      prometheus   = try(var.cert_resolver_override.prometheus, null)
      grafana      = try(var.cert_resolver_override.grafana, null)
      alertmanager = try(var.cert_resolver_override.alertmanager, null)
      consul       = try(var.cert_resolver_override.consul, null)
      vault        = try(var.cert_resolver_override.vault, null)
      portainer    = try(var.cert_resolver_override.portainer, null)
    }

    # Final resolved cert resolvers (what modules actually use)
    resolved_cert_resolvers = local.cert_resolvers
  } : null
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

# CPU architecture debugging information
output "cpu_arch_debug" {
  description = "CPU architecture debugging information"
  sensitive   = true
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

# Helm configuration debugging information
output "helm_debug" {
  description = "Helm configuration debugging information"
  sensitive   = true
  value = var.enable_debug_outputs ? {
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

    # System defaults for timeouts
    system_defaults = {
      helm_timeout_short  = local.defaults.helm_timeout_short
      helm_timeout_medium = local.defaults.helm_timeout_medium
      helm_timeout_long   = local.defaults.helm_timeout_long
      helm_timeout_xllong = local.defaults.helm_timeout_xllong
    }

    # All service Helm configurations from locals
    service_configs = local.helm_configs
  } : null
}

# Middleware configuration debugging information
output "middleware_debug" {
  description = "Middleware configuration debugging information"
  sensitive   = true
  value = var.enable_debug_outputs ? {
    # Middleware configuration
    middleware_config     = local.middleware_config
    auth_method_enabled   = local.auth_method_enabled
    preferred_auth_method = local.preferred_auth_method
    preferred_middleware  = local.preferred_middleware
    auth_middlewares      = local.auth_middlewares

    # Traefik middleware names (from outputs)
    traefik_middleware_names = local.services_enabled.traefik ? {
      basic_auth   = local.traefik_basic_middleware
      ldap_auth    = local.traefik_ldap_middleware
      default_auth = local.traefik_default_middleware
    } : null

    # Auth override configuration
    auth_override = var.auth_override
  } : null
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

# Consolidated module outputs - detailed information about each deployed service
output "service_outputs" {
  description = "Detailed outputs from all deployed services with full module information for debugging"
  sensitive   = true
  value = {
    consul = {
      enabled = local.services_enabled.consul
      module_outputs = local.services_enabled.consul ? {
        url            = try(module.consul[0].url, null)
        uri            = try(module.consul[0].uri, null)
        token          = try(module.consul[0].token, null)
        get_acl_secret = try(module.consul[0].get_acl_secret, null)
      } : null
      resolved_config = local.services_enabled.consul ? merge(local.service_configs.consul, {
        cert_resolver = local.cert_resolvers.consul
        helm_config   = local.helm_configs.consul
      }) : null
    }

    gatekeeper = {
      enabled = local.services_enabled.gatekeeper
      module_outputs = local.services_enabled.gatekeeper ? {
        # Gatekeeper module outputs (if any)
        deployed = true
      } : null
      resolved_config = local.services_enabled.gatekeeper ? {
        helm_config = local.helm_configs.gatekeeper
      } : null
    }

    grafana = {
      enabled = local.services_enabled.grafana
      module_outputs = local.services_enabled.grafana ? {
        namespace            = try(module.grafana[0].namespace, null)
        grafana_service_name = try(module.grafana[0].grafana_service_name, null)
        service_url          = try(module.grafana[0].service_url, null)
        ingress_url          = try(module.grafana[0].ingress_url, null)
        admin_user           = try(module.grafana[0].admin_user, null)
        admin_password       = try(module.grafana[0].admin_password, null)
      } : null
      resolved_config = local.services_enabled.grafana ? merge(local.service_configs.grafana, {
        cert_resolver = local.cert_resolvers.grafana
        helm_config   = local.helm_configs.grafana
      }) : null
    }

    host_path = {
      enabled = local.services_enabled.host_path
      module_outputs = local.services_enabled.host_path ? {
        namespace             = try(module.host_path[0].namespace, null)
        helm_release          = try(module.host_path[0].helm_release, null)
        storage_configuration = try(module.host_path[0].storage_configuration, null)
        resource_limits       = try(module.host_path[0].resource_limits, null)
      } : null
      resolved_config = local.services_enabled.host_path ? {
        is_default  = !var.use_nfs_storage || !local.services_enabled.nfs_csi
        helm_config = local.helm_configs.host_path
      } : null
    }

    kube_state_metrics = {
      enabled = local.services_enabled.kube_state_metrics
      module_outputs = local.services_enabled.kube_state_metrics ? {
        namespace           = try(module.kube_state_metrics[0].namespace, null)
        service_name        = try(module.kube_state_metrics[0].service_name, null)
        service_port        = try(module.kube_state_metrics[0].service_port, null)
        metrics_endpoint    = try(module.kube_state_metrics[0].metrics_endpoint, null)
        helm_release_name   = try(module.kube_state_metrics[0].helm_release_name, null)
        helm_release_status = try(module.kube_state_metrics[0].helm_release_status, null)
      } : null
      resolved_config = local.services_enabled.kube_state_metrics ? merge(local.service_configs.kube_state_metrics, {
        helm_config = local.helm_configs.kube_state_metrics
      }) : null
    }

    loki = {
      enabled = local.services_enabled.loki
      module_outputs = local.services_enabled.loki ? {
        namespace = try(module.loki[0].namespace, null)
        loki_url  = try(module.loki[0].loki_url, null)
      } : null
      resolved_config = local.services_enabled.loki ? merge(local.service_configs.loki, {
        helm_config = local.helm_configs.loki
      }) : null
    }

    metallb = {
      enabled = local.services_enabled.metallb
      module_outputs = local.services_enabled.metallb ? {
        # MetalLB module has no outputs currently
        deployed = true
      } : null
      resolved_config = local.services_enabled.metallb ? merge(local.service_configs.metallb, {
        helm_config = local.helm_configs.metallb
      }) : null
    }

    nfs_csi = {
      enabled = local.services_enabled.nfs_csi
      module_outputs = local.services_enabled.nfs_csi ? {
        namespace         = try(module.nfs_csi[0].namespace, null)
        storage_classes   = try(module.nfs_csi[0].storage_classes, null)
        helm_release_name = try(module.nfs_csi[0].helm_release_name, null)
        service_name      = try(module.nfs_csi[0].service_name, null)
        nfs_server        = try(module.nfs_csi[0].nfs_server, null)
        nfs_path          = try(module.nfs_csi[0].nfs_path, null)
      } : null
      resolved_config = local.services_enabled.nfs_csi ? {
        nfs_server  = local.nfs_server
        nfs_path    = local.nfs_path
        is_default  = var.use_nfs_storage
        helm_config = local.helm_configs.nfs_csi
      } : null
    }

    node_feature_discovery = {
      enabled = local.services_enabled.node_feature_discovery
      module_outputs = local.services_enabled.node_feature_discovery ? {
        namespace = try(module.node_feature_discovery[0].namespace, null)
      } : null
      resolved_config = local.services_enabled.node_feature_discovery ? {
        helm_config = local.helm_configs.node_feature_discovery
      } : null
    }

    portainer = {
      enabled = local.services_enabled.portainer
      module_outputs = local.services_enabled.portainer ? {
        portainer = try(module.portainer[0].portainer, null)
      } : null
      resolved_config = local.services_enabled.portainer ? merge(local.service_configs.portainer, {
        cert_resolver = local.cert_resolvers.portainer
        helm_config   = local.helm_configs.portainer
      }) : null
    }

    prometheus = {
      enabled = local.services_enabled.prometheus
      module_outputs = local.services_enabled.prometheus ? {
        namespace                  = try(module.prometheus[0].namespace, null)
        prometheus_service_name    = try(module.prometheus[0].prometheus_service_name, null)
        alertmanager_service_name  = try(module.prometheus[0].alertmanager_service_name, null)
        prometheus_url             = try(module.prometheus[0].prometheus_url, null)
        alertmanager_url           = try(module.prometheus[0].alertmanager_url, null)
        prometheus_ingress_url     = try(module.prometheus[0].prometheus_ingress_url, null)
        alertmanager_ingress_url   = try(module.prometheus[0].alertmanager_ingress_url, null)
        prometheus_storage_class   = try(module.prometheus[0].prometheus_storage_class, null)
        alertmanager_storage_class = try(module.prometheus[0].alertmanager_storage_class, null)
        helm_release_name          = try(module.prometheus[0].helm_release_name, null)
        environment_config         = try(module.prometheus[0].environment_config, null)
      } : null
      resolved_config = local.services_enabled.prometheus ? merge(local.service_configs.prometheus, {
        cert_resolver = local.cert_resolvers.prometheus
        helm_config   = local.helm_configs.prometheus_stack
      }) : null
    }

    prometheus_crds = {
      enabled = local.services_enabled.prometheus_crds
      module_outputs = local.services_enabled.prometheus_crds ? {
        namespace         = try(module.prometheus_crds[0].namespace, null)
        helm_release      = try(module.prometheus_crds[0].helm_release, null)
        crd_configuration = try(module.prometheus_crds[0].crd_configuration, null)
        resource_limits   = try(module.prometheus_crds[0].resource_limits, null)
      } : null
      resolved_config = local.services_enabled.prometheus_crds ? {
        helm_config = local.helm_configs.prometheus_stack_crds
      } : null
    }

    promtail = {
      enabled = local.services_enabled.promtail && local.services_enabled.loki
      module_outputs = (local.services_enabled.promtail && local.services_enabled.loki) ? {
        namespace            = try(module.promtail[0].namespace, null)
        release_name         = try(module.promtail[0].release_name, null)
        release_status       = try(module.promtail[0].release_status, null)
        service_account_name = try(module.promtail[0].service_account_name, null)
        cluster_role_name    = try(module.promtail[0].cluster_role_name, null)
        loki_endpoint        = try(module.promtail[0].loki_endpoint, null)
      } : null
      resolved_config = (local.services_enabled.promtail && local.services_enabled.loki) ? merge(local.service_configs.promtail, {
        helm_config = local.helm_configs.promtail
      }) : null
    }

    traefik = {
      enabled = local.services_enabled.traefik
      module_outputs = local.services_enabled.traefik ? {
        namespace          = try(module.traefik[0].namespace, null)
        service_name       = try(module.traefik[0].service_name, null)
        loadbalancer_ip    = try(module.traefik[0].loadbalancer_ip, null)
        dashboard_url      = try(module.traefik[0].dashboard_url, null)
        chart_version      = try(module.traefik[0].chart_version, null)
        cert_resolver_name = try(module.traefik[0].cert_resolver_name, null)
        middleware         = try(module.traefik[0].middleware, null)
        auth_credentials   = try(module.traefik[0].auth_credentials, null)
      } : null
      resolved_config = local.services_enabled.traefik ? merge(local.service_configs.traefik, {
        cert_resolver = local.cert_resolvers.traefik
        helm_config   = local.helm_configs.traefik
      }) : null
    }

    vault = {
      enabled = local.services_enabled.vault
      module_outputs = local.services_enabled.vault ? {
        namespace          = try(module.vault[0].namespace, null)
        service_name       = try(module.vault[0].service_name, null)
        service_url        = try(module.vault[0].service_url, null)
        vault_address      = try(module.vault[0].vault_address, null)
        ingress_url        = try(module.vault[0].ingress_url, null)
        web_ui_url         = try(module.vault[0].web_ui_url, null)
        health_check_url   = try(module.vault[0].health_check_url, null)
        storage_class      = try(module.vault[0].storage_class, null)
        helm_release_name  = try(module.vault[0].helm_release_name, null)
        environment_config = try(module.vault[0].environment_config, null)
      } : null
      resolved_config = local.services_enabled.vault ? merge(local.service_configs.vault, {
        cert_resolver = local.cert_resolvers.vault
        helm_config   = local.helm_configs.vault
      }) : null
    }

    node_red = {
      enabled = local.services_enabled.node_red
      module_outputs = local.services_enabled.node_red ? {
        namespace         = try(module.node_red[0].namespace, null)
        service_name      = try(module.node_red[0].service_name, null)
        service_url       = try(module.node_red[0].service_url, null)
        ingress_url       = try(module.node_red[0].ingress_url, null)
        helm_release_name = try(module.node_red[0].helm_release_name, null)
        node_red_config   = try(module.node_red[0].node_red_config, null)
      } : null
      resolved_config = local.services_enabled.node_red ? merge(local.service_configs.node_red, {
        cert_resolver = local.cert_resolvers.node_red
        helm_config   = local.helm_configs.node_red
      }) : null
    }

    n8n = {
      enabled = local.services_enabled.n8n
      module_outputs = local.services_enabled.n8n ? {
        namespace         = try(module.n8n[0].namespace, null)
        service_name      = try(module.n8n[0].service_name, null)
        service_url       = try(module.n8n[0].service_url, null)
        ingress_url       = try(module.n8n[0].ingress_url, null)
        webhook_url       = try(module.n8n[0].webhook_url, null)
        deployment_name   = try(module.n8n[0].deployment_name, null)
        deployment_status = try(module.n8n[0].deployment_status, null)
        n8n_version       = try(module.n8n[0].n8n_version, null)
        n8n_config        = try(module.n8n[0].n8n_config, null)
      } : null
      resolved_config = local.services_enabled.n8n ? merge(local.service_configs.n8n, {
        cert_resolver = local.cert_resolvers.n8n
        # Native Terraform deployment - no Helm configuration
      }) : null
    }

    homebridge = {
      enabled = local.services_enabled.homebridge
      module_outputs = local.services_enabled.homebridge ? {
        namespace         = try(module.homebridge[0].namespace, null)
        service_name      = try(module.homebridge[0].service_name, null)
        service_url       = try(module.homebridge[0].url, null)
        ingress_url       = try(module.homebridge[0].external_url, null)
        helm_release_name = try(module.homebridge[0].helm_release_name, null)
        plugins           = try(module.homebridge[0].plugins, null)
        storage_class     = try(module.homebridge[0].storage_class, null)
      } : null
      resolved_config = local.services_enabled.homebridge ? merge(local.service_configs.homebridge, {
        cert_resolver = local.cert_resolvers.homebridge
        helm_config   = local.helm_configs.homebridge
      }) : null
    }
  }
}

# Quick access URLs for deployed services (when ingress is enabled)
output "service_urls" {
  description = "Quick access URLs for deployed services"
  value = {
    alertmanager = (local.services_enabled.prometheus && local.service_configs.prometheus.enable_alertmanager_ingress) ? (
      "https://alertmanager.${local.domain}"
    ) : null

    consul = local.services_enabled.consul ? (
      "https://consul.${local.domain}"
    ) : null

    grafana = local.services_enabled.grafana ? (
      "https://grafana.${local.domain}"
    ) : null

    portainer = local.services_enabled.portainer ? (
      "https://portainer.${local.domain}"
    ) : null

    prometheus = (local.services_enabled.prometheus && local.service_configs.prometheus.enable_ingress) ? (
      "https://prometheus.${local.domain}"
    ) : null

    traefik_dashboard = local.services_enabled.traefik ? (
      "https://traefik.${local.domain}"
    ) : null

    vault = local.services_enabled.vault ? (
      "https://vault.${local.domain}"
    ) : null

    node_red = local.services_enabled.node_red ? (
      "https://node-red.${local.domain}"
    ) : null

    n8n = local.services_enabled.n8n ? (
      "https://n8n.${local.domain}"
    ) : null

    homebridge = local.services_enabled.homebridge ? (
      "https://homebridge.${local.domain}"
    ) : null
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

# Storage debugging information
output "storage_debug" {
  description = "Storage debugging information"
  sensitive   = true
  value = var.enable_debug_outputs ? {
    # Variables from tfvars
    use_nfs_storage      = var.use_nfs_storage
    enable_nfs_csi       = local.services_enabled.nfs_csi
    use_hostpath_storage = var.use_hostpath_storage
    enable_host_path     = local.services_enabled.host_path

    # Computed locals
    primary_storage_class = local.primary_storage_class
    storage_classes       = local.storage_classes

    # Service storage classes using unified configs
    consul_storage     = local.services_enabled.consul ? local.service_configs.consul.storage_class : "disabled"
    grafana_storage    = local.services_enabled.grafana ? local.service_configs.grafana.storage_class : "disabled"
    loki_storage       = local.services_enabled.loki ? local.service_configs.loki.storage_class : "disabled"
    portainer_storage  = local.services_enabled.portainer ? local.service_configs.portainer.storage_class : "disabled"
    prometheus_storage = local.services_enabled.prometheus ? local.service_configs.prometheus.storage_class : "disabled"
    traefik_storage    = local.services_enabled.traefik ? local.service_configs.traefik.storage_class : "disabled"
    vault_storage      = local.services_enabled.vault ? local.service_configs.vault.storage_class : "disabled"
  } : null
}

# System configuration and defaults
output "system_configuration" {
  description = "System defaults and configuration hierarchy"
  value = var.enable_debug_outputs ? {
    system_defaults = local.defaults
  } : null
  sensitive = true
}
