# Headlamp LDAP Authentication Integration

## Overview

Headlamp now supports LDAP authentication using the same configuration structure as Traefik middleware, enabling centralized authentication management across your Kubernetes infrastructure.

## Architecture

The LDAP authentication integration follows these principles:

1. **Unified Configuration**: Uses the same LDAP structure as Traefik middleware
2. **Optional**: LDAP is disabled by default, works alongside Headlamp's built-in auth
3. **Flexible**: Supports multiple authentication methods (LDAP, basic, or default)
4. **Secure**: TLS support and configurable logging levels

## Configuration

### Variable Structure

```hcl
service_overrides = {
  headlamp = {
    # LDAP authentication configuration
    ldap_config = {
      enabled       = true
      url           = "ldap://ldap.example.com"
      port          = 389
      base_dn       = "ou=users,dc=example,dc=com"
      bind_dn       = "cn=admin,dc=example,dc=com"
      bind_password = "your-bind-password"
      attribute     = "uid"
      search_filter = "(uid={{username}})"
      log_level     = "INFO"
      use_tls       = true
    }
  }
}
```

### LDAP Configuration Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `enabled` | bool | `false` | Enable LDAP authentication |
| `url` | string | `""` | LDAP server URL (e.g., `ldap://ldap.example.com`) |
| `port` | number | `389` | LDAP server port (389 for LDAP, 636 for LDAPS) |
| `base_dn` | string | `""` | Base DN for user search (e.g., `ou=users,dc=example,dc=com`) |
| `bind_dn` | string | `""` | DN for bind account (for authenticated searches) |
| `bind_password` | string | `""` | Password for bind account |
| `attribute` | string | `"uid"` | LDAP attribute matching username (e.g., `uid`, `sAMAccountName`) |
| `search_filter` | string | `"(uid={{username}})"` | LDAP search filter with `{{username}}` placeholder |
| `log_level` | string | `"INFO"` | LDAP logging level: `DEBUG`, `INFO`, `WARN`, `ERROR` |
| `use_tls` | bool | `true` | Enable TLS/SSL for LDAP connections |

## Usage Examples

### Example 1: Basic LDAP Configuration

```hcl
service_overrides = {
  headlamp = {
    ldap_config = {
      enabled       = true
      url           = "ldap://ldap.example.com"
      port          = 389
      base_dn       = "ou=users,dc=example,dc=com"
      bind_dn       = "cn=admin,dc=example,dc=com"
      bind_password = "secret-password"
      attribute     = "uid"
      search_filter = "(uid={{username}})"
    }
  }
}
```

### Example 2: Active Directory Configuration

```hcl
service_overrides = {
  headlamp = {
    ldap_config = {
      enabled       = true
      url           = "ldaps://ad.example.com"
      port          = 636
      base_dn       = "DC=example,DC=com"
      bind_dn       = "CN=ldap-service,CN=Users,DC=example,DC=com"
      bind_password = "service-account-password"
      attribute     = "sAMAccountName"
      search_filter = "(sAMAccountName={{username}})"
      use_tls       = true
    }
  }
}
```

### Example 3: Complex Search Filter

```hcl
service_overrides = {
  headlamp = {
    ldap_config = {
      enabled       = true
      url           = "ldap://ldap.example.com"
      port          = 389
      base_dn       = "ou=users,dc=example,dc=com"
      bind_dn       = "cn=readonly,dc=example,dc=com"
      bind_password = "readonly-password"
      attribute     = "uid"
      search_filter = "(&(objectClass=inetOrgPerson)(uid={{username}})(memberOf=CN=Kubernetes Admins,OU=Groups,DC=example,DC=com))"
    }
  }
}
```

### Example 4: Enable Headlamp Service

```hcl
services = {
  headlamp = true
}

service_overrides = {
  headlamp = {
    ldap_config = {
      enabled       = true
      url           = "ldap://ldap.example.com"
      port          = 389
      base_dn       = "ou=users,dc=example,dc=com"
      bind_dn       = "cn=admin,dc=example,dc=com"
      bind_password = "your-bind-password"
      attribute     = "uid"
      search_filter = "(uid={{username}})"
    }

    # Optional: Configure storage and resources
    storage_class    = "nfs-csi-safe"
    enable_persistence = true
    cpu_limit        = "500m"
    memory_limit     = "512Mi"
  }
}
```

## Security Considerations

### 1. Bind Account Permissions

Use a read-only LDAP bind account with minimal permissions:

```hcl
bind_dn       = "cn=ldap-readonly,ou=service-accounts,dc=example,dc=com"
bind_password = var.ldap_readonly_password  # Store in Terraform state or secret manager
```

### 2. TLS/SSL Configuration

Always use LDAPS or StartTLS for production:

```hcl
ldap_config = {
  url     = "ldaps://ldap.example.com"  # Use ldaps:// for SSL
  port    = 636                          # LDAPS default port
  use_tls = true
}
```

### 3. Logging Level

Set appropriate logging for security:

- **Production**: `WARN` or `ERROR`
- **Testing**: `INFO`
- **Debugging**: `DEBUG` (do not use in production)

