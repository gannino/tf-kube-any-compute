# ============================================================================
# HELM-NODE-FEATURE-DISCOVERY MODULE - STANDARDIZED CONFIGURATION PATTERNS
# ============================================================================
# This module follows the standardized patterns for Task 3:
# - locals for computed values
# - variables for inputs with validation
# - clear conditions for service enablement
# ============================================================================

locals {
  # ============================================================================
  # COMPUTED VALUES - All derived/computed values use locals
  # ============================================================================

  # Module configuration with defaults and overrides
  module_config = {
    # Core settings
    namespace     = var.namespace
    name          = var.name
    chart_name    = var.chart_name
    chart_repo    = var.chart_repo
    chart_version = var.chart_version

    # Architecture and node selection
    cpu_arch = var.cpu_arch

    # Resource limits
    cpu_limit      = var.cpu_limit
    memory_limit   = var.memory_limit
    cpu_request    = var.cpu_request
    memory_request = var.memory_request
  }

  # Helm configuration with validation
  helm_config = {
    timeout          = var.helm_timeout
    disable_webhooks = var.helm_disable_webhooks
    skip_crds        = var.helm_skip_crds
    replace          = var.helm_replace
    force_update     = var.helm_force_update
    cleanup_on_fail  = var.helm_cleanup_on_fail
    wait             = var.helm_wait
    wait_for_jobs    = var.helm_wait_for_jobs
  }

  # Computed labels
  common_labels = {
    "app.kubernetes.io/name"       = local.module_config.name
    "app.kubernetes.io/component"  = "node-feature-discovery"
    "app.kubernetes.io/managed-by" = "terraform"
    "app.kubernetes.io/part-of"    = "infrastructure"
  }

  # Template values for Helm chart
  template_values = {
    # Template variables used in values.yaml.tpl
    cpu_arch                = local.module_config.cpu_arch
    disable_arch_scheduling = var.disable_arch_scheduling
    cpu_limit               = local.module_config.cpu_limit
    memory_limit            = local.module_config.memory_limit
    cpu_request             = local.module_config.cpu_request
    memory_request          = local.module_config.memory_request
  }
}
