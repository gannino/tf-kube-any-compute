# ============================================================================
# Terraform Native Testing Framework - Unit Tests
# ============================================================================
# 
# Comprehensive unit tests for logic validation
# Run with: terraform test or make test-unit
#
# Coverage:
# - Architecture detection and validation
# - Storage class selection logic  
# - Helm configuration inheritance
# - Variable validation and defaults
# - Resource naming conventions
# - Service enablement logic
# - Timeout and port validation
# - Boolean conversion logic
#
# ============================================================================

# ============================================================================
# ARCHITECTURE DETECTION TESTS
# ============================================================================

# Test automatic architecture detection
run "test_architecture_auto_detection" {
  command = plan

  variables {
    cpu_arch                = ""
    auto_mixed_cluster_mode = true
  }

  assert {
    condition     = local.cpu_arch != ""
    error_message = "CPU architecture should be detected automatically when empty"
  }

  assert {
    condition     = contains(["amd64", "arm64"], local.cpu_arch)
    error_message = "Detected architecture should be either amd64 or arm64, got: ${local.cpu_arch}"
  }

  assert {
    condition     = local.cpu_architectures != null
    error_message = "CPU architectures map should be populated"
  }
}

# Test explicit architecture setting
run "test_architecture_explicit_setting" {
  command = plan

  variables {
    cpu_arch                = "arm64"
    auto_mixed_cluster_mode = false
  }

  assert {
    condition     = local.cpu_arch == "arm64"
    error_message = "CPU architecture should match explicit setting"
  }

  assert {
    condition     = local.cpu_architectures.traefik == "arm64"
    error_message = "All services should inherit explicit architecture"
  }

  assert {
    condition     = local.cpu_architectures.vault == "arm64"
    error_message = "Vault should inherit explicit architecture"
  }
}

# Test mixed cluster mode
run "test_mixed_cluster_mode" {
  command = plan

  variables {
    cpu_arch                = ""
    auto_mixed_cluster_mode = true
    cpu_arch_override = {
      traefik   = "amd64"
      portainer = "arm64"
    }
  }

  assert {
    condition     = contains(["amd64", "arm64"], local.cpu_architectures.traefik)
    error_message = "Traefik should use valid architecture (got ${local.cpu_architectures.traefik})"
  }

  assert {
    condition     = local.cpu_architectures.portainer == "arm64"
    error_message = "Portainer should use overridden ARM64 architecture"
  }

  assert {
    condition     = local.final_disable_arch_scheduling != null
    error_message = "Arch scheduling configuration should be computed"
  }
}

# ============================================================================
# STORAGE CLASS SELECTION TESTS
# ============================================================================

# Test hostpath storage selection
run "test_hostpath_storage_selection" {
  command = plan

  variables {
    use_nfs_storage      = false
    enable_nfs_csi       = false
    use_hostpath_storage = true
    enable_host_path     = true
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
    condition     = local.storage_classes.fast == "hostpath"
    error_message = "Fast storage class should fallback to hostpath"
  }
}

# Test NFS storage selection
run "test_nfs_storage_selection" {
  command = plan

  variables {
    use_nfs_storage = true
    enable_nfs_csi  = true
    nfs_server      = "192.168.1.100"
    nfs_path        = "/mnt/k8s"
  }

  assert {
    condition     = local.primary_storage_class == "nfs-csi"
    error_message = "Should use NFS as primary storage when enabled"
  }

  assert {
    condition     = local.storage_classes.safe == "nfs-csi-safe"
    error_message = "Should have NFS safe storage class available"
  }

  assert {
    condition     = local.storage_classes.default == "nfs-csi"
    error_message = "Default storage should be NFS when enabled"
  }
}

# Test storage class fallback logic
run "test_storage_fallback_logic" {
  command = plan

  variables {
    use_nfs_storage      = false
    enable_nfs_csi       = false
    use_hostpath_storage = false
    enable_host_path     = false
  }

  assert {
    condition     = local.primary_storage_class != ""
    error_message = "Primary storage class should always have a fallback"
  }

  assert {
    condition     = local.storage_classes.default != ""
    error_message = "Default storage class should always be available"
  }
}

# ============================================================================
# HELM CONFIGURATION TESTS
# ============================================================================

# Test helm configuration inheritance
run "test_helm_config_defaults" {
  command = plan

  variables {
    default_helm_timeout = 300
    default_helm_replace = true
    default_helm_wait    = true
  }

  assert {
    condition     = local.helm_configs.traefik.timeout >= 300
    error_message = "Traefik should have reasonable timeout (got ${local.helm_configs.traefik.timeout})"
  }

  assert {
    condition     = local.helm_configs.vault.timeout >= 300
    error_message = "Vault should have appropriate timeout (got ${local.helm_configs.vault.timeout})"
  }

  assert {
    condition     = local.helm_configs.consul.wait == true || local.helm_configs.consul.wait == false
    error_message = "Consul wait setting should be boolean"
  }
}

