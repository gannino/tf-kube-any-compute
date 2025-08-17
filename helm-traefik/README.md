# Traefik Helm Module

This module deploys Traefik ingress controller with flexible Let's Encrypt SSL certificate management supporting multiple DNS providers.

## Features

- Traefik v3.x ingress controller
- **Multi-DNS Provider Support**: Cloudflare, AWS Route53, DigitalOcean, Hurricane Electric, and more
- **Flexible Certificate Resolvers**: HTTP and DNS challenges with custom configurations
- **Automatic SSL Certificate Management**: Let's Encrypt integration with multiple challenge types
- Dashboard with authentication
- Prometheus metrics integration
- Architecture-aware deployment (ARM64/AMD64)
- Persistent storage for ACME certificates
- Backward compatibility with Hurricane Electric

## Supported DNS Providers

| Provider | Challenge Type | Configuration Keys |
|----------|----------------|---------------------|
| **Cloudflare** | DNS | `dns_token` or `email` + `api_key` |
| **AWS Route53** | DNS | `access_key_id`, `secret_access_key`, `region` |
| **DigitalOcean** | DNS | `auth_token` |
| **Hurricane Electric** | DNS | Auto-generated (backward compatible) |
| **Gandi** | DNS | `api_key` |
| **Namecheap** | DNS | `api_user`, `api_key` |
| **GoDaddy** | DNS | `api_key`, `api_secret` |
| **OVH** | DNS | `endpoint`, `application_key`, `application_secret`, `consumer_key` |
| **Linode** | DNS | `token` |
| **Vultr** | DNS | `api_key` |
| **Hetzner** | DNS | `api_token` |

## Usage Examples

### Basic HTTP Challenge (Default)

```hcl
module "traefik" {
  source = "./helm-traefik"

  name        = "traefik"
  namespace   = "traefik-system"
  domain_name = "example.com"
  le_email    = "admin@example.com"

  # HTTP challenge (default)
  cert_resolvers = {
    default = {
      challenge_type = "http"
    }
  }
}
```

### Cloudflare DNS Challenge

```hcl
module "traefik" {
  source = "./helm-traefik"

  name        = "traefik"
  namespace   = "traefik-system"
  domain_name = "example.com"
  le_email    = "admin@example.com"

  # Cloudflare DNS provider
  dns_providers = {
    primary = {
      name = "cloudflare"
      config = {
        dns_token = "your-cloudflare-dns-api-token"
      }
    }
  }

  # DNS challenge for wildcard certificates
  cert_resolvers = {
    wildcard = {
      challenge_type = "dns"
      dns_provider = "cloudflare"
    }
  }

  # Cloudflare-optimized settings
  dns_challenge_config = {
    resolvers = ["1.1.1.1:53", "1.0.0.1:53"]
    delay_before_check = "60s"
  }
}
```

### AWS Route53 DNS Challenge

```hcl
module "traefik" {
  source = "./helm-traefik"

  name        = "traefik"
  namespace   = "traefik-system"
  domain_name = "example.com"
  le_email    = "admin@example.com"

  # AWS Route53 DNS provider
  dns_providers = {
    primary = {
      name = "route53"
      config = {
        access_key_id = "your-aws-access-key-id"
        secret_access_key = "your-aws-secret-access-key"
        region = "us-east-1"
      }
    }
  }

  # DNS challenge configuration
  cert_resolvers = {
    wildcard = {
      challenge_type = "dns"
      dns_provider = "route53"
    }
  }

  # Route53-optimized settings
  dns_challenge_config = {
    delay_before_check = "120s"
    propagation_timeout = "600"
  }
}
```

## Configuration

### DNS Provider Configuration

#### `dns_providers`

```hcl
dns_providers = {
  primary = {
    name = "cloudflare"  # Provider name
    config = {           # Provider-specific configuration
      dns_token = "your-token"
    }
  }
  additional = [        # Optional additional providers
    {
      name = "route53"
      config = {
        access_key_id = "your-key"
        secret_access_key = "your-secret"
      }
    }
  ]
}
```

#### `cert_resolvers`

