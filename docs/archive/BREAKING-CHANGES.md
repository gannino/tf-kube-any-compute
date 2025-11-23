# Breaking Changes

## v2.0.0 - Centralized Middleware System

### Overview
The legacy Traefik dashboard middleware system has been completely removed in favor of a centralized middleware system. This provides better consistency, security, and maintainability.

### Breaking Changes

#### 1. Legacy Middleware Removal
- **Removed**: `traefik_dashboard_password` variable
- **Removed**: Legacy middleware creation in `helm-traefik/ingress/`
- **Removed**: Automatic fallback to legacy middleware

#### 2. Required Configuration
All Traefik dashboard authentication now **requires** centralized middleware configuration:

```hcl
service_overrides = {
  traefik = {
    middleware_config = {
      basic_auth = {
        enabled = true
        # ... configuration
      }
    }
  }
}
```

#### 3. Migration Guide

**Before (v1.x):**
```hcl
# Old way - no longer works
traefik_dashboard_password = "my-password"
```

**After (v2.0+):**
```hcl
# New way - required
service_overrides = {
  traefik = {
    middleware_config = {
      basic_auth = {
        enabled         = true
        static_password = "my-password"  # or leave empty for auto-generation
        username        = "admin"
        realm           = "Traefik Dashboard"
      }
    }
  }
}

# Optional: Override authentication for specific services
auth_override = {
  prometheus   = "basic"
  alertmanager = "basic"
}
```

### Benefits
- **Consistent Authentication**: All services use the same middleware system
- **Better Security**: Centralized password management and middleware configuration
- **LDAP Support**: Easy LDAP integration with fallback to basic auth
- **Simplified Codebase**: Removed complex legacy middleware logic

### Migration Steps
1. Remove `traefik_dashboard_password` from your configuration
2. Add `middleware_config` to `service_overrides.traefik`
3. Configure `basic_auth.enabled = true` and set passwords
4. Optionally configure LDAP authentication
5. Run `terraform apply`

### Support
If you encounter issues during migration, please check the updated documentation or open an issue.
