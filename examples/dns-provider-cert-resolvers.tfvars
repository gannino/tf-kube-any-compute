# ============================================================================
# DNS PROVIDER-BASED CERTIFICATE RESOLVERS EXAMPLE
# ============================================================================
# This example shows how the new DNS provider system automatically creates
# certificate resolvers using the DNS provider name instead of hardcoded values.

# Basic configuration
base_domain   = "example.com"
platform_name = "k3s"
le_email      = "admin@example.com"

# ============================================================================
# CLOUDFLARE DNS PROVIDER EXAMPLE
# ============================================================================
service_overrides = {
  traefik = {
    dns_providers = {
      primary = {
        name = "cloudflare"
        config = {
          CF_API_EMAIL = "your-email@example.com"
          CF_API_KEY   = "your-global-api-key"
          # OR use DNS token (recommended)
          CF_DNS_API_TOKEN = "your-dns-api-token"
        }
      }
    }

    dns_challenge_config = {
      resolvers                 = ["1.1.1.1:53", "8.8.8.8:53"]
      delay_before_check        = "120s"
      disable_propagation_check = false
      polling_interval          = "5s"
      propagation_timeout       = "300s"
    }
  }
}

# ============================================================================
# CERTIFICATE RESOLVER USAGE
# ============================================================================
# With the above configuration, Traefik will create a certificate resolver
# named "cloudflare" that all services will use automatically.
#
# The system will:
# 1. Create resolver: certificatesresolvers.cloudflare.acme.*
# 2. Pass "cloudflare" as traefik_cert_resolver to all modules
# 3. Services use: traefik.ingress.kubernetes.io/router.tls.certresolver=cloudflare
#
# This replaces the old hardcoded "wildcard" resolver with the actual
# DNS provider name, making the configuration more explicit and flexible.

# ============================================================================
# OVERRIDE SPECIFIC SERVICES (Optional)
# ============================================================================
# You can still override certificate resolvers for specific services:
cert_resolver_override = {
  grafana    = "cloudflare" # Use Cloudflare resolver
  prometheus = "cloudflare" # Use Cloudflare resolver
  vault      = "default"    # Use HTTP challenge for Vault
}

# ============================================================================
# ALTERNATIVE: ROUTE53 EXAMPLE
# ============================================================================
# service_overrides = {
#   traefik = {
#     dns_providers = {
#       primary = {
#         name = "route53"
#         config = {
#           AWS_ACCESS_KEY_ID     = "your-access-key"
#           AWS_SECRET_ACCESS_KEY = "your-secret-key"
#           AWS_REGION           = "us-east-1"
#         }
#       }
#     }
#   }
# }
# # This would create a "route53" certificate resolver

# ============================================================================
# ALTERNATIVE: HURRICANE ELECTRIC EXAMPLE (Default)
# ============================================================================
# service_overrides = {
#   traefik = {
#     dns_providers = {
#       primary = {
#         name = "hurricane"
#         config = {}  # Uses auto-generated tokens
#       }
#     }
#   }
# }
# # This would create a "hurricane" certificate resolver (default behavior)
