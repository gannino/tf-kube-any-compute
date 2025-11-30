# Random password for default authentication (basic auth mode, only when static password not provided)
resource "random_password" "default_auth_password" {
  count   = var.default_auth.enabled && !var.default_auth.ldap_override && var.default_auth.basic_config.static_password == "" ? 1 : 0
  length  = 16
  special = true
}

# Local value to determine the default auth password to use
locals {
  default_auth_password = var.default_auth.enabled && !var.default_auth.ldap_override ? (
    var.default_auth.basic_config.static_password != "" ? var.default_auth.basic_config.static_password : random_password.default_auth_password[0].result
  ) : ""
}

# Default authentication secret (basic auth mode)
resource "kubernetes_secret" "default_auth" {
  count = var.default_auth.enabled && !var.default_auth.ldap_override ? 1 : 0

  metadata {
    name      = var.default_auth.basic_config.secret_name != "" ? var.default_auth.basic_config.secret_name : "${var.name_prefix}-default-auth-secret"
    namespace = var.namespace
    labels    = var.labels
  }

  data = {
    users = "${var.default_auth.basic_config.username}:${bcrypt(local.default_auth_password, 10)}"
  }

  type = "Opaque"
}

# Default Authentication Middleware - LDAP ForwardAuth version - only create when CRDs are available
resource "kubectl_manifest" "default_auth_ldap_forwardauth" {
  count = var.default_auth.enabled && var.default_auth.ldap_override && var.default_auth.ldap_config.method == "forwardauth" && var.enable_middleware_resources ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "traefik.io/v1alpha1"
    kind       = "Middleware"
    metadata = {
      name      = "${var.name_prefix}-default-auth"
      namespace = var.namespace
      labels    = var.labels
    }
    spec = {
      forwardAuth = {
        address = "http://${var.name_prefix}-ldap-auth-service.${var.namespace}.svc.cluster.local:8080/auth"
        authResponseHeaders = [
          "X-Forwarded-User"
        ]
      }
    }
  })
}

# Default Authentication Middleware - LDAP Plugin version - only create when CRDs are available
resource "kubectl_manifest" "default_auth_ldap_plugin" {
  count = var.default_auth.enabled && var.default_auth.ldap_override && var.default_auth.ldap_config.method == "plugin" && var.enable_middleware_resources ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "traefik.io/v1alpha1"
    kind       = "Middleware"
    metadata = {
      name      = "${var.name_prefix}-default-auth"
      namespace = var.namespace
      labels    = var.labels
    }
    spec = {
      plugin = {
        ldapAuth = merge(
          # Always include URL and baseDN as they're required
          {
            url    = var.default_auth.ldap_config.url
            baseDN = var.default_auth.ldap_config.base_dn
          },
          # Conditionally include other parameters only if they're specified
          var.default_auth.ldap_config.attribute != "" ? { attribute = var.default_auth.ldap_config.attribute } : {},
          var.default_auth.ldap_config.bind_dn != "" ? { bindDN = var.default_auth.ldap_config.bind_dn } : {},
          var.default_auth.ldap_config.bind_password != "" ? { bindPassword = var.default_auth.ldap_config.bind_password } : {},
          var.default_auth.ldap_config.search_filter != "" ? { filter = var.default_auth.ldap_config.search_filter } : {},
          var.default_auth.ldap_config.port != 389 ? { port = var.default_auth.ldap_config.port } : {},
          var.default_auth.ldap_config.log_level != "INFO" ? { logLevel = var.default_auth.ldap_config.log_level } : {}
        )
      }
    }
  })
}

# Default Authentication Middleware - Basic Auth version (default) - only create when CRDs are available
resource "kubectl_manifest" "default_auth_basic" {
  count = var.default_auth.enabled && !var.default_auth.ldap_override && var.enable_middleware_resources ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "traefik.io/v1alpha1"
    kind       = "Middleware"
    metadata = {
      name      = "${var.name_prefix}-default-auth"
      namespace = var.namespace
      labels    = var.labels
    }
    spec = {
      basicAuth = {
        secret = kubernetes_secret.default_auth[0].metadata[0].name
        realm  = var.default_auth.basic_config.realm
      }
    }
  })

  depends_on = [kubernetes_secret.default_auth]
}
