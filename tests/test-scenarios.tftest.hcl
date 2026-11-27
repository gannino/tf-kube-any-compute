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
    # Hermetic: terraform test auto-loads terraform.tfvars; pin services so
    # this run is independent of developer configuration (longhorn flips
    # primary_storage_class away from hostpath)
    services = { longhorn = false, metallb = true }
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
    condition     = local.services_enabled.metallb == true
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
    # Hermetic: see test_raspberry_pi_cluster
    services = { longhorn = false }

    # Cloud-optimized settings
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
    # Real variable name is disable_arch_scheduling (map) - the previous
    # key (disable_arch_scheduling_override) was never declared, so the
    # override was silently dropped and the assertions below failed
    disable_arch_scheduling = {
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
    # Hermetic: see test_raspberry_pi_cluster (metallb pinned false to match
    # the assertion below regardless of developer terraform.tfvars)
    services = { longhorn = false, metallb = false }

    # MicroK8s typically single-node
    enable_gatekeeper = false
    enable_consul     = true
    # Real variable name is disable_arch_scheduling (map) - see
    # test_mixed_arch_cluster for why the old key never applied
    disable_arch_scheduling = {
      consul = true
      vault  = true
    }
  }

  assert {
    condition     = local.services_enabled.traefik == true
    error_message = "Traefik should be enabled for MicroK8s ingress"
  }

  assert {
    condition     = local.services_enabled.metallb == false
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

    # Hermetic: see test_raspberry_pi_cluster (also keeps the longhorn
    # module's plan-time data sources from reading a live cluster)
    services = { longhorn = false }
  }

  assert {
    condition     = local.services_enabled.metallb == true
    error_message = "MetalLB should be enabled for cloud-native LB"
  }

  assert {
    condition     = local.services_enabled.gatekeeper == true
    error_message = "Gatekeeper should be enabled for policy enforcement"
  }

  assert {
    condition     = local.storage_classes.safe == "nfs-csi-safe"
    error_message = "Should have safe NFS storage for HA workloads"
  }

  assert {
    condition     = local.services_enabled.vault == true && local.services_enabled.consul == true
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
    # Hermetic: see test_raspberry_pi_cluster
    services = { longhorn = false }
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
}

# Scenario 7: HostPath storage fallback
run "test_hostpath_storage_fallback" {
  command = plan

  variables {
    use_nfs_storage      = false
    enable_nfs_csi       = false
    use_hostpath_storage = true
    enable_host_path     = true

    # Hermetic: see test_raspberry_pi_cluster
    services = { longhorn = false }
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
    # platform_name must be a real platform (enum-validated); the "dev"
    # marker lives in the domain suffix below
    platform_name = "microk8s"
    domain_name   = ".dev.local"

    # Development optimizations
    enable_gatekeeper = false
    enable_prometheus = true
    enable_grafana    = true
    enable_loki       = false
    enable_vault      = false
    enable_consul     = true

    default_helm_timeout = 600

    # Development storage
    use_hostpath_storage = true
    enable_host_path     = true
  }

  assert {
    condition     = local.services_enabled.gatekeeper == false
    error_message = "Gatekeeper should be disabled in development"
  }

  assert {
    condition     = local.services_enabled.vault == false
    error_message = "Vault should be disabled in development for simplicity"
  }

  assert {
    condition     = local.services_enabled.grafana == true
    error_message = "Grafana should be enabled for development monitoring"
  }

  assert {
    condition     = contains(split(".", local.domain), "dev")
    error_message = "Domain should include development platform name"
  }
}

# Scenario 9: Production environment
run "test_production_environment" {
  command = plan

  variables {
    platform_name = "k8s"
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

    # Production storage
    use_nfs_storage = true
    enable_nfs_csi  = true
    nfs_server      = "prod-nfs.company.com"
    nfs_path        = "/data/prod-k8s"

    # Security settings
    traefik_cert_resolver = "letsencrypt"

    # Hermetic: see test_raspberry_pi_cluster
    services = { longhorn = false }
  }

  assert {
    condition     = local.services_enabled.gatekeeper == true
    error_message = "Gatekeeper should be enabled in production for security"
  }

  assert {
    condition     = local.services_enabled.vault == true
    error_message = "Vault should be enabled in production for secrets"
  }

  assert {
    condition     = local.services_enabled.loki == true
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

    # HA storage
    use_nfs_storage = true
    enable_nfs_csi  = true
    nfs_server      = "ha-nfs-cluster.internal"
    nfs_path        = "/shared/ha-k8s"
  }

  assert {
    condition     = local.storage_classes.safe == "nfs-csi-safe"
    error_message = "Should use safe storage classes for HA"
  }

  assert {
    condition     = local.storage_classes.shared == "nfs-csi"
    error_message = "Should use shared NFS storage for HA stateful services"
  }

  assert {
    condition     = local.services_enabled.consul == true && local.services_enabled.vault == true
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
    default_cpu_limit    = "200m"
    default_memory_limit = "256Mi"

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

    # Local storage
    use_hostpath_storage = true
    enable_host_path     = true

    # Hermetic: see test_raspberry_pi_cluster
    services = { longhorn = false }
  }

  assert {
    condition     = var.default_cpu_limit == "200m"
    error_message = "Should use minimal CPU limits for constrained environment"
  }

  assert {
    condition     = var.default_memory_limit == "256Mi"
    error_message = "Should use minimal memory limits for constrained environment"
  }

  assert {
    condition     = local.services_enabled.grafana == false
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
    condition     = local.services_enabled.traefik == true
    error_message = "Traefik should be enabled for basic ingress"
  }

  assert {
    condition     = local.services_enabled.metallb == true
    error_message = "MetalLB should be enabled for load balancing"
  }

  assert {
    condition     = local.services_enabled.consul == false
    error_message = "Non-essential services should be disabled"
  }

  assert {
    condition     = local.services_enabled.grafana == false
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
    condition     = local.services_enabled.vault == true
    error_message = "Explicit enable_ variables should take precedence over services map"
  }

  assert {
    condition     = local.helm_configs.vault.timeout == 900
    error_message = "Service overrides should be applied when service is enabled"
  }
}
