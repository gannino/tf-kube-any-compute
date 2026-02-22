# Module Output Tests
# Tests for verifying standardized module outputs added in Phase 2

run "test_metallb_outputs" {
  command = plan

  variables {
    base_domain   = "test.local"
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
      node_feature_discovery = false
    }
  }

  # Verify MetalLB service config is available
  assert {
    condition     = local.service_configs.metallb != null
    error_message = "MetalLB service config should be available"
  }

  assert {
    condition     = local.services_enabled.metallb == true
    error_message = "MetalLB should be enabled"
  }
}

run "test_portainer_outputs" {
  command = plan

  variables {
    base_domain   = "test.local"
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
      portainer              = true
      node_feature_discovery = false
    }
  }

  # Verify Portainer service config is available
  assert {
    condition     = local.service_configs.portainer != null
    error_message = "Portainer service config should be available"
  }

  assert {
    condition     = local.services_enabled.portainer == true
    error_message = "Portainer should be enabled"
  }

  # Verify cert resolver is assigned
  assert {
    condition     = local.cert_resolvers.portainer != null
    error_message = "Portainer should have a cert resolver assigned"
  }
}

run "test_loki_outputs" {
  command = plan

  variables {
    base_domain   = "test.local"
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
      loki                   = true
      promtail               = false
      consul                 = false
      vault                  = false
      gatekeeper             = false
      portainer              = false
      node_feature_discovery = false
    }
  }

  # Verify Loki service config is available
  assert {
    condition     = local.service_configs.loki != null
    error_message = "Loki service config should be available"
  }

  assert {
    condition     = local.services_enabled.loki == true
    error_message = "Loki should be enabled"
  }
}

run "test_consul_outputs" {
  command = plan

  variables {
    base_domain   = "test.local"
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
      consul                 = true
      vault                  = false
      gatekeeper             = false
      portainer              = false
      node_feature_discovery = false
    }
  }

  # Verify Consul service config is available
  assert {
    condition     = local.service_configs.consul != null
    error_message = "Consul service config should be available"
  }

  assert {
    condition     = local.services_enabled.consul == true
    error_message = "Consul should be enabled"
  }
}

run "test_gatekeeper_outputs" {
  command = plan

  variables {
    base_domain   = "test.local"
    platform_name = "k3s"
    cpu_arch      = "amd64"

    # Use enable_gatekeeper for backward compatibility override
    enable_gatekeeper = true

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
      gatekeeper             = true
      portainer              = false
      node_feature_discovery = false
    }
  }

  # Verify Gatekeeper service config is available
  assert {
    condition     = local.service_configs.gatekeeper != null
    error_message = "Gatekeeper service config should be available"
  }

  assert {
    condition     = local.services_enabled.gatekeeper == true
    error_message = "Gatekeeper should be enabled when enable_gatekeeper is set to true"
  }
}

run "test_node_feature_discovery_outputs" {
  command = plan

  variables {
    base_domain   = "test.local"
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

  # Verify NFD service config is available
  assert {
    condition     = local.service_configs.node_feature_discovery != null
    error_message = "Node Feature Discovery service config should be available"
  }

  assert {
    condition     = local.services_enabled.node_feature_discovery == true
    error_message = "Node Feature Discovery should be enabled"
  }
}

run "test_host_path_outputs" {
  command = plan

  variables {
    base_domain   = "test.local"
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
      node_feature_discovery = false
    }
  }

  # Verify Host Path service config is available
  assert {
    condition     = local.service_configs.host_path != null
    error_message = "Host Path service config should be available"
  }

  assert {
    condition     = local.services_enabled.host_path == true
    error_message = "Host Path should be enabled"
  }
}

run "test_nfs_csi_outputs" {
  command = plan

  variables {
    base_domain   = "test.local"
    platform_name = "k3s"
    cpu_arch      = "amd64"

    use_nfs_storage = true

    services = {
      traefik                = true
      metallb                = true
      host_path              = false
      nfs_csi                = true
      prometheus             = false
      prometheus_crds        = false
      grafana                = false
      loki                   = false
      promtail               = false
      consul                 = false
      vault                  = false
      gatekeeper             = false
      portainer              = false
      node_feature_discovery = false
    }
  }

  # Verify NFS CSI service config is available
  assert {
    condition     = local.service_configs.nfs_csi != null
    error_message = "NFS CSI service config should be available"
  }

  assert {
    condition     = local.services_enabled.nfs_csi == true
    error_message = "NFS CSI should be enabled"
  }
}

run "test_standardized_service_configs" {
  command = plan

  variables {
    base_domain   = "test.local"
    platform_name = "k3s"
    cpu_arch      = "amd64"

    services = {
      traefik                = true
      metallb                = true
      host_path              = true
      nfs_csi                = false
      prometheus             = true
      prometheus_crds        = true
      grafana                = true
      loki                   = true
      promtail               = false
      consul                 = true
      vault                  = true
      gatekeeper             = false
      portainer              = true
      node_feature_discovery = true
    }
  }

  # Verify all enabled services have configs
  assert {
    condition = (
      local.service_configs.traefik != null &&
      local.service_configs.metallb != null &&
      local.service_configs.host_path != null &&
      local.service_configs.prometheus != null &&
      local.service_configs.grafana != null &&
      local.service_configs.loki != null &&
      local.service_configs.consul != null &&
      local.service_configs.vault != null &&
      local.service_configs.portainer != null &&
      local.service_configs.node_feature_discovery != null
    )
    error_message = "All enabled services should have service_configs entries"
  }
}

run "test_helm_configs_for_updated_modules" {
  command = plan

  variables {
    base_domain   = "test.local"
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
      loki                   = true
      promtail               = false
      consul                 = true
      vault                  = false
      gatekeeper             = true
      portainer              = true
      node_feature_discovery = true
    }
  }

  # Verify helm configs exist for all enabled services
  assert {
    condition = (
      local.helm_configs.metallb != null &&
      local.helm_configs.loki != null &&
      local.helm_configs.consul != null &&
      local.helm_configs.gatekeeper != null &&
      local.helm_configs.portainer != null &&
      local.helm_configs.node_feature_discovery != null
    )
    error_message = "All enabled services should have helm_configs entries"
  }
}