```hcl
log_level = "WARN"  # Production-safe logging
```

## Troubleshooting

### Issue: Authentication Fails

**Check LDAP connectivity:**

```bash
# Test LDAP connection
ldapsearch -x -H ldap://ldap.example.com:389 \
  -D "cn=admin,dc=example,dc=com" \
  -W \
  -b "ou=users,dc=example,dc=com" \
  "(uid=testuser)"
```

**Verify configuration:**

```hcl
ldap_config = {
  enabled       = true
  url           = "ldap://ldap.example.com"
  port          = 389
  base_dn       = "ou=users,dc=example,dc=com"  # Check base DN
  bind_dn       = "cn=admin,dc=example,dc=com"   # Check bind DN
  bind_password = "correct-password"              # Verify password
  attribute     = "uid"                          # Verify attribute
  search_filter = "(uid={{username}})"           # Test filter manually
  log_level     = "DEBUG"                        # Enable debug logs
}
```

### Issue: TLS Certificate Errors

**Certificate verification:**

```bash
# Test TLS connection
openssl s_client -connect ldap.example.com:636 -showcerts
```

**Disable TLS for testing (not recommended for production):**

```hcl
ldap_config = {
  use_tls = false  # Only for testing!
}
```

### Issue: User Not Found

**Test search filter manually:**

```bash
ldapsearch -x -H ldap://ldap.example.com:389 \
  -D "cn=admin,dc=example,dc=com" \
  -W \
  -b "ou=users,dc=example,dc=com" \
  "(&(objectClass=inetOrgPerson)(uid=john.doe))"
```

**Check attribute mapping:**

- Active Directory: Use `sAMAccountName`
- OpenLDAP: Use `uid` or `cn`
- Other directories: Check your schema

## Comparison with Traefik LDAP

Headlamp LDAP uses the same structure as Traefik middleware:

```hcl
# Traefik middleware LDAP
service_overrides = {
  traefik = {
    middleware_config = {
      ldap_auth = {
        enabled       = true
        url           = "ldap://ldap.example.com"
        port          = 389
        base_dn       = "ou=users,dc=example,dc=com"
        bind_dn       = "cn=admin,dc=example,dc=com"
        bind_password = "password"
        attribute     = "uid"
        search_filter = "(uid={{username}})"
        log_level     = "INFO"
      }
    }
  }
}

# Headlamp LDAP (same structure!)
service_overrides = {
  headlamp = {
    ldap_config = {
      enabled       = true
      url           = "ldap://ldap.example.com"
      port          = 389
      base_dn       = "ou=users,dc=example,dc=com"
      bind_dn       = "cn=admin,dc=example,dc=com"
      bind_password = "password"
      attribute     = "uid"
      search_filter = "(uid={{username}})"
      log_level     = "INFO"
      use_tls       = true  # Additional TLS control
    }
  }
}
```

## Implementation Details

### Files Modified

1. **helm-headlamp/variables.tf**: Added `ldap_config` variable
2. **helm-headlamp/locals.tf**: Added LDAP configuration to locals
3. **helm-headlamp/templates/headlamp-values.yaml.tpl**: Added LDAP authentication section
4. **locals.tf**: Added `ldap_config` to `service_configs.headlamp`
5. **main.tf**: Passed `ldap_config` to headlamp module

### Configuration Flow

```
variables.tf (ldap_config)
    ↓
locals.tf (service_configs.headlamp.ldap_config)
    ↓
main.tf (module.headlamp.ldap_config)
    ↓
helm-headlamp/locals.tf (local.ldap_config)
    ↓
helm-headlamp/templates/headlamp-values.yaml.tpl (authentication section)
    ↓
Headlamp Helm Chart (LDAP authentication enabled)
```

## Best Practices

1. **Use read-only bind accounts** for LDAP authentication
2. **Enable TLS** for all production deployments
3. **Set appropriate log levels** (WARN/ERROR for production)
4. **Test LDAP connectivity** before enabling in production
5. **Use environment-specific configurations** (dev/test/prod)
6. **Monitor authentication logs** for security events
7. **Regularly rotate bind account passwords**
8. **Use complex search filters** for group-based access control

## Future Enhancements

Potential future improvements:

1. LDAP group-based authorization
2. Multi-LDAP server support (failover)
3. LDAP attribute mapping customization
4. LDAP connection pooling
5. Authentication metrics and monitoring
6. Integration with Terraform secrets management

## Support

For issues or questions:

1. Check Headlamp logs: `kubectl logs -n <namespace> -l app.kubernetes.io/name=headlamp`
2. Review this document for configuration examples
3. Test LDAP connectivity using `ldapsearch` command
4. Check Traefik LDAP middleware for similar issues
5. Consult Headlamp documentation: https://headlamp.dev/

## References

- [Headlamp Documentation](https://headlamp.dev/)
- [LDAP Authentication](https://www.openldap.org/doc/admin24/guide.html)
- [Active Directory Documentation](https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/active-directory-domain-services)
- [Terraform Variables](https://www.terraform.io/docs/language/values/variables.html)
