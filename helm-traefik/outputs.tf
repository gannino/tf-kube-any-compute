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

# ============================================================================
# MIDDLEWARE OUTPUTS - FOR CONSUMER MODULES
# ============================================================================

output "middleware" {
  description = "Middleware configuration and names for consumer modules"
  value = {
    namespace = kubernetes_namespace.this.metadata[0].name

    # Individual middleware names
    basic_auth_name   = module.middleware.basic_auth_middleware_name
    ldap_auth_name    = module.middleware.ldap_auth_middleware_name
    rate_limit_name   = module.middleware.rate_limit_middleware_name
    ip_whitelist_name = module.middleware.ip_whitelist_middleware_name
    default_auth_name = module.middleware.default_auth_middleware_name

    # Convenience collections
    auth_middleware_names     = module.middleware.auth_middleware_names
    security_middleware_names = module.middleware.security_middleware_names
    all_middleware_names      = module.middleware.all_middleware_names

    # Authentication credentials
    basic_auth_password      = module.middleware.basic_auth_password
    basic_auth_secret_name   = module.middleware.basic_auth_secret_name
    default_auth_password    = module.middleware.default_auth_password
    default_auth_secret_name = module.middleware.default_auth_secret_name
    default_auth_type        = module.middleware.default_auth_type

    # LDAP authentication info
    ldap_auth_config    = module.middleware.ldap_auth_config
    auth_method_summary = module.middleware.auth_method_summary
  }
}

# Individual outputs for backward compatibility
output "basic_auth_middleware_name" {
  description = "Basic auth middleware name for IngressRoute annotations"
  value       = module.middleware.basic_auth_middleware_name
}

output "ldap_auth_middleware_name" {
  description = "LDAP auth middleware name for IngressRoute annotations"
  value       = module.middleware.ldap_auth_middleware_name
}

output "default_auth_middleware_name" {
  description = "Default auth middleware name (switches between basic/LDAP)"
  value       = module.middleware.default_auth_middleware_name
}

# Authentication credentials outputs
output "basic_auth_password" {
  description = "Generated password for basic authentication middleware (admin user)"
  value       = module.middleware.basic_auth_password
  sensitive   = true
}

output "default_auth_password" {
  description = "Generated password for default authentication middleware when using basic auth (admin user)"
  value       = module.middleware.default_auth_password
  sensitive   = true
}

output "default_auth_type" {
  description = "Type of default authentication configured (basic or ldap)"
  value       = module.middleware.default_auth_type
}

output "ldap_auth_config" {
  description = "LDAP authentication configuration summary"
  value       = module.middleware.ldap_auth_config
}

output "preferred_auth_middleware_name" {
  description = "Preferred authentication middleware name (LDAP if enabled, otherwise basic)"
  value       = module.middleware.ldap_auth_middleware_name != null ? module.middleware.ldap_auth_middleware_name : module.middleware.basic_auth_middleware_name
}

output "auth_method_summary" {
  description = "Summary of enabled authentication methods"
  value       = module.middleware.auth_method_summary
}

output "middleware_namespace" {
  description = "Namespace where middleware resources are deployed (same as Traefik namespace)"
  value       = kubernetes_namespace.this.metadata[0].name
}
