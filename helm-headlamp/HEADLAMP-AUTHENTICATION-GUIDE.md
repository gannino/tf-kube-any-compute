# Headlamp Authentication Guide

## Important: Headlamp Uses OIDC, Not Direct LDAP

**Headlamp does NOT support direct LDAP authentication.** Instead, it uses **OpenID Connect (OIDC)** for authentication.

To use LDAP with Headlamp, you need an **OIDC Identity Provider** (like Dex, Keycloak, or Azure AD) that bridges LDAP to OIDC.

## Authentication Methods

Headlamp supports the following authentication methods:

1. **Kubernetes Service Account Token** (default) - Login using Kubeconfig token
2. **OIDC/OpenID Connect** - Login using external identity provider (supports LDAP via OIDC)
3. **Kubeconfig File** - Upload your kubeconfig file

## Using LDAP with Headlamp (via OIDC)

### Architecture

```
Headlamp → OIDC Protocol → OIDC Provider (Dex/Keycloak/Azure AD) → LDAP Server
```

### Option 1: Using Dex with LDAP

Dex is an OpenID Connect Provider that can authenticate against LDAP.

#### Step 1: Deploy Dex with LDAP Configuration

```yaml
apiVersion: v2
name: dex
description: Dex OIDC Provider with LDAP
type: application
version: "0.15.0"
```

Create a Dex configuration with LDAP connector:

```yaml
connectors:
  - type: ldap
    id: ldap
    name: LDAP
    config:
      host: ldap.example.com:389
      insecureNoSSL: true
      insecureSkipVerify: true
      bindDN: cn=admin,dc=example,dc=com
      bindPW: admin-password
      userSearch:
        baseDN: ou=users,dc=example,dc=com
        filter: "(objectClass=inetOrgPerson)"
        username: uid
        idAttr: uid
        emailAttr: mail
        nameAttr: cn
      groupSearch:
        baseDN: ou=groups,dc=example,dc=com
        filter: "(objectClass=groupOfNames)"
        userMatchers:
          - userAttr: DN
            groupAttr: member
        nameAttr: cn
```

#### Step 2: Configure Headlamp to Use Dex OIDC

```hcl
service_overrides = {
  headlamp = {
    oidc_config = {
      enabled                = true
      client_id              = "headlamp"
      client_secret          = "your-client-secret"
      issuer_url             = "https://dex.example.com"
      scopes                 = "profile,email,groups"
      use_access_token       = false
      validator_client_id     = "headlamp"
      validator_issuer_url   = "https://dex.example.com"
    }
  }
}
```

### Option 2: Using Keycloak with LDAP

Keycloak is a full-featured identity and access management solution that supports LDAP.

#### Step 1: Deploy Keycloak

```hcl
# Enable Keycloak service
services = {
  vault = false  # Keycloak can be used instead of Vault
}

service_overrides = {
  # Keycloak configuration
}
```

#### Step 2: Configure LDAP User Federation in Keycloak

1. Access Keycloak Admin Console
2. Navigate to: User Federation → Add provider → LDAP
3. Configure LDAP connection:
   - Connection URL: `ldap://ldap.example.com:389`
   - Bind DN: `cn=admin,dc=example,dc=com`
   - Bind Credential: `your-password`
   - Users DN: `ou=users,dc=example,dc=com`
   - Username LDAP attribute: `uid`
   - RDN LDAP attribute: `uid`
   - UUID LDAP attribute: `entryUUID`
4. Test connection and save

#### Step 3: Create Headlamp Client in Keycloak

1. Navigate to: Clients → Create
2. Client ID: `headlamp`
3. Client Authentication: ON
4. Valid Redirect URIs: `https://headlamp.example.com/*`
5. Save and note the Client Secret

#### Step 4: Configure Headlamp with Keycloak OIDC

