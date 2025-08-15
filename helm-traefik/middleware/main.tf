# ============================================================================
# TRAEFIK MIDDLEWARE SUBMODULE - REUSABLE AUTHENTICATION MIDDLEWARE
# ============================================================================

# Random password for basic authentication (only when static password not provided)
resource "random_password" "basic_auth_password" {
  count   = var.basic_auth.enabled && var.basic_auth.static_password == "" ? 1 : 0
  length  = 16
  special = true
}

# Local value to determine the password to use
locals {
  basic_auth_password = var.basic_auth.enabled ? (
    var.basic_auth.static_password != "" ? var.basic_auth.static_password : random_password.basic_auth_password[0].result
  ) : ""
}

# Basic authentication secret
resource "kubernetes_secret" "basic_auth" {
  count = var.basic_auth.enabled ? 1 : 0

  metadata {
    name      = var.basic_auth.secret_name != "" ? var.basic_auth.secret_name : "${var.name_prefix}-basic-auth-secret"
    namespace = var.namespace
    labels    = var.labels
  }

  data = {
    users = "${var.basic_auth.username}:${bcrypt(local.basic_auth_password, 10)}"
  }

  type = "Opaque"
}

# Basic Authentication Middleware
resource "kubernetes_manifest" "basic_auth" {
  count = var.basic_auth.enabled ? 1 : 0

  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "Middleware"
    metadata = {
      name      = "${var.name_prefix}-basic-auth"
      namespace = var.namespace
      labels    = var.labels
    }
    spec = {
      basicAuth = {
        secret = kubernetes_secret.basic_auth[0].metadata[0].name
        realm  = var.basic_auth.realm
      }
    }
  }

  depends_on = [kubernetes_secret.basic_auth]
}

# LDAP Authentication Middleware (using LDAP plugin)
resource "kubernetes_manifest" "ldap_auth" {
  count = var.ldap_auth.enabled ? 1 : 0

  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "Middleware"
    metadata = {
      name      = "${var.name_prefix}-ldap-auth"
      namespace = var.namespace
      labels    = var.labels
    }
    spec = {
      plugin = {
        ldapAuth = {
          enabled   = var.ldap_auth.enabled
          logLevel  = var.ldap_auth.log_level
          url       = var.ldap_auth.url
          port      = var.ldap_auth.port
          baseDn    = var.ldap_auth.base_dn
          attribute = var.ldap_auth.attribute
          # Optional additional configuration
          bindDn       = var.ldap_auth.bind_dn
          bindPassword = var.ldap_auth.bind_password
          searchFilter = var.ldap_auth.search_filter
        }
      }
    }
  }
}

# Rate Limiting Middleware (bonus)
resource "kubernetes_manifest" "rate_limit" {
  count = var.rate_limit.enabled ? 1 : 0

  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "Middleware"
    metadata = {
      name      = "${var.name_prefix}-rate-limit"
      namespace = var.namespace
      labels    = var.labels
    }
    spec = {
      rateLimit = {
        average = var.rate_limit.average
        burst   = var.rate_limit.burst
      }
    }
  }
}

# IP Whitelist Middleware (bonus)
resource "kubernetes_manifest" "ip_whitelist" {
  count = var.ip_whitelist.enabled ? 1 : 0

  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "Middleware"
    metadata = {
      name      = "${var.name_prefix}-ip-whitelist"
      namespace = var.namespace
      labels    = var.labels
    }
    spec = {
      ipWhiteList = {
        sourceRange = var.ip_whitelist.source_ranges
      }
    }
  }
}

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

# Default Authentication Middleware - LDAP version
resource "kubernetes_manifest" "default_auth_ldap" {
  count = var.default_auth.enabled && var.default_auth.ldap_override ? 1 : 0

  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "Middleware"
    metadata = {
      name      = "${var.name_prefix}-default-auth"
      namespace = var.namespace
      labels    = var.labels
    }
    spec = {
      plugin = {
        ldapAuth = {
          enabled      = true
          logLevel     = var.default_auth.ldap_config.log_level
          url          = var.default_auth.ldap_config.url
          port         = var.default_auth.ldap_config.port
          baseDn       = var.default_auth.ldap_config.base_dn
          attribute    = var.default_auth.ldap_config.attribute
          bindDn       = var.default_auth.ldap_config.bind_dn
          bindPassword = var.default_auth.ldap_config.bind_password
          searchFilter = var.default_auth.ldap_config.search_filter
        }
      }
    }
  }
}

# Default Authentication Middleware - Basic Auth version (default)
resource "kubernetes_manifest" "default_auth_basic" {
  count = var.default_auth.enabled && !var.default_auth.ldap_override ? 1 : 0

  manifest = {
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
  }

  depends_on = [kubernetes_secret.default_auth]
}
