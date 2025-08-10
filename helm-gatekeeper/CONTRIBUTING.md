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

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_crds"></a> [crds](#module\_crds) | ./crds | n/a |
| <a name="module_policies"></a> [policies](#module\_policies) | ./policies | n/a |

## Resources

| Name | Type |
|------|------|
| [helm_release.this](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_limit_range.namespace_limits](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/limit_range) | resource |
| [kubernetes_namespace.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_resources.gatekeeper_crds](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/resources) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_chart_name"></a> [chart\_name](#input\_chart\_name) | Helm chart name. | `string` | `"gatekeeper"` | no |
| <a name="input_chart_repo"></a> [chart\_repo](#input\_chart\_repo) | Helm repository name. | `string` | `"https://open-policy-agent.github.io/gatekeeper/charts"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Helm version. | `string` | `"3.15.1"` | no |
| <a name="input_container_max_cpu"></a> [container\_max\_cpu](#input\_container\_max\_cpu) | Maximum CPU limit for containers | `string` | `"500m"` | no |
| <a name="input_container_max_memory"></a> [container\_max\_memory](#input\_container\_max\_memory) | Maximum memory limit for containers | `string` | `"512Mi"` | no |
| <a name="input_cpu_arch"></a> [cpu\_arch](#input\_cpu\_arch) | CPU architecture for node selection (amd64, arm64) | `string` | `"amd64"` | no |
| <a name="input_cpu_limit"></a> [cpu\_limit](#input\_cpu\_limit) | CPU limit for the container | `string` | `"500m"` | no |
| <a name="input_cpu_request"></a> [cpu\_request](#input\_cpu\_request) | CPU request for the container | `string` | `"100m"` | no |
| <a name="input_crd_api_version"></a> [crd\_api\_version](#input\_crd\_api\_version) | API version for CRD operations | `string` | `"apiextensions.k8s.io/v1"` | no |
| <a name="input_crd_wait_timeout"></a> [crd\_wait\_timeout](#input\_crd\_wait\_timeout) | Timeout for CRD readiness checks | `string` | `"60s"` | no |
| <a name="input_disable_arch_scheduling"></a> [disable\_arch\_scheduling](#input\_disable\_arch\_scheduling) | Disable architecture-based node scheduling (useful for cluster-wide services) | `bool` | `false` | no |
| <a name="input_enable_hostpath_policy"></a> [enable\_hostpath\_policy](#input\_enable\_hostpath\_policy) | Enable hostpath PVC size limit policy | `bool` | `true` | no |
| <a name="input_enable_policies"></a> [enable\_policies](#input\_enable\_policies) | Enable Gatekeeper policies. | `bool` | `true` | no |
| <a name="input_enable_resource_policies"></a> [enable\_resource\_policies](#input\_enable\_resource\_policies) | Enable resource requirement policies (CPU/memory limits) | `bool` | `false` | no |
| <a name="input_enable_security_policies"></a> [enable\_security\_policies](#input\_enable\_security\_policies) | Enable security-related policies (security context, privileged containers) | `bool` | `true` | no |
| <a name="input_gatekeeper_version"></a> [gatekeeper\_version](#input\_gatekeeper\_version) | Gatekeeper version for CRD deployment (should match chart version) | `string` | `"3.15"` | no |
| <a name="input_helm_cleanup_on_fail"></a> [helm\_cleanup\_on\_fail](#input\_helm\_cleanup\_on\_fail) | Cleanup resources on failure | `bool` | `false` | no |
| <a name="input_helm_disable_webhooks"></a> [helm\_disable\_webhooks](#input\_helm\_disable\_webhooks) | Disable webhooks for Helm release | `bool` | `false` | no |
| <a name="input_helm_force_update"></a> [helm\_force\_update](#input\_helm\_force\_update) | Force resource updates if needed | `bool` | `false` | no |
| <a name="input_helm_replace"></a> [helm\_replace](#input\_helm\_replace) | Allow Helm to replace existing resources | `bool` | `false` | no |
| <a name="input_helm_skip_crds"></a> [helm\_skip\_crds](#input\_helm\_skip\_crds) | Skip CRDs for Helm release | `bool` | `false` | no |
| <a name="input_helm_timeout"></a> [helm\_timeout](#input\_helm\_timeout) | Timeout for Helm deployment in seconds | `number` | `120` | no |
| <a name="input_helm_wait"></a> [helm\_wait](#input\_helm\_wait) | Wait for Helm release to be ready | `bool` | `true` | no |
| <a name="input_helm_wait_for_jobs"></a> [helm\_wait\_for\_jobs](#input\_helm\_wait\_for\_jobs) | Wait for Helm jobs to complete | `bool` | `true` | no |
| <a name="input_hostpath_max_size"></a> [hostpath\_max\_size](#input\_hostpath\_max\_size) | Maximum allowed size for hostpath PVCs | `string` | `"10Gi"` | no |
| <a name="input_hostpath_storage_class"></a> [hostpath\_storage\_class](#input\_hostpath\_storage\_class) | Storage class name for hostpath policy | `string` | `"hostpath"` | no |
| <a name="input_limit_range_enabled"></a> [limit\_range\_enabled](#input\_limit\_range\_enabled) | Enable limit range for the namespace | `bool` | `true` | no |
| <a name="input_memory_limit"></a> [memory\_limit](#input\_memory\_limit) | Memory limit for the container | `string` | `"512Mi"` | no |
| <a name="input_memory_request"></a> [memory\_request](#input\_memory\_request) | Memory request for the container | `string` | `"256Mi"` | no |
| <a name="input_name"></a> [name](#input\_name) | Helm name. | `string` | `"gatekeeper"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace. | `string` | `"gatekeeper-stack"` | no |
| <a name="input_pvc_max_storage"></a> [pvc\_max\_storage](#input\_pvc\_max\_storage) | Maximum storage for persistent volume claims | `string` | `"10Gi"` | no |
| <a name="input_pvc_min_storage"></a> [pvc\_min\_storage](#input\_pvc\_min\_storage) | Minimum storage for persistent volume claims | `string` | `"1Gi"` | no |
| <a name="input_service_overrides"></a> [service\_overrides](#input\_service\_overrides) | Override values for existing helm deployment configurations | `map(any)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_gatekeeper_configuration"></a> [gatekeeper\_configuration](#output\_gatekeeper\_configuration) | Gatekeeper configuration details |
| <a name="output_helm_release"></a> [helm\_release](#output\_helm\_release) | Helm release information |
| <a name="output_namespace"></a> [namespace](#output\_namespace) | The namespace where Gatekeeper is deployed |
| <a name="output_policy_configuration"></a> [policy\_configuration](#output\_policy\_configuration) | Policy configuration details |
| <a name="output_resource_limits"></a> [resource\_limits](#output\_resource\_limits) | Resource limit configuration |
<!-- END_TF_DOCS -->