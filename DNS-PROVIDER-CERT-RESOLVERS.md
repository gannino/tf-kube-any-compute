# DNS Provider-Based Certificate Resolvers

## Overview

The tf-kube-any-compute project now supports **DNS provider-based certificate resolvers** instead of hardcoded resolver names like "wildcard". This enhancement provides:

- **Explicit Configuration**: Certificate resolvers are named after their DNS provider (e.g., "cloudflare", "route53", "hurricane")
- **Better Clarity**: Makes it clear which DNS provider is being used for certificate challenges
- **Flexible Management**: Easier to manage multiple DNS providers and certificate resolvers
- **Backward Compatibility**: Legacy "wildcard" resolver still supported

## How It Works

### Before (Legacy System)
```hcl
# Hardcoded certificate resolver names
traefik_cert_resolver = "wildcard"

# All services use "wildcard" resolver
# Traefik creates: certificatesresolvers.wildcard.acme.*
```

### After (DNS Provider System)
```hcl
# DNS provider configuration
service_overrides = {
  traefik = {
    dns_providers = {
      primary = {
        name = "cloudflare"
        config = {
          CF_API_EMAIL = "admin@example.com"
          CF_API_KEY   = "your-api-key"
        }
      }
    }
  }
}

# Certificate resolver automatically named after DNS provider
# Traefik creates: certificatesresolvers.cloudflare.acme.*
# All services use "cloudflare" as traefik_cert_resolver
```

## Configuration Examples

### Cloudflare DNS Provider
```hcl
base_domain   = "example.com"
platform_name = "k3s"
le_email      = "admin@example.com"

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
```

### AWS Route53 DNS Provider
```hcl
service_overrides = {
  traefik = {
    dns_providers = {
      primary = {
        name = "route53"
        config = {
          AWS_ACCESS_KEY_ID     = "your-access-key"
          AWS_SECRET_ACCESS_KEY = "your-secret-key"
          AWS_REGION           = "us-east-1"
        }
      }
    }
  }
}
```

### Hurricane Electric DNS Provider (Default)
```hcl
service_overrides = {
  traefik = {
    dns_providers = {
      primary = {
        name = "hurricane"
        config = {}  # Uses auto-generated tokens
      }
    }
  }
}
```

## Supported DNS Providers

The system supports 11 DNS providers:

1. **hurricane** - Hurricane Electric (default)
2. **cloudflare** - Cloudflare DNS
3. **route53** - AWS Route53
4. **digitalocean** - DigitalOcean DNS
5. **gandi** - Gandi DNS
6. **namecheap** - Namecheap DNS
7. **godaddy** - GoDaddy DNS
8. **ovh** - OVH DNS
9. **linode** - Linode DNS
10. **vultr** - Vultr DNS
11. **hetzner** - Hetzner DNS

## Certificate Resolver Naming

### Automatic Naming
When you configure a DNS provider, the certificate resolver is automatically named after the provider:

- `cloudflare` DNS provider → `cloudflare` certificate resolver
- `route53` DNS provider → `route53` certificate resolver
- `hurricane` DNS provider → `hurricane` certificate resolver

### Service Usage
All services automatically use the DNS provider name as their certificate resolver:

```yaml
# Kubernetes Ingress annotations
traefik.ingress.kubernetes.io/router.tls.certresolver: cloudflare
```

### Traefik Configuration
Traefik automatically creates the certificate resolver:

```yaml
# Traefik configuration
certificatesresolvers:
  cloudflare:
    acme:
      email: admin@example.com
      storage: /certs/acme-cloudflare.json
      dnschallenge:
        provider: cloudflare
        resolvers: ["1.1.1.1:53", "8.8.8.8:53"]
        delayBeforeCheck: 120s
```

## Override Specific Services

You can still override certificate resolvers for specific services:

```hcl
# Use Cloudflare for most services, HTTP challenge for Vault
cert_resolver_override = {
  grafana    = "cloudflare"  # Use Cloudflare resolver
  prometheus = "cloudflare"  # Use Cloudflare resolver
  vault      = "default"     # Use HTTP challenge for Vault
}
```

## Migration from Legacy System

### Step 1: Identify Current Configuration
```hcl
# Old configuration
traefik_cert_resolver = "wildcard"
```

### Step 2: Configure DNS Provider
```hcl
# New configuration
service_overrides = {
  traefik = {
    dns_providers = {
      primary = {
        name = "cloudflare"  # Replace with your DNS provider
        config = {
          # Add your DNS provider credentials
          CF_API_EMAIL = "admin@example.com"
          CF_API_KEY   = "your-api-key"
        }
      }
    }
  }
}
```

### Step 3: Update Certificate Resolver References
The system automatically updates all certificate resolver references to use the DNS provider name. No manual changes needed.

### Step 4: Verify Configuration
After applying the changes:

1. Check Traefik logs for certificate resolver creation
2. Verify ingress annotations use the new resolver name
3. Confirm SSL certificates are issued correctly

## Backward Compatibility

The system maintains backward compatibility:

1. **Legacy Variables**: Old `traefik_cert_resolver` variable still works
2. **Wildcard Resolver**: Legacy "wildcard" resolver is still created
3. **Validation**: All modules accept both legacy and DNS provider names

## Troubleshooting

### Common Issues

1. **DNS Provider Credentials**: Ensure credentials are correctly configured
2. **DNS Propagation**: Allow time for DNS changes to propagate
3. **Rate Limits**: Be aware of Let's Encrypt rate limits
4. **Firewall**: Ensure DNS queries can reach configured resolvers

### Debug Information

Enable debug outputs to see certificate resolver configuration:

```hcl
enable_debug_outputs = true
```

Check the `cert_resolver_debug` output for detailed information.

### Logs

Check Traefik logs for certificate resolver activity:

```bash
kubectl logs -n traefik-ingress deployment/traefik
```

## Benefits

1. **Clarity**: Explicit DNS provider naming makes configuration clearer
2. **Flexibility**: Easy to switch between DNS providers
3. **Maintainability**: Easier to manage multiple certificate resolvers
4. **Debugging**: Clear relationship between DNS provider and certificate resolver
5. **Future-Proof**: Extensible to support additional DNS providers

## Example Deployment

Complete example with Cloudflare DNS provider:

```hcl
# terraform.tfvars
base_domain   = "example.com"
platform_name = "k3s"
le_email      = "admin@example.com"

service_overrides = {
  traefik = {
    dns_providers = {
      primary = {
        name = "cloudflare"
        config = {
          CF_API_EMAIL = "admin@example.com"
          CF_API_KEY   = "your-global-api-key"
        }
      }
    }

    dns_challenge_config = {
      resolvers                 = ["1.1.1.1:53", "8.8.8.8:53"]
      delay_before_check        = "120s"
      disable_propagation_check = false
    }
  }
}

# Optional: Override specific services
cert_resolver_override = {
  vault = "default"  # Use HTTP challenge for Vault
}
```

This configuration will:
1. Create a "cloudflare" certificate resolver in Traefik
2. Configure all services to use "cloudflare" as their certificate resolver
3. Use Cloudflare DNS for ACME DNS challenges
4. Override Vault to use HTTP challenge instead

The result is a clear, maintainable certificate management system that explicitly shows which DNS provider is being used for each service.