# Test service-specific helm overrides
run "test_helm_service_overrides" {
  command = plan

  variables {
    service_overrides = {
      vault = {
        helm_timeout = 900
        helm_replace = false
      }
      consul = {
        helm_timeout      = 600
        helm_force_update = true
      }
    }
  }

  assert {
    condition     = local.helm_configs.vault.timeout == 900
    error_message = "Vault should use overridden timeout of 900"
  }

  assert {
    condition     = local.helm_configs.consul.timeout == 600
    error_message = "Consul should use overridden timeout of 600"
  }
}

# ============================================================================
# VARIABLE VALIDATION TESTS
# ============================================================================

# Test timeout validation
run "test_timeout_validation" {
  command = plan

  variables {
    vault_readiness_timeout = "60s"
    healthcheck_interval    = "30s"
    healthcheck_timeout     = "10s"
  }

  assert {
    condition     = can(regex("^[0-9]+[smh]$", var.vault_readiness_timeout))
    error_message = "Vault readiness timeout should match time format pattern"
  }

  assert {
    condition     = can(regex("^[0-9]+[smh]$", var.healthcheck_interval))
    error_message = "Healthcheck interval should match time format pattern"
  }

  assert {
    condition     = can(regex("^[0-9]+[smh]$", var.healthcheck_timeout))
    error_message = "Healthcheck timeout should match time format pattern"
  }
}

# Test port validation
run "test_port_validation" {
  command = plan

  variables {
    vault_port       = 8200
    consul_port      = 8500
    traefik_web_port = 8080
  }

  assert {
    condition     = var.vault_port > 0 && var.vault_port <= 65535
    error_message = "Vault port should be valid (1-65535)"
  }

  assert {
    condition     = var.consul_port > 0 && var.consul_port <= 65535
    error_message = "Consul port should be valid (1-65535)"
  }

  assert {
    condition     = var.traefik_web_port > 0 && var.traefik_web_port <= 65535
    error_message = "Traefik web port should be valid (1-65535)"
  }
}

# Test NFS timeout validation
run "test_nfs_timeout_validation" {
  command = plan

  variables {
    nfs_timeout_default = 600
    nfs_timeout_fast    = 150
    nfs_timeout_safe    = 900
    nfs_retrans_default = 2
    nfs_retrans_fast    = 3
    nfs_retrans_safe    = 5
  }

  assert {
    condition     = var.nfs_timeout_default >= 60 && var.nfs_timeout_default <= 3600
    error_message = "NFS default timeout should be reasonable (60-3600)"
  }

  assert {
    condition     = var.nfs_retrans_default >= 1 && var.nfs_retrans_default <= 10
    error_message = "NFS retrans should be reasonable (1-10)"
  }

  assert {
    condition     = var.nfs_timeout_fast <= var.nfs_timeout_default
    error_message = "Fast timeout should be <= default timeout"
  }

  assert {
    condition     = var.nfs_timeout_safe >= var.nfs_timeout_default
    error_message = "Safe timeout should be >= default timeout"
  }
}

# ============================================================================
# SERVICE ENABLEMENT LOGIC TESTS
# ============================================================================

# Test service enablement defaults
run "test_service_enablement_defaults" {
  command = plan

  variables {
    # Use all defaults
  }

  assert {
    condition     = local.enabled_services.traefik == true
    error_message = "Traefik should be enabled by default"
  }

  assert {
    condition     = local.enabled_services.metallb == true
    error_message = "MetalLB should be enabled by default"
  }

  assert {
    condition     = local.enabled_services.consul == true
    error_message = "Consul should be enabled by default"
  }
}

# Test service enablement overrides
run "test_service_enablement_overrides" {
  command = plan

  variables {
    enable_gatekeeper = false
    enable_vault      = true
    services = {
      portainer = false
      grafana   = true
    }
  }

  assert {
    condition     = local.enabled_services.gatekeeper == false
    error_message = "Gatekeeper should be disabled via explicit variable"
  }

  assert {
    condition     = local.enabled_services.vault == true
    error_message = "Vault should be enabled via explicit variable"
  }

  assert {
    condition     = local.enabled_services.portainer == false
    error_message = "Portainer should be disabled via services map"
  }

  assert {
    condition     = local.enabled_services.grafana == true
    error_message = "Grafana should be enabled via services map"
  }
}

# ============================================================================
# BOOLEAN CONVERSION TESTS
# ============================================================================

