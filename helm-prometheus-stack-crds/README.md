# helm-prometheus-stack-crds

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.14 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 3.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | 3.0.2 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.38.0 |
| <a name="provider_null"></a> [null](#provider\_null) | 3.2.4 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.prometheus_crds](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_limit_range.namespace_limits](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/limit_range) | resource |
| [kubernetes_namespace.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [null_resource.wait_for_crds](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alertmanager_storage_size"></a> [alertmanager\_storage\_size](#input\_alertmanager\_storage\_size) | AlertManager storage size | `string` | `"2Gi"` | no |
| <a name="input_chart_name"></a> [chart\_name](#input\_chart\_name) | Helm name. | `string` | `"kube-prometheus-stack"` | no |
| <a name="input_chart_repo"></a> [chart\_repo](#input\_chart\_repo) | Helm repository name. | `string` | `"https://prometheus-community.github.io/helm-charts"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Helm version. | `string` | `"14.0.0"` | no |
| <a name="input_container_max_cpu"></a> [container\_max\_cpu](#input\_container\_max\_cpu) | Maximum CPU limit for containers | `string` | `"500m"` | no |
| <a name="input_container_max_memory"></a> [container\_max\_memory](#input\_container\_max\_memory) | Maximum memory limit for containers | `string` | `"256Mi"` | no |
| <a name="input_cpu_arch"></a> [cpu\_arch](#input\_cpu\_arch) | CPU architecture | `string` | `"arm64"` | no |
| <a name="input_cpu_limit"></a> [cpu\_limit](#input\_cpu\_limit) | CPU limit for the container | `string` | `"500m"` | no |
| <a name="input_cpu_request"></a> [cpu\_request](#input\_cpu\_request) | CPU request for the container | `string` | `"250m"` | no |
| <a name="input_crd_wait_timeout_minutes"></a> [crd\_wait\_timeout\_minutes](#input\_crd\_wait\_timeout\_minutes) | Timeout in minutes to wait for CRDs to be registered | `number` | `20` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Domain name for the deployment. | `string` | `".local"` | no |
| <a name="input_enable_alertmanager_ingress"></a> [enable\_alertmanager\_ingress](#input\_enable\_alertmanager\_ingress) | Enable ingress for Alertmanager. | `bool` | `false` | no |
| <a name="input_enable_prometheus_ingress"></a> [enable\_prometheus\_ingress](#input\_enable\_prometheus\_ingress) | Enable ingress for Prometheus. | `bool` | `false` | no |
| <a name="input_enable_prometheus_ingress_route"></a> [enable\_prometheus\_ingress\_route](#input\_enable\_prometheus\_ingress\_route) | Enable ingress route for Prometheus. | `bool` | `false` | no |
| <a name="input_grafana_storage_size"></a> [grafana\_storage\_size](#input\_grafana\_storage\_size) | Grafana storage size | `string` | `"4Gi"` | no |
| <a name="input_helm_cleanup_on_fail"></a> [helm\_cleanup\_on\_fail](#input\_helm\_cleanup\_on\_fail) | Cleanup resources on failure | `bool` | `false` | no |
| <a name="input_helm_disable_webhooks"></a> [helm\_disable\_webhooks](#input\_helm\_disable\_webhooks) | Disable webhooks for Helm release | `bool` | `false` | no |
| <a name="input_helm_force_update"></a> [helm\_force\_update](#input\_helm\_force\_update) | Force resource updates if needed | `bool` | `false` | no |
| <a name="input_helm_replace"></a> [helm\_replace](#input\_helm\_replace) | Allow Helm to replace existing resources | `bool` | `false` | no |
| <a name="input_helm_skip_crds"></a> [helm\_skip\_crds](#input\_helm\_skip\_crds) | Skip CRDs for Helm release | `bool` | `false` | no |
| <a name="input_helm_timeout"></a> [helm\_timeout](#input\_helm\_timeout) | Timeout for Helm deployment in seconds | `number` | `300` | no |
| <a name="input_helm_wait"></a> [helm\_wait](#input\_helm\_wait) | Wait for Helm release to be ready | `bool` | `false` | no |
| <a name="input_helm_wait_for_jobs"></a> [helm\_wait\_for\_jobs](#input\_helm\_wait\_for\_jobs) | Wait for Helm jobs to complete | `bool` | `false` | no |
| <a name="input_limit_range_enabled"></a> [limit\_range\_enabled](#input\_limit\_range\_enabled) | Enable limit range for the namespace | `bool` | `true` | no |
| <a name="input_memory_limit"></a> [memory\_limit](#input\_memory\_limit) | Memory limit for the container | `string` | `"256Mi"` | no |
| <a name="input_memory_request"></a> [memory\_request](#input\_memory\_request) | Memory request for the container | `string` | `"128Mi"` | no |
| <a name="input_name"></a> [name](#input\_name) | Helm release name. | `string` | `"prometheus-operator-crds"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace. | `string` | `"pre-monitoring-system"` | no |
| <a name="input_prometheus_storage_size"></a> [prometheus\_storage\_size](#input\_prometheus\_storage\_size) | Prometheus storage size | `string` | `"8Gi"` | no |
| <a name="input_prometheus_url"></a> [prometheus\_url](#input\_prometheus\_url) | Prometheus URL | `string` | `""` | no |
| <a name="input_pvc_max_storage"></a> [pvc\_max\_storage](#input\_pvc\_max\_storage) | Maximum storage for persistent volume claims | `string` | `"10Gi"` | no |
| <a name="input_pvc_min_storage"></a> [pvc\_min\_storage](#input\_pvc\_min\_storage) | Minimum storage for persistent volume claims | `string` | `"1Gi"` | no |
| <a name="input_release_name"></a> [release\_name](#input\_release\_name) | Helm release name. | `string` | `"prometheus-operator-crds"` | no |
| <a name="input_service_overrides"></a> [service\_overrides](#input\_service\_overrides) | Override values for existing helm deployment configurations | `map(any)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_crd_configuration"></a> [crd\_configuration](#output\_crd\_configuration) | CRD configuration details |
| <a name="output_helm_release"></a> [helm\_release](#output\_helm\_release) | Helm release information |
| <a name="output_namespace"></a> [namespace](#output\_namespace) | The namespace where the Prometheus CRDs are deployed |
| <a name="output_resource_limits"></a> [resource\_limits](#output\_resource\_limits) | Resource limit configuration |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

<!-- BEGIN_TF_DOCS -->


## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.14 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 3.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | 3.0.2 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.38.0 |
| <a name="provider_null"></a> [null](#provider\_null) | 3.2.4 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.prometheus_crds](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_limit_range.namespace_limits](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/limit_range) | resource |
| [kubernetes_namespace.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [null_resource.wait_for_crds](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alertmanager_storage_size"></a> [alertmanager\_storage\_size](#input\_alertmanager\_storage\_size) | AlertManager storage size | `string` | `"2Gi"` | no |
| <a name="input_chart_name"></a> [chart\_name](#input\_chart\_name) | Helm name. | `string` | `"kube-prometheus-stack"` | no |
| <a name="input_chart_repo"></a> [chart\_repo](#input\_chart\_repo) | Helm repository name. | `string` | `"https://prometheus-community.github.io/helm-charts"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Helm version. | `string` | `"14.0.0"` | no |
| <a name="input_container_max_cpu"></a> [container\_max\_cpu](#input\_container\_max\_cpu) | Maximum CPU limit for containers | `string` | `"500m"` | no |
| <a name="input_container_max_memory"></a> [container\_max\_memory](#input\_container\_max\_memory) | Maximum memory limit for containers | `string` | `"256Mi"` | no |
| <a name="input_cpu_arch"></a> [cpu\_arch](#input\_cpu\_arch) | CPU architecture | `string` | `"arm64"` | no |
| <a name="input_cpu_limit"></a> [cpu\_limit](#input\_cpu\_limit) | CPU limit for the container | `string` | `"500m"` | no |
| <a name="input_cpu_request"></a> [cpu\_request](#input\_cpu\_request) | CPU request for the container | `string` | `"250m"` | no |
| <a name="input_crd_wait_timeout_minutes"></a> [crd\_wait\_timeout\_minutes](#input\_crd\_wait\_timeout\_minutes) | Timeout in minutes to wait for CRDs to be registered | `number` | `20` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Domain name for the deployment. | `string` | `".local"` | no |
| <a name="input_enable_alertmanager_ingress"></a> [enable\_alertmanager\_ingress](#input\_enable\_alertmanager\_ingress) | Enable ingress for Alertmanager. | `bool` | `false` | no |
| <a name="input_enable_prometheus_ingress"></a> [enable\_prometheus\_ingress](#input\_enable\_prometheus\_ingress) | Enable ingress for Prometheus. | `bool` | `false` | no |
| <a name="input_enable_prometheus_ingress_route"></a> [enable\_prometheus\_ingress\_route](#input\_enable\_prometheus\_ingress\_route) | Enable ingress route for Prometheus. | `bool` | `false` | no |
| <a name="input_grafana_storage_size"></a> [grafana\_storage\_size](#input\_grafana\_storage\_size) | Grafana storage size | `string` | `"4Gi"` | no |
| <a name="input_helm_cleanup_on_fail"></a> [helm\_cleanup\_on\_fail](#input\_helm\_cleanup\_on\_fail) | Cleanup resources on failure | `bool` | `false` | no |
| <a name="input_helm_disable_webhooks"></a> [helm\_disable\_webhooks](#input\_helm\_disable\_webhooks) | Disable webhooks for Helm release | `bool` | `false` | no |
| <a name="input_helm_force_update"></a> [helm\_force\_update](#input\_helm\_force\_update) | Force resource updates if needed | `bool` | `false` | no |
| <a name="input_helm_replace"></a> [helm\_replace](#input\_helm\_replace) | Allow Helm to replace existing resources | `bool` | `false` | no |
| <a name="input_helm_skip_crds"></a> [helm\_skip\_crds](#input\_helm\_skip\_crds) | Skip CRDs for Helm release | `bool` | `false` | no |
| <a name="input_helm_timeout"></a> [helm\_timeout](#input\_helm\_timeout) | Timeout for Helm deployment in seconds | `number` | `300` | no |
| <a name="input_helm_wait"></a> [helm\_wait](#input\_helm\_wait) | Wait for Helm release to be ready | `bool` | `false` | no |
| <a name="input_helm_wait_for_jobs"></a> [helm\_wait\_for\_jobs](#input\_helm\_wait\_for\_jobs) | Wait for Helm jobs to complete | `bool` | `false` | no |
| <a name="input_limit_range_enabled"></a> [limit\_range\_enabled](#input\_limit\_range\_enabled) | Enable limit range for the namespace | `bool` | `true` | no |
| <a name="input_memory_limit"></a> [memory\_limit](#input\_memory\_limit) | Memory limit for the container | `string` | `"256Mi"` | no |
| <a name="input_memory_request"></a> [memory\_request](#input\_memory\_request) | Memory request for the container | `string` | `"128Mi"` | no |
| <a name="input_name"></a> [name](#input\_name) | Helm release name. | `string` | `"prometheus-operator-crds"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace. | `string` | `"pre-monitoring-system"` | no |
| <a name="input_prometheus_storage_size"></a> [prometheus\_storage\_size](#input\_prometheus\_storage\_size) | Prometheus storage size | `string` | `"8Gi"` | no |
| <a name="input_prometheus_url"></a> [prometheus\_url](#input\_prometheus\_url) | Prometheus URL | `string` | `""` | no |
| <a name="input_pvc_max_storage"></a> [pvc\_max\_storage](#input\_pvc\_max\_storage) | Maximum storage for persistent volume claims | `string` | `"10Gi"` | no |
| <a name="input_pvc_min_storage"></a> [pvc\_min\_storage](#input\_pvc\_min\_storage) | Minimum storage for persistent volume claims | `string` | `"1Gi"` | no |
| <a name="input_release_name"></a> [release\_name](#input\_release\_name) | Helm release name. | `string` | `"prometheus-operator-crds"` | no |
| <a name="input_service_overrides"></a> [service\_overrides](#input\_service\_overrides) | Override values for existing helm deployment configurations | `map(any)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_crd_configuration"></a> [crd\_configuration](#output\_crd\_configuration) | CRD configuration details |
| <a name="output_helm_release"></a> [helm\_release](#output\_helm\_release) | Helm release information |
| <a name="output_namespace"></a> [namespace](#output\_namespace) | The namespace where the Prometheus CRDs are deployed |
| <a name="output_resource_limits"></a> [resource\_limits](#output\_resource\_limits) | Resource limit configuration |

<!-- END_TF_DOCS -->
