<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.14 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 3.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | 3.0.2 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.38.0 |
| <a name="provider_time"></a> [time](#provider\_time) | 0.13.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.this](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_config_map.vault_scripts](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_deployment.vault_unsealer](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment) | resource |
| [kubernetes_ingress_v1.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/ingress_v1) | resource |
| [kubernetes_job.vault_init](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/job) | resource |
| [kubernetes_limit_range.namespace_limits](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/limit_range) | resource |
| [kubernetes_manifest.vault_ingress_route](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_namespace.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_role.vault](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/role) | resource |
| [kubernetes_role_binding.vault](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/role_binding) | resource |
| [time_sleep.wait_for_crd_registration](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [kubernetes_service.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/service) | data source |
| [kubernetes_service_account.vault](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/service_account) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_chart_name"></a> [chart\_name](#input\_chart\_name) | Helm chart name. | `string` | `"vault"` | no |
| <a name="input_chart_repo"></a> [chart\_repo](#input\_chart\_repo) | Helm repository URL. | `string` | `"https://helm.releases.hashicorp.com"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Version of the Helm chart to deploy. Refer to https://artifacthub.io/packages/helm/hashicorp/vault for available versions. | `string` | `"0.28.0"` | no |
| <a name="input_consul_address"></a> [consul\_address](#input\_consul\_address) | Consul service address in hostname:port format (e.g., consul-server.consul.svc.cluster.local:8500). | `string` | `"consul-server.consul.svc.cluster.local:8500"` | no |
| <a name="input_consul_port"></a> [consul\_port](#input\_consul\_port) | Port number for Consul service | `number` | `8500` | no |
| <a name="input_consul_token"></a> [consul\_token](#input\_consul\_token) | Consul ACL token for Vault authentication. | `string` | `""` | no |
| <a name="input_cpu_arch"></a> [cpu\_arch](#input\_cpu\_arch) | CPU architecture for node selection (amd64, arm64) | `string` | `"amd64"` | no |
| <a name="input_cpu_limit"></a> [cpu\_limit](#input\_cpu\_limit) | CPU limit for the container | `string` | `"200m"` | no |
| <a name="input_cpu_request"></a> [cpu\_request](#input\_cpu\_request) | CPU request for the container | `string` | `"50m"` | no |
| <a name="input_disable_arch_scheduling"></a> [disable\_arch\_scheduling](#input\_disable\_arch\_scheduling) | Disable architecture-based node scheduling (useful for cluster-wide services) | `bool` | `false` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Domain name suffix. | `string` | `".local"` | no |
| <a name="input_enable_ingress"></a> [enable\_ingress](#input\_enable\_ingress) | Enable Ingress for Vault UI. | `bool` | `true` | no |
| <a name="input_enable_traefik_ingress"></a> [enable\_traefik\_ingress](#input\_enable\_traefik\_ingress) | n/a | `bool` | `false` | no |
| <a name="input_healthcheck_interval"></a> [healthcheck\_interval](#input\_healthcheck\_interval) | Interval for health check probes | `string` | `"10s"` | no |
| <a name="input_healthcheck_timeout"></a> [healthcheck\_timeout](#input\_healthcheck\_timeout) | Timeout for health check probes | `string` | `"5s"` | no |
| <a name="input_helm_cleanup_on_fail"></a> [helm\_cleanup\_on\_fail](#input\_helm\_cleanup\_on\_fail) | Cleanup resources on failure | `bool` | `false` | no |
| <a name="input_helm_disable_webhooks"></a> [helm\_disable\_webhooks](#input\_helm\_disable\_webhooks) | Disable webhooks for Helm release | `bool` | `true` | no |
| <a name="input_helm_force_update"></a> [helm\_force\_update](#input\_helm\_force\_update) | Force resource updates if needed | `bool` | `true` | no |
| <a name="input_helm_replace"></a> [helm\_replace](#input\_helm\_replace) | Allow Helm to replace existing resources | `bool` | `true` | no |
| <a name="input_helm_skip_crds"></a> [helm\_skip\_crds](#input\_helm\_skip\_crds) | Skip CRDs for Helm release | `bool` | `false` | no |
| <a name="input_helm_timeout"></a> [helm\_timeout](#input\_helm\_timeout) | Timeout for Helm deployment in seconds | `number` | `300` | no |
| <a name="input_helm_wait"></a> [helm\_wait](#input\_helm\_wait) | Wait for Helm release to be ready | `bool` | `false` | no |
| <a name="input_helm_wait_for_jobs"></a> [helm\_wait\_for\_jobs](#input\_helm\_wait\_for\_jobs) | Wait for Helm jobs to complete | `bool` | `false` | no |
| <a name="input_ingress_sleep_duration"></a> [ingress\_sleep\_duration](#input\_ingress\_sleep\_duration) | Duration to wait before creating ingress resources | `string` | `"1s"` | no |
| <a name="input_memory_limit"></a> [memory\_limit](#input\_memory\_limit) | Memory limit for the container | `string` | `"128Mi"` | no |
| <a name="input_memory_request"></a> [memory\_request](#input\_memory\_request) | Memory request for the container | `string` | `"64Mi"` | no |
| <a name="input_name"></a> [name](#input\_name) | Helm release name. | `string` | `"vault"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace. | `string` | `"vault-stack"` | no |
| <a name="input_service_overrides"></a> [service\_overrides](#input\_service\_overrides) | Override default service configuration | <pre>object({<br/>    helm_config = optional(object({<br/>      chart_name       = optional(string)<br/>      chart_repo       = optional(string)<br/>      chart_version    = optional(string)<br/>      timeout          = optional(number)<br/>      disable_webhooks = optional(bool)<br/>      skip_crds        = optional(bool)<br/>      replace          = optional(bool)<br/>      force_update     = optional(bool)<br/>      cleanup_on_fail  = optional(bool)<br/>      wait             = optional(bool)<br/>      wait_for_jobs    = optional(bool)<br/>    }), {})<br/>    labels          = optional(map(string), {})<br/>    template_values = optional(map(any), {})<br/>  })</pre> | <pre>{<br/>  "helm_config": {},<br/>  "labels": {},<br/>  "template_values": {}<br/>}</pre> | no |
| <a name="input_storage_class"></a> [storage\_class](#input\_storage\_class) | Storage class to use for persistent volumes | `string` | `""` | no |
| <a name="input_storage_size"></a> [storage\_size](#input\_storage\_size) | Size of the persistent volume | `string` | `"2Gi"` | no |
| <a name="input_traefik_cert_resolver"></a> [traefik\_cert\_resolver](#input\_traefik\_cert\_resolver) | n/a | `string` | `"default"` | no |
| <a name="input_vault_init_timeout"></a> [vault\_init\_timeout](#input\_vault\_init\_timeout) | Timeout in seconds for Vault initialization | `number` | `600` | no |
| <a name="input_vault_port"></a> [vault\_port](#input\_vault\_port) | Port number for Vault service | `number` | `8200` | no |
| <a name="input_vault_readiness_timeout"></a> [vault\_readiness\_timeout](#input\_vault\_readiness\_timeout) | Timeout in seconds for Vault container readiness | `number` | `300` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_common_labels"></a> [common\_labels](#output\_common\_labels) | Common labels applied to all resources |
| <a name="output_consul_backend_address"></a> [consul\_backend\_address](#output\_consul\_backend\_address) | Consul backend address used by Vault |
| <a name="output_consul_port"></a> [consul\_port](#output\_consul\_port) | Consul port used by Vault backend |
| <a name="output_environment_config"></a> [environment\_config](#output\_environment\_config) | Environment configuration summary |
| <a name="output_health_check_endpoint"></a> [health\_check\_endpoint](#output\_health\_check\_endpoint) | Vault health check endpoint |
| <a name="output_health_check_url"></a> [health\_check\_url](#output\_health\_check\_url) | Full health check URL |
| <a name="output_helm_chart_name"></a> [helm\_chart\_name](#output\_helm\_chart\_name) | Helm chart name |
| <a name="output_helm_chart_version"></a> [helm\_chart\_version](#output\_helm\_chart\_version) | Helm chart version deployed |
| <a name="output_helm_release_name"></a> [helm\_release\_name](#output\_helm\_release\_name) | Helm release name |
| <a name="output_ingress_url"></a> [ingress\_url](#output\_ingress\_url) | External ingress URL for Vault web UI |
| <a name="output_kubectl_commands"></a> [kubectl\_commands](#output\_kubectl\_commands) | Useful kubectl commands for Vault operations |
| <a name="output_namespace"></a> [namespace](#output\_namespace) | Vault namespace |
| <a name="output_service_name"></a> [service\_name](#output\_service\_name) | Vault service name |
| <a name="output_service_url"></a> [service\_url](#output\_service\_url) | Internal service URL for Vault (cluster-local) |
| <a name="output_storage_class"></a> [storage\_class](#output\_storage\_class) | Storage class used for Vault persistence |
| <a name="output_storage_size"></a> [storage\_size](#output\_storage\_size) | Storage size allocated for Vault |
| <a name="output_vault_address"></a> [vault\_address](#output\_vault\_address) | Vault server address (hostname:port format for client configuration) |
| <a name="output_vault_port"></a> [vault\_port](#output\_vault\_port) | Vault server port |
| <a name="output_web_ui_url"></a> [web\_ui\_url](#output\_web\_ui\_url) | Vault web UI URL |
<!-- END_TF_DOCS -->