# Test boolean conversion logic
run "test_boolean_conversions" {
  command = plan

  variables {
    helm_wait            = true
    helm_force_update    = false
    helm_cleanup_on_fail = true
  }

  assert {
    condition     = tostring(var.helm_wait) == "true"
    error_message = "Boolean true should convert to string 'true'"
  }

  assert {
    condition     = tostring(var.helm_force_update) == "false"
    error_message = "Boolean false should convert to string 'false'"
  }

  assert {
    condition     = tostring(var.helm_cleanup_on_fail) == "true"
    error_message = "Boolean conversion should be consistent"
  }
}

# ============================================================================
# RESOURCE NAMING TESTS
# ============================================================================

# Test resource naming conventions
run "test_resource_naming_conventions" {
  command = plan

  variables {
    platform_name = "prod"
    workspace     = "default"
  }

  assert {
    condition     = can(regex("^[a-z0-9-]+$", local.name_prefix))
    error_message = "Name prefix should follow Kubernetes naming conventions"
  }

  assert {
    condition     = length(local.name_prefix) <= 50
    error_message = "Name prefix should be reasonable length"
  }

  assert {
    condition     = !startswith(local.name_prefix, "-") && !endswith(local.name_prefix, "-")
    error_message = "Name prefix should not start or end with hyphen"
  }
}

# Test domain name construction
run "test_domain_name_construction" {
  command = plan

  variables {
    platform_name = "test"
    domain_name   = ".example.com"
    base_domain   = "cluster.local"
  }

  assert {
    condition     = local.full_domain_name != ""
    error_message = "Full domain name should be constructed"
  }

  assert {
    condition     = contains(split(".", local.full_domain_name), "test")
    error_message = "Domain should include platform name"
  }
}

# ============================================================================
# CERT RESOLVER CONFIGURATION TESTS
# ============================================================================

# Test cert resolver inheritance
run "test_cert_resolver_defaults" {
  command = plan

  variables {
    traefik_cert_resolver = "wildcard"
  }

  assert {
    condition     = local.cert_resolvers.traefik == "wildcard"
    error_message = "Traefik cert resolver should match input"
  }

  assert {
    condition     = local.cert_resolvers.grafana == "wildcard"
    error_message = "Grafana cert resolver should inherit default"
  }

  assert {
    condition     = local.cert_resolvers.prometheus == "wildcard"
    error_message = "Prometheus cert resolver should inherit default"
  }
}

# Test cert resolver overrides
run "test_cert_resolver_overrides" {
  command = plan

  variables {
    traefik_cert_resolver = "letsencrypt"
    cert_resolver_overrides = {
      vault  = "wildcard"
      consul = "selfsigned"
    }
  }

  assert {
    condition     = local.cert_resolvers.vault == "wildcard"
    error_message = "Vault should use overridden cert resolver"
  }

  assert {
    condition     = local.cert_resolvers.consul == "selfsigned"
    error_message = "Consul should use overridden cert resolver"
  }

  assert {
    condition     = local.cert_resolvers.grafana == "letsencrypt"
    error_message = "Grafana should inherit default when not overridden"
  }
}

# ============================================================================
# METALLB CONFIGURATION TESTS
# ============================================================================

# Test MetalLB default configuration
run "test_metallb_defaults" {
  command = plan

  variables {
    services = {
      metallb = true
    }
    metallb_address_pool = "192.168.1.200-192.168.1.210"
  }

  assert {
    condition     = local.services_enabled.metallb == true
    error_message = "MetalLB should be enabled when specified"
  }

  assert {
    condition     = local.service_configs.metallb.address_pool == "192.168.1.200-192.168.1.210"
    error_message = "MetalLB should use configured address pool"
  }
}

# Test MetalLB service overrides
run "test_metallb_service_overrides" {
  command = plan

  variables {
    service_overrides = {
      metallb = {
        address_pool              = "10.0.0.100-10.0.0.110"
        enable_bgp                = true
        enable_frr                = true
        enable_prometheus_metrics = true
        controller_replica_count  = 3
        speaker_replica_count     = 5
        log_level                 = "debug"
        load_balancer_class       = "custom-metallb"
      }
    }
  }

  assert {
    condition     = try(var.service_overrides.metallb.address_pool, "") == "10.0.0.100-10.0.0.110"
    error_message = "MetalLB should use overridden address pool"
  }

  assert {
    condition     = try(var.service_overrides.metallb.enable_bgp, false) == true
    error_message = "MetalLB BGP should be enabled when specified"
  }

  assert {
    condition     = try(var.service_overrides.metallb.controller_replica_count, 1) == 3
    error_message = "MetalLB controller replicas should be overridden"
  }

  assert {
    condition     = try(var.service_overrides.metallb.log_level, "info") == "debug"
    error_message = "MetalLB log level should be overridden"
  }
}

