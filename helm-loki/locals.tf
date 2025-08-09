# ============================================================================
# HELM-LOKI MODULE - STANDARDIZED CONFIGURATION PATTERNS
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

    # Domain configuration
    domain_name = var.domain_name

    # Storage configuration  
    storage_class = var.storage_class
    storage_size  = var.storage_size

    # Feature flags
    enable_ingress = var.enable_ingress

    # Architecture and node selection
    cpu_arch = var.cpu_arch

    # Resource limits
    cpu_limit      = var.cpu_limit
    memory_limit   = var.memory_limit
    cpu_request    = var.cpu_request
    memory_request = var.memory_request

    # Loki specific configuration
    traefik_cert_resolver = var.traefik_cert_resolver
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
    "app.kubernetes.io/component"  = "log-aggregation"
    "app.kubernetes.io/managed-by" = "terraform"
    "app.kubernetes.io/part-of"    = "infrastructure"
  }

  # Template values for Helm chart
  template_values = {
    # Template variables used in loki-values.yaml.tpl
    STORAGE_CLASS  = local.module_config.storage_class
    STORAGE_SIZE   = local.module_config.storage_size
    CPU_ARCH       = local.module_config.cpu_arch
    CPU_LIMIT      = local.module_config.cpu_limit
    MEMORY_LIMIT   = local.module_config.memory_limit
    CPU_REQUEST    = local.module_config.cpu_request
    MEMORY_REQUEST = local.module_config.memory_request
  }
}
