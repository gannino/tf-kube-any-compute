# Authelia-Headlamp Integration Guide

This document explains how Authelia and Headlamp are integrated for single sign-on (SSO) authentication in your Kubernetes cluster.

## Overview

- **Authelia**: Universal authentication and SSO provider with LDAP backend and 2FA support
- **Headlamp**: Modern Kubernetes web UI that uses OIDC for authentication
- **Integration**: Headlamp uses Authelia as its OIDC identity provider for secure, centralized authentication

## Architecture

```
User → Headlamp → OIDC → Authelia → LDAP (JumpCloud)
                          ↓
                         2FA (TOTP/Duo)
```

### Authentication Flow

1. User accesses Headlamp at `https://headlamp.example.com`
2. Headlamp redirects to Authelia login page
3. User authenticates with LDAP credentials (JumpCloud)
4. Authelia prompts for 2FA (TOTP app or Duo)
5. Authelia issues OIDC token to Headlamp
6. Headlamp grants access to Kubernetes resources

## Configuration

### Terraform Configuration

#### Enable Services

```hcl
services = {
  authelia = true  # SSO provider
  headlamp = true  # Kubernetes UI
}
```

#### Authelia Configuration

```hcl
service_overrides = {
  authelia = {
    # Authentication settings
    default_policy = "two_factor"  # Require 2FA for all access
    ldap_enabled   = true
    ldap_url      = "ldap://ldap.jumpcloud.com"
    ldap_base_dn  = "ou=Users,o=5460a98766ac83ce5301f50b,dc=jumpcloud,dc=com"
    ldap_username_attribute = "uid"

    # OIDC provider (for Headlamp)
    oidc_enabled = true

    # 2FA configuration
    totp_enabled = true  # Enable TOTP authenticator apps
    duo_enabled  = false # Duo Security (optional)

    # Storage
    storage_class        = "nfs-csi-safe"
    persistent_disk_size = "1Gi"
  }
}
```

#### Headlamp OIDC Configuration

```hcl
service_overrides = {
  headlamp = {
    # OIDC authentication using Authelia
    oidc_config = {
      enabled        = true
      issuer_url     = "https://authelia.k3s.example.com"
      client_id      = "headlamp"
      client_secret  = "headlamp-secret-change-me"
      scopes         = ["openid", "profile", "email", "groups"]
      username_claim = "preferred_username"
      email_claim    = "email"
      groups_claim   = "groups"
    }
  }
}
```

### Authelia OIDC Client Configuration

The Headlamp OIDC client is automatically configured in `helm-authelia/templates/values.yaml.tpl`:

```yaml
identity_providers:
  oidc:
    - enabled: true
      client_id: "headlamp"
      client_secret: "headlamp-secret-change-me"
      issuer: https://authelia.k3s.example.com
      authorization_policy: two_factor
      scopes:
        - openid
        - profile
        - email
        - groups
      redirect_uris:
        - https://headlamp.example.com/oauth2/callback
      userinfo_signing_algorithm: none
```

## Access Control

### Default Policy

All services require **two-factor authentication** by default (`default_policy = "two_factor"`).

### Admin Group Access

Only users in the `admins` group can access services:

```yaml
access_control:
  rules:
    - domain: "*.k3s.example.com"
      policy: two_factor
      subject:
        - ["group:admins"]
```

### Adding Users to Admin Group

To grant a user access to Headlamp:

1. **In JumpCloud**: Add user to appropriate group
2. **Verify**: Check that user is in `admins` group in LDAP
3. **Test**: User can now access Headlamp with 2FA

## Security Features

### 1. LDAP Authentication

- **Provider**: JumpCloud LDAP
- **Authentication**: Username/password from LDAP
- **User Attributes**: `uid`, `displayName`, `mail`, `memberOf`

### 2. Two-Factor Authentication (2FA)

#### TOTP (Time-Based One-Time Password)

- **Enabled by default**: `totp_enabled = true`
- **Apps Supported**: Google Authenticator, Authy, Microsoft Authenticator, etc.
- **Setup**: First login prompts to scan QR code with authenticator app

#### Duo Security (Optional)

- **Configuration**: Set `duo_enabled = true` and provide Duo API credentials
- **Factors**: Push notification, SMS, phone call
- **Use Case**: Corporate environments with Duo integration

### 3. OIDC Provider Security

- **Client Secrets**: Configure strong secrets (change default `headlamp-secret-change-me`)
- **Scopes**: Minimal required scopes (`openid`, `profile`, `email`, `groups`)
- **Redirect URIs**: Exact match for Headlamp callback URL
- **Token Expiration**: Sessions expire after 1 hour of inactivity