```hcl
service_overrides = {
  headlamp = {
    oidc_config = {
      enabled                = true
      client_id              = "headlamp"
      client_secret          = "your-keycloak-client-secret"
      issuer_url             = "https://keycloak.example.com/realms/master"
      scopes                 = "profile,email,groups"
      use_access_token       = false
    }
  }
}
```

## Headlamp OIDC Configuration

### Variable Structure

```hcl
service_overrides = {
  headlamp = {
    oidc_config = {
      enabled                = true
      client_id              = "headlamp-client-id"
      client_secret          = "your-client-secret"
      issuer_url             = "https://oidc-provider.example.com"
      scopes                 = "profile,email,groups"
      use_access_token       = false
      validator_client_id     = ""
      validator_issuer_url   = ""
    }
  }
}
```

### OIDC Configuration Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `enabled` | bool | Enable OIDC authentication |
| `client_id` | string | OIDC client ID from identity provider |
| `client_secret` | string | OIDC client secret from identity provider |
| `issuer_url` | string | OIDC issuer URL (e.g., `https://keycloak.example.com/realms/master`) |
| `scopes` | string | OIDC scopes (default: `profile,email`) |
| `use_access_token` | bool | Use access token instead of ID token (for Azure AD) |
| `validator_client_id` | string | Client ID audience for token validation (Azure AD) |
| `validator_issuer_url` | string | Issuer URL for token validation (Azure AD) |

## Usage Examples

### Example 1: Dex with LDAP

```hcl
services = {
  headlamp = true
}

service_overrides = {
  headlamp = {
    oidc_config = {
      enabled        = true
      client_id      = "headlamp"
      client_secret  = var.dex_headlamp_client_secret
      issuer_url     = "https://dex.example.com"
      scopes        = "profile,email,groups"
    }
  }
}
```

### Example 2: Keycloak with LDAP

```hcl
services = {
  headlamp = true
}

service_overrides = {
  headlamp = {
    oidc_config = {
      enabled        = true
      client_id      = "headlamp"
      client_secret  = var.keycloak_headlamp_client_secret
      issuer_url     = "https://keycloak.example.com/realms/kubernetes"
      scopes        = "profile,email,groups"
    }
  }
}
```

### Example 3: Azure Entra ID

```hcl
services = {
  headlamp = true
}

service_overrides = {
  headlamp = {
    oidc_config = {
      enabled                = true
      client_id              = "your-azure-app-client-id"
      client_secret          = var.azure_client_secret
      issuer_url             = "https://login.microsoftonline.com/{tenant-id}/v2.0"
      scopes                = "6dae42f8-4368-4678-94ff-3960e28e3630/user.read openid email profile"
      use_access_token      = true
      validator_client_id    = "6dae42f8-4368-4678-94ff-3960e28e3630"
      validator_issuer_url  = "https://sts.windows.net/{tenant-id}/"
    }
  }
}
```

## How to Login with OIDC

### Step 1: Access Headlamp URL

Open your browser and navigate to:
```
https://headlamp.{your-domain}
```

### Step 2: Click "Sign in with OIDC"

You'll see a "Sign in" button that redirects to your OIDC provider.

### Step 3: Authenticate with OIDC Provider

You'll be redirected to your OIDC provider (Dex, Keycloak, Azure AD, etc.):

1. Enter your LDAP credentials (username/password)
2. Complete any MFA requirements
3. Authorize Headlamp to access your profile

### Step 4: Automatic Login

After successful authentication:
- OIDC provider redirects back to Headlamp
- Headlamp receives and validates the token
- You're automatically logged into Headlamp with your LDAP user identity

### Step 5: Kubernetes RBAC Mapping

Your OIDC user is mapped to Kubernetes RBAC via the `username` claim:

```yaml
# Example RBAC RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: headlamp-admin
  namespace: default
subjects:
- kind: User
  name: "john.doe@example.com"  # Your OIDC email/username
roleRef:
  kind: ClusterRole
  name: admin
  apiGroup: rbac.authorization.k8s.io
```

## Troubleshooting

