# ============================================================================
# Terraform Regression Testing Scenarios
# ============================================================================
#
# Comprehensive scenario tests for different deployment configurations
# Run with: terraform test -filter=test-scenarios.tftest.hcl or make test-scenarios
#
# Test Coverage:
# - ARM64-only cluster (Raspberry Pi)
# - AMD64-only cluster (x86)
# - Mixed architecture cluster
# - MicroK8s-only deployment
# - Cloud-native deployment
# - NFS storage scenarios
# - HostPath storage scenarios
# - Production vs Development configs
# - High availability scenarios
# - Resource constraint scenarios
#
# ============================================================================

# ============================================================================
# ARCHITECTURE-SPECIFIC SCENARIOS
# ============================================================================

# Scenario 1: ARM64 Raspberry Pi cluster
run "test_raspberry_pi_cluster" {
  command = plan

  variables {
    cpu_arch                = "arm64"
    auto_mixed_cluster_mode = false
    enable_microk8s_mode    = true
    use_hostpath_storage    = true
    enable_nfs_csi          = false

    # Raspberry Pi specific optimizations
    container_max_cpu    = "500m"
    container_max_memory = "512Mi"
    default_helm_timeout = 600
  }

  assert {
    condition     = local.cpu_arch == "arm64"
    error_message = "Should use ARM64 architecture for Raspberry Pi"
  }

  assert {
    condition     = local.cpu_architectures.traefik == "arm64"
    error_message = "Traefik should use ARM64 architecture"
  }

  assert {
    condition     = local.cpu_architectures.prometheus == "arm64"
    error_message = "Prometheus should use ARM64 architecture"
  }

  assert {
    condition     = local.storage_classes.default == "hostpath"
    error_message = "Should use hostpath storage for Raspberry Pi cluster"
  }

  assert {
    condition     = local.enabled_services.metallb == true
    error_message = "MetalLB should be enabled for load balancing"
  }
}

# Scenario 2: AMD64 cloud cluster
run "test_amd64_cloud_cluster" {
  command = plan

  variables {
    cpu_arch                = "amd64"
    auto_mixed_cluster_mode = false
    enable_microk8s_mode    = false
    use_nfs_storage         = true
    enable_nfs_csi          = true
    nfs_server              = "nfs.internal.cloud"
    nfs_path                = "/data/k8s"

    # Cloud-optimized settings
    container_max_cpu    = "2000m"
    container_max_memory = "4Gi"
    default_helm_timeout = 300
  }

  assert {
    condition     = local.cpu_arch == "amd64"
    error_message = "Should use AMD64 architecture for cloud cluster"
  }

  assert {
    condition     = local.cpu_architectures.vault == "amd64"
    error_message = "Vault should use AMD64 architecture"
  }

  assert {
    condition     = local.storage_classes.default == "nfs-csi"
    error_message = "Should use NFS storage for cloud cluster"
  }

  assert {
    condition     = local.storage_classes.fast == "nfs-csi-fast"
    error_message = "Should have fast NFS storage class"
  }
}

# Scenario 3: Mixed architecture cluster
run "test_mixed_arch_cluster" {
  command = plan

  variables {
    cpu_arch                = ""
    auto_mixed_cluster_mode = true
    cpu_arch_override = {
      traefik    = "amd64"
      prometheus = "amd64"
      grafana    = "amd64"
      portainer  = "arm64"
      consul     = "arm64"
      vault      = "amd64"
    }
    disable_arch_scheduling_override = {
      metallb = true
      nfs_csi = true
    }
  }

  assert {
    condition     = local.cpu_architectures.traefik == "amd64"
    error_message = "Traefik should use overridden AMD64 architecture"
  }

  assert {
    condition     = local.cpu_architectures.portainer == "arm64"
    error_message = "Portainer should use overridden ARM64 architecture"
  }

  assert {
    condition     = local.final_disable_arch_scheduling.metallb == true
    error_message = "MetalLB should have arch scheduling disabled for mixed cluster"
  }

  assert {
    condition     = local.final_disable_arch_scheduling.nfs_csi == true
    error_message = "NFS CSI should have arch scheduling disabled"
  }
}

