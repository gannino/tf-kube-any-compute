# Authelia Module

The `helm-authelia` module deploys [Authelia](https://www.authelia.com/), an open-source authentication and authorization server providing two-factor authentication (2FA) and single sign-on (SSO) for your applications.

## Features

- **Single Sign-On (SSO)**: Centralized authentication for all your applications
- **Two-Factor Authentication (2FA)**: TOTP-based authentication (Google Authenticator, Authy, etc.)
- **LDAP Integration**: Enterprise-grade authentication with directory services
- **OIDC Provider**: Act as an identity provider for other services (e.g., Headlamp)
- **Access Control**: Fine-grained access policies based on users, groups, and networks
- **Session Management**: Secure session handling with Redis support for high availability
- **Traefik Integration**: Seamless integration with Traefik ingress and forward authentication
- **Multi-Architecture Support**: ARM64 and AMD64 architecture awareness
- **Prometheus Monitoring**: Optional ServiceMonitor integration for metrics collection and visualization

## Architecture

```
┌─────────────────┐
│   Traefik       │
│   Ingress       │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Authelia     │
│   (9091)       │
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
┌─────────┐ ┌─────────┐
│  LDAP   │ │ Redis   │
│ (Optional)│ │ (Optional)│
└─────────┘ └─────────┘

Storage:
┌─────────────────┐
│  Terraform     │
│  Managed PVC    │
│  (1Gi)        │
└─────────────────┘
```

### Storage Architecture

Authelia uses a **Terraform-managed Persistent Volume Claim** for configuration database storage:

- **PVC Name**: `{name}-storage` (e.g., `authelia-storage`)
- **Default Size**: 1Gi (configurable via `persistent_disk_size`)
- **Storage Class**: Configurable via `storage_class` variable
- **Lifecycle**: Managed independently from Helm releases
- **Benefits**:
  - Safe Helm upgrades without PVC replacement issues
  - Data preservation during configuration changes
  - No PVC immutability errors during `helm_replace: true` operations

## Requirements

- **Kubernetes**: 1.21+
- **Helm**: 3.0+
- **Traefik**: For ingress and forward authentication (recommended)
- **Storage**: 1Gi persistent volume for configuration database

## Usage

### Basic Configuration

```hcl
module "authelia" {
  source = "./helm-authelia"

  domain_name   = ".example.com"
  cpu_arch      = "amd64"
  storage_class = "nfs-csi-safe"

  traefik_ingress_config = {
    class_name    = "traefik"
    annotations   = {}
    cert_resolver = "letsencrypt"
    domain_name   = ".example.com"
  }
}
```

### LDAP Integration

```hcl
module "authelia" {
  source = "./helm-authelia"

  domain_name   = ".example.com"
  cpu_arch      = "amd64"

  # Enable LDAP authentication
  ldap_enabled     = true
  ldap_url         = "ldap://ldap.example.com:389"
  ldap_base_dn     = "dc=example,dc=com"
  ldap_bind_dn     = "cn=admin,dc=example,dc=com"
  ldap_bind_password = var.ldap_admin_password

  # Custom LDAP filters
  ldap_user_filter = "(&({ldap_username_attribute}={input})(objectClass=person))"
  ldap_group_filter = "(member={dn})"
}
```

### OIDC Provider (for Headlamp, etc.)

```hcl
module "authelia" {
  source = "./helm-authelia"

  domain_name   = ".example.com"
  cpu_arch      = "amd64"

  # Enable OIDC provider
  oidc_enabled = true

  oidc_clients = {
    headlamp = {
      client_id     = "headlamp"
      client_secret = "changeme-headlamp-secret"
      redirect_uris = [
        "https://headlamp.example.com/oauth2/callback"
      ]
    }
    grafana = {
      client_id     = "grafana"
      client_secret = "changeme-grafana-secret"
      redirect_uris = [
        "https://grafana.example.com/login/generic_oauth"
      ]
    }
  }
}
```

#### OIDC Client Secret Security

**Important**: Authelia recommends hashing client secrets in the configuration rather than using plaintext. However, for homelab and development environments, this module uses the `$plaintext$` prefix for backward compatibility and ease of use.

**Current Implementation**: The module automatically prefixes all client secrets with `$plaintext$` in the configuration, which Authelia accepts but considers deprecated.

**For Production Environments**: Generate proper password hashes for each client secret:

```bash
# Generate a hashed client secret using Authelia's recommended method
docker run --rm authelia/authelia:latest authelia crypto hash generate \
  pbkdf2 --variant sha512 --random --random.length 72 --random.charset rfc3986

# Example output:
# Plaintext Password: abc123...xyz
# Password Hash: $pbkdf2-sha512$310000$...
```

Then update your configuration to use the hashed value:

```hcl
oidc_clients = {
  headlamp = {
    client_id     = "headlamp"
    # Use the hash value without the $plaintext$ prefix
    client_secret = "$pbkdf2-sha512$310000$..."
    redirect_uris = ["https://headlamp.example.com/oauth2/callback"]
  }
}
```

**Note**: When using hashed secrets, remove the `client_secret` value from your OIDC client application configuration. The client application should use the plaintext secret, while Authelia stores the hash.

### High Availability with Redis

#### Manual Redis Configuration

```hcl
module "authelia" {
  source = "./helm-authelia"

  domain_name   = ".example.com"
  cpu_arch      = "amd64"
  replica_count = 2

  # Enable Redis for distributed sessions
  redis_enabled = true
  redis_address = "redis.redis-stack.svc.cluster.local"
}
```

#### Automatic Redis Configuration (Recommended)

When deploying Redis using the `redis` module in this project, use `redis_module_reference` for automatic service discovery:

```hcl
module "redis" {
  source = "./redis"

  enable_persistence = true
  storage_class      = "nfs-csi-safe"
}

module "authelia" {
  source = "./helm-authelia"

  domain_name   = ".example.com"
  cpu_arch      = "amd64"
  replica_count = 2

  # Automatic Redis configuration using module reference
  redis_enabled          = true
  redis_module_reference = module.redis[0].service_host
}
```

**Benefits of `redis_module_reference`:**
- Automatic service discovery
- No manual address configuration
- Consistent with project patterns
- Works seamlessly with workspace-aware deployments

### Duo Security 2FA

```hcl
module "authelia" {
  source = "./helm-authelia"

  domain_name   = ".example.com"
  cpu_arch      = "amd64"

  # Enable Duo Security
  duo_enabled        = true
  duo_api_hostname   = "api-xxxx.duosecurity.com"
  duo_integration_key = var.duo_integration_key
  duo_secret_key     = var.duo_secret_key
}
```

### Prometheus Monitoring

```hcl
module "authelia" {
  source = "./helm-authelia"

  domain_name   = ".example.com"
  cpu_arch      = "amd64"

  # Enable Prometheus ServiceMonitor
  enable_servicemonitor   = true
  servicemonitor_namespace = "monitoring"
}
```

## Configuration

### Required Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `cpu_arch` | CPU architecture (amd64, arm64) | - |
| `domain_name` | Domain name for ingress | `.local` |
| `storage_class` | Storage class for persistent volume | `hostpath` |

### Authentication Backends

| Variable | Description | Default |
|----------|-------------|---------|
| `default_policy` | Default access policy (one_factor, two_factor, deny) | `one_factor` |
| `ldap_enabled` | Enable LDAP authentication | `false` |
| `oidc_enabled` | Enable OIDC provider | `false` |
| `totp_enabled` | Enable TOTP 2FA | `true` |
| `duo_enabled` | Enable Duo Security 2FA | `false` |

### LDAP Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `ldap_url` | LDAP server URL | `` |
| `ldap_base_dn` | LDAP base DN | `` |
| `ldap_bind_dn` | LDAP bind DN | `` |
| `ldap_bind_password` | LDAP bind password | `` |
| `ldap_user_filter` | LDAP user search filter | `(uid={input})` |
| `ldap_group_filter` | LDAP group search filter | `(member={dn})` |
| `ldap_username_attribute` | LDAP username attribute | `uid` |

### Resource Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `cpu_limit` | CPU limit | `500m` |
| `memory_limit` | Memory limit | `512Mi` |
| `cpu_request` | CPU request | `100m` |
| `memory_request` | Memory request | `128Mi` |
| `persistent_disk_size` | Disk size | `1Gi` |
| `replica_count` | Number of replicas | `1` |

### Traefik Integration

| Variable | Description | Default |
|----------|-------------|---------|
| `traefik_cert_resolver` | Traefik certificate resolver | `default` |
| `traefik_ingress_config` | Traefik ingress configuration | `null` |

### Monitoring Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `enable_servicemonitor` | Enable Prometheus ServiceMonitor for metrics | `false` |
| `servicemonitor_namespace` | Namespace for ServiceMonitor (where Prometheus Operator is deployed) | `monitoring` |

### Namespace Cleanup Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `force_namespace_cleanup` | Force cleanup of namespace if deletion gets stuck (WARNING: Only use when namespace is stuck in Terminating phase) | `false` |
| `cleanup_timeout` | Timeout for namespace cleanup operations (e.g., 5m, 10m, 30s) | `10m` |
| `workspace_prefix` | Workspace prefix for kubeconfig file selection (e.g., 'prod', 'sit', 'dev'). Matches main provider.tf logic. | `""` |
| `ci_mode` | Running in CI mode (kubeconfig handled externally). | `false` |
| `kubeconfig_path` | Explicit kubeconfig path (overrides automatic detection). Leave empty to use workspace-based or default kubeconfig. | `""` |

#### Kubeconfig Detection Logic

The module automatically detects the correct kubeconfig file using the same logic as the main Terraform provider:

1. **Explicit Path**: If `kubeconfig_path` is provided, it's used directly
2. **CI Mode**: If `ci_mode` is `true`, kubeconfig is handled externally (set to `null`)
3. **Workspace-based**: Checks for `~/.kube/${workspace_prefix}-config` (e.g., `~/.kube/prod-config`)
4. **Default**: Falls back to `~/.kube/config` if no workspace-specific config exists

This ensures consistent kubeconfig selection across all modules and providers in your Terraform workspace.

## Outputs

| Output | Description |
|--------|-------------|
| `namespace` | Namespace where Authelia is deployed |
| `service_name` | Name of the Authelia service |
| `service_url` | URL to access Authelia web interface |
| `oidc_issuer_url` | OIDC issuer URL for other services |
| `ingress_config` | Ingress configuration for other services |
| `forward_auth_middleware` | Traefik forward auth middleware reference |
| `namespace_status` | Current status and health of Authelia namespace (name, uid, labels, annotations) |
| `namespace_cleanup_enabled` | Whether force cleanup is currently enabled |

## Access Control

Authelia uses a flexible access control system based on policies:

```yaml
access_control:
  default_policy: one_factor
  networks:
    - name: internal
      networks:
        - 10.0.0.0/8
        - 172.16.0.0/12
        - 192.168.0.0/16
  rules:
    - domain: "*.{domain_name}"
      policy: two_factor
      subject:
        - ["group:admins"]
```

### Policy Types

- `one_factor`: Single factor authentication (password only)
- `two_factor`: Two-factor authentication (password + 2FA)
- `deny`: Deny access completely

## Using Authelia with Traefik

### Forward Authentication

Protect any service behind Traefik using Authelia's forward authentication:

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: authelia-forward-auth
spec:
  forwardAuth:
    address: http://authelia.authelia-stack.svc.cluster.local:9091/api/verify
    trustForwardHeader: true
    authResponseHeaders:
      - Remote-User
      - Remote-Groups
      - Remote-Name
      - Remote-Email
```

Apply to any service's ingress route:

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: myapp
spec:
  routes:
    - match: Host(`app.example.com`)
      kind: Rule
      middlewares:
        - name: authelia-forward-auth
          namespace: authelia-stack
      services:
        - name: myapp
          port: 80
```

## Initial Setup

1. **Access Authelia**: Navigate to `https://authelia.${domain_name}`
2. **Create Admin User**: First user becomes administrator automatically
3. **Configure 2FA**: Set up TOTP with your authenticator app
4. **Add Users**: Create additional users through the web interface
5. **Configure Rules**: Set up access policies for your applications

## Troubleshooting

### Check Authelia Logs

```bash
kubectl logs -n authelia-stack deployment/authelia
```

### Verify Configuration

```bash
kubectl get configmap -n authelia-stack authelia -o yaml
```

### Test Authentication

```bash
curl -X POST https://authelia.example.com/api/verify \
  -H "X-Original-URL: https://app.example.com" \
  -H "X-Forwarded-Host: app.example.com"
```

### Session Issues with Redis

```bash
# Check Redis connection
kubectl logs -n authelia-stack deployment/authelia | grep redis

# Verify Redis address
kubectl get deployment authelia -n authelia-stack -o yaml | grep redis
```

### LDAP Connection Issues

```bash
# Test LDAP connectivity
kubectl exec -it authelia-0 -n authelia-stack -- ldapsearch \
  -H ldap://ldap.example.com:389 \
  -D "cn=admin,dc=example,dc=com" \
  -W \
  -b "dc=example,dc=com"
```

### Namespace Cleanup Issues

#### Stuck Namespace in Terminating Phase

If the Authelia namespace gets stuck in `Terminating` phase, you can use the force cleanup feature:

```hcl
module "authelia" {
  source = "./helm-authelia"

  # Enable force cleanup for stuck namespace
  force_namespace_cleanup = true
  cleanup_timeout          = "10m"
}
```

Then run:

```bash
terraform apply
terraform destroy  # This will trigger force cleanup
```

#### Manual Cleanup (if Terraform cleanup fails)

```bash
# Get namespace JSON
kubectl get namespace authelia-stack -o json > ns.json

# Remove finalizers
jq 'del(.spec.finalizers)' ns.json > ns-cleaned.json

# Apply cleaned namespace
kubectl replace --raw "/api/v1/namespaces/authelia-stack/finalize" -f ns-cleaned.json

# Wait for deletion
kubectl wait --for=delete namespace/authelia-stack --timeout=10m
```

#### Check Namespace Status

```bash
# Check if namespace is stuck in terminating
kubectl get namespace authelia-stack -o jsonpath='{.status.phase}'

# Get namespace details
terraform output namespace_status

# Check if cleanup is enabled
terraform output namespace_cleanup_enabled
```

## Security Best Practices

1. **Secrets Management**: Use Kubernetes secrets or external secret management
2. **Strong Passwords**: Enforce strong password policies
3. **2FA Required**: Require two-factor authentication for sensitive applications
4. **Network Policies**: Restrict network access with Kubernetes NetworkPolicies
5. **Regular Updates**: Keep Authelia updated with security patches
6. **Audit Logging**: Enable audit logging for compliance requirements
7. **Namespace Management**: Use lifecycle rules and force cleanup only when necessary; avoid production namespaces stuck in terminating phase

## Integration Examples

### Headlamp with OIDC

```hcl
module "headlamp" {
  source = "./helm-headlamp"

  oidc_enabled         = true
  oidc_issuer_url      = module.authelia.oidc_issuer_url
  oidc_client_id       = "headlamp"
  oidc_client_secret   = var.headlamp_oidc_secret
}
```

### Protecting Services with Authelia

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: portainer
spec:
  entryPoints:
    - websecure
  routes:
    - match: Host(`portainer.example.com`)
      kind: Rule
      middlewares:
        - name: authelia-forward-auth
          namespace: authelia-stack
      services:
        - name: portainer
          port: 9443
  tls:
    certResolver: letsencrypt
```

## Resources

- [Authelia Documentation](https://www.authelia.com/docs/)
- [Traefik Forward Auth](https://doc.traefik.io/traefik/middlewares/http/forwardauth/)
- [OIDC Provider Configuration](https://www.authelia.com/docs/configuration/identity-providers/openid-connect/)
- [LDAP Integration](https://www.authelia.com/docs/configuration/authentication/ldap/)

## Contributing

When contributing to the Authelia module, please follow these guidelines:

1. Test changes across both ARM64 and AMD64 architectures
2. Ensure backward compatibility with existing configurations
3. Update documentation for new features
4. Add appropriate validation rules for new variables
5. Follow the existing code style and patterns

## License

This module is part of the `tf-kube-any-compute` project. See the main repository for licensing information.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.14 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 3.0 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | ~> 1.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | 3.1.1 |
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | 1.19.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.38.0 |
| <a name="provider_null"></a> [null](#provider\_null) | 3.2.4 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.8.1 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | 4.2.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.this](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubectl_manifest.authelia_servicemonitor](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubernetes_config_map.authelia_config](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_ingress_v1.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/ingress_v1) | resource |
| [kubernetes_limit_range.namespace_limits](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/limit_range) | resource |
| [kubernetes_namespace.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_persistent_volume_claim.authelia](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume_claim) | resource |
| [kubernetes_secret.authelia_secrets](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.ldap_credentials](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [null_resource.force_namespace_cleanup](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [random_password.jwt_secret](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_password.session_secret](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_password.storage_encryption_key](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [tls_private_key.oidc_jwt](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_chart_name"></a> [chart\_name](#input\_chart\_name) | Helm chart name for Authelia. | `string` | `"authelia"` | no |
| <a name="input_chart_repo"></a> [chart\_repo](#input\_chart\_repo) | Helm repository URL for Authelia charts. | `string` | `"https://charts.authelia.com"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Helm chart version for Authelia. | `string` | `"0.10.49"` | no |
| <a name="input_ci_mode"></a> [ci\_mode](#input\_ci\_mode) | Running in CI mode (kubeconfig handled externally). | `bool` | `false` | no |
| <a name="input_cleanup_timeout"></a> [cleanup\_timeout](#input\_cleanup\_timeout) | Timeout for namespace cleanup operations (e.g., 5m, 10m, 30s). | `string` | `"10m"` | no |
| <a name="input_cpu_arch"></a> [cpu\_arch](#input\_cpu\_arch) | CPU architecture for container images (amd64, arm64). | `string` | n/a | yes |
| <a name="input_cpu_limit"></a> [cpu\_limit](#input\_cpu\_limit) | CPU limit for Authelia containers. | `string` | `"500m"` | no |
| <a name="input_cpu_request"></a> [cpu\_request](#input\_cpu\_request) | CPU request for Authelia containers. | `string` | `"100m"` | no |
| <a name="input_default_policy"></a> [default\_policy](#input\_default\_policy) | Default access policy for Authelia (one\_factor, two\_factor, deny). | `string` | `"one_factor"` | no |
| <a name="input_disable_arch_scheduling"></a> [disable\_arch\_scheduling](#input\_disable\_arch\_scheduling) | Disable architecture-based node scheduling. | `bool` | `false` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Domain name for Authelia ingress. | `string` | `".local"` | no |
| <a name="input_duo_api_hostname"></a> [duo\_api\_hostname](#input\_duo\_api\_hostname) | Duo API hostname. | `string` | `""` | no |
| <a name="input_duo_enabled"></a> [duo\_enabled](#input\_duo\_enabled) | Enable Duo Security for 2FA. | `bool` | `false` | no |
| <a name="input_duo_integration_key"></a> [duo\_integration\_key](#input\_duo\_integration\_key) | Duo integration key. | `string` | `""` | no |
| <a name="input_duo_secret_key"></a> [duo\_secret\_key](#input\_duo\_secret\_key) | Duo secret key. | `string` | `""` | no |
| <a name="input_enable_servicemonitor"></a> [enable\_servicemonitor](#input\_enable\_servicemonitor) | Enable Prometheus ServiceMonitor for Authelia metrics. | `bool` | `false` | no |
| <a name="input_force_namespace_cleanup"></a> [force\_namespace\_cleanup](#input\_force\_namespace\_cleanup) | Force cleanup of namespace if deletion gets stuck. WARNING: Only use when namespace is stuck in Terminating phase. | `bool` | `false` | no |
| <a name="input_helm_cleanup_on_fail"></a> [helm\_cleanup\_on\_fail](#input\_helm\_cleanup\_on\_fail) | Cleanup resources on deployment failure. | `bool` | `false` | no |
| <a name="input_helm_disable_webhooks"></a> [helm\_disable\_webhooks](#input\_helm\_disable\_webhooks) | Disable webhooks for Helm release. | `bool` | `false` | no |
| <a name="input_helm_force_update"></a> [helm\_force\_update](#input\_helm\_force\_update) | Force resource updates if needed. | `bool` | `false` | no |
| <a name="input_helm_replace"></a> [helm\_replace](#input\_helm\_replace) | Allow Helm to replace existing resources. | `bool` | `false` | no |
| <a name="input_helm_skip_crds"></a> [helm\_skip\_crds](#input\_helm\_skip\_crds) | Skip CRDs for Helm release. | `bool` | `false` | no |
| <a name="input_helm_timeout"></a> [helm\_timeout](#input\_helm\_timeout) | Timeout for Helm deployment in seconds. | `number` | `300` | no |
| <a name="input_helm_wait"></a> [helm\_wait](#input\_helm\_wait) | Wait for Helm release to be ready. | `bool` | `false` | no |
| <a name="input_helm_wait_for_jobs"></a> [helm\_wait\_for\_jobs](#input\_helm\_wait\_for\_jobs) | Wait for Helm jobs to complete. | `bool` | `false` | no |
| <a name="input_jwt_secret"></a> [jwt\_secret](#input\_jwt\_secret) | JWT secret for Authelia (empty = auto-generate). | `string` | `""` | no |
| <a name="input_kubeconfig_path"></a> [kubeconfig\_path](#input\_kubeconfig\_path) | Explicit kubeconfig path (overrides automatic detection). Leave empty to use workspace-based or default kubeconfig. | `string` | `""` | no |
| <a name="input_ldap_base_dn"></a> [ldap\_base\_dn](#input\_ldap\_base\_dn) | LDAP base DN for user search (e.g., dc=example,dc=com). | `string` | `""` | no |
| <a name="input_ldap_bind_dn"></a> [ldap\_bind\_dn](#input\_ldap\_bind\_dn) | LDAP bind DN for authentication (e.g., cn=admin,dc=example,dc=com). | `string` | `""` | no |
| <a name="input_ldap_bind_password"></a> [ldap\_bind\_password](#input\_ldap\_bind\_password) | LDAP bind password for authentication. | `string` | `""` | no |
| <a name="input_ldap_enabled"></a> [ldap\_enabled](#input\_ldap\_enabled) | Enable LDAP authentication backend. | `bool` | `false` | no |
| <a name="input_ldap_group_filter"></a> [ldap\_group\_filter](#input\_ldap\_group\_filter) | LDAP group search filter (e.g., (member={dn})). | `string` | `"(member={dn})"` | no |
| <a name="input_ldap_groups_filter"></a> [ldap\_groups\_filter](#input\_ldap\_groups\_filter) | LDAP groups filter (e.g., (\|(objectClass=groupOfNames)(objectClass=group))). | `string` | `"(|(objectClass=groupOfNames)(objectClass=group))"` | no |
| <a name="input_ldap_tls_skip_verify"></a> [ldap\_tls\_skip\_verify](#input\_ldap\_tls\_skip\_verify) | Skip TLS certificate verification for LDAP connections. When false (recommended), validates LDAP server certificates. When true, allows man-in-the-middle attacks. | `bool` | `false` | no |
| <a name="input_ldap_url"></a> [ldap\_url](#input\_ldap\_url) | LDAP server URL (e.g., ldap://ldap.example.com:389). | `string` | `""` | no |
| <a name="input_ldap_user_filter"></a> [ldap\_user\_filter](#input\_ldap\_user\_filter) | LDAP user search filter (e.g., (uid={input})). | `string` | `"(uid={input})"` | no |
| <a name="input_ldap_username_attribute"></a> [ldap\_username\_attribute](#input\_ldap\_username\_attribute) | LDAP username attribute (e.g., uid). | `string` | `"uid"` | no |
| <a name="input_log_level"></a> [log\_level](#input\_log\_level) | Authelia log level: trace, debug, info, warn, or error. Debug level may expose sensitive information in logs. | `string` | `"info"` | no |
| <a name="input_memory_limit"></a> [memory\_limit](#input\_memory\_limit) | Memory limit for Authelia containers. | `string` | `"512Mi"` | no |
| <a name="input_memory_request"></a> [memory\_request](#input\_memory\_request) | Memory request for Authelia containers. | `string` | `"128Mi"` | no |
| <a name="input_name"></a> [name](#input\_name) | Helm release name for Authelia. | `string` | `"authelia"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace for Authelia authentication service. | `string` | `"authelia-stack"` | no |
| <a name="input_oidc_clients"></a> [oidc\_clients](#input\_oidc\_clients) | Map of OIDC clients that will use Authelia as identity provider. | <pre>map(object({<br/>    client_id                  = string<br/>    client_secret              = string<br/>    authorization_policy       = optional(string, "two_factor")<br/>    scopes                     = optional(list(string), ["openid", "profile", "email", "groups"])<br/>    redirect_uris              = list(string)<br/>    userinfo_signing_algorithm = optional(string, "none")<br/>  }))</pre> | <pre>{<br/>  "headlamp": {<br/>    "client_id": "headlamp",<br/>    "client_secret": "headlamp-secret-change-me",<br/>    "redirect_uris": [<br/>      "https://headlamp.k3s.annino.cloud/oauth2/callback"<br/>    ]<br/>  }<br/>}</pre> | no |
| <a name="input_oidc_enabled"></a> [oidc\_enabled](#input\_oidc\_enabled) | Enable OIDC provider for other services (e.g., Headlamp, Grafana). | `bool` | `false` | no |
| <a name="input_persistent_disk_size"></a> [persistent\_disk\_size](#input\_persistent\_disk\_size) | Persistent disk size for Authelia data storage. | `string` | `"1Gi"` | no |
| <a name="input_redis_address"></a> [redis\_address](#input\_redis\_address) | Redis server address for distributed session storage (e.g., 'redis-master.redis-system.svc.cluster.local'). Use redis\_module\_reference instead for automatic discovery. Can be empty when redis\_enabled is false. | `string` | `""` | no |
| <a name="input_redis_enabled"></a> [redis\_enabled](#input\_redis\_enabled) | Enable Redis for distributed session storage (recommended for HA). When true, either redis\_address or redis\_module\_reference must be provided. | `bool` | `false` | no |
| <a name="input_redis_module_reference"></a> [redis\_module\_reference](#input\_redis\_module\_reference) | Reference to redis module output for automatic configuration (e.g., 'module.redis[0].service\_host'). Overrides redis\_address when set. | `string` | `""` | no |
| <a name="input_replica_count"></a> [replica\_count](#input\_replica\_count) | Number of Authelia replicas. | `number` | `1` | no |
| <a name="input_servicemonitor_namespace"></a> [servicemonitor\_namespace](#input\_servicemonitor\_namespace) | Namespace for ServiceMonitor (typically where Prometheus Operator is deployed). | `string` | `"monitoring"` | no |
| <a name="input_session_secret"></a> [session\_secret](#input\_session\_secret) | Session secret for Authelia (empty = auto-generate). | `string` | `""` | no |
| <a name="input_storage_class"></a> [storage\_class](#input\_storage\_class) | Storage class for Authelia persistent volume. | `string` | `"hostpath"` | no |
| <a name="input_storage_encryption_key"></a> [storage\_encryption\_key](#input\_storage\_encryption\_key) | Storage encryption key for Authelia (empty = auto-generate). | `string` | `""` | no |
| <a name="input_totp_enabled"></a> [totp\_enabled](#input\_totp\_enabled) | Enable Time-based One-Time Password (TOTP) for 2FA. | `bool` | `true` | no |
| <a name="input_traefik_cert_resolver"></a> [traefik\_cert\_resolver](#input\_traefik\_cert\_resolver) | Traefik certificate resolver for TLS. | `string` | `"default"` | no |
| <a name="input_traefik_ingress_config"></a> [traefik\_ingress\_config](#input\_traefik\_ingress\_config) | Traefik ingress configuration from Traefik module | <pre>object({<br/>    class_name    = string<br/>    annotations   = map(string)<br/>    cert_resolver = string<br/>    domain_name   = string<br/>  })</pre> | `null` | no |
| <a name="input_workspace_prefix"></a> [workspace\_prefix](#input\_workspace\_prefix) | Workspace prefix for kubeconfig file selection (e.g., 'prod', 'sit', 'dev'). | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_forward_auth_url"></a> [forward\_auth\_url](#output\_forward\_auth\_url) | Traefik forward auth URL for other services |
| <a name="output_ingress_config"></a> [ingress\_config](#output\_ingress\_config) | Ingress configuration for other services to use Authelia |
| <a name="output_jwt_secret"></a> [jwt\_secret](#output\_jwt\_secret) | JWT secret used by Authelia |
| <a name="output_ldap_secret_name"></a> [ldap\_secret\_name](#output\_ldap\_secret\_name) | Name of the Kubernetes Secret storing LDAP credentials (if enabled) |
| <a name="output_ldap_secret_namespace"></a> [ldap\_secret\_namespace](#output\_ldap\_secret\_namespace) | Namespace of the LDAP credentials Secret |
| <a name="output_namespace"></a> [namespace](#output\_namespace) | Namespace where Authelia is deployed |
| <a name="output_namespace_cleanup_enabled"></a> [namespace\_cleanup\_enabled](#output\_namespace\_cleanup\_enabled) | Whether force cleanup is currently enabled |
| <a name="output_namespace_status"></a> [namespace\_status](#output\_namespace\_status) | Current status and health of Authelia namespace |
| <a name="output_oidc_clients"></a> [oidc\_clients](#output\_oidc\_clients) | Configured OIDC clients |
| <a name="output_oidc_issuer_url"></a> [oidc\_issuer\_url](#output\_oidc\_issuer\_url) | OIDC issuer URL for other services to use |
| <a name="output_redis_address"></a> [redis\_address](#output\_redis\_address) | Redis service address (if enabled) - use redis\_module\_reference for automatic discovery |
| <a name="output_redis_enabled"></a> [redis\_enabled](#output\_redis\_enabled) | Whether Redis is enabled for distributed session storage |
| <a name="output_service_name"></a> [service\_name](#output\_service\_name) | Name of the Authelia service |
| <a name="output_service_url"></a> [service\_url](#output\_service\_url) | URL to access Authelia web interface |
| <a name="output_session_secret"></a> [session\_secret](#output\_session\_secret) | Session secret used by Authelia |
| <a name="output_storage_encryption_key"></a> [storage\_encryption\_key](#output\_storage\_encryption\_key) | Storage encryption key used by Authelia |
<!-- END_TF_DOCS -->
