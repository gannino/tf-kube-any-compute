# Flexible Middleware System

## Overview

The tf-kube-any-compute project implements a flexible middleware system that allows fine-grained control over which Traefik middlewares are applied to each service. This system provides security, authentication, and traffic management capabilities while maintaining ease of use.

## Architecture

### Service Categories

**Unprotected Services** (automatically get auth middleware when enabled):
- `traefik` - Dashboard
- `prometheus` - Metrics API
- `alertmanager` - Alert management

**Protected Services** (have built-in authentication):
- `grafana` - Built-in user management
- `portainer` - Built-in authentication
- `vault` - Built-in authentication
- `consul` - Built-in authentication

### Middleware Types

1. **Authentication Middlewares**
   - `basic_auth` - Username/password authentication
   - `ldap_auth` - LDAP directory integration
   - `default_auth` - Smart auth (LDAP with basic fallback)

2. **Security Middlewares**
   - `rate_limit` - Request rate limiting
   - `ip_whitelist` - IP-based access control

3. **Custom Middlewares**
   - User-defined middleware names

## Configuration

### 1. Enable Middlewares (Deploy)

```hcl
service_overrides = {
  traefik = {
    middleware_config = {
      # Deploy basic auth middleware
      basic_auth = {
        enabled = true
        username = "admin"
        realm = "Monitoring Services"
      }

      # Deploy rate limiting middleware
      rate_limit = {
        enabled = true
        average = 100  # requests per second
        burst = 200    # burst capacity
      }

      # Deploy IP whitelist middleware
      ip_whitelist = {
        enabled = true
        source_ranges = ["192.168.1.0/24", "10.0.0.0/8"]
      }
    }
  }
}
```

### 2. Apply Middlewares (Assign to Services)

```hcl
middleware_overrides = {
  # Global defaults (applied to all services unless overridden)
  all = {
    enable_rate_limit = true
    enable_ip_whitelist = true
  }

  # Per-service overrides
  traefik = {
    # Auth automatically applied (unprotected service)
    # Rate limit + IP whitelist from 'all'
  }

  prometheus = {
    disable_auth = true  # Remove auth for Prometheus
    # Rate limit + IP whitelist from 'all'
  }

  grafana = {
    # No auth needed (built-in authentication)
    # Rate limit + IP whitelist from 'all'
  }
}
```

## Usage Examples

### Maximum Security (All Middlewares)

```hcl
# Deploy all middlewares
service_overrides = {
  traefik = {
    middleware_config = {
      basic_auth = { enabled = true }
      rate_limit = { enabled = true }
      ip_whitelist = { enabled = true }
    }
  }
}

# Apply to all services
middleware_overrides = {
  all = {
    enable_rate_limit = true
    enable_ip_whitelist = true
  }
  # Auth automatically applied to unprotected services
}
```

### Selective Protection

```hcl
middleware_overrides = {
  traefik = {
    enable_rate_limit = true
    enable_ip_whitelist = true
    # Auth applied automatically
  }

  prometheus = {
    disable_auth = true
    enable_rate_limit = true
    # No IP whitelist
  }

  grafana = {
    # Only inherits from 'all' if defined
  }
}
```

### Custom Middlewares

```hcl
middleware_overrides = {
  traefik = {
    custom_middlewares = ["my-custom-middleware", "cors-middleware"]
  }
}
```

### Development Mode (No Security)

```hcl
# Deploy middlewares but don't apply them
service_overrides = {
  traefik = {
    middleware_config = {
      basic_auth = { enabled = true }
      rate_limit = { enabled = true }
      ip_whitelist = { enabled = true }
    }
  }
}

# Don't apply any middlewares
middleware_overrides = {
  all = {}
  traefik = { disable_auth = true }
}
```

## Implementation Details

### Middleware Name Generation

Middlewares are named using the pattern: `{workspace_prefix}-traefik-{middleware_type}`

Example: `prod-traefik-basic-auth`

### Priority Logic

1. **Service-specific settings** override global settings
2. **Global settings** (`all`) provide defaults
3. **Auth middleware** automatically applied to unprotected services unless `disable_auth = true`

### Terraform Locals Logic

```hcl
service_middlewares = {
  for service in all_services : service => compact(concat(
    # Auth for unprotected services
    contains(unprotected_services, service) && auth_enabled ? (
      disable_auth ? [] : [auth_middleware]
    ) : [],

    # Security middlewares
    enable_rate_limit ? [rate_limit_middleware] : [],
    enable_ip_whitelist ? [ip_whitelist_middleware] : [],

    # Custom middlewares
    custom_middlewares
  ))
}
```

## Contributing Guidelines

### Adding New Middleware Types

1. **Add to middleware module** (`helm-traefik/middleware/`)
   - Add variables in `variables.tf`
   - Add resources in `main.tf`
   - Add outputs in `outputs.tf`

2. **Update main variables** (`variables.tf`)
   - Add to `middleware_config` structure
   - Add to `middleware_overrides` structure

3. **Update locals** (`locals.tf`)
   - Add to `traefik_middleware_names`
   - Add to `service_middlewares` logic

4. **Update documentation**
   - Add examples to this file
   - Update README.md

### Testing New Middleware

1. **Deploy middleware**:
   ```hcl
   middleware_config = {
     new_middleware = { enabled = true }
   }
   ```

2. **Apply to test service**:
   ```hcl
   middleware_overrides = {
     traefik = {
       custom_middlewares = ["workspace-traefik-new-middleware"]
     }
   }
   ```

3. **Verify deployment**:
   ```bash
   kubectl get middleware -A
   kubectl get ingressroute traefik-dashboard -o yaml
   ```

### Best Practices

1. **Always test in development** before production
2. **Use global defaults** for consistent security
3. **Document custom middlewares** in your configuration
4. **Validate middleware names** match Traefik CRD format
5. **Consider service dependencies** when disabling auth

### Troubleshooting

**Middleware not applied**:
- Check `terraform console <<< "local.service_middlewares.{service}"`
- Verify middleware is deployed: `kubectl get middleware -A`
- Check ingress annotations: `kubectl get ingress {service} -o yaml`

**Auth not working**:
- Verify `middleware_config.basic_auth.enabled = true`
- Check service is in `unprotected_services` list
- Ensure `disable_auth = false` (default)

**Custom middleware not found**:
- Verify middleware exists: `kubectl get middleware {name} -n {namespace}`
- Check middleware name format matches Traefik requirements
- Ensure namespace is correct

## Migration from Legacy System

### Old System (Deprecated)
```hcl
traefik_dashboard_password = "password"
auth_override = {
  prometheus = "basic"
}
```

### New System
```hcl
service_overrides = {
  traefik = {
    middleware_config = {
      basic_auth = { enabled = true }
    }
  }
}

middleware_overrides = {
  all = { enable_rate_limit = true }
  prometheus = { disable_auth = true }
}
```

## Security Considerations

1. **Always enable IP whitelisting** for production
2. **Use strong passwords** for basic auth
3. **Consider LDAP integration** for enterprise environments
4. **Enable rate limiting** to prevent abuse
5. **Regularly review middleware assignments**
6. **Test auth bypass scenarios** during development

## Future Enhancements

- OAuth2/OIDC middleware support
- Dynamic middleware configuration
- Middleware health monitoring
- Advanced rate limiting strategies
- Geo-blocking capabilities
