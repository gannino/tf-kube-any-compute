# Storage Configuration Tests
# Tests for NFS/hostpath selection and storage class logic

run "test_nfs_storage_primary" {
  command = plan

  variables {
    base_domain          = "test.local"
    platform_name        = "k3s"
    cpu_arch             = "amd64"
    use_nfs_storage      = true
    use_hostpath_storage = true
    nfs_server_address   = "192.168.1.100"
    nfs_server_path      = "/data/k8s"

    services = {
      traefik                = true
      metallb                = true
      host_path              = true
      nfs_csi                = true
      prometheus             = false
      grafana                = false
      consul                 = false
      vault                  = false
      gatekeeper             = false
      portainer              = false
      loki                   = false
      promtail               = false
      node_feature_discovery = true
      prometheus_crds        = false
    }
  }

  assert {
    condition     = local.primary_storage_class == "nfs-csi"
    error_message = "Primary storage class should be nfs-csi when NFS is enabled"
  }

  assert {
    condition     = local.storage_classes.default == "nfs-csi"
    error_message = "Default storage class should be nfs-csi"
  }

  assert {
    condition     = local.storage_classes.safe == "nfs-csi-safe"
    error_message = "Safe storage class should be nfs-csi-safe"
  }

  assert {
    condition     = local.storage_classes.backup == "hostpath"
    error_message = "Backup storage should always use hostpath"
  }
}

run "test_hostpath_storage_fallback" {
  command = plan

  variables {
    base_domain          = "test.local"
    platform_name        = "k3s"
    cpu_arch             = "amd64"
    use_nfs_storage      = false
    use_hostpath_storage = true

    services = {
      traefik                = true
      metallb                = true
      host_path              = true
      nfs_csi                = false
      prometheus             = false
      grafana                = false
      consul                 = false
      vault                  = false
      gatekeeper             = false
      portainer              = false
      loki                   = false
      promtail               = false
      node_feature_discovery = true
      prometheus_crds        = false
    }
  }

  assert {
    condition     = local.primary_storage_class == "hostpath"
    error_message = "Primary storage class should be hostpath when NFS is disabled"
  }

  assert {
    condition     = local.storage_classes.default == "hostpath"
    error_message = "Default storage class should be hostpath"
  }

  assert {
    condition     = local.storage_classes.safe == "hostpath"
    error_message = "Safe storage class should fallback to hostpath"
  }
}

run "test_storage_class_overrides" {
  command = plan

  variables {
    base_domain          = "test.local"
    platform_name        = "k3s"
    cpu_arch             = "amd64"
    use_nfs_storage      = true
    use_hostpath_storage = true

    storage_class_override = {
      grafana    = "hostpath"
      traefik    = "nfs-csi-fast"
      prometheus = "nfs-csi-safe"
    }

    services = {
      traefik                = true
      metallb                = true
      host_path              = true
      nfs_csi                = true
      prometheus             = true
      grafana                = true
      consul                 = false
      vault                  = false
      gatekeeper             = false
      portainer              = false
      loki                   = false
      promtail               = false
      node_feature_discovery = true
      prometheus_crds        = true
    }
  }

  assert {
    condition     = local.service_configs.grafana.storage_class == "hostpath"
    error_message = "Grafana should use overridden storage class"
  }

  assert {
    condition     = local.service_configs.traefik.storage_class == "nfs-csi-fast"
    error_message = "Traefik should use overridden storage class"
  }

  assert {
    condition     = local.service_configs.prometheus.storage_class == "nfs-csi-safe"
    error_message = "Prometheus should use overridden storage class"
  }
}

run "test_microk8s_storage_sizes" {
  command = plan

  variables {
    base_domain          = "test.local"
    platform_name        = "microk8s"
    cpu_arch             = "arm64"
    enable_microk8s_mode = true
    use_hostpath_storage = true

    services = {
      traefik                = true
      metallb                = true
      host_path              = true
      nfs_csi                = false
      prometheus             = true
      grafana                = true
      consul                 = false
      vault                  = false
      gatekeeper             = false
      portainer              = false
      loki                   = false
      promtail               = false
      node_feature_discovery = true
      prometheus_crds        = true
    }
  }

  assert {
    condition     = local.storage_sizes.prometheus == "4Gi"
    error_message = "Prometheus storage should be reduced for MicroK8s mode"
  }

  assert {
    condition     = local.storage_sizes.grafana == "2Gi"
    error_message = "Grafana storage should be reduced for MicroK8s mode"
  }

  assert {
    condition     = local.storage_sizes.traefik == "128Mi"
    error_message = "Traefik storage should be minimal for MicroK8s mode"
  }
}

run "test_nfs_server_configuration" {
  command = plan

  variables {
    base_domain        = "test.local"
    platform_name      = "k3s"
    cpu_arch           = "amd64"
    use_nfs_storage    = true
    nfs_server_address = "10.0.1.100"
    nfs_server_path    = "/shared/kubernetes"

    services = {
      traefik                = true
      metallb                = true
      host_path              = true
      nfs_csi                = true
      prometheus             = false
      grafana                = false
      consul                 = false
      vault                  = false
      gatekeeper             = false
      portainer              = false
      loki                   = false
      promtail               = false
      node_feature_discovery = true
      prometheus_crds        = false
    }
  }

  assert {
    condition     = local.nfs_server == "10.0.1.100"
    error_message = "NFS server should match configured address"
  }

  assert {
    condition     = local.nfs_path == "/shared/kubernetes"
    error_message = "NFS path should match configured path"
  }
}

run "test_storage_service_overrides" {
  command = plan

  variables {
    base_domain   = "test.local"
    platform_name = "k3s"
    cpu_arch      = "amd64"

    service_overrides = {
      grafana = {
        storage_class = "hostpath"
        storage_size  = "1Gi"
      }
      prometheus = {
        storage_class = "nfs-csi-safe"
        storage_size  = "10Gi"
      }
    }

    services = {
      traefik                = true
      metallb                = true
      host_path              = true
      nfs_csi                = true
      prometheus             = true
      grafana                = true
      consul                 = false
      vault                  = false
      gatekeeper             = false
      portainer              = false
      loki                   = false
      promtail               = false
      node_feature_discovery = true
      prometheus_crds        = true
    }
  }

  assert {
    condition     = local.service_configs.grafana.storage_class == "hostpath"
    error_message = "Grafana should use service override storage class"
  }

  assert {
    condition     = local.service_configs.prometheus.storage_class == "nfs-csi-safe"
    error_message = "Prometheus should use service override storage class"
  }
}
