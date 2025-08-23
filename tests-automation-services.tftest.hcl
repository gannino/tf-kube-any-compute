# Automation Services Tests
# Tests for Node-RED and n8n workflow automation services

run "test_node_red_service_enablement" {
  command = plan

  variables {
    base_domain   = "test.local"
    platform_name = "k3s"
    cpu_arch      = "amd64"

    services = {
      traefik                = true
      metallb                = true
      host_path              = true
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
      node_feature_discovery = true
      node_red               = true
      n8n                    = false
    }
  }

  assert {
    condition     = local.services_enabled.node_red == true
    error_message = "Node-RED should be enabled when explicitly set"
  }

  assert {
    condition     = local.services_enabled.n8n == false
    error_message = "n8n should be disabled when explicitly set to false"
  }
}

run "test_n8n_service_enablement" {
  command = plan

  variables {
    base_domain   = "test.local"
    platform_name = "k3s"
    cpu_arch      = "amd64"

    services = {
      traefik                = true
      metallb                = true
      host_path              = true
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
      node_feature_discovery = true
      node_red               = false
      n8n                    = true
    }
  }

  assert {
    condition     = local.services_enabled.n8n == true
    error_message = "n8n should be enabled when explicitly set"
  }

  assert {
    condition     = local.services_enabled.node_red == false
    error_message = "Node-RED should be disabled when explicitly set to false"
  }
}

run "test_automation_services_configuration" {
  command = plan

  variables {
    base_domain   = "test.local"
    platform_name = "k3s"
    cpu_arch      = "arm64"

    services = {
      traefik                = true
      metallb                = true
      host_path              = true
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
      node_feature_discovery = true
      node_red               = true
      n8n                    = true
    }

    service_overrides = {
      node_red = {
        cpu_arch             = "arm64"
        storage_class        = "nfs-csi"
        persistent_disk_size = "2Gi"
        enable_persistence   = true
        palette_packages = [
          "node-red-contrib-home-assistant-websocket",
          "node-red-dashboard"
        ]
      }
      n8n = {
        cpu_arch             = "arm64"
        storage_class        = "nfs-csi"
        persistent_disk_size = "5Gi"
        enable_persistence   = true
        enable_database      = false
      }
    }
  }

  assert {
    condition     = local.service_configs.node_red.cpu_arch == "arm64"
    error_message = "Node-RED should use ARM64 architecture when specified"
  }

  assert {
    condition     = local.service_configs.n8n.cpu_arch == "arm64"
    error_message = "n8n should use ARM64 architecture when specified"
  }

  assert {
    condition     = local.service_configs.node_red.storage_class == "nfs-csi"
    error_message = "Node-RED should use NFS-CSI storage class when specified"
  }

  assert {
    condition     = local.service_configs.n8n.storage_class == "nfs-csi"
    error_message = "n8n should use NFS-CSI storage class when specified"
  }
}

run "test_node_red_palette_packages" {
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
      node_red               = true
      n8n                    = false
    }

    service_overrides = {
      node_red = {
        palette_packages = [
          "node-red-contrib-home-assistant-websocket",
          "node-red-dashboard",
          "node-red-contrib-influxdb",
          "https://github.com/user/custom-nodes.git"
        ]
      }
    }
  }

  assert {
    condition = contains(
      local.service_configs.node_red.palette_packages,
      "node-red-contrib-home-assistant-websocket"
    )
    error_message = "Node-RED should include Home Assistant package in palette"
  }

  assert {
    condition = contains(
      local.service_configs.node_red.palette_packages,
      "https://github.com/user/custom-nodes.git"
    )
    error_message = "Node-RED should support Git repository packages"
  }
}

run "test_automation_services_resource_limits" {
  command = plan

  variables {
    base_domain            = "test.local"
    platform_name          = "k3s"
    cpu_arch               = "amd64"
    enable_resource_limits = true
    enable_microk8s_mode   = true

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
      node_red               = true
      n8n                    = true
    }
  }

  assert {
    condition     = local.service_configs.node_red.cpu_limit == "500m"
    error_message = "Node-RED should have appropriate CPU limits for homelab"
  }

  assert {
    condition     = local.service_configs.node_red.memory_limit == "512Mi"
    error_message = "Node-RED should have appropriate memory limits for homelab"
  }

  assert {
    condition     = local.service_configs.n8n.cpu_limit == "1000m"
    error_message = "n8n should have higher CPU limits for workflow processing"
  }

  assert {
    condition     = local.service_configs.n8n.memory_limit == "1Gi"
    error_message = "n8n should have higher memory limits for workflow processing"
  }
}

run "test_automation_services_storage_configuration" {
  command = plan

  variables {
    base_domain          = "test.local"
    platform_name        = "k3s"
    cpu_arch             = "amd64"
    enable_microk8s_mode = true

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
      node_red               = true
      n8n                    = true
    }
  }

  assert {
    condition     = local.storage_sizes.node_red == "2Gi"
    error_message = "Node-RED should use appropriate storage size for MicroK8s mode"
  }

  assert {
    condition     = local.storage_sizes.n8n == "5Gi"
    error_message = "n8n should use larger storage size for workflow data"
  }

  assert {
    condition     = local.service_configs.node_red.enable_persistence == true
    error_message = "Node-RED should enable persistence by default"
  }

  assert {
    condition     = local.service_configs.n8n.enable_persistence == true
    error_message = "n8n should enable persistence by default"
  }
}

run "test_automation_services_cert_resolvers" {
  command = plan

  variables {
    base_domain           = "example.com"
    platform_name         = "k3s"
    cpu_arch              = "amd64"
    traefik_cert_resolver = "letsencrypt"

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
      node_red               = true
      n8n                    = true
    }
  }

  assert {
    condition     = local.cert_resolvers.node_red == "letsencrypt"
    error_message = "Node-RED should use configured certificate resolver"
  }

  assert {
    condition     = local.cert_resolvers.n8n == "letsencrypt"
    error_message = "n8n should use configured certificate resolver"
  }
}

run "test_automation_services_native_deployment" {
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
      node_red               = true
      n8n                    = true
    }
  }

  assert {
    condition     = local.helm_configs.node_red.timeout == 300
    error_message = "Node-RED should use Helm deployment configuration"
  }

  # n8n uses native Terraform - no Helm configuration to test
  assert {
    condition     = local.service_configs.n8n.enable_persistence == true
    error_message = "n8n should enable persistence by default (native deployment)"
  }

  assert {
    condition     = local.service_configs.n8n.enable_database == false
    error_message = "n8n should use SQLite by default (native deployment)"
  }
}
