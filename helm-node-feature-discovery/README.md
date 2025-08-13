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
| [kubernetes_limit_range.namespace_limits](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/limit_range) | resource |
| [kubernetes_namespace.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_chart_name"></a> [chart\_name](#input\_chart\_name) | Helm chart name. | `string` | `"node-feature-discovery"` | no |
| <a name="input_chart_repo"></a> [chart\_repo](#input\_chart\_repo) | Helm repository name. | `string` | `"https://kubernetes-sigs.github.io/node-feature-discovery/charts"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Helm version. | `string` | `"0.17.3"` | no |
| <a name="input_cpu_arch"></a> [cpu\_arch](#input\_cpu\_arch) | CPU architecture for node selection (amd64, arm64) | `string` | `"amd64"` | no |
| <a name="input_cpu_limit"></a> [cpu\_limit](#input\_cpu\_limit) | CPU limit for the container | `string` | `"200m"` | no |
| <a name="input_cpu_request"></a> [cpu\_request](#input\_cpu\_request) | CPU request for the container | `string` | `"50m"` | no |
| <a name="input_disable_arch_scheduling"></a> [disable\_arch\_scheduling](#input\_disable\_arch\_scheduling) | Disable architecture-based node scheduling (useful for cluster-wide services) | `bool` | `true` | no |
| <a name="input_helm_cleanup_on_fail"></a> [helm\_cleanup\_on\_fail](#input\_helm\_cleanup\_on\_fail) | Cleanup resources on failure | `bool` | `false` | no |
| <a name="input_helm_disable_webhooks"></a> [helm\_disable\_webhooks](#input\_helm\_disable\_webhooks) | Disable webhooks for Helm release | `bool` | `false` | no |
| <a name="input_helm_force_update"></a> [helm\_force\_update](#input\_helm\_force\_update) | Force resource updates if needed | `bool` | `false` | no |
| <a name="input_helm_replace"></a> [helm\_replace](#input\_helm\_replace) | Allow Helm to replace existing resources | `bool` | `false` | no |
| <a name="input_helm_skip_crds"></a> [helm\_skip\_crds](#input\_helm\_skip\_crds) | Skip CRDs for Helm release | `bool` | `false` | no |
| <a name="input_helm_timeout"></a> [helm\_timeout](#input\_helm\_timeout) | Timeout for Helm deployment in seconds | `number` | `120` | no |
| <a name="input_helm_wait"></a> [helm\_wait](#input\_helm\_wait) | Wait for Helm release to be ready | `bool` | `false` | no |
| <a name="input_helm_wait_for_jobs"></a> [helm\_wait\_for\_jobs](#input\_helm\_wait\_for\_jobs) | Wait for Helm jobs to complete | `bool` | `false` | no |
| <a name="input_memory_limit"></a> [memory\_limit](#input\_memory\_limit) | Memory limit for the container | `string` | `"128Mi"` | no |
| <a name="input_memory_request"></a> [memory\_request](#input\_memory\_request) | Memory request for the container | `string` | `"64Mi"` | no |
| <a name="input_name"></a> [name](#input\_name) | Helm name. | `string` | `"node-feature-discovery"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace. | `string` | `"node-feature-discovery-stack"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_namespace"></a> [namespace](#output\_namespace) | n/a |

<!-- END_TF_DOCS -->