# ============================================================================
# CLUSTER TYPE SCENARIOS
# ============================================================================

# Scenario 4: MicroK8s-only deployment
run "test_microk8s_only_deployment" {
  command = plan

  variables {
    enable_microk8s_mode = true
    enable_metallb       = false
    enable_nfs_csi       = false
    use_hostpath_storage = true
    enable_host_path     = true
    enable_traefik       = true

    # MicroK8s typically single-node
    enable_gatekeeper = false
    enable_consul     = true
    disable_arch_scheduling_override = {
      consul = true
      vault  = true
    }
  }

  assert {
    condition     = local.enabled_services.traefik == true
    error_message = "Traefik should be enabled for MicroK8s ingress"
  }

  assert {
    condition     = local.enabled_services.metallb == false
    error_message = "MetalLB should be disabled for MicroK8s (uses built-in LB)"
  }

  assert {
    condition     = local.storage_classes.default == "hostpath"
    error_message = "Should use hostpath storage for MicroK8s"
  }

  assert {
    condition     = local.final_disable_arch_scheduling.consul == true
    error_message = "Consul should disable arch scheduling for single-node"
  }
}

# Scenario 5: Cloud-native deployment
run "test_cloud_native_deployment" {
  command = plan

  variables {
    enable_microk8s_mode = false
    enable_metallb       = true
    enable_nfs_csi       = true
    use_nfs_storage      = true
    nfs_server           = "10.0.0.100"
    nfs_path             = "/shared/kubernetes"

    # Cloud-native features
    enable_gatekeeper      = true
    enable_prometheus      = true
    enable_prometheus_crds = true
    enable_grafana         = true
    enable_loki            = true
    enable_vault           = true
    enable_consul          = true

    # High availability
    vault_ha_replicas = 3
    consul_replicas   = 3
  }

  assert {
    condition     = local.enabled_services.metallb == true
    error_message = "MetalLB should be enabled for cloud-native LB"
  }

  assert {
    condition     = local.enabled_services.gatekeeper == true
    error_message = "Gatekeeper should be enabled for policy enforcement"
  }

  assert {
    condition     = local.storage_classes.safe == "nfs-csi-safe"
    error_message = "Should have safe NFS storage for HA workloads"
  }

  assert {
    condition     = local.enabled_services.vault == true && local.enabled_services.consul == true
    error_message = "Vault and Consul should be enabled for secrets management"
  }
}

# ============================================================================
# STORAGE SCENARIOS
# ============================================================================

# Scenario 6: NFS storage with multiple classes
run "test_nfs_storage_comprehensive" {
  command = plan

  variables {
    use_nfs_storage = true
    enable_nfs_csi  = true
    nfs_server      = "192.168.1.100"
    nfs_path        = "/mnt/k8s"

    # NFS optimization parameters
    nfs_timeout_default = 600
    nfs_timeout_fast    = 150
    nfs_timeout_safe    = 900
    nfs_retrans_default = 2
    nfs_retrans_fast    = 3
    nfs_retrans_safe    = 5

    # Storage classes for different workloads
    prometheus_storage_class = "nfs-csi-safe"
    grafana_storage_class    = "nfs-csi"
    vault_storage_class      = "nfs-csi-safe"
  }

  assert {
    condition     = local.primary_storage_class == "nfs-csi"
    error_message = "Should use NFS as primary storage"
  }

  assert {
    condition     = local.storage_classes.fast == "nfs-csi-fast"
    error_message = "Should have fast NFS storage class"
  }

  assert {
    condition     = local.storage_classes.safe == "nfs-csi-safe"
    error_message = "Should have safe NFS storage class"
  }

  assert {
    condition     = var.nfs_timeout_fast < var.nfs_timeout_default
    error_message = "Fast timeout should be less than default"
  }

  assert {
    condition     = var.nfs_timeout_safe > var.nfs_timeout_default
    error_message = "Safe timeout should be greater than default"
  }
}

