# ============================================================================
# HELM-LOKI MODULE - OUTPUTS
# ============================================================================

output "namespace" {
  description = "Kubernetes namespace where Loki is deployed"
  value       = kubernetes_namespace.this.metadata[0].name
}

output "name" {
  description = "Name of the Loki deployment"
  value       = local.module_config.name
}

output "loki_url" {
  description = "Loki service URL for log ingestion"
  value       = "http://${local.module_config.name}.${kubernetes_namespace.this.metadata[0].name}.svc.cluster.local:3100"
}

output "service_host" {
  description = "Loki service hostname (for connection strings)"
  value       = "${local.module_config.name}.${kubernetes_namespace.this.metadata[0].name}.svc.cluster.local"
}

output "service_port" {
  description = "Loki service port"
  value       = 3100
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

output "storage_configuration" {
  description = "Storage configuration for Loki"
  value = {
    storage_class = local.module_config.storage_class
    storage_size  = local.module_config.storage_size
  }
}

output "resource_limits" {
  description = "Resource limits applied to Loki"
  value = {
    cpu    = local.module_config.cpu_limit
    memory = local.module_config.memory_limit
  }
}

output "resource_requests" {
  description = "Resource requests applied to Loki"
  value = {
    cpu    = local.module_config.cpu_request
    memory = local.module_config.memory_request
  }
}
