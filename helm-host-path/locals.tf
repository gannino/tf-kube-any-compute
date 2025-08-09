locals {
  # Module configuration
  module_config = {
    component = "storage-provisioner"
    name      = var.name
    namespace = var.namespace
  }

  # Helm configuration
  helm_config = {
    name       = var.name
    chart      = var.chart_name
    repository = var.chart_repo
    version    = var.chart_version
    namespace  = kubernetes_namespace.this.metadata[0].name
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

  # Storage configuration for host path provisioner
  storage_config = {
    set_as_default_storage_class  = var.set_as_default_storage_class
    let_helm_create_storage_class = var.let_helm_create_storage_class
  }

  # Common labels following Kubernetes recommended labels
  common_labels = merge(var.service_overrides.labels, {
    "app.kubernetes.io/name"       = local.module_config.name
    "app.kubernetes.io/component"  = local.module_config.component
    "app.kubernetes.io/part-of"    = "infrastructure"
    "app.kubernetes.io/managed-by" = "terraform"
  })

  # Template values for the Helm chart
  template_values = {
    namespace                    = local.module_config.namespace
    set_as_default_storage_class = local.storage_config.set_as_default_storage_class
    cpu_limit                    = local.resource_config.limits.cpu
    memory_limit                 = local.resource_config.limits.memory
    cpu_request                  = local.resource_config.requests.cpu
    memory_request               = local.resource_config.requests.memory
  }

  # Limit Range configuration using actual variable values
  limit_range_config = {
    enabled              = var.limit_range_enabled
    container_max_cpu    = var.limit_range_container_max_cpu != null ? var.limit_range_container_max_cpu : var.cpu_limit
    container_max_memory = var.limit_range_container_max_memory != null ? var.limit_range_container_max_memory : var.memory_limit
    pvc_max_storage      = var.limit_range_pvc_max_storage
    pvc_min_storage      = var.limit_range_pvc_min_storage
    hostpath_max_storage = var.hostpath_storage_quota_limit
  }
}
