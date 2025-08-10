<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 3.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.20 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.4 |

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
| [random_password.password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [kubernetes_service.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/service) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alertmanager_url"></a> [alertmanager\_url](#input\_alertmanager\_url) | Alertmanager URL for datasource configuration. | `string` | `"http://localhost:9093"` | no |
| <a name="input_chart_name"></a> [chart\_name](#input\_chart\_name) | Helm chart name for Grafana. | `string` | `"grafana"` | no |
| <a name="input_chart_repo"></a> [chart\_repo](#input\_chart\_repo) | Helm repository URL for Grafana charts. | `string` | `"https://grafana.github.io/helm-charts"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Helm chart version for Grafana. | `string` | `"9.3.1"` | no |
| <a name="input_cpu_arch"></a> [cpu\_arch](#input\_cpu\_arch) | CPU architecture for container images (amd64, arm64). | `string` | `"amd64"` | no |
| <a name="input_cpu_limit"></a> [cpu\_limit](#input\_cpu\_limit) | CPU limit for Grafana containers. | `string` | `"200m"` | no |
| <a name="input_cpu_request"></a> [cpu\_request](#input\_cpu\_request) | CPU request for Grafana containers. | `string` | `"100m"` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Domain name for Grafana ingress. | `string` | `".local"` | no |
| <a name="input_enable_persistence"></a> [enable\_persistence](#input\_enable\_persistence) | Enable persistent storage for Grafana. | `bool` | `true` | no |
| <a name="input_grafana_admin_password"></a> [grafana\_admin\_password](#input\_grafana\_admin\_password) | Custom password for Grafana admin (empty = auto-generate). | `string` | `""` | no |
| <a name="input_grafana_admin_user"></a> [grafana\_admin\_user](#input\_grafana\_admin\_user) | Grafana admin username. | `string` | `"admin"` | no |
| <a name="input_grafana_node_name"></a> [grafana\_node\_name](#input\_grafana\_node\_name) | Specific node name to run Grafana (for high-disk nodes). | `string` | `""` | no |
| <a name="input_helm_cleanup_on_fail"></a> [helm\_cleanup\_on\_fail](#input\_helm\_cleanup\_on\_fail) | Cleanup resources on deployment failure. | `bool` | `false` | no |
| <a name="input_helm_disable_webhooks"></a> [helm\_disable\_webhooks](#input\_helm\_disable\_webhooks) | Disable webhooks for Helm release. | `bool` | `false` | no |
| <a name="input_helm_force_update"></a> [helm\_force\_update](#input\_helm\_force\_update) | Force resource updates if needed. | `bool` | `false` | no |
| <a name="input_helm_replace"></a> [helm\_replace](#input\_helm\_replace) | Allow Helm to replace existing resources. | `bool` | `false` | no |
| <a name="input_helm_skip_crds"></a> [helm\_skip\_crds](#input\_helm\_skip\_crds) | Skip CRDs for Helm release. | `bool` | `false` | no |
| <a name="input_helm_timeout"></a> [helm\_timeout](#input\_helm\_timeout) | Timeout for Helm deployment in seconds. | `number` | `300` | no |
| <a name="input_helm_wait"></a> [helm\_wait](#input\_helm\_wait) | Wait for Helm release to be ready. | `bool` | `false` | no |
| <a name="input_helm_wait_for_jobs"></a> [helm\_wait\_for\_jobs](#input\_helm\_wait\_for\_jobs) | Wait for Helm jobs to complete. | `bool` | `false` | no |
| <a name="input_loki_url"></a> [loki\_url](#input\_loki\_url) | Loki URL for datasource configuration. | `string` | `"http://localhost:3100"` | no |
| <a name="input_memory_limit"></a> [memory\_limit](#input\_memory\_limit) | Memory limit for Grafana containers. | `string` | `"256Mi"` | no |
| <a name="input_memory_request"></a> [memory\_request](#input\_memory\_request) | Memory request for Grafana containers. | `string` | `"128Mi"` | no |
| <a name="input_name"></a> [name](#input\_name) | Helm release name for Grafana. | `string` | `"grafana"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace for Grafana visualization system. | `string` | `"grafana-system"` | no |
| <a name="input_prometheus_namespace"></a> [prometheus\_namespace](#input\_prometheus\_namespace) | Prometheus namespace for service discovery. | `string` | `"prometheus_namespace"` | no |
| <a name="input_prometheus_url"></a> [prometheus\_url](#input\_prometheus\_url) | Prometheus datasource URL for Grafana. | `string` | `"build-prometheus-server"` | no |
| <a name="input_storage_class"></a> [storage\_class](#input\_storage\_class) | Storage class for Grafana persistent volume. | `string` | `"hostpath"` | no |
| <a name="input_storage_size"></a> [storage\_size](#input\_storage\_size) | Size of the persistent volume for Grafana. | `string` | `"2Gi"` | no |
| <a name="input_traefik_cert_resolver"></a> [traefik\_cert\_resolver](#input\_traefik\_cert\_resolver) | Traefik certificate resolver for TLS. | `string` | `"default"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_admin_password"></a> [admin\_password](#output\_admin\_password) | n/a |
| <a name="output_admin_user"></a> [admin\_user](#output\_admin\_user) | n/a |
| <a name="output_grafana_service_name"></a> [grafana\_service\_name](#output\_grafana\_service\_name) | n/a |
| <a name="output_ingress_url"></a> [ingress\_url](#output\_ingress\_url) | n/a |
| <a name="output_namespace"></a> [namespace](#output\_namespace) | n/a |
| <a name="output_service_url"></a> [service\_url](#output\_service\_url) | n/a |
<!-- END_TF_DOCS -->
