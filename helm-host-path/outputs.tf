output "namespace" {
  description = "The namespace where the host path provisioner is deployed"
  value       = local.helm_config.namespace
}

output "helm_release" {
  description = "Helm release information"
  value = {
    name      = helm_release.this.name
    namespace = helm_release.this.namespace
    version   = helm_release.this.version
    status    = helm_release.this.status
  }
}

output "storage_configuration" {
  description = "Storage configuration details"
  value = {
    set_as_default                = local.storage_config.set_as_default_storage_class
    let_helm_create_storage_class = local.storage_config.let_helm_create_storage_class
    quota_limit                   = local.limit_range_config.hostpath_max_storage
    pvc_max_storage               = local.limit_range_config.pvc_max_storage
    pvc_min_storage               = local.limit_range_config.pvc_min_storage
  }
}

output "resource_limits" {
  description = "Resource limit configuration"
  value = {
    enabled = local.limit_range_config.enabled
    limits = {
      cpu    = local.resource_config.limits.cpu
      memory = local.resource_config.limits.memory
    }
    requests = {
      cpu    = local.resource_config.requests.cpu
      memory = local.resource_config.requests.memory
    }
    max_limits = {
      cpu    = local.limit_range_config.container_max_cpu
      memory = local.limit_range_config.container_max_memory
    }
  }
}
