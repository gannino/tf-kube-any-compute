# LDAP Authentication Methods

tf-kube-any-compute supports two methods for LDAP authentication with Traefik:

## 1. ForwardAuth Method (Default - Recommended)

Uses a dedicated Python service to handle LDAP authentication via Traefik's ForwardAuth middleware.

### Advantages
- ✅ **Works out of the box** - No plugin installation required
- ✅ **Reliable** - Uses standard Traefik ForwardAuth middleware
- ✅ **Flexible** - Easy to customize authentication logic
- ✅ **Debuggable** - Clear logs and error handling

### Configuration
```hcl
service_overrides = {
  traefik = {
    middleware_config = {
      ldap_auth = {
        enabled = true
        method  = "forwardauth"  # Default
        url     = "ldap://ldap.jumpcloud.com"
        base_dn = "ou=Users,o=YOUR_ORG_ID,dc=jumpcloud,dc=com"
      }
    }
  }
}
```

## 2. Plugin Method

Uses Traefik's LDAP plugin for direct LDAP authentication.

### Advantages
- ⚡ **Performance** - Direct LDAP authentication without additional service
- 🔧 **Native** - Uses Traefik's built-in plugin system

### Disadvantages
- ❌ **Plugin dependency** - Requires LDAP plugin to be installed in Traefik
- ❌ **Complex setup** - May require custom Traefik image or plugin installation
- ❌ **Limited debugging** - Plugin errors can be harder to troubleshoot

### Configuration
```hcl
service_overrides = {
  traefik = {
    middleware_config = {
      ldap_auth = {
        enabled = true
        method  = "plugin"
        url     = "ldap://ldap.jumpcloud.com"
        base_dn = "ou=Users,o=YOUR_ORG_ID,dc=jumpcloud,dc=com"
      }
    }
  }
}
```

### Plugin Installation Required

To use the plugin method, you need to install the LDAP plugin in Traefik. This can be done by:

1. **Custom Traefik Image**: Build a custom Traefik image with the plugin pre-installed
2. **Plugin Configuration**: Configure Traefik to download the plugin at startup
3. **Helm Values Override**: Use service_overrides to configure plugin installation

Example plugin configuration:
```yaml
# In Traefik Helm values
experimental:
  plugins:
    ldapAuth:
      moduleName: "github.com/wiltonsr/ldapAuth"
      version: "v0.1.5"
```

## Recommendation

**Use ForwardAuth method (default)** unless you have specific requirements for the plugin method. The ForwardAuth approach is more reliable and easier to troubleshoot.

## Common Configuration Options

Both methods support the same LDAP configuration parameters:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `enabled` | Enable LDAP authentication | `false` |
| `method` | Authentication method | `"forwardauth"` |
| `url` | LDAP server URL | `""` |
| `port` | LDAP server port | `389` |
| `base_dn` | Base DN for user search | `""` |
| `attribute` | Username attribute | `"uid"` |
| `bind_dn` | Service account DN | `""` |
| `bind_password` | Service account password | `""` |
| `search_filter` | Custom search filter | `""` |
| `log_level` | Logging level | `"INFO"` |

## Testing

Both methods can be tested using the same approach:

```bash
# Test LDAP authentication
curl -u "username:password" https://prometheus.homelab.k3s.example.com

# Check middleware logs (ForwardAuth method)
kubectl logs -n traefik deployment/homelab-ldap-auth-service

# Check Traefik logs (Plugin method)
kubectl logs -n traefik deployment/traefik
```