### Issue: "Sign in" button not visible

**Cause**: OIDC configuration not enabled or invalid

**Solution**:
```hcl
# Ensure OIDC is enabled
oidc_config = {
  enabled = true  # Must be true
  client_id = "valid-client-id"
  client_secret = "valid-secret"
  issuer_url = "https://valid-issuer-url"
}
```

### Issue: Authentication fails with "Invalid issuer URL"

**Cause**: Incorrect issuer URL format

**Solution**:
- Keycloak: `https://keycloak.example.com/realms/{realm}`
- Dex: `https://dex.example.com`
- Azure AD: `https://login.microsoftonline.com/{tenant-id}/v2.0`

### Issue: Callback URL error

**Cause**: Redirect URI not configured in OIDC provider

**Solution**: Add the following redirect URI to your OIDC client:
```
https://headlamp.{your-domain}/oidc-callback
```

### Issue: "Token validation failed"

**Cause**: Validator configuration needed (Azure AD)

**Solution**: For Azure AD, set validator parameters:
```hcl
oidc_config = {
  validator_client_id   = "api://your-client-id"
  validator_issuer_url = "https://sts.windows.net/{tenant-id}/"
}
```

## Security Best Practices

### 1. Use TLS for OIDC

Always use HTTPS for OIDC callbacks:
```hcl
# Ensure Traefik is enabled with SSL
services = {
  traefik = true
  headlamp = true
}
```

### 2. Secure Client Secrets

Store OIDC client secrets securely:
```hcl
# Use Terraform variables or secret managers
oidc_config = {
  client_secret = var.headlamp_oidc_client_secret  # From secure source
}
```

### 3. Limit OIDC Scopes

Request only necessary scopes:
```hcl
oidc_config = {
  scopes = "profile,email"  # Minimal scopes
}
```

### 4. Enable Kubernetes RBAC

Configure appropriate RBAC for OIDC users:
```yaml
# Create specific roles for LDAP users
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: developer-role
rules:
- apiGroups: ["*"]
  resources: ["pods", "services", "configmaps"]
  verbs: ["get", "list", "create", "update"]
```

## Comparison: OIDC vs Direct LDAP

| Feature | OIDC (Recommended) | Direct LDAP |
|---------|---------------------|-------------|
| **Headlamp Support** | ✅ Native | ❌ Not supported |
| **Security** | ✅ Industry standard | ❌ Custom implementation |
| **Token Management** | ✅ Automatic | ❌ Manual |
| **Multi-factor** | ✅ Supported | ❌ Limited |
| **Scalability** | ✅ Enterprise-grade | ❌ Basic |
| **Standards** | ✅ OAuth 2.0/OIDC | ❌ Proprietary |

## References

- [Headlamp OIDC Documentation](https://headlamp.dev/docs/latest/installation/in-cluster/oidc/)
- [Dex Documentation](https://dexidp.io/docs/)
- [Keycloak Documentation](https://www.keycloak.org/documentation)
- [Kubernetes OIDC Authentication](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#openid-connect-tokens)
- [Azure AD OIDC Guide](https://docs.microsoft.com/en-us/azure/active-directory/develop/v2-protocols-oidc)

## Summary

**Key Points:**

1. ✅ Headlamp uses **OIDC**, not direct LDAP
2. ✅ LDAP authentication requires an **OIDC provider** (Dex, Keycloak, Azure AD)
3. ✅ OIDC providers bridge LDAP to OpenID Connect
4. ✅ This is the standard, secure approach for Kubernetes authentication
5. ✅ Users login via "Sign in" button, not token input

**Architecture:**
```
User → Headlamp → OIDC Protocol → Dex/Keycloak/Azure AD → LDAP Server
```

This approach provides:
- ✅ Enterprise-grade security
- ✅ Standard OIDC/OAuth 2.0 protocols
- ✅ Automatic token management
- ✅ Multi-factor authentication support
- ✅ Centralized identity management
