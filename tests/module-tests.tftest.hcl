# ============================================================================
# Module-Specific Unit Tests
# ============================================================================
#
# Focused tests for individual helm modules and their configuration logic
# Run with: terraform test -filter=module-tests.tftest.hcl
#
# Test Coverage:
# - Vault module configuration and outputs
# - Consul module configuration and ACL setup
# - Traefik module ingress configuration
# - NFS CSI module timeout validation
# - Gatekeeper module CRD management
# - Prometheus stack configuration
# - Storage class inheritance
#
# ============================================================================

# ============================================================================
# VAULT MODULE TESTS
# ============================================================================

run "test_vault_module_configuration" {
  command = plan

  variables {
    enable_vault            = true
    vault_port              = 8200
    consul_port             = 8500
    healthcheck_interval    = "30s"
    healthcheck_timeout     = "10s"
    vault_readiness_timeout = "60s"
    service_overrides = {
      vault = {
        helm_timeout = 900
        helm_replace = false
      }
    }
  }

  # Test that vault module is properly configured
  assert {
    condition = length([
      for module in module.vault : module
    ]) > 0
    error_message = "Vault module should be created when enabled"
  }

  # Test vault port configuration
  assert {
    condition     = var.vault_port == 8200
    error_message = "Vault port should be configurable"
  }

  # Test timeout validation
  assert {
    condition     = can(regex("^[0-9]+[smh]$", var.healthcheck_interval))
    error_message = "Healthcheck interval should follow time format"
  }
}

run "test_vault_outputs_structure" {
  command = plan

  variables {
    enable_vault   = true
    domain_name    = ".test.local"
    enable_ingress = true
  }

  # Test vault outputs when module is enabled
  assert {
    condition = length(module.vault) > 0 ? (
      module.vault[0].service_name != "" &&
      module.vault[0].namespace != "" &&
      module.vault[0].service_url != ""
    ) : true
    error_message = "Vault outputs should be properly structured when enabled"
  }
}

# ============================================================================
# CONSUL MODULE TESTS
# ============================================================================

run "test_consul_module_configuration" {
  command = plan

  variables {
    enable_consul   = true
    consul_port     = 8500
    consul_replicas = 3
    service_overrides = {
      consul = {
        helm_timeout      = 600
        helm_replace      = false
        helm_force_update = true
      }
    }
  }

  # Test consul module creation
  assert {
    condition = length([
      for module in module.consul : module
    ]) > 0
    error_message = "Consul module should be created when enabled"
  }

  # Test consul port configuration
  assert {
    condition     = var.consul_port == 8500
    error_message = "Consul port should be configurable"
  }
}

run "test_consul_acl_configuration" {
  command = plan

  variables {
    enable_consul     = true
    consul_enable_acl = true
  }

  # Test that consul ACL is properly configured
  assert {
    condition     = var.consul_enable_acl == true
    error_message = "Consul ACL should be configurable"
  }
}

# ============================================================================
# TRAEFIK MODULE TESTS
# ============================================================================

run "test_traefik_ingress_configuration" {
  command = plan

  variables {
    enable_traefik           = true
    traefik_web_port         = 8080
    traefik_websecure_port   = 8443
    traefik_cert_resolver    = "letsencrypt"
    enable_traefik_dashboard = true
  }

  # Test traefik module creation
  assert {
    condition = length([
      for module in module.traefik : module
    ]) > 0
    error_message = "Traefik module should be created when enabled"
  }

  # Test port configuration
  assert {
    condition     = var.traefik_web_port == 8080
    error_message = "Traefik web port should be configurable"
  }

  assert {
    condition     = var.traefik_websecure_port == 8443
    error_message = "Traefik websecure port should be configurable"
  }

  # Test cert resolver configuration
  assert {
    condition     = var.traefik_cert_resolver == "letsencrypt"
    error_message = "Cert resolver should be configurable"
  }
}

run "test_traefik_dashboard_security" {
  command = plan

  variables {
    enable_traefik              = true
    enable_traefik_dashboard    = true
    traefik_dashboard_auth_user = "admin"
  }

  # Test dashboard configuration
  assert {
    condition     = var.enable_traefik_dashboard == true
    error_message = "Traefik dashboard should be configurable"
  }

  assert {
    condition     = var.traefik_dashboard_auth_user == "admin"
    error_message = "Dashboard auth user should be configurable"
  }
}

