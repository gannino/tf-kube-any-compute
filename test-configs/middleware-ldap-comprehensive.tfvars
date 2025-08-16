# ============================================================================
# COMPREHENSIVE LDAP MIDDLEWARE TESTING CONFIGURATION
# ============================================================================
# This configuration tests all LDAP authentication scenarios including
# fallback mechanisms, priority systems, and integration with services

# Basic cluster configuration
base_domain   = "ldap-comprehensive.local"
platform_name = "k3s"
le_email      = "admin@ldap-comprehensive.local"

# Enable services for comprehensive LDAP testing
services = {
  traefik            = true
  metallb            = true
  host_path          = true
  prometheus         = true  # Enable for middleware integration testing
  grafana            = false # Disable to focus on middleware
  consul             = false
  vault              = false
  portainer          = false
  loki               = false
  promtail           = false
  kube_state_metrics = false
}

# Comprehensive LDAP middleware testing
service_overrides = {
  traefik = {
    enable_dashboard = true

    # Comprehensive middleware configuration
    middleware_config = {
      # Basic Authentication (fallback)
      basic_auth = {
        enabled         = true
        realm           = "LDAP Fallback Authentication"
        static_password = "fallback-secure-password-123"
        username        = "fallbackadmin"
        secret_name     = "ldap-fallback-auth"
      }

      # Primary LDAP Authentication - JumpCloud example
      ldap_auth = {
        enabled       = true
        log_level     = "DEBUG" # Verbose logging for testing
        url           = "ldap://ldap.jumpcloud.com"
        port          = 389
        base_dn       = "ou=Users,o=YOUR_ORG_ID,dc=jumpcloud,dc=com"
        attribute     = "uid"
        bind_dn       = "uid=service-account,ou=Users,o=YOUR_ORG_ID,dc=jumpcloud,dc=com"
        bind_password = "service-account-password"
        search_filter = "(objectClass=inetOrgPerson)"
      }

      # Rate Limiting for LDAP (conservative)
      rate_limit = {
        enabled = true
        average = 10 # Lower rate for LDAP testing
        burst   = 20
      }

      # IP Whitelist for testing environment
      ip_whitelist = {
        enabled = true
        source_ranges = [
          "127.0.0.1/32",
          "10.0.0.0/8",
          "192.168.0.0/16",
          "172.16.0.0/12"
        ]
      }

      # Default Authentication with LDAP priority
      default_auth = {
        enabled       = true
        ldap_override = true # Use LDAP as primary

        # LDAP configuration for default auth
        ldap_config = {
          log_level     = "INFO"
          url           = "ldap://ldap.jumpcloud.com"
          port          = 389
          base_dn       = "ou=Users,o=YOUR_ORG_ID,dc=jumpcloud,dc=com"
          attribute     = "uid"
          bind_dn       = "uid=service-account,ou=Users,o=YOUR_ORG_ID,dc=jumpcloud,dc=com"
          bind_password = "service-account-password"
          search_filter = "(objectClass=inetOrgPerson)"
        }

        # Basic auth fallback configuration
        basic_config = {
          realm           = "Default LDAP Fallback"
          static_password = "default-ldap-fallback-password"
          username        = "defaultldap"
          secret_name     = "default-ldap-fallback"
        }
      }
    }

    # Use default auth middleware for dashboard - will be populated by Traefik module outputs
    # dashboard_middleware = [] # Let Traefik module handle middleware assignment

    # DNS configuration
    dns_providers = {
      primary = {
        name   = "hurricane"
        config = {}
      }
    }
  }

  # Test Prometheus with LDAP middleware
  prometheus = {
    enable_ingress              = true
    enable_alertmanager_ingress = true
    enable_monitoring_auth      = true
  }
}

# Resource constraints for testing
enable_resource_limits = true
default_cpu_limit      = "200m"
default_memory_limit   = "256Mi"

# Authentication override testing - use logical middleware types
auth_override = {
  prometheus   = "ldap"    # Use LDAP middleware specifically
  alertmanager = "default" # Use default auth (LDAP priority in this config)
}
