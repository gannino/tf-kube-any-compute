# Terraform Module

<!-- BEGIN_TF_DOCS -->


## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.14 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.38.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.7.2 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [kubernetes_manifest.basic_auth](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.default_auth_basic](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.default_auth_ldap](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.ip_whitelist](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.ldap_auth](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.rate_limit](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_secret.basic_auth](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.default_auth](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [random_password.basic_auth_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_password.default_auth_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_basic_auth"></a> [basic\_auth](#input\_basic\_auth) | Basic authentication middleware configuration | <pre>object({<br/>    enabled         = bool<br/>    secret_name     = optional(string, "")<br/>    realm           = optional(string, "Authentication Required")<br/>    static_password = optional(string, "")      # If set, uses this instead of random password<br/>    username        = optional(string, "admin") # Username for basic auth<br/>  })</pre> | <pre>{<br/>  "enabled": false<br/>}</pre> | no |
| <a name="input_default_auth"></a> [default\_auth](#input\_default\_auth) | Default authentication middleware - uses basic auth by default, switches to LDAP when ldap\_override is true | <pre>object({<br/>    enabled       = bool<br/>    ldap_override = optional(bool, false) # Set to true to use LDAP instead of basic<br/><br/>    # Basic auth configuration (used when type = "basic")<br/>    basic_config = optional(object({<br/>      secret_name     = optional(string, "default-basic-auth")<br/>      realm           = optional(string, "Authentication Required")<br/>      static_password = optional(string, "")      # If set, uses this instead of random password<br/>      username        = optional(string, "admin") # Username for basic auth<br/>      }), {<br/>      secret_name = "default-basic-auth"<br/>      realm       = "Authentication Required"<br/>      username    = "admin"<br/>    })<br/><br/>    # LDAP configuration (used when type = "ldap")<br/>    ldap_config = optional(object({<br/>      log_level     = optional(string, "INFO")<br/>      url           = optional(string, "")<br/>      port          = optional(number, 389)<br/>      base_dn       = optional(string, "")<br/>      attribute     = optional(string, "uid")<br/>      bind_dn       = optional(string, "")<br/>      bind_password = optional(string, "")<br/>      search_filter = optional(string, "")<br/>      }), {<br/>      log_level = "INFO"<br/>      port      = 389<br/>      attribute = "uid"<br/>    })<br/>  })</pre> | <pre>{<br/>  "enabled": false<br/>}</pre> | no |
| <a name="input_ip_whitelist"></a> [ip\_whitelist](#input\_ip\_whitelist) | IP whitelist middleware configuration | <pre>object({<br/>    enabled       = bool<br/>    source_ranges = optional(list(string), ["127.0.0.1/32"])<br/>  })</pre> | <pre>{<br/>  "enabled": false<br/>}</pre> | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Common labels for middleware resources | `map(string)` | `{}` | no |
| <a name="input_ldap_auth"></a> [ldap\_auth](#input\_ldap\_auth) | LDAP authentication middleware configuration using LDAP plugin | <pre>object({<br/>    enabled       = bool<br/>    log_level     = optional(string, "INFO")<br/>    url           = optional(string, "")<br/>    port          = optional(number, 389)<br/>    base_dn       = optional(string, "")<br/>    attribute     = optional(string, "uid")<br/>    bind_dn       = optional(string, "")<br/>    bind_password = optional(string, "")<br/>    search_filter = optional(string, "")<br/>  })</pre> | <pre>{<br/>  "enabled": false<br/>}</pre> | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix for middleware names | `string` | `"auth"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Kubernetes namespace for middleware resources | `string` | n/a | yes |
| <a name="input_rate_limit"></a> [rate\_limit](#input\_rate\_limit) | Rate limiting middleware configuration | <pre>object({<br/>    enabled = bool<br/>    average = optional(number, 100)<br/>    burst   = optional(number, 200)<br/>  })</pre> | <pre>{<br/>  "enabled": false<br/>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_all_middleware_names"></a> [all\_middleware\_names](#output\_all\_middleware\_names) | List of all enabled middleware names |
| <a name="output_auth_method_summary"></a> [auth\_method\_summary](#output\_auth\_method\_summary) | Summary of enabled authentication methods |
| <a name="output_auth_middleware_names"></a> [auth\_middleware\_names](#output\_auth\_middleware\_names) | List of enabled authentication middleware names |
| <a name="output_basic_auth_is_static"></a> [basic\_auth\_is\_static](#output\_basic\_auth\_is\_static) | Whether basic auth is using a static password (true) or generated password (false) |
| <a name="output_basic_auth_middleware_name"></a> [basic\_auth\_middleware\_name](#output\_basic\_auth\_middleware\_name) | Name of the basic auth middleware for use in IngressRoute annotations |
| <a name="output_basic_auth_password"></a> [basic\_auth\_password](#output\_basic\_auth\_password) | Password for basic authentication (static if provided, otherwise generated) |
| <a name="output_basic_auth_secret_name"></a> [basic\_auth\_secret\_name](#output\_basic\_auth\_secret\_name) | Name of the Kubernetes secret containing basic auth credentials |
| <a name="output_basic_auth_username"></a> [basic\_auth\_username](#output\_basic\_auth\_username) | Username for basic authentication |
| <a name="output_default_auth_is_static"></a> [default\_auth\_is\_static](#output\_default\_auth\_is\_static) | Whether default auth is using a static password (true) or generated password (false) |
| <a name="output_default_auth_middleware_name"></a> [default\_auth\_middleware\_name](#output\_default\_auth\_middleware\_name) | Name of the default auth middleware (switches between basic/LDAP) |
| <a name="output_default_auth_password"></a> [default\_auth\_password](#output\_default\_auth\_password) | Password for default authentication when using basic auth (static if provided, otherwise generated) |
| <a name="output_default_auth_secret_name"></a> [default\_auth\_secret\_name](#output\_default\_auth\_secret\_name) | Name of the Kubernetes secret containing default auth credentials |
| <a name="output_default_auth_type"></a> [default\_auth\_type](#output\_default\_auth\_type) | Type of default authentication configured (basic or ldap) |
| <a name="output_default_auth_username"></a> [default\_auth\_username](#output\_default\_auth\_username) | Username for default authentication when using basic auth |
| <a name="output_ip_whitelist_middleware_name"></a> [ip\_whitelist\_middleware\_name](#output\_ip\_whitelist\_middleware\_name) | Name of the IP whitelist middleware for use in IngressRoute annotations |
| <a name="output_ldap_auth_config"></a> [ldap\_auth\_config](#output\_ldap\_auth\_config) | LDAP authentication configuration summary |
| <a name="output_ldap_auth_middleware_name"></a> [ldap\_auth\_middleware\_name](#output\_ldap\_auth\_middleware\_name) | Name of the LDAP auth middleware for use in IngressRoute annotations |
| <a name="output_middleware_namespace"></a> [middleware\_namespace](#output\_middleware\_namespace) | Namespace where middleware resources are deployed (same as Traefik namespace) |
| <a name="output_rate_limit_middleware_name"></a> [rate\_limit\_middleware\_name](#output\_rate\_limit\_middleware\_name) | Name of the rate limit middleware for use in IngressRoute annotations |
| <a name="output_security_middleware_names"></a> [security\_middleware\_names](#output\_security\_middleware\_names) | List of enabled security middleware names |

<!-- END_TF_DOCS -->
