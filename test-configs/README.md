# Test Configuration Files

This directory contains pre-configured `.tfvars` files for different deployment scenarios and testing environments.

## Available Configurations

### 🏠 **minimal.tfvars**
- **Use Case**: Resource-constrained environments, basic homelab setups
- **Services**: Only essential infrastructure (Traefik, MetalLB, HostPath)
- **Architecture**: AMD64
- **Storage**: Local hostPath only
- **SSL**: HTTP challenge (no DNS provider needed)

### 🏭 **production.tfvars**
- **Use Case**: Production enterprise environments
- **Services**: Full stack with security and monitoring
- **Architecture**: AMD64 with high resource limits
- **Storage**: Enterprise NFS with multiple storage classes
- **SSL**: DNS challenge with Cloudflare provider example
- **Features**: HA configurations, long retention periods

### ☁️ **cloud.tfvars**
- **Use Case**: Cloud provider deployments (EKS, GKE, AKS)
- **Services**: Cloud-optimized stack (no MetalLB)
- **Architecture**: AMD64 with cloud resources
- **Storage**: Cloud NFS/persistent volumes
- **SSL**: DNS challenge with Route53 provider example
- **Features**: Cloud load balancer integration

### 🔄 **mixed-cluster.tfvars**
- **Use Case**: Mixed ARM64/AMD64 clusters
- **Services**: Full stack with architecture-specific placement
- **Architecture**: Auto-detection with service placement optimization
- **Storage**: Both NFS and hostPath
- **SSL**: DNS challenge with Hurricane Electric (default)
- **Features**: Intelligent service placement, architecture overrides

### 🥧 **raspberry-pi.tfvars**
- **Use Case**: Raspberry Pi ARM64 clusters
- **Services**: Lightweight stack optimized for ARM64
- **Architecture**: ARM64 with resource constraints
- **Storage**: Local hostPath only
- **SSL**: HTTP challenge (resource efficient)
- **Features**: Optimized for low-power ARM64 devices

## DNS Provider Configuration

All configurations now use DNS provider names as certificate resolvers instead of the deprecated "wildcard" resolver:

### Supported DNS Providers
- `hurricane` - Hurricane Electric (default, auto-configured)
- `cloudflare` - Cloudflare DNS
- `route53` - AWS Route53
- `digitalocean` - DigitalOcean DNS
- `gandi` - Gandi DNS
- `namecheap` - Namecheap DNS
- `godaddy` - GoDaddy DNS
- `ovh` - OVH DNS
- `linode` - Linode DNS
- `vultr` - Vultr DNS
- `hetzner` - Hetzner DNS

### Configuration Examples

#### Hurricane Electric (Default)
```hcl
service_overrides = {
  traefik = {
    dns_providers = {
      primary = {
        name = "hurricane"
        config = {} # Auto-generated tokens
      }
    }
    cert_resolvers = {
      hurricane = {
        challenge_type = "dns"
        dns_provider = "hurricane"
      }
    }
  }
}
```

#### Cloudflare
```hcl
service_overrides = {
  traefik = {
    dns_providers = {
      primary = {
        name = "cloudflare"
        config = {
          CF_DNS_API_TOKEN = "your-dns-api-token"
        }
      }
    }
    cert_resolvers = {
      cloudflare = {
        challenge_type = "dns"
        dns_provider = "cloudflare"
      }
    }
  }
}
```

#### AWS Route53
```hcl
service_overrides = {
  traefik = {
    dns_providers = {
      primary = {
        name = "route53"
        config = {
          AWS_ACCESS_KEY_ID = "your-access-key"
          AWS_SECRET_ACCESS_KEY = "your-secret-key"
          AWS_REGION = "us-east-1"
        }
      }
    }
    cert_resolvers = {
      route53 = {
        challenge_type = "dns"
        dns_provider = "route53"
      }
    }
  }
}
```

## Usage

1. **Copy the appropriate configuration**:
   ```bash
   cp test-configs/minimal.tfvars terraform.tfvars
   ```

2. **Customize for your environment**:
   - Update domain names
   - Configure DNS provider credentials
   - Adjust resource limits
   - Modify service selection

3. **Deploy**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Testing

These configurations are used in CI/CD pipelines for:
- **Validation Testing**: Syntax and logic validation
- **Unit Testing**: Architecture detection and configuration logic
- **Integration Testing**: Service deployment and connectivity
- **Scenario Testing**: Different deployment patterns

## Migration from Legacy Configuration

If you're migrating from configurations using `traefik_cert_resolver = "wildcard"`:

1. **Remove the deprecated variable**:
   ```hcl
   # Remove this line
   # traefik_cert_resolver = "wildcard"
   ```

2. **Add DNS provider configuration**:
   ```hcl
   service_overrides = {
     traefik = {
       dns_providers = {
         primary = {
           name = "hurricane"  # or your preferred provider
           config = {}
         }
       }
       cert_resolvers = {
         hurricane = {
           challenge_type = "dns"
           dns_provider = "hurricane"
         }
       }
     }
   }
   ```

The system will automatically use the DNS provider name as the certificate resolver name.
