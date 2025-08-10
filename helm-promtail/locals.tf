locals {
  # Module configuration
  module_config = {
    name          = try(var.service_overrides.helm_config.name, var.name)
    namespace     = try(var.service_overrides.helm_config.namespace, var.namespace)
    chart_name    = var.chart_name
    chart_repo    = var.chart_repo
    chart_version = var.chart_version
    component     = "log-collector"
  }

  # Helm configuration
  helm_config = {
    disable_webhooks = var.helm_disable_webhooks
    skip_crds        = var.helm_skip_crds
    replace          = var.helm_replace
    force_update     = var.helm_force_update
    cleanup_on_fail  = var.helm_cleanup_on_fail
    timeout          = var.helm_timeout
    wait             = var.helm_wait
    wait_for_jobs    = var.helm_wait_for_jobs
  }

  # Common labels for all resources
  common_labels = merge({
    "app.kubernetes.io/name"       = local.module_config.name
    "app.kubernetes.io/component"  = local.module_config.component
    "app.kubernetes.io/part-of"    = "infrastructure"
    "app.kubernetes.io/managed-by" = "terraform"
  }, try(var.service_overrides.labels, {}))

  # Resource configuration
  resource_config = {
    requests = {
      cpu    = try(var.service_overrides.helm_config.resource_limits.requests.cpu, var.resource_limits.requests.cpu)
      memory = try(var.service_overrides.helm_config.resource_limits.requests.memory, var.resource_limits.requests.memory)
    }
    limits = {
      cpu    = try(var.service_overrides.helm_config.resource_limits.limits.cpu, var.resource_limits.limits.cpu)
      memory = try(var.service_overrides.helm_config.resource_limits.limits.memory, var.resource_limits.limits.memory)
    }
  }

  # Security context configuration
  security_config = {
    run_as_user               = var.security_context.run_as_user
    run_as_group              = var.security_context.run_as_group
    run_as_non_root           = var.security_context.run_as_non_root
    read_only_root_filesystem = var.security_context.read_only_root_filesystem
    privileged                = var.security_context.privileged
  }

  # RBAC configuration
  rbac_config = {
    cluster_role_name         = "${local.module_config.name}-cluster-role"
    cluster_role_binding_name = "${local.module_config.name}-cluster-role-binding"
    service_account_name      = local.module_config.name
  }

  # Limit range configuration
  limit_range_config = {
    enabled = var.limit_range_enabled
    container_defaults = {
      cpu    = var.container_default_cpu
      memory = var.container_default_memory
    }
    container_requests = {
      cpu    = var.container_request_cpu
      memory = var.container_request_memory
    }
    container_limits = {
      cpu    = var.container_max_cpu
      memory = var.container_max_memory
    }
    pvc_limits = {
      max_storage = var.pvc_max_storage
      min_storage = var.pvc_min_storage
    }
  }

  # Template values for Helm chart
  template_values = merge({
    # Core module configuration
    name      = local.module_config.name
    namespace = local.module_config.namespace

    # Loki configuration
    loki_url  = var.loki_url
    log_level = var.log_level

    # Resource configuration
    cpu_request    = local.resource_config.requests.cpu
    memory_request = local.resource_config.requests.memory
    cpu_limit      = local.resource_config.limits.cpu
    memory_limit   = local.resource_config.limits.memory

    # Security context
    read_only_root_filesystem = local.security_config.read_only_root_filesystem
    run_as_non_root           = local.security_config.run_as_non_root
    run_as_user               = local.security_config.run_as_user
    run_as_group              = local.security_config.run_as_group
    privileged                = local.security_config.privileged

    # Legacy support
    cpu_arch = var.cpu_arch

    # Additional configurations
    service_monitor_enabled   = var.service_monitor_enabled
    node_selector             = var.node_selector
    tolerations               = var.tolerations
    affinity                  = var.affinity
    persistence               = var.persistence
    additional_scrape_configs = var.additional_scrape_configs
  }, try(var.service_overrides.template_values, {}))
}