```hcl
cert_resolvers = {
  default = {
    challenge_type = "http"     # or "dns"
    dns_provider = "cloudflare" # required for DNS challenges
  }
  wildcard = {
    challenge_type = "dns"
    dns_provider = "cloudflare"
  }
  custom = {
    my-resolver = {
      challenge_type = "dns"
      dns_provider = "route53"
    }
  }
}
```

#### `dns_challenge_config`

```hcl
dns_challenge_config = {
  resolvers = ["1.1.1.1:53", "8.8.8.8:53"]
  delay_before_check = "60s"
  disable_propagation_check = false
  polling_interval = "5"
  propagation_timeout = "300"
  sequence_interval = "60"
  http_timeout = "30"
}
```

## Security Best Practices

### API Token Management

1. **Use environment variables**:
   ```bash
   export TF_VAR_cloudflare_dns_token="your-token"
   ```

2. **Use Terraform Cloud/Enterprise variables**

3. **Use external secret management** (Vault, AWS Secrets Manager, etc.)

4. **Never commit secrets to version control**

### Provider-Specific Security

- **Cloudflare**: Use DNS API tokens instead of Global API keys
- **AWS**: Use IAM roles with minimal Route53 permissions
- **DigitalOcean**: Scope tokens to DNS operations only

## Troubleshooting

### DNS Challenge Issues

1. **Check DNS propagation**:
   ```bash
   dig TXT _acme-challenge.yourdomain.com
   ```

2. **Verify API credentials**:
   ```bash
   kubectl logs -n traefik-system deployment/traefik
   ```

3. **Adjust timing settings**:
   - Increase `delay_before_check` for slower DNS providers
   - Increase `propagation_timeout` for global DNS propagation

### Provider-Specific Troubleshooting

- **Cloudflare**: Ensure DNS API token has Zone:Read and Zone:Edit permissions
- **Route53**: Verify IAM permissions for route53:ChangeResourceRecordSets
- **Hurricane Electric**: Check dynamic DNS key configuration

## Outputs

- `namespace`: Deployment namespace
- `service_name`: Traefik service name
- `loadbalancer_ip`: LoadBalancer IP address
- `dashboard_url`: Dashboard URL (if enabled)
- `dns_provider_config`: Complete DNS provider configuration
- `supported_dns_providers`: List of supported DNS providers
- `he_dns_config`: Hurricane Electric DNS configuration (legacy)

<!-- BEGIN_TF_DOCS -->


## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.14 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 3.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | 3.0.2 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.38.0 |
| <a name="provider_null"></a> [null](#provider\_null) | 3.2.4 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.7.2 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ingress"></a> [ingress](#module\_ingress) | ./ingress | n/a |
| <a name="module_middleware"></a> [middleware](#module\_middleware) | ./middleware | n/a |

## Resources

| Name | Type |
|------|------|
| [helm_release.this](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_limit_range.namespace_limits](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/limit_range) | resource |
| [kubernetes_manifest.traefik_ingress_class](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.traefik_servicemonitor](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_namespace.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_persistent_volume_claim.plugins_storage](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume_claim) | resource |
| [kubernetes_persistent_volume_claim.traefik](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume_claim) | resource |
| [kubernetes_secret.additional_dns_credentials](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.cloudflare_dns_credentials](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.digitalocean_dns_credentials](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.gandi_dns_credentials](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.godaddy_dns_credentials](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.he_dns_token](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.hetzner_dns_credentials](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.linode_dns_credentials](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.namecheap_dns_credentials](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.ovh_dns_credentials](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.route53_dns_credentials](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.vultr_dns_credentials](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [null_resource.wait_for_traefik_crds](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.wait_for_traefik_deployment](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [random_password.hurricane_token](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [kubernetes_service.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/service) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cert_resolvers"></a> [cert\_resolvers](#input\_cert\_resolvers) | Certificate resolver configurations - uses DNS provider names as resolver names | <pre>object({<br/>    default = optional(object({<br/>      challenge_type = optional(string, "http")<br/>      dns_provider   = optional(string)<br/>      }), {<br/>      challenge_type = "http"<br/>    })<br/><br/>    # DNS provider-based resolvers (e.g., hurricane, cloudflare, route53)<br/>    custom = optional(map(object({<br/>      challenge_type = string<br/>      dns_provider   = optional(string)<br/>    })), {})<br/>  })</pre> | `{}` | no |
| <a name="input_chart_name"></a> [chart\_name](#input\_chart\_name) | Helm chart name | `string` | `"traefik"` | no |
| <a name="input_chart_repo"></a> [chart\_repo](#input\_chart\_repo) | Helm chart repository URL | `string` | `"https://helm.traefik.io/traefik"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Helm chart version | `string` | `"37.0.0"` | no |
| <a name="input_consul_url"></a> [consul\_url](#input\_consul\_url) | Consul URL for service discovery and service mesh integration | `string` | `""` | no |
| <a name="input_cpu_arch"></a> [cpu\_arch](#input\_cpu\_arch) | CPU architecture for node selection | `string` | `"amd64"` | no |
| <a name="input_cpu_limit"></a> [cpu\_limit](#input\_cpu\_limit) | CPU limit for Traefik containers | `string` | `"200m"` | no |
| <a name="input_cpu_request"></a> [cpu\_request](#input\_cpu\_request) | CPU request for Traefik containers | `string` | `"100m"` | no |
| <a name="input_dashboard_middleware"></a> [dashboard\_middleware](#input\_dashboard\_middleware) | List of middleware names to apply to Traefik dashboard | `list(string)` | `[]` | no |
| <a name="input_dashboard_port"></a> [dashboard\_port](#input\_dashboard\_port) | Dashboard port for Traefik web UI | `number` | `8080` | no |
| <a name="input_deployment_wait_timeout"></a> [deployment\_wait\_timeout](#input\_deployment\_wait\_timeout) | Timeout in seconds to wait for Traefik deployment to be ready | `number` | `300` | no |
| <a name="input_disable_arch_scheduling"></a> [disable\_arch\_scheduling](#input\_disable\_arch\_scheduling) | Disable architecture-based node scheduling (useful for cluster-wide services) | `bool` | `false` | no |
| <a name="input_dns_challenge_config"></a> [dns\_challenge\_config](#input\_dns\_challenge\_config) | DNS challenge configuration options | <pre>object({<br/>    resolvers                 = optional(list(string), ["1.1.1.1:53", "8.8.8.8:53"])<br/>    delay_before_check        = optional(string, "150s")<br/>    disable_propagation_check = optional(bool, false)<br/>    polling_interval          = optional(string, "5")<br/>    propagation_timeout       = optional(string, "300")<br/>    sequence_interval         = optional(string, "60")<br/>    http_timeout              = optional(string, "30")<br/>  })</pre> | `{}` | no |
| <a name="input_dns_providers"></a> [dns\_providers](#input\_dns\_providers) | DNS providers configuration for Let's Encrypt DNS challenge | <pre>object({<br/>    # Primary DNS provider<br/>    primary = optional(object({<br/>      name   = string # hurricane, cloudflare, route53, digitalocean, etc.<br/>      config = optional(map(string), {})<br/>      }), {<br/>      name   = "hurricane"<br/>      config = {}<br/>    })<br/><br/>    # Additional DNS providers for multi-domain setups<br/>    additional = optional(list(object({<br/>      name   = string<br/>      config = map(string)<br/>    })), [])<br/>  })</pre> | <pre>{<br/>  "additional": [],<br/>  "primary": {<br/>    "config": {},<br/>    "name": "hurricane"<br/>  }<br/>}</pre> | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Domain name for ingress resources | `string` | `".local"` | no |
| <a name="input_enable_ingress"></a> [enable\_ingress](#input\_enable\_ingress) | Enable ingress functionality for external access | `bool` | `false` | no |
| <a name="input_enable_middleware"></a> [enable\_middleware](#input\_enable\_middleware) | Enable middleware deployment (requires Traefik CRDs to be available) | `bool` | `true` | no |
| <a name="input_enable_tracing"></a> [enable\_tracing](#input\_enable\_tracing) | Enable distributed tracing in Traefik | `bool` | `false` | no |
| <a name="input_helm_cleanup_on_fail"></a> [helm\_cleanup\_on\_fail](#input\_helm\_cleanup\_on\_fail) | Cleanup resources on failure | `bool` | `false` | no |
| <a name="input_helm_disable_webhooks"></a> [helm\_disable\_webhooks](#input\_helm\_disable\_webhooks) | Disable webhooks for Helm release | `bool` | `true` | no |
| <a name="input_helm_force_update"></a> [helm\_force\_update](#input\_helm\_force\_update) | Force resource updates if needed | `bool` | `false` | no |
| <a name="input_helm_replace"></a> [helm\_replace](#input\_helm\_replace) | Allow Helm to replace existing resources | `bool` | `false` | no |
| <a name="input_helm_skip_crds"></a> [helm\_skip\_crds](#input\_helm\_skip\_crds) | Skip CRDs for Helm release | `bool` | `false` | no |
| <a name="input_helm_timeout"></a> [helm\_timeout](#input\_helm\_timeout) | Timeout for Helm deployment in seconds | `number` | `600` | no |
| <a name="input_helm_wait"></a> [helm\_wait](#input\_helm\_wait) | Wait for Helm release to be ready | `bool` | `false` | no |
| <a name="input_helm_wait_for_jobs"></a> [helm\_wait\_for\_jobs](#input\_helm\_wait\_for\_jobs) | Wait for Helm jobs to complete | `bool` | `false` | no |
| <a name="input_http_port"></a> [http\_port](#input\_http\_port) | HTTP port for Traefik entrypoint | `number` | `80` | no |
| <a name="input_https_port"></a> [https\_port](#input\_https\_port) | HTTPS port for Traefik entrypoint | `number` | `443` | no |
| <a name="input_hurricane_tokens"></a> [hurricane\_tokens](#input\_hurricane\_tokens) | Hurricane Electric DNS tokens (DEPRECATED: use dns\_providers configuration) | `string` | `""` | no |
| <a name="input_ingress_api_version"></a> [ingress\_api\_version](#input\_ingress\_api\_version) | API version for ingress resources | `string` | `"networking.k8s.io/v1"` | no |
| <a name="input_jaeger_endpoint"></a> [jaeger\_endpoint](#input\_jaeger\_endpoint) | Jaeger endpoint for tracing (when using jaeger backend) | `string` | `""` | no |
| <a name="input_le_email"></a> [le\_email](#input\_le\_email) | Email address for Let's Encrypt certificate notifications | `string` | `""` | no |
| <a name="input_loki_endpoint"></a> [loki\_endpoint](#input\_loki\_endpoint) | Loki endpoint for tracing (when using loki backend) | `string` | `""` | no |
| <a name="input_memory_limit"></a> [memory\_limit](#input\_memory\_limit) | Memory limit for Traefik containers | `string` | `"256Mi"` | no |
| <a name="input_memory_request"></a> [memory\_request](#input\_memory\_request) | Memory request for Traefik containers | `string` | `"128Mi"` | no |
| <a name="input_metrics_port"></a> [metrics\_port](#input\_metrics\_port) | Metrics port for Traefik Prometheus metrics | `number` | `9100` | no |
| <a name="input_middleware_config"></a> [middleware\_config](#input\_middleware\_config) | Middleware configuration for authentication and security | <pre>object({<br/>    # Basic Authentication<br/>    basic_auth = optional(object({<br/>      enabled     = bool<br/>      secret_name = optional(string, "")<br/>      realm       = optional(string, "Authentication Required")<br/>    }), { enabled = false })<br/><br/>    # LDAP Authentication<br/>    ldap_auth = optional(object({<br/>      enabled       = bool<br/>      method        = optional(string, "forwardauth") # "plugin" or "forwardauth"<br/>      log_level     = optional(string, "INFO")<br/>      url           = optional(string, "")<br/>      port          = optional(number, 389)<br/>      base_dn       = optional(string, "")<br/>      attribute     = optional(string, "uid")<br/>      bind_dn       = optional(string, "")<br/>      bind_password = optional(string, "")<br/>      search_filter = optional(string, "")<br/>    }), { enabled = false })<br/><br/>    # Rate Limiting<br/>    rate_limit = optional(object({<br/>      enabled = bool<br/>      average = optional(number, 100)<br/>      burst   = optional(number, 200)<br/>    }), { enabled = false })<br/><br/>    # IP Whitelist<br/>    ip_whitelist = optional(object({<br/>      enabled       = bool<br/>      source_ranges = optional(list(string), ["127.0.0.1/32"])<br/>    }), { enabled = false })<br/><br/>    # Default Authentication (switches between basic and LDAP)<br/>    default_auth = optional(object({<br/>      enabled = bool<br/>      type    = optional(string, "basic")<br/>      basic_config = optional(object({<br/>        secret_name = optional(string)<br/>        realm       = optional(string)<br/>      }))<br/>      ldap_config = optional(object({<br/>        log_level     = optional(string)<br/>        url           = optional(string)<br/>        port          = optional(number)<br/>        base_dn       = optional(string)<br/>        attribute     = optional(string)<br/>        bind_dn       = optional(string)<br/>        bind_password = optional(string)<br/>        search_filter = optional(string)<br/>      }))<br/>    }), { enabled = false })<br/>  })</pre> | <pre>{<br/>  "basic_auth": {<br/>    "enabled": false<br/>  },<br/>  "default_auth": {<br/>    "enabled": false<br/>  },<br/>  "ip_whitelist": {<br/>    "enabled": false<br/>  },<br/>  "ldap_auth": {<br/>    "enabled": false<br/>  },<br/>  "rate_limit": {<br/>    "enabled": false<br/>  }<br/>}</pre> | no |
| <a name="input_name"></a> [name](#input\_name) | Helm release name for Traefik | `string` | `"traefik"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Kubernetes namespace for Traefik deployment | `string` | `"traefik-ingress-controller"` | no |
| <a name="input_persistent_disk_size"></a> [persistent\_disk\_size](#input\_persistent\_disk\_size) | Size of persistent disk for Traefik data | `string` | `"1Gi"` | no |
| <a name="input_storage_class"></a> [storage\_class](#input\_storage\_class) | Storage class for persistent volumes | `string` | `"hostpath"` | no |
| <a name="input_tracing_backend"></a> [tracing\_backend](#input\_tracing\_backend) | Tracing backend to use (loki, jaeger) | `string` | `"loki"` | no |
| <a name="input_traefik_cert_resolver"></a> [traefik\_cert\_resolver](#input\_traefik\_cert\_resolver) | Traefik certificate resolver name | `string` | `"default"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_auth_credentials"></a> [auth\_credentials](#output\_auth\_credentials) | Authentication credentials for enabled middleware |
| <a name="output_cert_resolver_name"></a> [cert\_resolver\_name](#output\_cert\_resolver\_name) | Primary certificate resolver name for use by other services |
| <a name="output_chart_version"></a> [chart\_version](#output\_chart\_version) | Helm chart version used |
| <a name="output_dashboard_url"></a> [dashboard\_url](#output\_dashboard\_url) | Traefik dashboard URL |
| <a name="output_default_auth_middleware_name"></a> [default\_auth\_middleware\_name](#output\_default\_auth\_middleware\_name) | Default auth middleware name (recommended for most services) |
| <a name="output_dns_provider_config"></a> [dns\_provider\_config](#output\_dns\_provider\_config) | DNS provider configuration for ACME certificates |
| <a name="output_loadbalancer_ip"></a> [loadbalancer\_ip](#output\_loadbalancer\_ip) | LoadBalancer IP address for Traefik service |
| <a name="output_middleware"></a> [middleware](#output\_middleware) | Middleware configuration and names for consumer modules |
| <a name="output_namespace"></a> [namespace](#output\_namespace) | Kubernetes namespace where Traefik is deployed |
| <a name="output_preferred_auth_middleware_name"></a> [preferred\_auth\_middleware\_name](#output\_preferred\_auth\_middleware\_name) | Preferred authentication middleware name (LDAP if enabled, otherwise basic) |
| <a name="output_service_name"></a> [service\_name](#output\_service\_name) | Traefik service name |
| <a name="output_supported_dns_providers"></a> [supported\_dns\_providers](#output\_supported\_dns\_providers) | List of supported DNS providers |

<!-- END_TF_DOCS -->
