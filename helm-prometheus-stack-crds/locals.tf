locals {
  # Module configuration
  module_config = {
    component = "monitoring-crds"
  }

  # Helm configuration
  helm_config = {
    name          = var.name
    namespace     = var.namespace
    chart         = var.chart_name
    repository    = var.chart_repo
    version       = var.chart_version
    timeout       = var.helm_timeout
    wait          = var.helm_wait
    wait_for_jobs = var.helm_wait_for_jobs
    values_template = templatefile("${path.module}/values.yaml.tpl", {
      cpu_limit      = local.resource_config.limits.cpu
      memory_limit   = local.resource_config.limits.memory
      cpu_request    = local.resource_config.requests.cpu
      memory_request = local.resource_config.requests.memory
    })
  }

  # Standardized labels
  common_labels = {
    "app.kubernetes.io/name"       = var.name
    "app.kubernetes.io/component"  = local.module_config.component
    "app.kubernetes.io/part-of"    = "infrastructure"
    "app.kubernetes.io/managed-by" = "terraform"
  }

  # Resource configuration
  resource_config = {
    limits = {
      cpu    = var.cpu_limit
      memory = var.memory_limit
    }
    requests = {
      cpu    = var.cpu_request
      memory = var.memory_request
    }
  }

  # Limit range configuration
  limit_range_config = {
    enabled              = var.limit_range_enabled
    container_max_cpu    = var.container_max_cpu
    container_max_memory = var.container_max_memory
    pvc_max_storage      = var.pvc_max_storage
    pvc_min_storage      = var.pvc_min_storage
  }

  # CRD-specific configuration
  crd_config = {
    critical_crds = [
      "prometheuses.monitoring.coreos.com",
      "servicemonitors.monitoring.coreos.com",
      "alertmanagers.monitoring.coreos.com",
      "prometheusrules.monitoring.coreos.com"
    ]
    wait_timeout_minutes = var.crd_wait_timeout_minutes
  }

  # Helm configuration options
  helm_options = merge(var.service_overrides, {
    disable_webhooks = var.helm_disable_webhooks
    skip_crds        = var.helm_skip_crds
    replace          = var.helm_replace
    force_update     = var.helm_force_update
    cleanup_on_fail  = var.helm_cleanup_on_fail
  })
}
