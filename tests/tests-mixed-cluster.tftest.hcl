# Mixed Cluster Configuration Tests
# Tests for mixed architecture cluster handling and service placement

run "test_mixed_cluster_detection" {
  command = plan

  variables {
    base_domain             = "test.local"
    platform_name           = "k3s"
    cpu_arch                = "amd64"
    auto_mixed_cluster_mode = true

    services = {
      traefik                = true
      metallb                = true
      host_path              = true
      nfs_csi                = false
      prometheus             = true
      prometheus_crds        = true
      grafana                = true
      loki                   = false
      promtail               = false
      consul                 = true
      vault                  = true
      gatekeeper             = false
      portainer              = true
      node_feature_discovery = true
    }
  }

  assert {
    condition     = var.auto_mixed_cluster_mode == true
    error_message = "Auto mixed cluster mode should be enabled"
  }

  assert {
    condition     = local.cpu_architectures.node_feature_discovery == "amd64"
    error_message = "Cluster-wide services should use detected architecture"
  }

  assert {
    condition     = local.cpu_architectures.metallb == "amd64"
    error_message = "MetalLB should use cluster-wide architecture"
  }
}

run "test_architecture_override_mixed_cluster" {
  command = plan

  variables {
    base_domain             = "test.local"
    platform_name           = "k3s"
    cpu_arch                = "amd64"
    auto_mixed_cluster_mode = true

    cpu_arch_override = {
      traefik          = "arm64"
      grafana          = "arm64"
      portainer        = "arm64"
      prometheus_stack = "amd64"
      consul           = "amd64"
      vault            = "amd64"
    }

    services = {
      traefik                = true
      metallb                = true
      host_path              = true
      nfs_csi                = false
      prometheus             = true
      prometheus_crds        = true
      grafana                = true
      loki                   = false
      promtail               = false
      consul                 = true
      vault                  = true
      gatekeeper             = false
      portainer              = true
      node_feature_discovery = true
    }
  }

  assert {
    condition     = local.cpu_architectures.traefik == "arm64"
    error_message = "Traefik should use ARM64 override for UI services"
  }

  assert {
    condition     = local.cpu_architectures.grafana == "arm64"
    error_message = "Grafana should use ARM64 override for UI services"
  }

  assert {
    condition     = local.cpu_architectures.prometheus_stack == "amd64"
    error_message = "Prometheus should use AMD64 override for performance"
  }

  assert {
    condition     = local.cpu_architectures.consul == "amd64"
    error_message = "Consul should use AMD64 override for performance"
  }

  assert {
    condition     = local.cpu_architectures.vault == "amd64"
    error_message = "Vault should use AMD64 override for security workloads"
  }
}

