# ============================================================================
# DNS PROVIDER: Cloudflare
# ============================================================================
# Cloudflare DNS configuration for Let's Encrypt SSL certificates
# ============================================================================

base_domain   = "example.com"
platform_name = "k3s"
le_email      = "admin@example.com"

service_overrides = {
  traefik = {
    dns_providers = {
      primary = {
        name = "cloudflare"
        config = {
          # Option 1: DNS API Token (Recommended - scoped permissions)
          CF_DNS_API_TOKEN = "your-cloudflare-dns-token"

          # Option 2: Global API Key (Less secure - full account access)
          # CF_API_EMAIL = "your-email@example.com"
          # CF_API_KEY   = "your-global-api-key"
        }
      }
    }

    dns_challenge_config = {
      resolvers          = ["1.1.1.1:53", "1.0.0.1:53"]
      delay_before_check = "60s" # Cloudflare is fast
    }
  }
}
