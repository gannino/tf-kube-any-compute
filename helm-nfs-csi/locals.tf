locals {
  # Module configuration
  module_config = {
    name          = try(var.service_overrides.helm_config.name, var.name)
    namespace     = try(var.service_overrides.helm_config.namespace, var.namespace)
    chart_name    = var.chart_name
    chart_repo    = var.chart_repo
    chart_version = var.chart_version
    component     = "storage-provisioner"
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
      cpu    = try(var.service_overrides.helm_config.resource_limits.requests.cpu, var.cpu_request)
      memory = try(var.service_overrides.helm_config.resource_limits.requests.memory, var.memory_request)
    }
    limits = {
      cpu    = try(var.service_overrides.helm_config.resource_limits.limits.cpu, var.cpu_limit)
      memory = try(var.service_overrides.helm_config.resource_limits.limits.memory, var.memory_limit)
    }
  }

  # Storage configuration
  storage_config = {
    nfs_server                    = var.nfs_server
    nfs_path                      = var.nfs_path
    storage_class                 = var.storage_class
    let_helm_create_storage_class = var.let_helm_create_storage_class
    set_as_default_storage_class  = var.set_as_default_storage_class
    create_fast_storage_class     = var.create_fast_storage_class
    create_safe_storage_class     = var.create_safe_storage_class
  }

  # Limit Range configuration using actual variable values
  limit_range_config = {
    enabled              = var.limit_range_enabled
    container_max_cpu    = var.limit_range_container_max_cpu != null ? var.limit_range_container_max_cpu : var.cpu_limit
    container_max_memory = var.limit_range_container_max_memory != null ? var.limit_range_container_max_memory : var.memory_limit
    pvc_max_storage      = var.limit_range_pvc_max_storage
    pvc_min_storage      = var.limit_range_pvc_min_storage
  }

  # Storage class labels
  storage_class_labels = merge(local.common_labels, {
    "app.kubernetes.io/name"      = "nfs-csi-driver"
    "app.kubernetes.io/component" = "storage-class"
  })

  # Template values for Helm chart
  template_values = merge({
    # Core configuration
    let_helm_create_storage_class = tostring(local.storage_config.let_helm_create_storage_class)
    storage_class                 = local.storage_config.storage_class
    nfs_server                    = local.storage_config.nfs_server
    nfs_path                      = local.storage_config.nfs_path

    # Resource configuration
    cpu_limit      = local.resource_config.limits.cpu
    memory_limit   = local.resource_config.limits.memory
    cpu_request    = local.resource_config.requests.cpu
    memory_request = local.resource_config.requests.memory

    # Architecture and scheduling
    cpu_arch                = var.cpu_arch
    disable_arch_scheduling = var.disable_arch_scheduling
  }, try(var.service_overrides.template_values, {}))
}
