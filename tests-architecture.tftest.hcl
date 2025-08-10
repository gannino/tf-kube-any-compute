# Architecture Detection Tests
# Tests for CPU architecture detection and mixed cluster handling

run "test_architecture_auto_detection" {
  command = plan

  variables {
    base_domain   = "test.local"
    platform_name = "k3s"
    cpu_arch      = "" # Auto-detect
    
    services = {
      traefik                = true
      metallb                = true
      host_path              = true
      prometheus             = false
      grafana                = false
      consul                 = false
      vault                  = false
      gatekeeper             = false
      portainer              = false
      loki                   = false
      promtail               = false
      nfs_csi                = false
      node_feature_discovery = true
      prometheus_crds        = false
    }
  }

  assert {
    condition     = local.cpu_arch != ""
    error_message = "CPU architecture should be auto-detected"
  }

  assert {
    condition     = contains(["amd64", "arm64"], local.cpu_arch)
    error_message = "Detected architecture should be either amd64 or arm64"
  }
}

run "test_architecture_explicit_setting" {
  command = plan

  variables {
    base_domain   = "test.local"
    platform_name = "k3s"
    cpu_arch      = "arm64"
    
    services = {
      traefik                = true
      metallb                = true
      host_path              = true
      prometheus             = false
      grafana                = false
      consul                 = false
      vault                  = false
      gatekeeper             = false
      portainer              = false
      loki                   = false
      promtail               = false
      nfs_csi                = false
      node_feature_discovery = true
      prometheus_crds        = false
    }
  }

  assert {
    condition     = local.cpu_arch == "arm64"
    error_message = "CPU architecture should match explicit setting"
  }

  assert {
    condition     = local.cpu_architectures.traefik == "arm64"
    error_message = "Service architecture should inherit from global setting"
  }
}

run "test_mixed_cluster_mode" {
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
      prometheus             = false
      grafana                = false
      consul                 = false
      vault                  = false
      gatekeeper             = false
      portainer              = false
      loki                   = false
      promtail               = false
      nfs_csi                = false
      node_feature_discovery = true
      prometheus_crds        = false
    }
  }

  assert {
    condition     = var.auto_mixed_cluster_mode == true
    error_message = "Mixed cluster mode should be enabled"
  }

  assert {
    condition     = local.cpu_architectures.metallb == "amd64"
    error_message = "Cluster-wide services should use detected architecture"
  }
}

run "test_architecture_override_per_service" {
  command = plan

  variables {
    base_domain   = "test.local"
    platform_name = "k3s"
    cpu_arch      = "amd64"
    
    cpu_arch_override = {
      traefik = "arm64"
      grafana = "arm64"
    }
    
    services = {
      traefik                = true
      metallb                = true
      host_path              = true
      prometheus             = false
      grafana                = true
      consul                 = false
      vault                  = false
      gatekeeper             = false
      portainer              = false
      loki                   = false
      promtail               = false
      nfs_csi                = false
      node_feature_discovery = true
      prometheus_crds        = false
    }
  }

  assert {
    condition     = local.cpu_architectures.traefik == "arm64"
    error_message = "Traefik should use overridden architecture"
  }

  assert {
    condition     = local.cpu_architectures.grafana == "arm64"
    error_message = "Grafana should use overridden architecture"
  }

  assert {
    condition     = local.cpu_architectures.metallb == "amd64"
    error_message = "MetalLB should use global architecture when not overridden"
  }
}

run "test_ci_mode_architecture_fallback" {
  command = plan

  variables {
    base_domain   = "test.local"
    platform_name = "k3s"
    cpu_arch      = ""
    
    services = {
      traefik                = true
      metallb                = true
      host_path              = true
      prometheus             = false
      grafana                = false
      consul                 = false
      vault                  = false
      gatekeeper             = false
      portainer              = false
      loki                   = false
      promtail               = false
      nfs_csi                = false
      node_feature_discovery = true
      prometheus_crds        = false
    }
  }

  assert {
    condition     = local.ci_mode == true
    error_message = "CI mode should be detected in GitHub Actions"
  }

  assert {
    condition     = local.enable_k8s_node_queries == false
    error_message = "Kubernetes node queries should be disabled in CI mode"
  }

  assert {
    condition     = local.cpu_arch == "amd64"
    error_message = "Should fallback to amd64 when node queries disabled"
  }
}