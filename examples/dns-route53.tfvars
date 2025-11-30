# ============================================================================
# DNS PROVIDER: AWS Route53
# ============================================================================
# AWS Route53 DNS configuration for Let's Encrypt SSL certificates
# ============================================================================

base_domain   = "example.com"
platform_name = "eks"
le_email      = "admin@example.com"

service_overrides = {
  traefik = {
    dns_providers = {
      primary = {
        name = "route53"
        config = {
          AWS_ACCESS_KEY_ID     = "your-access-key"
          AWS_SECRET_ACCESS_KEY = "your-secret-key"
          AWS_REGION            = "us-east-1"
        }
      }
    }

    dns_challenge_config = {
      resolvers          = ["8.8.8.8:53", "8.8.4.4:53"]
      delay_before_check = "120s"
    }
  }
}
