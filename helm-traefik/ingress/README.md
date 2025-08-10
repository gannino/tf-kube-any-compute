# ingress

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | n/a |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [kubernetes_manifest.ingressroute_traefik_dashboard](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.traefik_dashboard_auth_middleware](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_secret.traefik_dashboard_auth](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [random_password.password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_dashboard_auth"></a> [dashboard\_auth](#input\_dashboard\_auth) | Basic authentication configuration for Traefik dashboard | `string` | `"traefik-dashboard-basicauth"` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Domain name suffix for ingress rules | `string` | `".local"` | no |
| <a name="input_label_app"></a> [label\_app](#input\_label\_app) | Application label for Kubernetes resources | `string` | `"traefik"` | no |
| <a name="input_label_role"></a> [label\_role](#input\_label\_role) | Role label for Kubernetes resources | `string` | `"ingress-controller"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Kubernetes namespace where resources will be deployed | `string` | `""` | no |
| <a name="input_service_name"></a> [service\_name](#input\_service\_name) | Name of the Kubernetes service | `string` | `""` | no |
| <a name="input_traefik_cert_resolver"></a> [traefik\_cert\_resolver](#input\_traefik\_cert\_resolver) | Certificate resolver configuration for Traefik | `string` | `"default"` | no |
| <a name="input_traefik_dashboard_password"></a> [traefik\_dashboard\_password](#input\_traefik\_dashboard\_password) | Custom password for Traefik dashboard (empty = auto-generate) | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_traefik_dashboard_password"></a> [traefik\_dashboard\_password](#output\_traefik\_dashboard\_password) | n/a |
<!-- END_TF_DOCS -->
