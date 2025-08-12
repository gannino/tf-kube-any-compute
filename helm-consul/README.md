# helm-consul

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.14 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 3.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | 3.0.2 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.38.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.7.2 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.this](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_ingress_v1.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/ingress_v1) | resource |
| [kubernetes_limit_range.namespace_limits](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/limit_range) | resource |
| [kubernetes_namespace.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_secret.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [random_bytes.gossip_encryption_key](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/bytes) | resource |
| [kubernetes_secret.token](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/secret) | data source |
| [kubernetes_service.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/service) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_chart_name"></a> [chart\_name](#input\_chart\_name) | Helm name. | `string` | `"consul"` | no |
| <a name="input_chart_repo"></a> [chart\_repo](#input\_chart\_repo) | Helm repository name. | `string` | `"https://helm.releases.hashicorp.com"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Helm version. | `string` | `"1.8.0"` | no |
| <a name="input_consul_image_version"></a> [consul\_image\_version](#input\_consul\_image\_version) | Consul image version | `string` | `"1.19.1"` | no |
| <a name="input_consul_k8s_image_version"></a> [consul\_k8s\_image\_version](#input\_consul\_k8s\_image\_version) | Consul K8S image version | `string` | `"1.4.1"` | no |
| <a name="input_cpu_arch"></a> [cpu\_arch](#input\_cpu\_arch) | CPU architecture for node selection (amd64, arm64) | `string` | `"amd64"` | no |
| <a name="input_cpu_limit"></a> [cpu\_limit](#input\_cpu\_limit) | Default CPU limit for containers | `string` | `"200m"` | no |
| <a name="input_cpu_request"></a> [cpu\_request](#input\_cpu\_request) | Default CPU request for containers | `string` | `"50m"` | no |
| <a name="input_disable_arch_scheduling"></a> [disable\_arch\_scheduling](#input\_disable\_arch\_scheduling) | Disable architecture-based node scheduling (useful for cluster-wide services) | `bool` | `false` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Domain name for the Consul deployment. | `string` | `".local"` | no |
| <a name="input_enable_ingress"></a> [enable\_ingress](#input\_enable\_ingress) | Enable ingress for the Consul deployment. | `bool` | `true` | no |
| <a name="input_helm_cleanup_on_fail"></a> [helm\_cleanup\_on\_fail](#input\_helm\_cleanup\_on\_fail) | Cleanup resources on failure | `bool` | `false` | no |
| <a name="input_helm_disable_webhooks"></a> [helm\_disable\_webhooks](#input\_helm\_disable\_webhooks) | Disable webhooks for Helm release | `bool` | `true` | no |
| <a name="input_helm_force_update"></a> [helm\_force\_update](#input\_helm\_force\_update) | Force resource updates if needed | `bool` | `true` | no |
| <a name="input_helm_replace"></a> [helm\_replace](#input\_helm\_replace) | Allow Helm to replace existing resources | `bool` | `true` | no |
| <a name="input_helm_skip_crds"></a> [helm\_skip\_crds](#input\_helm\_skip\_crds) | Skip CRDs for Helm release | `bool` | `false` | no |
| <a name="input_helm_timeout"></a> [helm\_timeout](#input\_helm\_timeout) | Timeout for Helm deployment in seconds | `number` | `300` | no |
| <a name="input_helm_wait"></a> [helm\_wait](#input\_helm\_wait) | Wait for Helm release to be ready | `bool` | `false` | no |
| <a name="input_helm_wait_for_jobs"></a> [helm\_wait\_for\_jobs](#input\_helm\_wait\_for\_jobs) | Wait for Helm jobs to complete | `bool` | `false` | no |
| <a name="input_memory_limit"></a> [memory\_limit](#input\_memory\_limit) | Default memory limit for containers | `string` | `"256Mi"` | no |
| <a name="input_memory_request"></a> [memory\_request](#input\_memory\_request) | Default memory request for containers | `string` | `"128Mi"` | no |
| <a name="input_name"></a> [name](#input\_name) | Helm name. | `string` | `"consul"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace. | `string` | `"consul-stack"` | no |
| <a name="input_persistent_disk_size"></a> [persistent\_disk\_size](#input\_persistent\_disk\_size) | Persistent disk size for Consul storage in GB. | `string` | `"1"` | no |
| <a name="input_service_overrides"></a> [service\_overrides](#input\_service\_overrides) | Override default service configuration | <pre>object({<br/>    helm_config = optional(object({<br/>      chart_name       = optional(string)<br/>      chart_repo       = optional(string)<br/>      chart_version    = optional(string)<br/>      timeout          = optional(number)<br/>      disable_webhooks = optional(bool)<br/>      skip_crds        = optional(bool)<br/>      replace          = optional(bool)<br/>      force_update     = optional(bool)<br/>      cleanup_on_fail  = optional(bool)<br/>      wait             = optional(bool)<br/>      wait_for_jobs    = optional(bool)<br/>    }), {})<br/>    labels          = optional(map(string), {})<br/>    template_values = optional(map(any), {})<br/>  })</pre> | <pre>{<br/>  "helm_config": {},<br/>  "labels": {},<br/>  "template_values": {}<br/>}</pre> | no |
| <a name="input_storage_class"></a> [storage\_class](#input\_storage\_class) | Storage class to use for Consul persistent storage. | `string` | `"hostpath"` | no |
| <a name="input_traefik_cert_resolver"></a> [traefik\_cert\_resolver](#input\_traefik\_cert\_resolver) | Traefik certificate resolver to use for ingress. | `string` | `"default"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_get_acl_secret"></a> [get\_acl\_secret](#output\_get\_acl\_secret) | Command to retrieve the ACL bootstrap token from the Kubernetes secret. |
| <a name="output_token"></a> [token](#output\_token) | Consul bootstrap token |
| <a name="output_uri"></a> [uri](#output\_uri) | Consul server URI with port (hostname:port format) |
| <a name="output_url"></a> [url](#output\_url) | Consul server hostname (without port) |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.14 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 3.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | 3.0.2 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.38.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.7.2 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.this](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_ingress_v1.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/ingress_v1) | resource |
| [kubernetes_limit_range.namespace_limits](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/limit_range) | resource |
| [kubernetes_namespace.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_secret.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [random_bytes.gossip_encryption_key](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/bytes) | resource |
| [kubernetes_secret.token](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/secret) | data source |
| [kubernetes_service.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/service) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_chart_name"></a> [chart\_name](#input\_chart\_name) | Helm name. | `string` | `"consul"` | no |
| <a name="input_chart_repo"></a> [chart\_repo](#input\_chart\_repo) | Helm repository name. | `string` | `"https://helm.releases.hashicorp.com"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Helm version. | `string` | `"1.8.0"` | no |
| <a name="input_consul_image_version"></a> [consul\_image\_version](#input\_consul\_image\_version) | Consul image version | `string` | `"1.19.1"` | no |
| <a name="input_consul_k8s_image_version"></a> [consul\_k8s\_image\_version](#input\_consul\_k8s\_image\_version) | Consul K8S image version | `string` | `"1.4.1"` | no |
| <a name="input_cpu_arch"></a> [cpu\_arch](#input\_cpu\_arch) | CPU architecture for node selection (amd64, arm64) | `string` | `"amd64"` | no |
| <a name="input_cpu_limit"></a> [cpu\_limit](#input\_cpu\_limit) | Default CPU limit for containers | `string` | `"200m"` | no |
| <a name="input_cpu_request"></a> [cpu\_request](#input\_cpu\_request) | Default CPU request for containers | `string` | `"50m"` | no |
| <a name="input_disable_arch_scheduling"></a> [disable\_arch\_scheduling](#input\_disable\_arch\_scheduling) | Disable architecture-based node scheduling (useful for cluster-wide services) | `bool` | `false` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Domain name for the Consul deployment. | `string` | `".local"` | no |
| <a name="input_enable_ingress"></a> [enable\_ingress](#input\_enable\_ingress) | Enable ingress for the Consul deployment. | `bool` | `true` | no |
| <a name="input_helm_cleanup_on_fail"></a> [helm\_cleanup\_on\_fail](#input\_helm\_cleanup\_on\_fail) | Cleanup resources on failure | `bool` | `false` | no |
| <a name="input_helm_disable_webhooks"></a> [helm\_disable\_webhooks](#input\_helm\_disable\_webhooks) | Disable webhooks for Helm release | `bool` | `true` | no |
| <a name="input_helm_force_update"></a> [helm\_force\_update](#input\_helm\_force\_update) | Force resource updates if needed | `bool` | `true` | no |
| <a name="input_helm_replace"></a> [helm\_replace](#input\_helm\_replace) | Allow Helm to replace existing resources | `bool` | `true` | no |
| <a name="input_helm_skip_crds"></a> [helm\_skip\_crds](#input\_helm\_skip\_crds) | Skip CRDs for Helm release | `bool` | `false` | no |
| <a name="input_helm_timeout"></a> [helm\_timeout](#input\_helm\_timeout) | Timeout for Helm deployment in seconds | `number` | `300` | no |
| <a name="input_helm_wait"></a> [helm\_wait](#input\_helm\_wait) | Wait for Helm release to be ready | `bool` | `false` | no |
| <a name="input_helm_wait_for_jobs"></a> [helm\_wait\_for\_jobs](#input\_helm\_wait\_for\_jobs) | Wait for Helm jobs to complete | `bool` | `false` | no |
| <a name="input_memory_limit"></a> [memory\_limit](#input\_memory\_limit) | Default memory limit for containers | `string` | `"256Mi"` | no |
| <a name="input_memory_request"></a> [memory\_request](#input\_memory\_request) | Default memory request for containers | `string` | `"128Mi"` | no |
| <a name="input_name"></a> [name](#input\_name) | Helm name. | `string` | `"consul"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace. | `string` | `"consul-stack"` | no |
| <a name="input_persistent_disk_size"></a> [persistent\_disk\_size](#input\_persistent\_disk\_size) | Persistent disk size for Consul storage in GB. | `string` | `"1"` | no |
| <a name="input_service_overrides"></a> [service\_overrides](#input\_service\_overrides) | Override default service configuration | <pre>object({<br/>    helm_config = optional(object({<br/>      chart_name       = optional(string)<br/>      chart_repo       = optional(string)<br/>      chart_version    = optional(string)<br/>      timeout          = optional(number)<br/>      disable_webhooks = optional(bool)<br/>      skip_crds        = optional(bool)<br/>      replace          = optional(bool)<br/>      force_update     = optional(bool)<br/>      cleanup_on_fail  = optional(bool)<br/>      wait             = optional(bool)<br/>      wait_for_jobs    = optional(bool)<br/>    }), {})<br/>    labels          = optional(map(string), {})<br/>    template_values = optional(map(any), {})<br/>  })</pre> | <pre>{<br/>  "helm_config": {},<br/>  "labels": {},<br/>  "template_values": {}<br/>}</pre> | no |
| <a name="input_storage_class"></a> [storage\_class](#input\_storage\_class) | Storage class to use for Consul persistent storage. | `string` | `"hostpath"` | no |
| <a name="input_traefik_cert_resolver"></a> [traefik\_cert\_resolver](#input\_traefik\_cert\_resolver) | Traefik certificate resolver to use for ingress. | `string` | `"default"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_get_acl_secret"></a> [get\_acl\_secret](#output\_get\_acl\_secret) | Command to retrieve the ACL bootstrap token from the Kubernetes secret. |
| <a name="output_token"></a> [token](#output\_token) | Consul bootstrap token |
| <a name="output_uri"></a> [uri](#output\_uri) | Consul server URI with port (hostname:port format) |
| <a name="output_url"></a> [url](#output\_url) | Consul server hostname (without port) |
<!-- END_TF_DOCS -->
