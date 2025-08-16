# Authentication Guide

## Overview

**tf-kube-any-compute** provides flexible authentication through Traefik middleware with support for multiple authentication methods. This guide covers the complete authentication setup process.

## 🚀 Quick Start (Recommended)

### Step 1: Initial Deployment
```bash
# Clone and setup
git clone https://github.com/gannino/tf-kube-any-compute.git
cd tf-kube-any-compute

# Copy example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit basic settings (domain, email, etc.)
vi terraform.tfvars

# Deploy core services (no authentication yet)
make init
terraform workspace new homelab
make apply
```

### Step 2: Enable Authentication
```bash
# Edit terraform.tfvars and change the enabled flag
vi terraform.tfvars

# Find this line in middleware_overrides section:
# enabled = false  # CHANGE TO TRUE after first deployment

# Change it to:
# enabled = true

# Apply authentication
make apply
```

## 🔐 Authentication Methods

### 1. Basic Authentication (Default)

**Best for:** Most users, homelab environments, simple setups

```hcl
service_overrides = {
  traefik = {
    middleware_config = {
      basic_auth = {
        enabled         = true
        username        = "admin"
        static_password = ""  # Auto-generated secure password
        realm           = "Monitoring Services"
      }
    }
  }
}
```

**Features:**
- ✅ Works out of the box
- ✅ Auto-generated secure passwords
- ✅ No external dependencies
- ✅ Perfect for homelab and development

### 2. LDAP Authentication

**Best for:** Enterprise environments, existing directory integration

#### JumpCloud Configuration
```hcl
service_overrides = {
  traefik = {
    middleware_config = {
      ldap_auth = {
        enabled   = true
        method    = "forwardauth"  # Recommended
        url       = "ldap://ldap.jumpcloud.com"
        base_dn   = "ou=Users,o=YOUR_ORG_ID,dc=jumpcloud,dc=com"
        attribute = "uid"
      }
    }
  }
}
```

#### Active Directory Configuration
```hcl
service_overrides = {
  traefik = {
    middleware_config = {
      ldap_auth = {
        enabled       = true
        method        = "forwardauth"
        url           = "ldap://ad.company.com"
        base_dn       = "dc=company,dc=com"
        bind_dn       = "cn=service,dc=company,dc=com"
        bind_password = "service-password"
        search_filter = "(sAMAccountName={username})"
      }
    }
  }
}
```

#### OpenLDAP Configuration
```hcl
service_overrides = {
  traefik = {
    middleware_config = {
      ldap_auth = {
        enabled   = true
        method    = "forwardauth"
        url       = "ldap://openldap.company.com"
        base_dn   = "ou=people,dc=company,dc=com"
        attribute = "uid"
      }
    }
  }
}
```

## 🛡️ Security Features

### Rate Limiting
Protects against brute force attacks:
```hcl
middleware_config = {
  rate_limit = {
    enabled = true
    average = 100  # requests per second
    burst   = 200  # burst capacity
  }
}
```

### IP Whitelisting
Restricts access to trusted networks:
```hcl
middleware_config = {
  ip_whitelist = {
    enabled       = true
    source_ranges = [
      "192.168.0.0/16",  # Private networks
      "10.0.0.0/8",
      "172.16.0.0/12"
    ]
  }
}
```

## 📋 Service Categories

### Unprotected Services (Require Authentication)
These services need authentication middleware:
- **Traefik Dashboard** - Ingress controller management
- **Prometheus** - Metrics collection
- **AlertManager** - Alert management

### Protected Services (Built-in Authentication)
These services have native authentication:
- **Grafana** - Dashboard and visualization
- **Portainer** - Container management
- **Vault** - Secrets management
- **Consul** - Service discovery

## 🔧 Advanced Configuration