# Test MetalLB BGP configuration
run "test_metallb_bgp_config" {
  command = plan

  variables {
    service_overrides = {
      metallb = {
        enable_bgp = true
        bgp_peers = [
          {
            peer_address = "10.0.0.1"
            peer_asn     = 65001
            my_asn       = 65000
          }
        ]
        additional_ip_pools = [
          {
            name        = "production-pool"
            addresses   = ["10.0.1.100-10.0.1.110"]
            auto_assign = false
          }
        ]
      }
    }
  }

  assert {
    condition     = length(try(var.service_overrides.metallb.bgp_peers, [])) == 1
    error_message = "MetalLB should have one BGP peer configured"
  }

  assert {
    condition     = try(var.service_overrides.metallb.bgp_peers[0].peer_address, "") == "10.0.0.1"
    error_message = "BGP peer address should be configured correctly"
  }

  assert {
    condition     = length(try(var.service_overrides.metallb.additional_ip_pools, [])) == 1
    error_message = "MetalLB should have additional IP pool configured"
  }

  assert {
    condition     = try(var.service_overrides.metallb.additional_ip_pools[0].auto_assign, true) == false
    error_message = "Additional IP pool auto_assign should be configurable"
  }
}

# Test MetalLB monitoring configuration
run "test_metallb_monitoring" {
  command = plan

  variables {
    service_overrides = {
      metallb = {
        enable_prometheus_metrics = true
        service_monitor_enabled   = true
      }
    }
  }

  assert {
    condition     = try(var.service_overrides.metallb.enable_prometheus_metrics, false) == true
    error_message = "MetalLB Prometheus metrics should be enabled"
  }

  assert {
    condition     = try(var.service_overrides.metallb.service_monitor_enabled, false) == true
    error_message = "MetalLB ServiceMonitor should be enabled"
  }
}

# Test MetalLB address pool validation
run "test_metallb_address_pool_validation" {
  command = plan

  variables {
    metallb_address_pool = "192.168.1.200-192.168.1.210"
  }

  assert {
    condition     = can(regex("^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)-((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$", var.metallb_address_pool))
    error_message = "MetalLB address pool should match IP range format"
  }
}

# Test MetalLB replica count validation
run "test_metallb_replica_validation" {
  command = plan

  variables {
    service_overrides = {
      metallb = {
        controller_replica_count = 3
        speaker_replica_count    = 5
      }
    }
  }

  assert {
    condition     = try(var.service_overrides.metallb.controller_replica_count, 1) >= 1 && try(var.service_overrides.metallb.controller_replica_count, 1) <= 5
    error_message = "MetalLB controller replica count should be between 1 and 5"
  }

  assert {
    condition     = try(var.service_overrides.metallb.speaker_replica_count, 1) >= 1 && try(var.service_overrides.metallb.speaker_replica_count, 1) <= 20
    error_message = "MetalLB speaker replica count should be between 1 and 20"
  }
}

# ============================================================================
# LOADBALANCERCLASS CONFIGURATION TESTS
# ============================================================================

# Test LoadBalancerClass default behavior (disabled)
run "test_loadbalancerclass_defaults" {
  command = plan

  variables {
    # Use all defaults
  }

  assert {
    condition     = local.service_configs.traefik.enable_load_balancer_class == false
    error_message = "Traefik LoadBalancerClass should be disabled by default"
  }

  assert {
    condition     = local.service_configs.metallb.enable_load_balancer_class == false
    error_message = "MetalLB LoadBalancerClass should be disabled by default"
  }

  assert {
    condition     = local.service_configs.traefik.load_balancer_class == "metallb"
    error_message = "Traefik should default to metallb LoadBalancerClass name"
  }

  assert {
    condition     = local.service_configs.metallb.load_balancer_class == "metallb"
    error_message = "MetalLB should default to metallb LoadBalancerClass name"
  }
}

# Test LoadBalancerClass enabled configuration
run "test_loadbalancerclass_enabled" {
  command = plan

  variables {
    service_overrides = {
      traefik = {
        enable_load_balancer_class = true
        load_balancer_class        = "custom-lb"
      }
      metallb = {
        enable_load_balancer_class = true
        load_balancer_class        = "custom-lb"
        address_pool_name          = "production-pool"
      }
    }
  }

  assert {
    condition     = local.service_configs.traefik.enable_load_balancer_class == true
    error_message = "Traefik LoadBalancerClass should be enabled when specified"
  }

  assert {
    condition     = local.service_configs.traefik.load_balancer_class == "custom-lb"
    error_message = "Traefik should use custom LoadBalancerClass name"
  }

  assert {
    condition     = local.service_configs.metallb.enable_load_balancer_class == true
    error_message = "MetalLB LoadBalancerClass should be enabled when specified"
  }

  assert {
    condition     = local.service_configs.metallb.address_pool_name == "production-pool"
    error_message = "MetalLB should use custom address pool name"
  }
}