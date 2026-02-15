<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.14 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 3.0 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | ~> 1.14 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | 3.0.2 |
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | 1.19.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.38.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.this](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubectl_manifest.metallb_ip_pool](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.metallb_l2_advert](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubernetes_limit_range.namespace_limits](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/limit_range) | resource |
| [kubernetes_namespace.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_address_pool"></a> [address\_pool](#input\_address\_pool) | MetalLB address pool | `string` | `"192.168.169.30-192.168.169.60"` | no |
| <a name="input_controller_replica_count"></a> [controller\_replica\_count](#input\_controller\_replica\_count) | Number of replicas for the controller | `number` | `1` | no |
| <a name="input_cpu_arch"></a> [cpu\_arch](#input\_cpu\_arch) | CPU architecture for node selection (amd64, arm64) | `string` | `"arm64"` | no |
| <a name="input_cpu_limit"></a> [cpu\_limit](#input\_cpu\_limit) | CPU limit for the container | `string` | `"100m"` | no |
| <a name="input_cpu_request"></a> [cpu\_request](#input\_cpu\_request) | CPU request for the container | `string` | `"25m"` | no |
| <a name="input_disable_arch_scheduling"></a> [disable\_arch\_scheduling](#input\_disable\_arch\_scheduling) | Disable architecture-based node scheduling (useful for cluster-wide services) | `bool` | `false` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Domain name | `string` | `".local"` | no |
| <a name="input_enable_ingress"></a> [enable\_ingress](#input\_enable\_ingress) | Enable ingress | `bool` | `false` | no |
| <a name="input_helm_cleanup_on_fail"></a> [helm\_cleanup\_on\_fail](#input\_helm\_cleanup\_on\_fail) | Cleanup resources on failure | `bool` | `false` | no |
| <a name="input_helm_disable_webhooks"></a> [helm\_disable\_webhooks](#input\_helm\_disable\_webhooks) | Disable webhooks for Helm release | `bool` | `false` | no |
| <a name="input_helm_force_update"></a> [helm\_force\_update](#input\_helm\_force\_update) | Force resource updates if needed | `bool` | `false` | no |
| <a name="input_helm_replace"></a> [helm\_replace](#input\_helm\_replace) | Allow Helm to replace existing resources | `bool` | `false` | no |
| <a name="input_helm_skip_crds"></a> [helm\_skip\_crds](#input\_helm\_skip\_crds) | Skip CRDs for Helm release | `bool` | `false` | no |
| <a name="input_helm_timeout"></a> [helm\_timeout](#input\_helm\_timeout) | Timeout for Helm deployment in seconds | `number` | `300` | no |
| <a name="input_helm_wait"></a> [helm\_wait](#input\_helm\_wait) | Wait for Helm release to be ready | `bool` | `false` | no |
| <a name="input_helm_wait_for_jobs"></a> [helm\_wait\_for\_jobs](#input\_helm\_wait\_for\_jobs) | Wait for Helm jobs to complete | `bool` | `false` | no |
| <a name="input_ingress_gateway_chart_name"></a> [ingress\_gateway\_chart\_name](#input\_ingress\_gateway\_chart\_name) | Ingress Gateway Helm chart name. | `string` | `"metallb"` | no |
| <a name="input_ingress_gateway_chart_repo"></a> [ingress\_gateway\_chart\_repo](#input\_ingress\_gateway\_chart\_repo) | Ingress Gateway Helm repository name. | `string` | `"https://metallb.github.io/metallb"` | no |
| <a name="input_ingress_gateway_chart_version"></a> [ingress\_gateway\_chart\_version](#input\_ingress\_gateway\_chart\_version) | Ingress Gateway Helm repository version. | `string` | `"0.13.10"` | no |
| <a name="input_ingress_gateway_name"></a> [ingress\_gateway\_name](#input\_ingress\_gateway\_name) | Ingress Gateway Helm chart name. | `string` | `"metallb"` | no |
| <a name="input_le_email"></a> [le\_email](#input\_le\_email) | Let's Encrypt email | `string` | `""` | no |
| <a name="input_memory_limit"></a> [memory\_limit](#input\_memory\_limit) | Memory limit for the container | `string` | `"64Mi"` | no |
| <a name="input_memory_request"></a> [memory\_request](#input\_memory\_request) | Memory request for the container | `string` | `"32Mi"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Ingress Gateway namespace. | `string` | `"metallb-system"` | no |
| <a name="input_persistent_disc_size"></a> [persistent\_disc\_size](#input\_persistent\_disc\_size) | Persistent disk size | `string` | `"1"` | no |
| <a name="input_speaker_replica_count"></a> [speaker\_replica\_count](#input\_speaker\_replica\_count) | Number of replicas for the speaker | `number` | `1` | no |
| <a name="input_workspace"></a> [workspace](#input\_workspace) | Workspace name | `string` | `"set-me"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.14 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 3.0 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | ~> 1.14 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | 3.0.2 |
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | 1.19.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.38.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.this](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubectl_manifest.metallb_ip_pool](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.metallb_l2_advert](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubernetes_limit_range.namespace_limits](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/limit_range) | resource |
| [kubernetes_namespace.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_address_pool"></a> [address\_pool](#input\_address\_pool) | MetalLB address pool | `string` | `"192.168.169.30-192.168.169.60"` | no |
| <a name="input_controller_replica_count"></a> [controller\_replica\_count](#input\_controller\_replica\_count) | Number of replicas for the controller | `number` | `1` | no |
| <a name="input_cpu_arch"></a> [cpu\_arch](#input\_cpu\_arch) | CPU architecture for node selection (amd64, arm64) | `string` | `"arm64"` | no |
| <a name="input_cpu_limit"></a> [cpu\_limit](#input\_cpu\_limit) | CPU limit for the container | `string` | `"100m"` | no |
| <a name="input_cpu_request"></a> [cpu\_request](#input\_cpu\_request) | CPU request for the container | `string` | `"25m"` | no |
| <a name="input_disable_arch_scheduling"></a> [disable\_arch\_scheduling](#input\_disable\_arch\_scheduling) | Disable architecture-based node scheduling (useful for cluster-wide services) | `bool` | `false` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Domain name | `string` | `".local"` | no |
| <a name="input_enable_ingress"></a> [enable\_ingress](#input\_enable\_ingress) | Enable ingress | `bool` | `false` | no |
| <a name="input_helm_cleanup_on_fail"></a> [helm\_cleanup\_on\_fail](#input\_helm\_cleanup\_on\_fail) | Cleanup resources on failure | `bool` | `false` | no |
| <a name="input_helm_disable_webhooks"></a> [helm\_disable\_webhooks](#input\_helm\_disable\_webhooks) | Disable webhooks for Helm release | `bool` | `false` | no |
| <a name="input_helm_force_update"></a> [helm\_force\_update](#input\_helm\_force\_update) | Force resource updates if needed | `bool` | `false` | no |
| <a name="input_helm_replace"></a> [helm\_replace](#input\_helm\_replace) | Allow Helm to replace existing resources | `bool` | `false` | no |
| <a name="input_helm_skip_crds"></a> [helm\_skip\_crds](#input\_helm\_skip\_crds) | Skip CRDs for Helm release | `bool` | `false` | no |
| <a name="input_helm_timeout"></a> [helm\_timeout](#input\_helm\_timeout) | Timeout for Helm deployment in seconds | `number` | `300` | no |
| <a name="input_helm_wait"></a> [helm\_wait](#input\_helm\_wait) | Wait for Helm release to be ready | `bool` | `false` | no |
| <a name="input_helm_wait_for_jobs"></a> [helm\_wait\_for\_jobs](#input\_helm\_wait\_for\_jobs) | Wait for Helm jobs to complete | `bool` | `false` | no |
| <a name="input_ingress_gateway_chart_name"></a> [ingress\_gateway\_chart\_name](#input\_ingress\_gateway\_chart\_name) | Ingress Gateway Helm chart name. | `string` | `"metallb"` | no |
| <a name="input_ingress_gateway_chart_repo"></a> [ingress\_gateway\_chart\_repo](#input\_ingress\_gateway\_chart\_repo) | Ingress Gateway Helm repository name. | `string` | `"https://metallb.github.io/metallb"` | no |
| <a name="input_ingress_gateway_chart_version"></a> [ingress\_gateway\_chart\_version](#input\_ingress\_gateway\_chart\_version) | Ingress Gateway Helm repository version. | `string` | `"0.13.10"` | no |
| <a name="input_ingress_gateway_name"></a> [ingress\_gateway\_name](#input\_ingress\_gateway\_name) | Ingress Gateway Helm chart name. | `string` | `"metallb"` | no |
| <a name="input_le_email"></a> [le\_email](#input\_le\_email) | Let's Encrypt email | `string` | `""` | no |
| <a name="input_memory_limit"></a> [memory\_limit](#input\_memory\_limit) | Memory limit for the container | `string` | `"64Mi"` | no |
| <a name="input_memory_request"></a> [memory\_request](#input\_memory\_request) | Memory request for the container | `string` | `"32Mi"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Ingress Gateway namespace. | `string` | `"metallb-system"` | no |
| <a name="input_persistent_disc_size"></a> [persistent\_disc\_size](#input\_persistent\_disc\_size) | Persistent disk size | `string` | `"1"` | no |
| <a name="input_speaker_replica_count"></a> [speaker\_replica\_count](#input\_speaker\_replica\_count) | Number of replicas for the speaker | `number` | `1` | no |
| <a name="input_workspace"></a> [workspace](#input\_workspace) | Workspace name | `string` | `"set-me"` | no |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
