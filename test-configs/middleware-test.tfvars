# ============================================================================
# MIDDLEWARE TESTING CONFIGURATION
# ============================================================================
# This configuration tests various middleware scenarios for Traefik

# Basic cluster configuration
base_domain   = "test.local"
platform_name = "k3s"
le_email      = "admin@test.local"

# Enable Traefik with middleware
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

# Test different middleware configurations
service_overrides = {
  traefik = {
    enable_dashboard = true

    # Test comprehensive middleware configuration
    middleware_config = {
      # Basic Authentication
      basic_auth = {
        enabled         = true
        realm           = "Traefik Test Environment"
        static_password = "test-password-123"
        username        = "testadmin"
      }

      # LDAP Authentication (disabled for testing)
      ldap_auth = {
        enabled   = false
        log_level = "INFO"
        url       = "ldap://test.example.com"
        port      = 389
        base_dn   = "ou=Users,dc=test,dc=example,dc=com"
        attribute = "uid"
      }

      # Rate Limiting
      rate_limit = {
        enabled = true
        average = 50
        burst   = 100
      }

      # IP Whitelist
      ip_whitelist = {
        enabled = true
        source_ranges = [
          "127.0.0.1/32",
          "10.0.0.0/8",
          "192.168.0.0/16"
        ]
      }

      # Default Authentication (using basic auth)
      default_auth = {
        enabled       = true
        ldap_override = false
        basic_config = {
          realm           = "Default Authentication"
          static_password = "default-test-password"
          username        = "defaultadmin"
        }
      }
    }

    # Use centralized middleware for dashboard - will be populated by Traefik module outputs
    # dashboard_middleware = [] # Let Traefik module handle middleware assignment

    # DNS configuration for testing
    dns_providers = {
      primary = {
        name   = "hurricane"
        config = {}
      }
    }
  }
}

# Resource constraints for testing
enable_resource_limits = true
default_cpu_limit      = "100m"
default_memory_limit   = "128Mi"

# Authentication override testing - use logical middleware types
# auth_override = {
#   prometheus   = "basic"   # Use basic auth specifically
#   alertmanager = "default" # Use default auth (basic in this config)
# }
