# ============================================================================
# NATIVE TERRAFORM N8N MODULE OUTPUTS
# ============================================================================

output "namespace" {
  description = "The namespace where n8n is deployed"
  value       = kubernetes_namespace.this.metadata[0].name
}

output "service_name" {
  description = "The name of the n8n service"
  value       = kubernetes_service.n8n.metadata[0].name
}

output "service_url" {
  description = "Internal service URL for n8n"
  value       = "http://${kubernetes_service.n8n.metadata[0].name}.${kubernetes_namespace.this.metadata[0].name}.svc.cluster.local:5678"
}

output "ingress_url" {
  description = "External ingress URL for n8n (when ingress is enabled)"
  value       = var.enable_ingress ? "https://${local.n8n_host}" : null
}

output "webhook_url" {
  description = "Webhook URL for n8n workflows"
  value       = var.enable_ingress ? "https://${local.n8n_host}/webhook" : null
}

output "deployment_name" {
  description = "The name of the n8n deployment"
  value       = kubernetes_deployment.n8n.metadata[0].name
}

output "deployment_status" {
  description = "The status of the n8n deployment"
  value       = "deployed"
}

output "n8n_version" {
  description = "The version of n8n deployed"
  value       = local.n8n_version
}

output "n8n_config" {
  description = "n8n configuration summary"
  value = {
    namespace           = kubernetes_namespace.this.metadata[0].name
    service_name        = kubernetes_service.n8n.metadata[0].name
    deployment_name     = kubernetes_deployment.n8n.metadata[0].name
    cpu_arch            = var.cpu_arch
    storage_class       = var.storage_class
    persistence_enabled = var.enable_persistence
    ingress_enabled     = var.enable_ingress
    database_enabled    = var.enable_database
    host                = local.n8n_host
  }
}