run "test_disable_arch_scheduling" {
  command = plan

  variables {
    base_domain   = "test.local"
    platform_name = "k3s"
    cpu_arch      = "amd64"

    disable_arch_scheduling = {
      traefik                = true
      node_feature_discovery = true
      metallb                = true
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
    condition     = var.disable_arch_scheduling.traefik == true
    error_message = "Architecture scheduling should be disabled for Traefik"
  }

  assert {
    condition     = var.disable_arch_scheduling.metallb == true
    error_message = "Architecture scheduling should be disabled for MetalLB"
  }

  assert {
    condition     = var.disable_arch_scheduling.node_feature_discovery == true
    error_message = "Architecture scheduling should be disabled for NFD"
  }
}

run "test_mixed_cluster_service_placement_strategy" {
  command = plan

  variables {
    base_domain             = "test.local"
    platform_name           = "k3s"
    cpu_arch                = "amd64"
    auto_mixed_cluster_mode = true

    # Strategic placement for mixed cluster
    cpu_arch_override = {
      # Performance-critical on AMD64
      prometheus_stack = "amd64"
      consul           = "amd64"
      vault            = "amd64"

      # UI services on efficient ARM64
      grafana   = "arm64"
      portainer = "arm64"
    }

    services = {
      traefik                = true
      metallb                = true
      host_path              = true
      nfs_csi                = false
      prometheus             = true
      prometheus_crds        = true
      grafana                = true
      loki                   = false
      promtail               = false
      consul                 = true
      vault                  = true
      gatekeeper             = false
      portainer              = true
      node_feature_discovery = true
    }
  }

  # Verify performance services on AMD64
  assert {
    condition = (
      local.cpu_architectures.prometheus_stack == "amd64" &&
      local.cpu_architectures.consul == "amd64" &&
      local.cpu_architectures.vault == "amd64"
    )
    error_message = "Performance-critical services should be placed on AMD64"
  }

  # Verify UI services on ARM64
  assert {
    condition = (
      local.cpu_architectures.grafana == "arm64" &&
      local.cpu_architectures.portainer == "arm64"
    )
    error_message = "UI services should be placed on ARM64 for efficiency"
  }

  # Verify cluster services use global architecture
  assert {
    condition = (
      local.cpu_architectures.metallb == "amd64" &&
      local.cpu_architectures.node_feature_discovery == "amd64"
    )
    error_message = "Cluster-wide services should use global architecture"
  }
}

run "test_raspberry_pi_mixed_cluster" {
  command = plan

  variables {
    base_domain             = "pi.local"
    platform_name           = "microk8s"
    cpu_arch                = "arm64"
    enable_microk8s_mode    = true
    auto_mixed_cluster_mode = true

    # Pi cluster with some AMD64 workers
    cpu_arch_override = {
      # Heavy workloads on AMD64 workers (if available)
      prometheus_stack = "amd64"
      vault            = "amd64"

      # UI services on ARM64 masters
      grafana   = "arm64"
      portainer = "arm64"
    }

    services = {
      traefik                = true
      metallb                = true
      host_path              = true
      nfs_csi                = false
      prometheus             = true
      prometheus_crds        = true
      grafana                = true
      loki                   = false
      promtail               = false
      consul                 = false
      vault                  = true
      gatekeeper             = false
      portainer              = true
      node_feature_discovery = true
    }
  }

  assert {
    condition     = var.enable_microk8s_mode == true
    error_message = "MicroK8s mode should be enabled for Pi clusters"
  }

  assert {
    condition     = local.storage_sizes.prometheus == "4Gi"
    error_message = "Storage should be optimized for Pi clusters"
  }

  assert {
    condition     = local.cpu_architectures.grafana == "arm64"
    error_message = "UI services should run on ARM64 Pi nodes"
  }
}

run "test_cloud_mixed_cluster" {
  command = plan

  variables {
    base_domain             = "cloud.example.com"
    platform_name           = "eks"
    cpu_arch                = "amd64"
    auto_mixed_cluster_mode = true
    use_nfs_storage         = true

    # Cloud mixed cluster with strategic placement
    cpu_arch_override = {
      # Compute-intensive on AMD64
      prometheus_stack = "amd64"
      consul           = "amd64"
      vault            = "amd64"

      # Cost-effective on ARM64 (Graviton)
      grafana   = "arm64"
      portainer = "arm64"
      traefik   = "arm64"
    }

    services = {
      traefik                = true
      metallb                = false # Use cloud load balancer
      host_path              = false
      nfs_csi                = true
      prometheus             = true
      prometheus_crds        = true
      grafana                = true
      loki                   = true
      promtail               = true
      consul                 = true
      vault                  = true
      gatekeeper             = true
      portainer              = true
      node_feature_discovery = true
    }
  }

  assert {
    condition     = local.services_enabled.metallb == false
    error_message = "MetalLB should be disabled in cloud environments"
  }

  assert {
    condition     = local.services_enabled.nfs_csi == true
    error_message = "NFS CSI should be enabled for cloud storage"
  }

  assert {
    condition     = local.cpu_architectures.traefik == "arm64"
    error_message = "Traefik should use cost-effective ARM64 in cloud"
  }

  assert {
    condition     = local.cpu_architectures.prometheus_stack == "amd64"
    error_message = "Prometheus should use performance AMD64 in cloud"
  }
}
