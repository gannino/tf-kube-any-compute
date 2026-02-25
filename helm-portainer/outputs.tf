# ============================================================================
# Portainer Module Outputs
# ============================================================================

# Basic outputs
output "namespace" {
  description = "Kubernetes namespace where Portainer is deployed"
  value       = kubernetes_namespace.this.metadata[0].name
}

output "name" {
  description = "Name of the Portainer deployment"
  value       = var.name
}

# Service discovery outputs (for module-to-module integration)
output "service_host" {
  description = "Service hostname for module-to-module integration. Usage: module.portainer[0].service_host"
  value       = "${var.name}.${var.namespace}.svc.cluster.local"
}

output "service_port" {
  description = "Service port for service discovery"
  value       = 9443
}

output "service_name" {
  description = "Kubernetes service name"
  value       = data.kubernetes_service.this.metadata[0].name
}

# Configuration endpoints
output "url" {
  description = "URL for Portainer web interface"
  value       = var.enable_portainer_ingress_route ? "https://portainer.${var.domain_name}" : null
}

# Integration outputs
output "helm_release" {
  description = "Helm release name for Portainer"
  value       = helm_release.this.name
}

output "chart_version" {
  description = "Helm chart version deployed"
  value       = local.helm_config.version
}

# Credential outputs (sensitive)
output "portainer" {
  description = "Portainer service information (admin password auto-configured via init job)"
  sensitive   = true
  value = {
    namespace      = kubernetes_namespace.this.metadata[0].name
    service_name   = data.kubernetes_service.this.metadata[0].name
    url            = var.enable_portainer_ingress_route ? "https://portainer.${var.domain_name}" : null
    helm_release   = helm_release.this.name
    admin_username = "admin"
    admin_password = local.admin_password
    init_job_name  = var.portainer_admin_password != null && var.portainer_admin_password != "" ? "${var.name}-init" : null
  }
}
