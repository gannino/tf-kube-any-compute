# Rook Ceph Module Tests
# Tests for 5-level override hierarchy and configuration logic

# ============================================================================
# OVERRIDE HIERARCHY TESTS
# ============================================================================

run "test_chart_version_amd64_default" {
  command = plan

  variables {
    cpu_arch = "amd64"
  }

  assert {
    condition     = local.chart_version == "v1.17.5"
    error_message = "AMD64 should use v1.17.5 by default"
  }
}

run "test_chart_version_arm64_default" {
  command = plan

  variables {
    cpu_arch = "arm64"
  }

  assert {
    condition     = local.chart_version == "v1.15.7"
    error_message = "ARM64 should use v1.15.7 by default (better compatibility)"
  }
}

run "test_chart_version_explicit_override" {
  command = plan

  variables {
    cpu_arch      = "arm64"
    chart_version = "v1.16.0"
  }

  assert {
    condition     = local.chart_version == "v1.16.0"
    error_message = "Explicit chart_version should override auto-detection"
  }
}

run "test_chart_version_service_override" {
  command = plan

  variables {
    cpu_arch = "arm64"
    service_overrides = {
      chart_version = "v1.17.0"
    }
  }

  assert {
    condition     = local.chart_version == "v1.17.0"
    error_message = "service_overrides.chart_version should have highest priority"
  }
}

# ============================================================================
# RESOURCE CONFIGURATION TESTS
# ============================================================================

run "test_resource_defaults" {
  command = plan

  variables {
    cpu_arch = "amd64"
  }

  assert {
    condition     = local.cpu_limit == "500m"
    error_message = "Default CPU limit should be 500m"
  }

  assert {
    condition     = local.memory_limit == "512Mi"
    error_message = "Default memory limit should be 512Mi"
  }

  assert {
    condition     = local.cpu_request == "250m"
    error_message = "Default CPU request should be 250m"
  }

  assert {
    condition     = local.memory_request == "256Mi"
    error_message = "Default memory request should be 256Mi"
  }
}

run "test_resource_variable_override" {
  command = plan

  variables {
    cpu_arch       = "amd64"
    cpu_limit      = "1000m"
    memory_limit   = "1Gi"
    cpu_request    = "500m"
    memory_request = "512Mi"
  }

  assert {
    condition     = local.cpu_limit == "1000m"
    error_message = "Variable cpu_limit should override default"
  }

  assert {
    condition     = local.memory_limit == "1Gi"
    error_message = "Variable memory_limit should override default"
  }
}

run "test_resource_service_override" {
  command = plan

  variables {
    cpu_arch  = "amd64"
    cpu_limit = "800m"
    service_overrides = {
      cpu_limit = "2000m"
    }
  }

  assert {
    condition     = local.cpu_limit == "2000m"
    error_message = "service_overrides.cpu_limit should have highest priority"
  }
}

# ============================================================================
# CSI CONFIGURATION TESTS
# ============================================================================

run "test_csi_defaults" {
  command = plan

  variables {
    cpu_arch = "amd64"
  }

  assert {
    condition     = local.csi_provisioner_replicas == 1
    error_message = "Default CSI provisioner replicas should be 1"
  }

  assert {
    condition     = local.csi_rbd_provisioner_cpu_limit == "200m"
    error_message = "Default RBD provisioner CPU limit should be 200m"
  }

  assert {
    condition     = local.csi_rbd_plugin_memory_limit == "512Mi"
    error_message = "Default RBD plugin memory limit should be 512Mi"
  }
}

