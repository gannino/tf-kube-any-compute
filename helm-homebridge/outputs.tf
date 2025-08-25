output "namespace" {
  description = "Kubernetes namespace where Homebridge is deployed"
  value       = kubernetes_namespace.this.metadata[0].name
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

output "service_name" {
  description = "Name of the Homebridge Kubernetes service"
  value       = try(data.kubernetes_service.this.metadata[0].name, "")
}

output "service_port" {
  description = "Port of the Homebridge service"
  value       = try(data.kubernetes_service.this.spec[0].port[0].port, 8581)
}

output "url" {
  description = "Internal URL for Homebridge service"
  value       = "http://${var.name}.${var.namespace}.svc.cluster.local:8581"
}

output "external_url" {
  description = "External URL for Homebridge (when ingress is enabled)"
  value       = local.ingress_enabled ? "https://${local.ingress_host}" : ""
}

output "storage_class" {
  description = "Storage class used for persistent volumes"
  value       = var.storage_class
}

output "persistent_volume_size" {
  description = "Size of the persistent volume"
  value       = var.enable_persistence ? var.persistent_disk_size : ""
}

output "plugins" {
  description = "List of installed Homebridge plugins"
  value       = var.plugins
}
