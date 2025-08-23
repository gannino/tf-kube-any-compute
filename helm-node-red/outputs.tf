# ============================================================================
# HELM-NODE-RED MODULE OUTPUTS
# ============================================================================

output "namespace" {
  description = "The namespace where Node-RED is deployed"
  value       = kubernetes_namespace.this.metadata[0].name
}

output "service_name" {
  description = "The name of the Node-RED service"
  value       = data.kubernetes_service.this.metadata[0].name
}

output "service_url" {
  description = "Internal service URL for Node-RED"
  value       = "http://${data.kubernetes_service.this.metadata[0].name}.${kubernetes_namespace.this.metadata[0].name}.svc.cluster.local:1880"
}

output "ingress_url" {
  description = "External ingress URL for Node-RED (when ingress is enabled)"
  value       = var.enable_ingress ? "https://node-red.${var.domain_name}" : null
}

output "helm_release_name" {
  description = "The name of the Helm release"
  value       = helm_release.this.name
}

output "helm_release_status" {
  description = "The status of the Helm release"
  value       = helm_release.this.status
}

output "chart_version" {
  description = "The version of the Helm chart deployed"
  value       = helm_release.this.version
}

output "node_red_config" {
  description = "Node-RED configuration summary"
  value = {
    namespace           = kubernetes_namespace.this.metadata[0].name
    service_name        = data.kubernetes_service.this.metadata[0].name
    cpu_arch            = var.cpu_arch
    storage_class       = var.storage_class
    persistence_enabled = var.enable_persistence
    ingress_enabled     = var.enable_ingress
  }
}