run "test_csi_service_override" {
  command = plan

  variables {
    cpu_arch = "amd64"
    service_overrides = {
      csi = {
        provisioner_replicas      = 2
        rbd_provisioner_cpu_limit = "500m"
        rbd_plugin_memory_limit   = "1Gi"
      }
    }
  }

  assert {
    condition     = local.csi_provisioner_replicas == 2
    error_message = "service_overrides.csi.provisioner_replicas should override default"
  }

  assert {
    condition     = local.csi_rbd_provisioner_cpu_limit == "500m"
    error_message = "service_overrides.csi.rbd_provisioner_cpu_limit should override default"
  }

  assert {
    condition     = local.csi_rbd_plugin_memory_limit == "1Gi"
    error_message = "service_overrides.csi.rbd_plugin_memory_limit should override default"
  }
}

# ============================================================================
# FEATURE TOGGLE TESTS
# ============================================================================

run "test_feature_defaults" {
  command = plan

  variables {
    cpu_arch = "amd64"
  }

  assert {
    condition     = local.enable_ceph_cluster == true
    error_message = "Default enable_ceph_cluster should be true"
  }

  assert {
    condition     = local.enable_dashboard == true
    error_message = "Default enable_dashboard should be true"
  }

  assert {
    condition     = local.enable_ingress == true
    error_message = "Default enable_ingress should be true"
  }

  assert {
    condition     = local.dashboard_ssl == false
    error_message = "Default dashboard_ssl should be false"
  }
}

run "test_feature_service_override" {
  command = plan

  variables {
    cpu_arch = "amd64"
    service_overrides = {
      enable_dashboard = false
      enable_ingress   = false
      dashboard_ssl    = true
    }
  }

  assert {
    condition     = local.enable_dashboard == false
    error_message = "service_overrides.enable_dashboard should override default"
  }

  assert {
    condition     = local.enable_ingress == false
    error_message = "service_overrides.enable_ingress should override default"
  }

  assert {
    condition     = local.dashboard_ssl == true
    error_message = "service_overrides.dashboard_ssl should override default"
  }
}

# ============================================================================
# HELM CONFIGURATION TESTS
# ============================================================================

run "test_helm_timeout_default" {
  command = plan

  variables {
    cpu_arch = "amd64"
  }

  assert {
    condition     = local.helm_timeout == 600
    error_message = "Default helm_timeout should be 600 seconds"
  }
}

run "test_helm_timeout_service_override" {
  command = plan

  variables {
    cpu_arch = "amd64"
    service_overrides = {
      helm_timeout = 900
    }
  }

  assert {
    condition     = local.helm_timeout == 900
    error_message = "service_overrides.helm_timeout should override default"
  }
}

# ============================================================================
# MODULE CONFIGURATION TESTS
# ============================================================================

run "test_module_config_uses_overridden_values" {
  command = plan

  variables {
    cpu_arch = "amd64"
    service_overrides = {
      name      = "custom-rook"
      namespace = "custom-ceph"
    }
  }

  assert {
    condition     = local.module_config.name == "custom-rook"
    error_message = "module_config.name should use overridden value"
  }

  assert {
    condition     = local.module_config.namespace == "custom-ceph"
    error_message = "module_config.namespace should use overridden value"
  }
}

# ============================================================================
# INGRESS CONFIGURATION TESTS
# ============================================================================

run "test_ingress_config_default" {
  command = plan

  variables {
    cpu_arch    = "amd64"
    domain_name = "example.com"
  }

  assert {
    condition     = local.ingress_config.host == "rook-ceph.example.com"
    error_message = "Ingress host should be rook-ceph.{domain_name}"
  }

  assert {
    condition     = local.ingress_config.service_name == "rook-ceph-mgr-dashboard"
    error_message = "Ingress service name should be rook-ceph-mgr-dashboard"
  }

  assert {
    condition     = local.ingress_config.service_port == 8443
    error_message = "Ingress service port should be 8443"
  }
}

run "test_ingress_config_domain_override" {
  command = plan

  variables {
    cpu_arch = "amd64"
    service_overrides = {
      domain_name = "custom.local"
    }
  }

  assert {
    condition     = local.ingress_config.host == "rook-ceph.custom.local"
    error_message = "Ingress host should use overridden domain_name"
  }
}