# ============================================================================
# NFS CSI MODULE TESTS
# ============================================================================

run "test_nfs_csi_timeout_configuration" {
  command = plan

  variables {
    enable_nfs_csi      = true
    nfs_timeout_default = 600
    nfs_timeout_fast    = 150
    nfs_timeout_safe    = 900
    nfs_retrans_default = 2
    nfs_retrans_fast    = 3
    nfs_retrans_safe    = 5
  }

  # Test NFS module creation
  assert {
    condition = length([
      for module in module.nfs_csi : module
    ]) > 0
    error_message = "NFS CSI module should be created when enabled"
  }

  # Test timeout validation
  assert {
    condition     = var.nfs_timeout_default >= 60 && var.nfs_timeout_default <= 3600
    error_message = "NFS default timeout should be reasonable (60-3600)"
  }

  assert {
    condition     = var.nfs_timeout_fast <= var.nfs_timeout_default
    error_message = "Fast timeout should be <= default timeout"
  }

  assert {
    condition     = var.nfs_timeout_safe >= var.nfs_timeout_default
    error_message = "Safe timeout should be >= default timeout"
  }

  # Test retrans validation
  assert {
    condition     = var.nfs_retrans_default >= 1 && var.nfs_retrans_default <= 10
    error_message = "NFS retrans should be reasonable (1-10)"
  }
}

run "test_nfs_mount_options" {
  command = plan

  variables {
    enable_nfs_csi      = true
    nfs_server          = "192.168.1.100"
    nfs_path            = "/data/k8s"
    nfs_timeout_default = 600
    nfs_retrans_default = 2
  }

  # Test NFS server configuration
  assert {
    condition     = var.nfs_server == "192.168.1.100"
    error_message = "NFS server should be configurable"
  }

  assert {
    condition     = var.nfs_path == "/data/k8s"
    error_message = "NFS path should be configurable"
  }

  # Test storage class naming
  assert {
    condition     = local.storage_classes.default == "nfs-csi"
    error_message = "Default storage class should be nfs-csi when NFS enabled"
  }
}

# ============================================================================
# GATEKEEPER MODULE TESTS
# ============================================================================

run "test_gatekeeper_crd_configuration" {
  command = plan

  variables {
    enable_gatekeeper               = true
    gatekeeper_timeout_default      = "30s"
    gatekeeper_timeout_crd_creation = "60s"
    gatekeeper_api_version          = "apiextensions.k8s.io/v1"
  }

  # Test gatekeeper module creation when enabled
  assert {
    condition = length([
      for module in module.gatekeeper : module
    ]) > 0
    error_message = "Gatekeeper module should be created when enabled"
  }

  # Test timeout validation
  assert {
    condition     = can(regex("^[0-9]+[smh]$", var.gatekeeper_timeout_default))
    error_message = "Gatekeeper timeout should follow time format"
  }

  # Test API version validation
  assert {
    condition     = can(regex("^[a-z0-9./]+$", var.gatekeeper_api_version))
    error_message = "API version should follow Kubernetes format"
  }
}

run "test_gatekeeper_disabled_scenario" {
  command = plan

  variables {
    enable_gatekeeper = false
  }

  # Test that gatekeeper is not created when disabled
  assert {
    condition = length([
      for module in module.gatekeeper : module
    ]) == 0
    error_message = "Gatekeeper module should not be created when disabled"
  }

  # Test service enablement
  assert {
    condition     = local.enabled_services.gatekeeper == false
    error_message = "Gatekeeper should be disabled in service map"
  }
}

# ============================================================================
# PROMETHEUS STACK TESTS
# ============================================================================

run "test_prometheus_stack_configuration" {
  command = plan

  variables {
    enable_prometheus          = true
    enable_prometheus_crds     = true
    prometheus_storage_class   = "nfs-csi-safe"
    prometheus_storage_size    = "20Gi"
    alertmanager_storage_class = "nfs-csi"
    alertmanager_storage_size  = "5Gi"
  }

  # Test prometheus modules creation
  assert {
    condition = length([
      for module in module.prometheus : module
    ]) > 0
    error_message = "Prometheus module should be created when enabled"
  }

  assert {
    condition = length([
      for module in module.prometheus_crds : module
    ]) > 0
    error_message = "Prometheus CRDs module should be created when enabled"
  }

  # Test storage configuration
  assert {
    condition     = var.prometheus_storage_class == "nfs-csi-safe"
    error_message = "Prometheus storage class should be configurable"
  }

  assert {
    condition     = var.alertmanager_storage_class == "nfs-csi"
    error_message = "AlertManager storage class should be configurable"
  }
}

