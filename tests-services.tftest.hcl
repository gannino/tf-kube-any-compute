# Service Enablement Tests
# Tests for service configuration and enablement logic

run "test_service_enablement_defaults" {
  command = plan

  variables {
    base_domain   = "test.local"
    platform_name = "k3s"
    cpu_arch      = "amd64"
    
    # Use default services configuration
    services = {
      traefik                = true
      metallb                = true
      host_path              = true
      nfs_csi                = true
      prometheus             = true
      prometheus_crds        = true
      grafana                = true
      loki                   = true
      promtail               = true
      consul                 = true
      vault                  = true
      gatekeeper             = false
      portainer              = true
      node_feature_discovery = true
    }
  }

  assert {
    condition     = local.services_enabled.traefik == true
    error_message = "Traefik should be enabled by default"
  }

  assert {
    condition     = local.services_enabled.metallb == true
    error_message = "MetalLB should be enabled by default"
  }

  assert {
    condition     = local.services_enabled.gatekeeper == false
    error_message = "Gatekeeper should be disabled by default"
  }

  assert {
    condition     = local.services_enabled.prometheus == true
    error_message = "Prometheus should be enabled by default"
  }
}

run "test_service_enablement_overrides" {
  command = plan

  variables {
    base_domain   = "test.local"
    platform_name = "k3s"
    cpu_arch      = "amd64"
    
    services = {
      traefik                = false
      metallb                = false
      host_path              = true
      nfs_csi                = false
      prometheus             = false
      prometheus_crds        = false
      grafana                = false
      loki                   = false
      promtail               = false
      consul                 = false
      vault                  = false
      gatekeeper             = true
      portainer              = false
      node_feature_discovery = true
    }
  }

  assert {
    condition     = local.services_enabled.traefik == false
    error_message = "Traefik should be disabled when explicitly set"
  }

  assert {
    condition     = local.services_enabled.gatekeeper == true
    error_message = "Gatekeeper should be enabled when explicitly set"
  }

  assert {
    condition     = local.services_enabled.node_feature_discovery == true
    error_message = "Node feature discovery should remain enabled"
  }
}

run "test_backward_compatibility_variables" {
  command = plan

  variables {
    base_domain   = "test.local"
    platform_name = "k3s"
    cpu_arch      = "amd64"
    
    # Test backward compatibility with individual enable_* variables
    enable_traefik    = false
    enable_prometheus = false
    enable_grafana    = true
    
    services = {
      traefik                = true  # Should be overridden by enable_traefik
      metallb                = true
      host_path              = true
      nfs_csi                = false
      prometheus             = true  # Should be overridden by enable_prometheus
      prometheus_crds        = false
      grafana                = false # Should be overridden by enable_grafana
      loki                   = false
      promtail               = false
      consul                 = false
      vault                  = false
      gatekeeper             = false
      portainer              = false
      node_feature_discovery = true
    }
  }

  assert {
    condition     = local.services_enabled.traefik == false
    error_message = "Backward compatibility: enable_traefik should override services.traefik"
  }

  assert {
    condition     = local.services_enabled.prometheus == false
    error_message = "Backward compatibility: enable_prometheus should override services.prometheus"
  }

  assert {
    condition     = local.services_enabled.grafana == true
    error_message = "Backward compatibility: enable_grafana should override services.grafana"
  }
}

run "test_minimal_service_configuration" {
  command = plan

  variables {
    base_domain   = "test.local"
    platform_name = "k3s"
    cpu_arch      = "amd64"
    
    # Minimal configuration for resource-constrained environments
    services = {
      traefik                = true
      metallb                = true
      host_path              = true
      nfs_csi                = false
      prometheus             = false
      prometheus_crds        = false
      grafana                = false
      loki                   = false
      promtail               = false
      consul                 = false
      vault                  = false
      gatekeeper             = false
      portainer              = false
      node_feature_discovery = true
    }
  }

  assert {
    condition = (
      local.services_enabled.traefik == true &&
      local.services_enabled.metallb == true &&
      local.services_enabled.host_path == true &&
      local.services_enabled.node_feature_discovery == true
    )
    error_message = "Core services should be enabled in minimal configuration"
  }

  assert {
    condition = (
      local.services_enabled.prometheus == false &&
      local.services_enabled.grafana == false &&
      local.services_enabled.consul == false &&
      local.services_enabled.vault == false
    )
    error_message = "Optional services should be disabled in minimal configuration"
  }
}

run "test_service_configuration_inheritance" {
  command = plan

  variables {
    base_domain   = "test.local"
    platform_name = "k3s"
    cpu_arch      = "amd64"
    
    # Global defaults
    default_helm_timeout = 900
    default_helm_wait    = true
    
    service_overrides = {
      traefik = {
        helm_timeout = 300
        helm_wait    = false
      }
    }
    
    services = {
      traefik                = true
      metallb                = true
      host_path              = true
      nfs_csi                = false
      prometheus             = false
      prometheus_crds        = false
      grafana                = false
      loki                   = false
      promtail               = false
      consul                 = false
      vault                  = false
      gatekeeper             = false
      portainer              = false
      node_feature_discovery = true
    }
  }

  assert {
    condition     = local.helm_configs.traefik.timeout == 300
    error_message = "Traefik should use service-specific timeout override"
  }

  assert {
    condition     = local.helm_configs.traefik.wait == false
    error_message = "Traefik should use service-specific wait override"
  }

  assert {
    condition     = local.helm_configs.metallb.timeout == 900
    error_message = "MetalLB should inherit global timeout default"
  }

  assert {
    condition     = local.helm_configs.metallb.wait == true
    error_message = "MetalLB should inherit global wait default"
  }
}

run "test_resource_limits_configuration" {
  command = plan

  variables {
    base_domain            = "test.local"
    platform_name          = "k3s"
    cpu_arch               = "amd64"
    enable_resource_limits = true
    default_cpu_limit      = "500m"
    default_memory_limit   = "512Mi"
    
    services = {
      traefik                = true
      metallb                = true
      host_path              = true
      nfs_csi                = false
      prometheus             = false
      prometheus_crds        = false
      grafana                = false
      loki                   = false
      promtail               = false
      consul                 = false
      vault                  = false
      gatekeeper             = false
      portainer              = false
      node_feature_discovery = true
    }
  }

  assert {
    condition     = local.resource_defaults.cpu_limit == "500m"
    error_message = "CPU limit should match configured value when resource limits enabled"
  }

  assert {
    condition     = local.resource_defaults.memory_limit == "512Mi"
    error_message = "Memory limit should match configured value when resource limits enabled"
  }
}

run "test_domain_construction" {
  command = plan

  variables {
    base_domain   = "example.com"
    platform_name = "k3s"
    cpu_arch      = "amd64"
    
    services = {
      traefik                = true
      metallb                = true
      host_path              = true
      nfs_csi                = false
      prometheus             = false
      prometheus_crds        = false
      grafana                = false
      loki                   = false
      promtail               = false
      consul                 = false
      vault                  = false
      gatekeeper             = false
      portainer              = false
      node_feature_discovery = true
    }
  }

  assert {
    condition     = can(regex("^[a-z]+\\.k3s\\.example\\.com$", local.domain))
    error_message = "Domain should follow workspace.platform.base_domain format"
  }

  assert {
    condition     = local.workspace_prefix != ""
    error_message = "Workspace prefix should be determined from terraform workspace"
  }
}