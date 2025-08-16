# ============================================================================
# LDAP MIDDLEWARE TESTING CONFIGURATION
# ============================================================================
# This configuration tests LDAP authentication middleware

# Basic cluster configuration
base_domain   = "ldap-test.local"
platform_name = "k3s"
le_email      = "admin@ldap-test.local"

# Enable minimal services for LDAP testing
services = {
  traefik   = true
  metallb   = true
  host_path = true
  # Disable other services for focused testing
  prometheus         = false
  grafana            = false
  consul             = false
  vault              = false
  portainer          = false
  loki               = false
  promtail           = false
  kube_state_metrics = false
}

# Test LDAP middleware configuration
service_overrides = {
  traefik = {
    enable_dashboard = true

    # LDAP-focused middleware configuration
    middleware_config = {
      # Basic Authentication (fallback)
      basic_auth = {
        enabled         = true
        realm           = "Fallback Authentication"
        static_password = "fallback-password"
        username        = "fallback"
      }

      # Primary LDAP Authentication
      ldap_auth = {
        enabled       = true
        log_level     = "DEBUG"
        url           = "ldap://ldap.jumpcloud.com"
        port          = 389
        base_dn       = "ou=Users,o=YOUR_ORG_ID,dc=jumpcloud,dc=com"
        attribute     = "uid"
        bind_dn       = "uid=service,ou=Users,o=YOUR_ORG_ID,dc=jumpcloud,dc=com"
        bind_password = "service-password"
        search_filter = "(objectClass=inetOrgPerson)"
      }

      # Rate Limiting for LDAP
      rate_limit = {
        enabled = true
        average = 20 # Lower rate for LDAP to prevent server overload
        burst   = 40
      }

      # Default Authentication with LDAP override
      default_auth = {
        enabled       = true
        ldap_override = true # Use LDAP instead of basic
        ldap_config = {
          log_level     = "INFO"
          url           = "ldap://ldap.jumpcloud.com"
          port          = 389
          base_dn       = "ou=Users,o=YOUR_ORG_ID,dc=jumpcloud,dc=com"
          attribute     = "uid"
          bind_dn       = "uid=service,ou=Users,o=YOUR_ORG_ID,dc=jumpcloud,dc=com"
          bind_password = "service-password"
          search_filter = "(objectClass=inetOrgPerson)"
        }
        basic_config = {
          realm           = "LDAP Fallback"
          static_password = "ldap-fallback-password"
          username        = "ldapfallback"
        }
      }
    }

    # Use LDAP middleware for dashboard - will be populated by Traefik module outputs
    # dashboard_middleware = [] # Let Traefik module handle middleware assignment

    # DNS configuration
    dns_providers = {
      primary = {
        name   = "hurricane"
        config = {}
      }
    }
  }
}

# Resource constraints
enable_resource_limits = true
default_cpu_limit      = "200m"
default_memory_limit   = "256Mi"

# Authentication override testing - use logical middleware types
auth_override = {
  prometheus   = "ldap"    # Use LDAP middleware specifically
  alertmanager = "default" # Use default auth (LDAP priority in this config)
}
