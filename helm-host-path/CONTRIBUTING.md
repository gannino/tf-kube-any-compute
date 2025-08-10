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

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.this](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_limit_range.hostpath_pvc_limit](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/limit_range) | resource |
| [kubernetes_limit_range.namespace_limits](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/limit_range) | resource |
| [kubernetes_namespace.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_resource_quota.hostpath_quota](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/resource_quota) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_chart_name"></a> [chart\_name](#input\_chart\_name) | Helm chart name. | `string` | `"local-path-provisioner"` | no |
| <a name="input_chart_repo"></a> [chart\_repo](#input\_chart\_repo) | Helm chart repository URL. | `string` | `"https://charts.containeroo.ch"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Helm chart version. | `string` | `"0.0.33"` | no |
| <a name="input_cpu_arch"></a> [cpu\_arch](#input\_cpu\_arch) | CPU architecture for node selection (amd64, arm64) | `string` | `"amd64"` | no |
| <a name="input_cpu_limit"></a> [cpu\_limit](#input\_cpu\_limit) | CPU limit for the container | `string` | `"100m"` | no |
| <a name="input_cpu_request"></a> [cpu\_request](#input\_cpu\_request) | CPU request for the container | `string` | `"25m"` | no |
| <a name="input_disable_arch_scheduling"></a> [disable\_arch\_scheduling](#input\_disable\_arch\_scheduling) | Disable architecture-based node scheduling (useful for cluster-wide services) | `bool` | `false` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Domain name to be used for the deployment. | `string` | `".local"` | no |
| <a name="input_helm_cleanup_on_fail"></a> [helm\_cleanup\_on\_fail](#input\_helm\_cleanup\_on\_fail) | Cleanup resources on failure | `bool` | `false` | no |
| <a name="input_helm_disable_webhooks"></a> [helm\_disable\_webhooks](#input\_helm\_disable\_webhooks) | Disable webhooks for Helm release | `bool` | `false` | no |
| <a name="input_helm_force_update"></a> [helm\_force\_update](#input\_helm\_force\_update) | Force resource updates if needed | `bool` | `false` | no |
| <a name="input_helm_replace"></a> [helm\_replace](#input\_helm\_replace) | Allow Helm to replace existing resources | `bool` | `false` | no |
| <a name="input_helm_skip_crds"></a> [helm\_skip\_crds](#input\_helm\_skip\_crds) | Skip CRDs for Helm release | `bool` | `false` | no |
| <a name="input_helm_timeout"></a> [helm\_timeout](#input\_helm\_timeout) | Timeout for Helm deployment in seconds | `number` | `300` | no |
| <a name="input_helm_wait"></a> [helm\_wait](#input\_helm\_wait) | Wait for Helm release to be ready | `bool` | `false` | no |
| <a name="input_helm_wait_for_jobs"></a> [helm\_wait\_for\_jobs](#input\_helm\_wait\_for\_jobs) | Wait for Helm jobs to complete | `bool` | `false` | no |
| <a name="input_hostpath_storage_quota_limit"></a> [hostpath\_storage\_quota\_limit](#input\_hostpath\_storage\_quota\_limit) | Storage quota limit for hostpath volumes | `string` | `"50Gi"` | no |
| <a name="input_let_helm_create_storage_class"></a> [let\_helm\_create\_storage\_class](#input\_let\_helm\_create\_storage\_class) | Create a storage class using helm | `bool` | `false` | no |
| <a name="input_limit_range_container_max_cpu"></a> [limit\_range\_container\_max\_cpu](#input\_limit\_range\_container\_max\_cpu) | Maximum CPU limit for containers (default: same as cpu\_limit) | `string` | `null` | no |
| <a name="input_limit_range_container_max_memory"></a> [limit\_range\_container\_max\_memory](#input\_limit\_range\_container\_max\_memory) | Maximum memory limit for containers (default: same as memory\_limit) | `string` | `null` | no |
| <a name="input_limit_range_enabled"></a> [limit\_range\_enabled](#input\_limit\_range\_enabled) | Enable limit range for the namespace | `bool` | `true` | no |
| <a name="input_limit_range_pvc_max_storage"></a> [limit\_range\_pvc\_max\_storage](#input\_limit\_range\_pvc\_max\_storage) | Maximum storage size for PVCs | `string` | `"10Gi"` | no |
| <a name="input_limit_range_pvc_min_storage"></a> [limit\_range\_pvc\_min\_storage](#input\_limit\_range\_pvc\_min\_storage) | Minimum storage size for PVCs | `string` | `"100Mi"` | no |
| <a name="input_memory_limit"></a> [memory\_limit](#input\_memory\_limit) | Memory limit for the container | `string` | `"64Mi"` | no |
| <a name="input_memory_request"></a> [memory\_request](#input\_memory\_request) | Memory request for the container | `string` | `"32Mi"` | no |
| <a name="input_name"></a> [name](#input\_name) | Helm name. | `string` | `"host-path"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace. | `string` | `"host-path-stack"` | no |
| <a name="input_service_overrides"></a> [service\_overrides](#input\_service\_overrides) | Service-specific overrides for labels, annotations, and other configurations | <pre>object({<br/>    labels      = optional(map(string), {})<br/>    annotations = optional(map(string), {})<br/>  })</pre> | <pre>{<br/>  "annotations": {},<br/>  "labels": {}<br/>}</pre> | no |
| <a name="input_set_as_default_storage_class"></a> [set\_as\_default\_storage\_class](#input\_set\_as\_default\_storage\_class) | Set the NFS storage class as the default storage class | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_helm_release"></a> [helm\_release](#output\_helm\_release) | Helm release information |
| <a name="output_namespace"></a> [namespace](#output\_namespace) | The namespace where the host path provisioner is deployed |
| <a name="output_resource_limits"></a> [resource\_limits](#output\_resource\_limits) | Resource limit configuration |
| <a name="output_storage_configuration"></a> [storage\_configuration](#output\_storage\_configuration) | Storage configuration details |
<!-- END_TF_DOCS -->
