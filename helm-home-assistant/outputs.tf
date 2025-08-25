# ============================================================================
# HOME ASSISTANT MODULE OUTPUTS
# ============================================================================

output "namespace" {
  description = "Kubernetes namespace where Home Assistant is deployed"
  value       = kubernetes_namespace.this.metadata[0].name
}

output "service_name" {
  description = "Name of the Home Assistant Kubernetes service"
  value       = try(data.kubernetes_service.this.metadata[0].name, var.name)
}

output "service_port" {
  description = "Port of the Home Assistant service"
  value       = 8123
}

output "url" {
  description = "Internal URL for Home Assistant service"
  value       = "http://${try(data.kubernetes_service.this.metadata[0].name, var.name)}.${kubernetes_namespace.this.metadata[0].name}.svc.cluster.local:8123"
}

output "external_url" {
  description = "External URL for Home Assistant (when ingress is enabled)"
  value       = var.enable_ingress ? "https://home-assistant.${var.domain_name}" : null
}

output "helm_release_name" {
  description = "Name of the Helm release"
  value       = helm_release.this.name
}

output "helm_release_namespace" {
  description = "Namespace of the Helm release"
  value       = helm_release.this.namespace
}

output "helm_release_version" {
  description = "Version of the deployed Helm chart"
  value       = helm_release.this.version
}

output "storage_class" {
  description = "Storage class used for persistent volumes"
  value       = var.storage_class
}

output "persistent_volume_size" {
  description = "Size of the persistent volume"
  value       = var.enable_persistence ? var.persistent_disk_size : null
}
