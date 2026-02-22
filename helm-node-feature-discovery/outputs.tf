# ============================================================================
# HELM-NODE-FEATURE-DISCOVERY MODULE - OUTPUTS
# ============================================================================

output "namespace" {
  description = "Kubernetes namespace where Node Feature Discovery is deployed"
  value       = kubernetes_namespace.this.metadata[0].name
}

output "name" {
  description = "Name of the Node Feature Discovery deployment"
  value       = local.module_config.name
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

output "chart_version" {
  description = "Helm chart version deployed"
  value       = local.module_config.chart_version
}

output "cpu_arch" {
  description = "CPU architecture for node scheduling"
  value       = local.module_config.cpu_arch
}

output "resource_limits" {
  description = "Resource limits applied to Node Feature Discovery"
  value = {
    cpu    = local.module_config.cpu_limit
    memory = local.module_config.memory_limit
  }
}

output "resource_requests" {
  description = "Resource requests applied to Node Feature Discovery"
  value = {
    cpu    = local.module_config.cpu_request
    memory = local.module_config.memory_request
  }
}