# Scenario 7: HostPath storage fallback
run "test_hostpath_storage_fallback" {
  command = plan

  variables {
    use_nfs_storage      = false
    enable_nfs_csi       = false
    use_hostpath_storage = true
    enable_host_path     = true

    # HostPath specific settings
    hostpath_storage_path = "/opt/k8s-storage"
    container_max_cpu     = "1000m"
    container_max_memory  = "2Gi"
  }

  assert {
    condition     = local.primary_storage_class == "hostpath"
    error_message = "Should fallback to hostpath storage"
  }

  assert {
    condition     = local.storage_classes.default == "hostpath"
    error_message = "All storage classes should fallback to hostpath"
  }

  assert {
    condition     = local.storage_classes.fast == "hostpath"
    error_message = "Fast storage should fallback to hostpath"
  }

  assert {
    condition     = local.storage_classes.safe == "hostpath"
    error_message = "Safe storage should fallback to hostpath"
  }
}

# ============================================================================
# ENVIRONMENT-SPECIFIC SCENARIOS
# ============================================================================

# Scenario 8: Development environment
run "test_development_environment" {
  command = plan

  variables {
    platform_name = "dev"
    domain_name   = ".dev.local"

    # Development optimizations
    enable_gatekeeper = false
    enable_prometheus = true
    enable_grafana    = true
    enable_loki       = false
    enable_vault      = false
    enable_consul     = true

    # Relaxed resource limits
    container_max_cpu    = "2000m"
    container_max_memory = "4Gi"
    default_helm_timeout = 600

    # Development storage
    use_hostpath_storage = true
    enable_host_path     = true
  }

  assert {
    condition     = local.enabled_services.gatekeeper == false
    error_message = "Gatekeeper should be disabled in development"
  }

  assert {
    condition     = local.enabled_services.vault == false
    error_message = "Vault should be disabled in development for simplicity"
  }

  assert {
    condition     = local.enabled_services.grafana == true
    error_message = "Grafana should be enabled for development monitoring"
  }

  assert {
    condition     = contains(split(".", local.full_domain_name), "dev")
    error_message = "Domain should include development platform name"
  }
}

# Scenario 9: Production environment
run "test_production_environment" {
  command = plan

  variables {
    platform_name = "prod"
    domain_name   = ".company.com"

    # Production services
    enable_gatekeeper      = true
    enable_prometheus      = true
    enable_prometheus_crds = true
    enable_grafana         = true
    enable_loki            = true
    enable_promtail        = true
    enable_vault           = true
    enable_consul          = true

    # Production hardening
    container_max_cpu    = "1000m"
    container_max_memory = "2Gi"

    # Production storage
    use_nfs_storage = true
    enable_nfs_csi  = true
    nfs_server      = "prod-nfs.company.com"
    nfs_path        = "/data/prod-k8s"

    # Security settings
    traefik_cert_resolver = "letsencrypt"
  }

  assert {
    condition     = local.enabled_services.gatekeeper == true
    error_message = "Gatekeeper should be enabled in production for security"
  }

  assert {
    condition     = local.enabled_services.vault == true
    error_message = "Vault should be enabled in production for secrets"
  }

  assert {
    condition     = local.enabled_services.loki == true
    error_message = "Loki should be enabled in production for log aggregation"
  }

  assert {
    condition     = local.cert_resolvers.traefik == "letsencrypt"
    error_message = "Should use Let's Encrypt for production certificates"
  }

  assert {
    condition     = local.storage_classes.default == "nfs-csi"
    error_message = "Should use NFS storage in production"
  }
}

# ============================================================================
# HIGH AVAILABILITY SCENARIOS
# ============================================================================

