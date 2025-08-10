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
| [kubernetes_storage_class.nfs_fast](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/storage_class) | resource |
| [kubernetes_storage_class.nfs_safe](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/storage_class) | resource |
| [kubernetes_storage_class.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/storage_class) | resource |
| [kubernetes_service.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/service) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_chart_name"></a> [chart\_name](#input\_chart\_name) | Helm name. | `string` | `"nfs-subdir-external-provisioner"` | no |
| <a name="input_chart_repo"></a> [chart\_repo](#input\_chart\_repo) | Helm repository name. | `string` | `"https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Helm version. | `string` | `"4.0.17"` | no |
| <a name="input_cpu_arch"></a> [cpu\_arch](#input\_cpu\_arch) | n/a | `string` | `"arm64"` | no |
| <a name="input_cpu_limit"></a> [cpu\_limit](#input\_cpu\_limit) | CPU limit for the container | `string` | `"100m"` | no |
| <a name="input_cpu_request"></a> [cpu\_request](#input\_cpu\_request) | CPU request for the container | `string` | `"25m"` | no |
| <a name="input_create_fast_storage_class"></a> [create\_fast\_storage\_class](#input\_create\_fast\_storage\_class) | Create an additional high-performance NFS storage class | `bool` | `false` | no |
| <a name="input_create_safe_storage_class"></a> [create\_safe\_storage\_class](#input\_create\_safe\_storage\_class) | Create an additional safety-focused NFS storage class | `bool` | `true` | no |
| <a name="input_disable_arch_scheduling"></a> [disable\_arch\_scheduling](#input\_disable\_arch\_scheduling) | Disable architecture-based node scheduling (useful for cluster-wide services) | `bool` | `true` | no |
| <a name="input_enable_nfs_csi_ingress"></a> [enable\_nfs\_csi\_ingress](#input\_enable\_nfs\_csi\_ingress) | n/a | `bool` | `false` | no |
| <a name="input_enable_nfs_csi_ingress_route"></a> [enable\_nfs\_csi\_ingress\_route](#input\_enable\_nfs\_csi\_ingress\_route) | n/a | `bool` | `false` | no |
| <a name="input_helm_cleanup_on_fail"></a> [helm\_cleanup\_on\_fail](#input\_helm\_cleanup\_on\_fail) | Cleanup resources on failure | `bool` | `false` | no |
| <a name="input_helm_disable_webhooks"></a> [helm\_disable\_webhooks](#input\_helm\_disable\_webhooks) | Disable webhooks for Helm release | `bool` | `false` | no |
| <a name="input_helm_force_update"></a> [helm\_force\_update](#input\_helm\_force\_update) | Force resource updates if needed | `bool` | `false` | no |
| <a name="input_helm_replace"></a> [helm\_replace](#input\_helm\_replace) | Allow Helm to replace existing resources | `bool` | `false` | no |
| <a name="input_helm_skip_crds"></a> [helm\_skip\_crds](#input\_helm\_skip\_crds) | Skip CRDs for Helm release | `bool` | `false` | no |
| <a name="input_helm_timeout"></a> [helm\_timeout](#input\_helm\_timeout) | Timeout for Helm deployment in seconds | `number` | `300` | no |
| <a name="input_helm_wait"></a> [helm\_wait](#input\_helm\_wait) | Wait for Helm release to be ready | `bool` | `false` | no |
| <a name="input_helm_wait_for_jobs"></a> [helm\_wait\_for\_jobs](#input\_helm\_wait\_for\_jobs) | Wait for Helm jobs to complete | `bool` | `false` | no |
| <a name="input_let_helm_create_storage_class"></a> [let\_helm\_create\_storage\_class](#input\_let\_helm\_create\_storage\_class) | Create a storage class using helm | `bool` | `false` | no |
| <a name="input_limit_range_container_max_cpu"></a> [limit\_range\_container\_max\_cpu](#input\_limit\_range\_container\_max\_cpu) | Maximum CPU limit for containers (default: same as cpu\_limit) | `string` | `null` | no |
| <a name="input_limit_range_container_max_memory"></a> [limit\_range\_container\_max\_memory](#input\_limit\_range\_container\_max\_memory) | Maximum memory limit for containers (default: same as memory\_limit) | `string` | `null` | no |
| <a name="input_limit_range_enabled"></a> [limit\_range\_enabled](#input\_limit\_range\_enabled) | Enable limit range for the namespace | `bool` | `true` | no |
| <a name="input_limit_range_pvc_max_storage"></a> [limit\_range\_pvc\_max\_storage](#input\_limit\_range\_pvc\_max\_storage) | Maximum storage size for PVCs | `string` | `"10Gi"` | no |
| <a name="input_limit_range_pvc_min_storage"></a> [limit\_range\_pvc\_min\_storage](#input\_limit\_range\_pvc\_min\_storage) | Minimum storage size for PVCs | `string` | `"100Mi"` | no |
| <a name="input_memory_limit"></a> [memory\_limit](#input\_memory\_limit) | Memory limit for the container | `string` | `"64Mi"` | no |
| <a name="input_memory_request"></a> [memory\_request](#input\_memory\_request) | Memory request for the container | `string` | `"32Mi"` | no |
| <a name="input_name"></a> [name](#input\_name) | Helm name. | `string` | `"nfs-csi"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace. | `string` | `"nfs-csi-stack"` | no |
| <a name="input_nfs_domain_name"></a> [nfs\_domain\_name](#input\_nfs\_domain\_name) | Domain name for NFS server. | `string` | `".local"` | no |
| <a name="input_nfs_path"></a> [nfs\_path](#input\_nfs\_path) | n/a | `string` | n/a | yes |
| <a name="input_nfs_retrans_default"></a> [nfs\_retrans\_default](#input\_nfs\_retrans\_default) | Default number of NFS retries | `number` | `2` | no |
| <a name="input_nfs_retrans_fast"></a> [nfs\_retrans\_fast](#input\_nfs\_retrans\_fast) | Number of NFS retries for fast storage class | `number` | `3` | no |
| <a name="input_nfs_retrans_safe"></a> [nfs\_retrans\_safe](#input\_nfs\_retrans\_safe) | Number of NFS retries for safe storage class | `number` | `5` | no |
| <a name="input_nfs_server"></a> [nfs\_server](#input\_nfs\_server) | n/a | `string` | n/a | yes |
| <a name="input_nfs_timeout_default"></a> [nfs\_timeout\_default](#input\_nfs\_timeout\_default) | Default NFS timeout in deciseconds (600 = 60 seconds) | `number` | `600` | no |
| <a name="input_nfs_timeout_fast"></a> [nfs\_timeout\_fast](#input\_nfs\_timeout\_fast) | Fast NFS timeout in deciseconds for quick failover (150 = 15 seconds) | `number` | `150` | no |
| <a name="input_nfs_timeout_safe"></a> [nfs\_timeout\_safe](#input\_nfs\_timeout\_safe) | Safe NFS timeout in deciseconds for stability (900 = 90 seconds) | `number` | `900` | no |
| <a name="input_service_overrides"></a> [service\_overrides](#input\_service\_overrides) | Override default service configuration for backward compatibility | <pre>object({<br/>    helm_config = optional(object({<br/>      name      = optional(string)<br/>      namespace = optional(string)<br/>      resource_limits = optional(object({<br/>        requests = optional(object({<br/>          cpu    = optional(string)<br/>          memory = optional(string)<br/>        }))<br/>        limits = optional(object({<br/>          cpu    = optional(string)<br/>          memory = optional(string)<br/>        }))<br/>      }))<br/>    }))<br/>    labels          = optional(map(string))<br/>    template_values = optional(map(any))<br/>  })</pre> | `{}` | no |
| <a name="input_set_as_default_storage_class"></a> [set\_as\_default\_storage\_class](#input\_set\_as\_default\_storage\_class) | Set the NFS storage class as the default storage class | `bool` | `true` | no |
| <a name="input_storage_class"></a> [storage\_class](#input\_storage\_class) | Storage class name for NFS CSI | `string` | `"nfs-csi"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_helm_release_name"></a> [helm\_release\_name](#output\_helm\_release\_name) | Name of the Helm release |
| <a name="output_helm_release_status"></a> [helm\_release\_status](#output\_helm\_release\_status) | Status of the Helm release |
| <a name="output_namespace"></a> [namespace](#output\_namespace) | Namespace where NFS CSI is deployed |
| <a name="output_nfs_path"></a> [nfs\_path](#output\_nfs\_path) | NFS path used by the CSI driver |
| <a name="output_nfs_server"></a> [nfs\_server](#output\_nfs\_server) | NFS server used by the CSI driver |
| <a name="output_service_name"></a> [service\_name](#output\_service\_name) | Name of the NFS CSI frontend service |
| <a name="output_storage_classes"></a> [storage\_classes](#output\_storage\_classes) | Created storage classes |
<!-- END_TF_DOCS -->
