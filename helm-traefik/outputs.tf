# ============================================================================
# OUTPUTS - STANDARDIZED MODULE OUTPUTS
# ============================================================================

output "namespace" {
  description = "Kubernetes namespace where Traefik is deployed"
  value       = kubernetes_namespace.this.metadata[0].name
}

output "service_name" {
  description = "Traefik service name"
  value       = data.kubernetes_service.this.metadata[0].name
}

output "loadbalancer_ip" {
  description = "LoadBalancer IP address for Traefik service"
  value       = try(data.kubernetes_service.this.status[0].load_balancer[0].ingress[0].ip, "")
}

output "dashboard_url" {
  description = "Traefik dashboard URL"
  value       = var.enable_ingress ? "https://traefik.${var.domain_name}" : ""
}

output "dashboard_password" {
  description = "Traefik dashboard password"
  value       = var.enable_ingress ? module.ingress[0].traefik_dashboard_password : ""
  sensitive   = true
}

output "chart_version" {
  description = "Helm chart version used"
  value       = var.chart_version
}

output "he_dns_config" {
  description = "Hurricane Electric DNS configuration for ACME wildcard certificates"
  value = {
    txt_record_name = "_acme-challenge.${var.domain_name}"
    dynamic_dns_key = random_password.hurricane_token.result
    domain          = var.domain_name
    instructions    = "Add TXT record '_acme-challenge.${var.domain_name}' with the dynamic DNS key to Hurricane Electric DNS"
  }
}