# Scenario 10: High availability setup
run "test_high_availability_setup" {
  command = plan

  variables {
    # HA configuration
    auto_mixed_cluster_mode = true

    # Multiple replicas for stateful services
    consul_replicas   = 3
    vault_ha_replicas = 3

    # HA storage
    use_nfs_storage = true
    enable_nfs_csi  = true
    nfs_server      = "ha-nfs-cluster.internal"
    nfs_path        = "/shared/ha-k8s"

    # HA timeouts
    vault_init_timeout      = "300s"
    vault_readiness_timeout = "120s"
    consul_join_timeout     = "180s"

    # Anti-affinity enabled
    disable_arch_scheduling_override = {}
  }

  assert {
    condition     = local.storage_classes.safe == "nfs-csi-safe"
    error_message = "Should use safe storage classes for HA"
  }

  assert {
    condition     = var.vault_readiness_timeout != ""
    error_message = "Should have appropriate readiness timeouts for HA"
  }

  assert {
    condition     = local.enabled_services.consul == true && local.enabled_services.vault == true
    error_message = "Both Consul and Vault should be enabled for HA secrets management"
  }
}

# ============================================================================
# RESOURCE CONSTRAINT SCENARIOS
# ============================================================================

# Scenario 11: Resource constrained environment
run "test_resource_constrained_environment" {
  command = plan

  variables {
    # Minimal resource limits
    container_max_cpu    = "200m"
    container_max_memory = "256Mi"
    pvc_max_storage      = "5Gi"

    # Minimal services
    enable_gatekeeper = false
    enable_prometheus = true
    enable_grafana    = false
    enable_loki       = false
    enable_promtail   = false
    enable_vault      = false
    enable_consul     = true

    # Fast timeouts for resource efficiency
    default_helm_timeout = 180
    vault_init_timeout   = "60s"
    healthcheck_interval = "60s"

    # Local storage
    use_hostpath_storage = true
    enable_host_path     = true
  }

  assert {
    condition     = var.container_max_cpu == "200m"
    error_message = "Should use minimal CPU limits for constrained environment"
  }

  assert {
    condition     = var.container_max_memory == "256Mi"
    error_message = "Should use minimal memory limits for constrained environment"
  }

  assert {
    condition     = local.enabled_services.grafana == false
    error_message = "Non-essential services should be disabled in constrained environment"
  }

  assert {
    condition     = local.storage_classes.default == "hostpath"
    error_message = "Should use local storage for resource efficiency"
  }
}

# ============================================================================
# EDGE CASE SCENARIOS
# ============================================================================

# Scenario 12: All services disabled except core
run "test_minimal_core_deployment" {
  command = plan

  variables {
    # Only essential services
    enable_traefik   = true
    enable_metallb   = true
    enable_host_path = true

    # Disable everything else
    enable_prometheus = false
    enable_grafana    = false
    enable_loki       = false
    enable_promtail   = false
    enable_consul     = false
    enable_vault      = false
    enable_gatekeeper = false
    enable_portainer  = false
    enable_nfs_csi    = false
  }

  assert {
    condition     = local.enabled_services.traefik == true
    error_message = "Traefik should be enabled for basic ingress"
  }

  assert {
    condition     = local.enabled_services.metallb == true
    error_message = "MetalLB should be enabled for load balancing"
  }

  assert {
    condition     = local.enabled_services.consul == false
    error_message = "Non-essential services should be disabled"
  }

  assert {
    condition     = local.enabled_services.grafana == false
    error_message = "Monitoring should be disabled in minimal deployment"
  }
}

# Scenario 13: Service override conflicts resolution
run "test_service_override_conflicts" {
  command = plan

  variables {
    # Conflicting settings to test resolution
    enable_vault = true
    services = {
      vault = false
    }
    service_overrides = {
      vault = {
        helm_timeout = 900
        helm_replace = false
      }
    }
  }

  assert {
    condition     = local.enabled_services.vault == true
    error_message = "Explicit enable_ variables should take precedence over services map"
  }

  assert {
    condition     = local.helm_configs.vault.timeout == 900
    error_message = "Service overrides should be applied when service is enabled"
  }
}
