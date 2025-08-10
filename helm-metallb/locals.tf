# ============================================================================
# HELM-METALLB MODULE - STANDARDIZED CONFIGURATION PATTERNS
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
    name          = var.ingress_gateway_name
    chart_name    = var.ingress_gateway_chart_name
    chart_repo    = var.ingress_gateway_chart_repo
    chart_version = var.ingress_gateway_chart_version

    # Domain configuration
    domain_name = var.domain_name

    # Storage configuration
    persistent_disk_size = var.persistent_disc_size

    # Architecture and node selection
    cpu_arch = var.cpu_arch

    # Resource limits
    cpu_limit      = var.cpu_limit
    memory_limit   = var.memory_limit
    cpu_request    = var.cpu_request
    memory_request = var.memory_request

    # MetalLB specific configuration
    address_pool             = var.address_pool
    controller_replica_count = var.controller_replica_count
    speaker_replica_count    = var.speaker_replica_count

    # Advanced MetalLB features
    enable_bgp                 = var.enable_bgp
    bgp_peers                  = var.bgp_peers
    enable_frr                 = var.enable_frr
    enable_load_balancer_class = var.enable_load_balancer_class
    load_balancer_class        = var.load_balancer_class
    enable_prometheus_metrics  = var.enable_prometheus_metrics
    service_monitor_enabled    = var.service_monitor_enabled
    log_level                  = var.log_level
    additional_ip_pools        = var.additional_ip_pools
    address_pool_name          = var.address_pool_name
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
    "app.kubernetes.io/component"  = "load-balancer"
    "app.kubernetes.io/managed-by" = "terraform"
    "app.kubernetes.io/part-of"    = "infrastructure"
  }

  # Template values for Helm chart
  template_values = {
    # Template variables used in metallb-values.yaml.tpl
    controller_replica_count = local.module_config.controller_replica_count
    speaker_replica_count    = local.module_config.speaker_replica_count
    cpu_arch                 = local.module_config.cpu_arch
    disable_arch_scheduling  = var.disable_arch_scheduling
    cpu_limit                = local.module_config.cpu_limit
    memory_limit             = local.module_config.memory_limit
    cpu_request              = local.module_config.cpu_request
    memory_request           = local.module_config.memory_request
    workspace                = var.workspace
    le_email                 = var.le_email
    namespace                = local.module_config.namespace


    # Advanced MetalLB features
    enable_bgp                 = local.module_config.enable_bgp
    enable_frr                 = local.module_config.enable_frr
    log_level                  = local.module_config.log_level
    enable_load_balancer_class = local.module_config.enable_load_balancer_class
    load_balancer_class        = local.module_config.load_balancer_class
    enable_prometheus_metrics  = local.module_config.enable_prometheus_metrics
    service_monitor_enabled    = local.module_config.service_monitor_enabled
  }

  # MetalLB Helm values (preserving existing logic)
  metallb_values = templatefile("${path.module}/templates/metallb-values.yaml.tpl", local.template_values)
}