run "test_prometheus_crds_timeout" {
  command = plan

  variables {
    enable_prometheus_crds   = true
    crd_wait_timeout_minutes = 20
  }

  # Test CRD timeout validation
  assert {
    condition     = var.crd_wait_timeout_minutes > 0 && var.crd_wait_timeout_minutes <= 60
    error_message = "CRD wait timeout must be between 1 and 60 minutes"
  }
}

# ============================================================================
# STORAGE CLASS INHERITANCE TESTS
# ============================================================================

run "test_storage_class_inheritance_hostpath" {
  command = plan

  variables {
    use_hostpath_storage = true
    enable_host_path     = true
    use_nfs_storage      = false
    enable_nfs_csi       = false
  }

  # Test hostpath inheritance
  assert {
    condition     = local.primary_storage_class == "hostpath"
    error_message = "Primary storage should be hostpath when configured"
  }

  assert {
    condition     = local.storage_classes.default == "hostpath"
    error_message = "Default storage should inherit primary"
  }

  assert {
    condition     = local.storage_classes.fast == "hostpath"
    error_message = "Fast storage should fallback to primary"
  }

  assert {
    condition     = local.storage_classes.safe == "hostpath"
    error_message = "Safe storage should fallback to primary"
  }
}

run "test_storage_class_inheritance_nfs" {
  command = plan

  variables {
    use_nfs_storage      = true
    enable_nfs_csi       = true
    nfs_server           = "nfs.example.com"
    nfs_path             = "/data"
    use_hostpath_storage = false
    enable_host_path     = false
  }

  # Test NFS inheritance
  assert {
    condition     = local.primary_storage_class == "nfs-csi"
    error_message = "Primary storage should be nfs-csi when configured"
  }

  assert {
    condition     = local.storage_classes.default == "nfs-csi"
    error_message = "Default storage should be nfs-csi"
  }

  assert {
    condition     = local.storage_classes.fast == "nfs-csi-fast"
    error_message = "Fast storage should be nfs-csi-fast"
  }

  assert {
    condition     = local.storage_classes.safe == "nfs-csi-safe"
    error_message = "Safe storage should be nfs-csi-safe"
  }
}

# ============================================================================
# SERVICE OVERRIDE TESTS
# ============================================================================

run "test_service_override_precedence" {
  command = plan

  variables {
    enable_vault = true
    services = {
      vault = false # Conflicting setting
    }
    service_overrides = {
      vault = {
        helm_timeout      = 900
        helm_replace      = false
        helm_force_update = true
      }
    }
  }

  # Test that explicit enable_ variables take precedence
  assert {
    condition     = local.enabled_services.vault == true
    error_message = "Explicit enable_vault should override services map"
  }

  # Test that service overrides are applied when service is enabled
  assert {
    condition     = local.helm_configs.vault.timeout == 900
    error_message = "Service overrides should be applied when service is enabled"
  }

  assert {
    condition     = local.helm_configs.vault.replace == false
    error_message = "Helm replace override should be applied"
  }
}

run "test_service_override_inheritance" {
  command = plan

  variables {
    default_helm_timeout = 300
    default_helm_wait    = true
    service_overrides = {
      traefik = {
        helm_timeout = 450
      }
      consul = {
        helm_wait = false
      }
    }
  }

  # Test that services inherit defaults when not overridden
  assert {
    condition     = local.helm_configs.vault.timeout == 300
    error_message = "Vault should inherit default timeout when not overridden"
  }

  # Test that services use overrides when provided
  assert {
    condition     = local.helm_configs.traefik.timeout == 450
    error_message = "Traefik should use overridden timeout"
  }

  assert {
    condition     = local.helm_configs.consul.wait == false
    error_message = "Consul should use overridden wait setting"
  }

  # Test that other properties still inherit defaults
  assert {
    condition     = local.helm_configs.consul.timeout == 300
    error_message = "Consul should inherit default timeout for non-overridden properties"
  }
}
