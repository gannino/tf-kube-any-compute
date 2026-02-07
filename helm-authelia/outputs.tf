output "namespace" {
  description = "Namespace where Authelia is deployed"
  value       = kubernetes_namespace.this.metadata[0].name
}

output "service_name" {
  description = "Name of the Authelia service"
  value       = var.name
}

output "service_url" {
  description = "URL to access Authelia web interface"
  value       = "https://authelia.${var.domain_name}"
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL for other services to use"
  value       = var.oidc_enabled ? "https://authelia.${var.domain_name}" : null
}

output "jwt_secret" {
  description = "JWT secret used by Authelia"
  value       = local.jwt_secret
  sensitive   = true
}

output "session_secret" {
  description = "Session secret used by Authelia"
  value       = local.session_secret
  sensitive   = true
}

output "storage_encryption_key" {
  description = "Storage encryption key used by Authelia"
  value       = local.storage_encryption_key
  sensitive   = true
}

output "ingress_config" {
  description = "Ingress configuration for other services to use Authelia"
  value = {
    url             = "https://authelia.${var.domain_name}"
    authelia_url    = "https://authelia.${var.domain_name}"
    oidc_issuer_url = var.oidc_enabled ? "https://authelia.${var.domain_name}" : null
    oidc_client_ids = var.oidc_enabled ? keys(var.oidc_clients) : []
  }
}

output "oidc_clients" {
  description = "Configured OIDC clients"
  value       = var.oidc_enabled ? var.oidc_clients : {}
  sensitive   = true
}
