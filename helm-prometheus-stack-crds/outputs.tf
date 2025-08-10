output "namespace" {
  description = "The namespace where the Prometheus CRDs are deployed"
  value       = local.helm_config.namespace
}

output "helm_release" {
  description = "Helm release information"
  value = {
    name      = helm_release.prometheus_crds.name
    namespace = helm_release.prometheus_crds.namespace
    version   = helm_release.prometheus_crds.version
    status    = helm_release.prometheus_crds.status
  }
}

output "crd_configuration" {
  description = "CRD configuration details"
  value = {
    critical_crds        = local.crd_config.critical_crds
    wait_timeout_minutes = local.crd_config.wait_timeout_minutes
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
