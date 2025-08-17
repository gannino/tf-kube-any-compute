# ============================================================================
# MIDDLEWARE OUTPUTS - FOR CONSUMER MODULES
# ============================================================================

output "basic_auth_middleware_name" {
  description = "Name of the basic auth middleware for use in IngressRoute annotations"
  value       = var.basic_auth.enabled ? "${var.name_prefix}-basic-auth" : null
}

output "ldap_auth_middleware_name" {
  description = "Name of the LDAP auth middleware for use in IngressRoute annotations"
  value       = var.ldap_auth.enabled ? "${var.name_prefix}-ldap-auth" : null
}

output "rate_limit_middleware_name" {
  description = "Name of the rate limit middleware for use in IngressRoute annotations"
  value       = var.rate_limit.enabled ? "${var.name_prefix}-rate-limit" : null
}

output "ip_whitelist_middleware_name" {
  description = "Name of the IP whitelist middleware for use in IngressRoute annotations"
  value       = var.ip_whitelist.enabled ? "${var.name_prefix}-ip-whitelist" : null
}

output "middleware_namespace" {
  description = "Namespace where middleware resources are deployed (same as Traefik namespace)"
  value       = var.namespace
}

# Convenience outputs for common middleware combinations
output "auth_middleware_names" {
  description = "List of enabled authentication middleware names"
  value = compact([
    var.basic_auth.enabled ? "${var.name_prefix}-basic-auth" : "",
    var.ldap_auth.enabled ? "${var.name_prefix}-ldap-auth" : ""
  ])
}

output "security_middleware_names" {
  description = "List of enabled security middleware names"
  value = compact([
    var.rate_limit.enabled ? "${var.name_prefix}-rate-limit" : "",
    var.ip_whitelist.enabled ? "${var.name_prefix}-ip-whitelist" : ""
  ])
}

output "default_auth_middleware_name" {
  description = "Name of the default auth middleware (switches between basic/LDAP)"
  value       = var.default_auth.enabled ? "${var.name_prefix}-default-auth" : null
}

output "all_middleware_names" {
  description = "List of all enabled middleware names"
  value = compact([
    var.basic_auth.enabled ? "${var.name_prefix}-basic-auth" : "",
    var.ldap_auth.enabled ? "${var.name_prefix}-ldap-auth" : "",
    var.rate_limit.enabled ? "${var.name_prefix}-rate-limit" : "",
    var.ip_whitelist.enabled ? "${var.name_prefix}-ip-whitelist" : "",
    var.default_auth.enabled ? "${var.name_prefix}-default-auth" : ""
  ])
}

# ============================================================================
# AUTHENTICATION CREDENTIALS OUTPUTS
# ============================================================================

output "basic_auth_password" {
  description = "Password for basic authentication (static if provided, otherwise generated)"
  value       = var.basic_auth.enabled ? local.basic_auth_password : null
  sensitive   = true
}

output "basic_auth_username" {
  description = "Username for basic authentication"
  value       = var.basic_auth.enabled ? var.basic_auth.username : null
}

output "basic_auth_secret_name" {
  description = "Name of the Kubernetes secret containing basic auth credentials"
  value       = var.basic_auth.enabled ? kubernetes_secret.basic_auth[0].metadata[0].name : null
}

output "basic_auth_is_static" {
  description = "Whether basic auth is using a static password (true) or generated password (false)"
  value       = var.basic_auth.enabled ? var.basic_auth.static_password != "" : null
}

output "default_auth_password" {
  description = "Password for default authentication when using basic auth (static if provided, otherwise generated)"
  value       = var.default_auth.enabled && !var.default_auth.ldap_override ? local.default_auth_password : null
  sensitive   = true
}

output "default_auth_username" {
  description = "Username for default authentication when using basic auth"
  value       = var.default_auth.enabled && !var.default_auth.ldap_override ? var.default_auth.basic_config.username : null
}

output "default_auth_is_static" {
  description = "Whether default auth is using a static password (true) or generated password (false)"
  value       = var.default_auth.enabled && !var.default_auth.ldap_override ? var.default_auth.basic_config.static_password != "" : null
}

output "default_auth_secret_name" {
  description = "Name of the Kubernetes secret containing default auth credentials"
  value       = var.default_auth.enabled && !var.default_auth.ldap_override ? kubernetes_secret.default_auth[0].metadata[0].name : null
}

output "default_auth_type" {
  description = "Type of default authentication configured (basic or ldap)"
  value       = var.default_auth.enabled ? (var.default_auth.ldap_override ? "ldap" : "basic") : null
}

output "ldap_auth_config" {
  description = "LDAP authentication configuration summary"
  value = var.ldap_auth.enabled || (var.default_auth.enabled && var.default_auth.ldap_override) ? {
    enabled   = true
    url       = var.ldap_auth.enabled ? var.ldap_auth.url : var.default_auth.ldap_config.url
    port      = var.ldap_auth.enabled ? var.ldap_auth.port : var.default_auth.ldap_config.port
    base_dn   = var.ldap_auth.enabled ? var.ldap_auth.base_dn : var.default_auth.ldap_config.base_dn
    attribute = var.ldap_auth.enabled ? var.ldap_auth.attribute : var.default_auth.ldap_config.attribute
    log_level = var.ldap_auth.enabled ? var.ldap_auth.log_level : var.default_auth.ldap_config.log_level
    } : {
    enabled = false
  }
  sensitive = false
}

output "auth_method_summary" {
  description = "Summary of enabled authentication methods"
  value = {
    basic_auth_enabled   = var.basic_auth.enabled
    ldap_auth_enabled    = var.ldap_auth.enabled
    default_auth_enabled = var.default_auth.enabled
    default_auth_type    = var.default_auth.enabled ? (var.default_auth.ldap_override ? "ldap" : "basic") : null
    active_auth_methods = compact([
      var.basic_auth.enabled ? "basic" : "",
      var.ldap_auth.enabled ? "ldap" : "",
      var.default_auth.enabled ? "default-${var.default_auth.ldap_override ? "ldap" : "basic"}" : ""
    ])
  }
}
