# ============================================================================
# OPENHAB MODULE OUTPUTS
# ============================================================================

output "namespace" {
  description = "Kubernetes namespace where openHAB is deployed"
  value       = kubernetes_namespace.this.metadata[0].name
}

output "service_name" {
  description = "Name of the openHAB Kubernetes service"
  value       = kubernetes_service.this.metadata[0].name
}

output "service_port" {
  description = "Port of the openHAB service"
  value       = 8080
}

output "karaf_port" {
  description = "Port of the Karaf console (if enabled)"
  value       = var.enable_karaf_console ? 8101 : null
}

output "url" {
  description = "Internal URL for openHAB service"
  value       = "http://${kubernetes_service.this.metadata[0].name}.${kubernetes_namespace.this.metadata[0].name}.svc.cluster.local:8080"
}

output "external_url" {
  description = "External URL for openHAB (when ingress is enabled)"
  value       = var.enable_ingress ? "https://openhab.${var.domain_name}" : null
}

output "karaf_external_url" {
  description = "External URL for Karaf console (when ingress and console are enabled)"
  value       = var.enable_ingress && var.enable_karaf_console ? "https://openhab-karaf.${var.domain_name}" : null
}

output "helm_release_name" {
  description = "Name of the deployment"
  value       = kubernetes_deployment.this.metadata[0].name
}

output "helm_release_namespace" {
  description = "Namespace of the deployment"
  value       = kubernetes_deployment.this.metadata[0].namespace
}

output "helm_release_version" {
  description = "Version of the deployment"
  value       = "native-k8s"
}

output "storage_class" {
  description = "Storage class used for persistent volumes"
  value       = var.storage_class
}

output "persistent_volumes" {
  description = "Information about persistent volumes"
  value = var.enable_persistence ? {
    data_size   = var.persistent_disk_size
    addons_size = var.addons_disk_size
    conf_size   = var.conf_disk_size
  } : null
}
