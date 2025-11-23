# ============================================================================
# HOME ASSISTANT MODULE OUTPUTS
# ============================================================================

output "namespace" {
  description = "Kubernetes namespace where Home Assistant is deployed"
  value       = kubernetes_namespace.this.metadata[0].name
}

output "service_name" {
  description = "Name of the Home Assistant Kubernetes service"
  value       = kubernetes_service.this.metadata[0].name
}

output "service_port" {
  description = "Port of the Home Assistant service"
  value       = 8123
}

output "url" {
  description = "Internal URL for Home Assistant service"
  value       = "http://${kubernetes_service.this.metadata[0].name}.${kubernetes_namespace.this.metadata[0].name}.svc.cluster.local:8123"
}

output "external_url" {
  description = "External URL for Home Assistant (when ingress is enabled)"
  value       = var.enable_ingress ? "https://home-assistant.${var.domain_name}" : null
}

output "deployment_name" {
  description = "Name of the Kubernetes deployment"
  value       = kubernetes_deployment.this.metadata[0].name
}

output "deployment_namespace" {
  description = "Namespace of the Kubernetes deployment"
  value       = kubernetes_deployment.this.metadata[0].namespace
}

output "image" {
  description = "Container image used for Home Assistant"
  value       = "homeassistant/home-assistant:2024.1"
}

output "storage_class" {
  description = "Storage class used for persistent volumes"
  value       = var.storage_class
}

output "persistent_volume_size" {
  description = "Size of the persistent volume"
  value       = var.enable_persistence ? var.persistent_disk_size : null
}
