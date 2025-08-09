output "namespace" {
  description = "The namespace where Gatekeeper is deployed"
  value       = local.helm_config.namespace
}

output "helm_release" {
  description = "Helm release information"
  value = length(helm_release.this) > 0 ? {
    name      = helm_release.this[0].name
    namespace = helm_release.this[0].namespace
    version   = helm_release.this[0].version
    status    = helm_release.this[0].status
  } : null
}

output "gatekeeper_configuration" {
  description = "Gatekeeper configuration details"
  value = {
    version         = local.gatekeeper_config.version
    enable_policies = local.gatekeeper_config.enable_policies
    crds_ready      = local.crds_ready
    critical_crds   = local.gatekeeper_config.critical_crds
  }
}

output "policy_configuration" {
  description = "Policy configuration details"
  value = {
    enable_hostpath_policy   = local.policy_config.enable_hostpath_policy
    hostpath_max_size        = local.policy_config.hostpath_max_size
    hostpath_storage_class   = local.policy_config.hostpath_storage_class
    enable_security_policies = local.policy_config.enable_security_policies
    enable_resource_policies = local.policy_config.enable_resource_policies
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
