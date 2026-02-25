# ============================================================================
# Redis Module Outputs
# ============================================================================

output "namespace" {
  description = "Kubernetes namespace where Redis is deployed"
  value       = var.namespace
}

output "release_name" {
  description = "Helm release name"
  value       = var.name
}

output "service_name" {
  description = "Redis service name (for connection strings)"
  value       = "${var.name}.${var.namespace}.svc.cluster.local"
}

output "service_host" {
  description = "Redis service host (for connection strings)"
  value       = "${var.name}.${var.namespace}.svc.cluster.local"
}

output "service_port" {
  description = "Redis service port"
  value       = 6379
}

output "connection_string" {
  description = "Full Redis connection string (host:port)"
  value       = "${var.name}-master.${var.namespace}.svc.cluster.local:6379"
}

output "storage_enabled" {
  description = "Whether persistent storage is enabled"
  value       = var.enable_persistence
}

output "storage_class" {
  description = "Storage class used for PVC"
  value       = var.enable_persistence ? var.storage_class : null
}

output "cpu_arch" {
  description = "CPU architecture for node scheduling"
  value       = var.cpu_arch == "" ? "auto-detect" : var.cpu_arch
}

output "resource_limits" {
  description = "Resource limits applied to Redis"
  value = {
    cpu    = var.cpu_limit
    memory = var.memory_limit
  }
}

output "resource_requests" {
  description = "Resource requests applied to Redis"
  value = {
    cpu    = var.cpu_request
    memory = var.memory_request
  }
}

output "servicemonitor_enabled" {
  description = "Whether Prometheus ServiceMonitor is enabled"
  value       = var.enable_servicemonitor
}