### Per-Service Middleware Control
```hcl
middleware_overrides = {
  # Global defaults
  all = {
    enable_rate_limit   = true
    enable_ip_whitelist = true
  }

  # Service-specific overrides
  traefik = {
    disable_auth = false  # Keep auth for dashboard
  }

  prometheus = {
    disable_auth = false  # Enable auth
  }

  alertmanager = {
    disable_auth = false  # Enable auth
  }

  # Services with built-in auth
  grafana = {
    # No auth middleware needed
  }
}
```

### Custom Middleware
```hcl
middleware_overrides = {
  prometheus = {
    custom_middlewares = [
      "custom-auth-middleware",
      "custom-security-middleware"
    ]
  }
}
```

## 🔍 Troubleshooting

### Common Issues

#### 1. CRD Not Found Error
```
Error: CustomResourceDefinition not found
```
**Solution:** Deploy in two steps - core services first, then authentication.

#### 2. LDAP Connection Failed
```
LDAP Auth Error: connection failed
```
**Solutions:**
- Check LDAP URL and port
- Verify network connectivity
- Test with `ldapsearch` command
- Check bind credentials

#### 3. Authentication Loop
```
Redirect loop detected
```
**Solutions:**
- Check middleware order
- Verify service configuration
- Review Traefik logs

### Debug Commands
```bash
# Check middleware status
kubectl get middleware -A

# View Traefik logs
kubectl logs -n traefik-ingress-controller deployment/traefik

# Test LDAP connection
kubectl exec -it deployment/traefik-ldap-auth-service -- python -c "
import ldap3
server = ldap3.Server('ldap://ldap.jumpcloud.com')
conn = ldap3.Connection(server)
print('LDAP connection:', conn.bind())
"

# Check ingress annotations
kubectl get ingress -A -o yaml | grep middleware
```

## 📚 Examples

### Homelab Setup
```hcl
# terraform.tfvars
base_domain = "homelab.local"
platform_name = "k3s"

middleware_overrides = {
  all = {
    enable_rate_limit   = true
    enable_ip_whitelist = true
  }
  prometheus = { disable_auth = false }
  alertmanager = { disable_auth = false }
}

service_overrides = {
  traefik = {
    middleware_config = {
      basic_auth = {
        enabled = true
        username = "admin"
        static_password = "homelab123"
      }
      ip_whitelist = {
        enabled = true
        source_ranges = ["192.168.1.0/24"]
      }
    }
  }
}
```

### Enterprise Setup
```hcl
# terraform.tfvars
base_domain = "company.com"
platform_name = "k8s"

middleware_overrides = {
  all = {
    enable_rate_limit   = true
    enable_ip_whitelist = true
  }
  prometheus = { disable_auth = false }
  alertmanager = { disable_auth = false }
}

service_overrides = {
  traefik = {
    middleware_config = {
      ldap_auth = {
        enabled = true
        method = "forwardauth"
        url = "ldap://ad.company.com"
        base_dn = "dc=company,dc=com"
        bind_dn = "cn=k8s-service,ou=ServiceAccounts,dc=company,dc=com"
        bind_password = "secure-service-password"
        search_filter = "(sAMAccountName={username})"
      }
      rate_limit = {
        enabled = true
        average = 50
        burst = 100
      }
      ip_whitelist = {
        enabled = true
        source_ranges = ["10.0.0.0/8", "172.16.0.0/12"]
      }
    }
  }
}
```

## 🔗 Related Documentation

- [LDAP Authentication Methods](LDAP-AUTHENTICATION-METHODS.md) - Detailed LDAP configuration
- [Variables Guide](VARIABLES.md) - Complete configuration reference
- [Contributing Guide](CONTRIBUTING.md) - Development and testing
- [Troubleshooting](README.md#troubleshooting) - Common issues and solutions

## 🤝 Support

- **Issues**: [GitHub Issues](https://github.com/gannino/tf-kube-any-compute/issues)
- **Questions**: [GitHub Issues](https://github.com/gannino/tf-kube-any-compute/issues)
- **Documentation**: [Project Wiki](https://github.com/gannino/tf-kube-any-compute/wiki)