### 4. Session Management

- **Session Duration**: 1 hour
- **Inactivity Timeout**: 5 minutes
- **Remember Me**: 1 month (optional)
- **Redis Storage**: Available for HA deployments

## First-Time Setup

### 1. Apply Configuration

```bash
terraform plan
terraform apply
```

### 2. Access Authelia Dashboard

Navigate to: `https://authelia.k3s.example.com`

### 3. Register First User

1. Enter LDAP username and password
2. Set up TOTP authenticator (scan QR code)
3. Complete 2FA setup

### 4. Access Headlamp

Navigate to: `https://headlamp.example.com`

You will be redirected to Authelia for authentication.

## Troubleshooting

### Login Fails at Authelia

**Problem**: Invalid credentials

**Solution**:
- Verify LDAP credentials in JumpCloud
- Check `ldap_url` and `ldap_base_dn` in configuration
- Ensure user account is active in JumpCloud

### TOTP Not Working

**Problem**: Invalid TOTP code

**Solution**:
- Ensure device time is synchronized
- Check TOTP app is using correct QR code
- Reset TOTP in Authelia if needed

### Headlamp OIDC Redirect Fails

**Problem**: "redirect_uri_mismatch" error

**Solution**:
- Verify `issuer_url` in headlamp oidc_config matches Authelia issuer
- Check redirect URI in Authelia configuration
- Ensure TLS certificates are valid for both domains

### Groups Not Working

**Problem**: User cannot access despite being in admin group

**Solution**:
- Verify `groups_claim` matches LDAP attribute (`memberOf`)
- Check group membership in JumpCloud
- Review Authelia logs for group resolution issues

### Session Expiring Too Quickly

**Problem**: Frequent re-authentication required

**Solution**:
- Adjust `session.expiration` in Authelia config (default: 1h)
- Adjust `session.inactivity` in Authelia config (default: 5m)
- Enable Redis for session persistence in HA setups

## Advanced Configuration

### Adding Additional OIDC Clients

To add another service as an OIDC client (e.g., Grafana, custom apps):

1. **Add client in Authelia template**:

```yaml
identity_providers:
  oidc:
    - enabled: true
      client_id: "grafana"
      client_secret: "grafana-secret"
      issuer: https://authelia.k3s.example.com
      authorization_policy: two_factor
      scopes:
        - openid
        - profile
        - email
      redirect_uris:
        - https://grafana.k3s.example.com/login/generic_oauth
```

2. **Configure service to use Authelia as OIDC provider**

### Custom Access Control Rules

Create fine-grained access control based on groups, domains, or policies:

```yaml
access_control:
  rules:
    # Admins get full access
    - domain: "*.k3s.example.com"
      policy: two_factor
      subject:
        - ["group:admins"]

    # Developers get access to development services
    - domain:
        - dev.k3s.example.com
        - grafana.k3s.example.com
      policy: two_factor
      subject:
        - ["group:developers"]

    # Read-only access for viewers
    - domain:
        - grafana.k3s.example.com
      policy: one_factor
      subject:
        - ["group:viewers"]
```

### Enabling Redis for High Availability

For production deployments with multiple Authelia replicas:

```hcl
service_overrides = {
  authelia = {
    redis_enabled = true
    redis_address = "redis-authelia:6379"
    # Redis must be deployed separately
  }
}
```

### Enabling Duo Security

For Duo Security 2FA:

```hcl
service_overrides = {
  authelia = {
    duo_enabled       = true
    duo_api_hostname = "api-XXXX.duosecurity.com"
    duo_integration_key = "DIXXXXXXXXXXXXXXXXXX"
    duo_secret_key    = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
  }
}
```

## Monitoring and Logging

### View Authelia Logs

```bash
kubectl logs -n authelia deployment/authelia -f
```

### View Headlamp Logs

```bash
kubectl logs -n headlamp deployment/headlamp -f
```

### Check OIDC Configuration

1. Access Authelia configuration:
```bash
kubectl get configmap -n authelia authelia -o yaml
```

2. Verify OIDC client configuration in `configuration.yml`

## References

- [Authelia Documentation](https://www.authelia.com/docs/)
- [Headlamp Documentation](https://headlamp.dev/docs/)
- [OIDC Core Specification](https://openid.net/connect/)
- [TOTP Best Practices](https://tools.ietf.org/html/rfc6238)

## Support

For issues or questions:

1. Check this guide for common problems
2. Review Authelia logs for detailed error messages
3. Verify configuration matches examples above
4. Consult service-specific documentation in `helm-authelia/README.md` and `helm-headlamp/HEADLAMP-AUTHENTICATION-GUIDE.md`
