# ============================================================================
# DNS PROVIDERS CONFIGURATION EXAMPLES
# ============================================================================
# This file demonstrates how to configure different DNS providers for
# Let's Encrypt DNS challenges with Traefik in tf-kube-any-compute
# ============================================================================

# ============================================================================
# CLOUDFLARE DNS PROVIDER EXAMPLE
# ============================================================================

# Example 1: Cloudflare with API Token (Recommended)
service_overrides = {
  traefik = {
    dns_providers = {
      primary = {
        name = "cloudflare"
        config = {
          # Use DNS API Token (recommended - more secure, scoped permissions)
          dns_token = "your-cloudflare-dns-api-token-here"
          # OR use Global API Key (less secure, full account access)
          # email = "your-email@example.com"
          # api_key = "your-global-api-key-here"
        }
      }
    }

    cert_resolvers = {
      default = {
        challenge_type = "http" # HTTP challenge for default resolver
      }
      wildcard = {
        challenge_type = "dns" # DNS challenge for wildcard certificates
        dns_provider   = "cloudflare"
      }
    }

    dns_challenge_config = {
      resolvers                 = ["1.1.1.1:53", "1.0.0.1:53"] # Use Cloudflare DNS
      delay_before_check        = "60s"                        # Faster for Cloudflare
      disable_propagation_check = false
    }
  }
}

# Base configuration (applies to all examples above)
base_domain   = "example.com"
platform_name = "k3s"
le_email      = "admin@example.com"

# Service enablement
services = {
  traefik    = true
  metallb    = true
  prometheus = true
  grafana    = true
}
