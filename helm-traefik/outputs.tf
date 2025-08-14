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

output "dns_provider_config" {
  description = "DNS provider configuration for ACME certificates"
  value = {
    primary_provider           = local.dns_config.primary_provider
    primary_cert_resolver_name = local.dns_config.primary_provider
    challenge_config           = local.dns_config.challenge_config
    cert_resolvers             = local.computed_cert_resolvers

    # Hurricane Electric specific (backward compatibility)
    he_dns_config = local.dns_config.primary_provider == "hurricane" ? {
      txt_record_name = "_acme-challenge.${var.domain_name}"
      dynamic_dns_key = random_password.hurricane_token.result
      domain          = var.domain_name
      instructions    = "Add TXT record '_acme-challenge.${var.domain_name}' with the dynamic DNS key to Hurricane Electric DNS"
    } : null
  }
  sensitive = true
}

# Legacy output for backward compatibility
output "he_dns_config" {
  description = "Hurricane Electric DNS configuration for ACME wildcard certificates (DEPRECATED: use dns_provider_config)"
  value = local.dns_config.primary_provider == "hurricane" ? {
    txt_record_name = "_acme-challenge.${var.domain_name}"
    dynamic_dns_key = random_password.hurricane_token.result
    domain          = var.domain_name
    instructions    = "Add TXT record '_acme-challenge.${var.domain_name}' with the dynamic DNS key to Hurricane Electric DNS"
  } : null
}

output "supported_dns_providers" {
  description = "List of supported DNS providers"
  value = [
    "hurricane", "cloudflare", "route53", "digitalocean",
    "gandi", "namecheap", "godaddy", "ovh", "linode", "vultr", "hetzner"
  ]
}

output "cert_resolver_name" {
  description = "Primary certificate resolver name for use by other services"
  value       = local.dns_config.primary_provider
}
