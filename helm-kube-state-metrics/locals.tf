locals {
  # Module configuration using standardized computed values pattern
  module_config = {
    name      = var.name
    namespace = var.namespace
    component = "kube-state-metrics"

    # Resource limits configuration
    cpu_limit      = var.cpu_limit
    memory_limit   = var.memory_limit
    cpu_request    = var.cpu_request
    memory_request = var.memory_request

    # Deployment configuration
    cpu_arch                = var.cpu_arch
    disable_arch_scheduling = var.disable_arch_scheduling
  }

  # Helm configuration using standardized pattern
  helm_config = {
    name       = local.module_config.name
    chart      = var.chart_name
    repository = var.chart_repo
    version    = var.chart_version
    namespace  = local.module_config.namespace

    # Helm deployment options
    timeout          = var.helm_timeout
    disable_webhooks = var.helm_disable_webhooks
    skip_crds        = var.helm_skip_crds
    replace          = var.helm_replace
    force_update     = var.helm_force_update
    cleanup_on_fail  = var.helm_cleanup_on_fail
    wait             = var.helm_wait
    wait_for_jobs    = var.helm_wait_for_jobs
  }

  # Common labels following app.kubernetes.io standard
  common_labels = {
    "app.kubernetes.io/name"       = local.module_config.name
    "app.kubernetes.io/component"  = local.module_config.component
    "app.kubernetes.io/part-of"    = "infrastructure"
    "app.kubernetes.io/managed-by" = "terraform"
  }

  # Template values for Helm chart configuration
  template_values = {
    CPU_ARCH                = local.module_config.cpu_arch
    CPU_LIMIT               = local.module_config.cpu_limit
    MEMORY_LIMIT            = local.module_config.memory_limit
    CPU_REQUEST             = local.module_config.cpu_request
    MEMORY_REQUEST          = local.module_config.memory_request
    DISABLE_ARCH_SCHEDULING = local.module_config.disable_arch_scheduling
    NAMESPACE               = local.module_config.namespace
    NAME                    = local.module_config.name
  }
}
