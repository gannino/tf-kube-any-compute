# DNS Provider-Based Certificate Resolvers - Changelog

## Overview

This update enhances the tf-kube-any-compute project to support **DNS provider-based certificate resolvers** instead of hardcoded resolver names like "wildcard". This provides better clarity, flexibility, and maintainability for SSL certificate management.

## Key Changes

### 1. Enhanced Traefik Module (`helm-traefik/`)

#### Variables (`variables.tf`)
- Added comprehensive DNS provider configuration variables
- Added support for 11 DNS providers with validation
- Added DNS challenge configuration options
- Added flexible certificate resolver configuration

#### Logic (`locals.tf`)
- Updated certificate resolver computation to use DNS provider names
- Added support for creating resolvers named after DNS providers
- Maintained backward compatibility with legacy "wildcard" resolver

#### Template (`templates/traefik-values.yaml.tpl`)
- Updated to create certificate resolvers with DNS provider names
- Added dynamic DNS provider environment variable configuration
- Maintained legacy wildcard resolver for backward compatibility

#### Secrets (`main.tf`)
- Added dynamic DNS provider secret creation for all 11 supported providers
- Conditional secret creation based on primary DNS provider selection

#### Documentation (`README.md`)
- Completely rewritten with comprehensive DNS provider documentation
- Added usage examples for all supported providers
- Added troubleshooting and migration guides

### 2. Updated Main Module

#### Variables (`variables.tf`)
- Updated `traefik_cert_resolver` validation to accept DNS provider names
- Updated `cert_resolver_override` validation for all services
- Enhanced service overrides with DNS provider configuration

#### Logic (`locals.tf`)
- Updated certificate resolver mapping to use DNS provider names
- Added DNS provider name extraction from Traefik configuration
- Maintained backward compatibility with existing configurations

#### Module Calls (`main.tf`)
- Updated Traefik module call to pass DNS provider configuration
- All other modules automatically receive DNS provider name as certificate resolver

### 3. Updated All Service Modules

Updated validation in all service modules to accept DNS provider names:
- `helm-consul/variables.tf`
- `helm-grafana/variables.tf`
- `helm-vault/variables.tf`
- `helm-portainer/variables.tf`
- `helm-prometheus-stack/variables.tf`
- `helm-loki/variables.tf`

Each module now accepts both legacy resolver names and DNS provider names.

### 4. Configuration Files

#### `terraform.tfvars`
- Updated with DNS provider configuration examples
- Added Hurricane Electric as default DNS provider
- Added commented examples for Cloudflare, Route53, and DigitalOcean
- Added certificate resolver override examples

#### `terraform.tfvars.example`
- Updated with comprehensive DNS provider documentation
- Added configuration examples for all supported providers
- Added environment-specific DNS provider examples
- Added certificate resolver override documentation

### 5. Documentation

#### `DNS-PROVIDER-CERT-RESOLVERS.md`
- Comprehensive documentation for the new system
- Configuration examples for all supported providers
- Migration guide from legacy system
- Troubleshooting and debugging information

#### `examples/dns-provider-cert-resolvers.tfvars`
- Complete configuration example with Cloudflare
- Alternative provider examples
- Certificate resolver override examples

## Supported DNS Providers

The system now supports 11 DNS providers:

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

## Backward Compatibility

The update maintains full backward compatibility:

1. **Legacy Variables**: Old `traefik_cert_resolver = "wildcard"` still works
2. **Legacy Resolvers**: "wildcard" resolver is still created alongside DNS provider resolver
3. **Validation**: All modules accept both legacy and DNS provider names
4. **Migration**: No breaking changes - existing configurations continue to work

## Benefits

1. **Explicit Configuration**: Certificate resolvers clearly show which DNS provider is used
2. **Better Debugging**: Easy to identify DNS provider issues
3. **Flexible Management**: Easy to switch between DNS providers
4. **Future-Proof**: Extensible architecture for additional DNS providers
5. **Maintainability**: Clear relationship between DNS provider and certificate resolver

## Migration Path

### For Existing Users
No immediate action required - existing configurations continue to work.

### For New Deployments
Use the new DNS provider configuration:

```hcl
service_overrides = {
  traefik = {
    dns_providers = {
      primary = {
        name = "cloudflare"  # or your preferred provider
        config = {
          CF_API_EMAIL = "admin@example.com"
          CF_API_KEY   = "your-api-key"
        }
      }
    }
  }
}
```

### For Enhanced Flexibility
Configure certificate resolver overrides:

```hcl
cert_resolver_override = {
  vault = "default"  # Use HTTP challenge for Vault
}
```

## Testing

- All changes validated with `terraform validate`
- Unit tests updated and passing
- Configuration examples tested
- Backward compatibility verified

## Files Modified

### Core Infrastructure
- `variables.tf` - Enhanced validation and DNS provider support
- `locals.tf` - Updated certificate resolver logic
- `main.tf` - Updated Traefik module call
- `terraform.tfvars` - Updated with DNS provider configuration
- `terraform.tfvars.example` - Enhanced with comprehensive examples

### Traefik Module
- `helm-traefik/variables.tf` - Added DNS provider configuration
- `helm-traefik/locals.tf` - Updated resolver computation
- `helm-traefik/main.tf` - Added dynamic DNS provider secrets
- `helm-traefik/templates/traefik-values.yaml.tpl` - Updated template logic
- `helm-traefik/outputs.tf` - Enhanced DNS provider outputs
- `helm-traefik/README.md` - Completely rewritten documentation

### Service Modules
- `helm-consul/variables.tf` - Updated validation
- `helm-grafana/variables.tf` - Updated validation
- `helm-vault/variables.tf` - Updated validation
- `helm-portainer/variables.tf` - Updated validation
- `helm-prometheus-stack/variables.tf` - Updated validation
- `helm-loki/variables.tf` - Updated validation

### Documentation
- `DNS-PROVIDER-CERT-RESOLVERS.md` - New comprehensive guide
- `examples/dns-provider-cert-resolvers.tfvars` - Configuration examples
- `CHANGELOG-DNS-PROVIDERS.md` - This changelog

## Next Steps

1. **Test with Real DNS Providers**: Validate with actual DNS provider credentials
2. **Monitor Certificate Issuance**: Verify SSL certificates are issued correctly
3. **Update Documentation**: Add provider-specific troubleshooting guides
4. **Community Feedback**: Gather feedback on the new system
5. **Additional Providers**: Consider adding more DNS providers based on demand

This enhancement significantly improves the flexibility and maintainability of SSL certificate management in tf-kube-any-compute while maintaining full backward compatibility.
