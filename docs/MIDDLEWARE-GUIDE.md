# Traefik Middleware Configuration Guide

## Overview

The tf-kube-any-compute project provides a comprehensive middleware system for Traefik that enables centralized authentication, rate limiting, and security controls across your Kubernetes infrastructure.

## Features

### 🔐 Authentication Middleware
- **Basic Authentication**: Username/password authentication with bcrypt hashing
- **LDAP Authentication**: Enterprise directory integration (JumpCloud, Active Directory, OpenLDAP)
- **Default Authentication**: Intelligent fallback system (LDAP → Basic Auth)

### 🛡️ Security Middleware
- **Rate Limiting**: Configurable request rate limiting with burst capacity
- **IP Whitelist**: Source IP filtering for enhanced security
- **Centralized Management**: Single configuration point for all middleware

### ⚡ Smart Features
- **CRD-Aware**: Automatically handles fresh cluster deployments without CRD errors
- **Priority System**: LDAP takes priority over Basic Auth when both are configured
- **Flexible Integration**: Use centralized middleware or legacy per-service authentication

## Quick Start

### Basic Authentication
```hcl
service_overrides = {
  traefik = {
    enable_dashboard = true
    middleware_config = {
      basic_auth = {
        enabled = true
        static_password = "secure-password-123"
        username = "admin"
      }
    }
    dashboard_middleware = ["traefik-basic-auth"]
  }
}
```

### LDAP Authentication
```hcl
service_overrides = {
  traefik = {
    middleware_config = {
      ldap_auth = {
        enabled = true
        url = "ldap://ldap.jumpcloud.com"
        base_dn = "ou=Users,o=YOUR_ORG_ID,dc=jumpcloud,dc=com"
      }
    }
    dashboard_middleware = ["traefik-ldap-auth"]
  }
}
```

## Middleware Names

Generated middleware names follow the pattern: `{service-name}-{type}`

- `traefik-basic-auth` - Basic authentication
- `traefik-ldap-auth` - LDAP authentication
- `traefik-default-auth` - Smart fallback authentication
- `traefik-rate-limit` - Rate limiting
- `traefik-ip-whitelist` - IP filtering

## Testing

```bash
# Validate configuration
./scripts/test-middleware.sh --validate-only

# Full test suite
./scripts/test-middleware.sh

# Test without cleanup
./scripts/test-middleware.sh --no-cleanup
```

## Migration from Legacy

The new system automatically handles CRD availability and provides centralized middleware management. Legacy per-service authentication is still supported as fallback.

## Troubleshooting

### CRD Not Found
The system automatically waits for Traefik CRDs. If issues persist, ensure Traefik is fully deployed.

### Middleware Not Applied
Check middleware names match the generated pattern and are in the correct namespace.

For detailed configuration options and examples, see `test-configs/middleware-test.tfvars`.
