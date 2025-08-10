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
| <a name="provider_null"></a> [null](#provider\_null) | 3.2.4 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.7.2 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.this](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_ingress_v1.alertmanager](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/ingress_v1) | resource |
| [kubernetes_ingress_v1.prometheus](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/ingress_v1) | resource |
| [kubernetes_limit_range.namespace_limits](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/limit_range) | resource |
| [kubernetes_manifest.monitoring_auth_middleware](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_namespace.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_secret.monitoring_auth](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [null_resource.wait_for_traefik_crds](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [random_password.monitoring_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [kubernetes_service.alertmanager](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/service) | data source |
| [kubernetes_service.prometheus](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/service) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alertmanager_storage_class"></a> [alertmanager\_storage\_class](#input\_alertmanager\_storage\_class) | Storage class for Alertmanager PVC (empty uses cluster default). | `string` | `""` | no |
| <a name="input_alertmanager_storage_size"></a> [alertmanager\_storage\_size](#input\_alertmanager\_storage\_size) | Storage size for Alertmanager persistent volume. | `string` | `"2Gi"` | no |
| <a name="input_chart_name"></a> [chart\_name](#input\_chart\_name) | Helm chart name for Prometheus stack. | `string` | `"kube-prometheus-stack"` | no |
| <a name="input_chart_repo"></a> [chart\_repo](#input\_chart\_repo) | Helm repository URL for Prometheus charts. | `string` | `"https://prometheus-community.github.io/helm-charts"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Helm chart version for Prometheus stack. | `string` | `"75.15.2"` | no |
| <a name="input_cpu_arch"></a> [cpu\_arch](#input\_cpu\_arch) | CPU architecture for container images (amd64, arm64). | `string` | `"arm64"` | no |
| <a name="input_cpu_limit"></a> [cpu\_limit](#input\_cpu\_limit) | CPU limit for containers in the namespace. | `string` | `"300m"` | no |
| <a name="input_cpu_request"></a> [cpu\_request](#input\_cpu\_request) | CPU request for containers in the namespace. | `string` | `"50m"` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Domain name for ingress resources. | `string` | `".local"` | no |
| <a name="input_enable_alertmanager_ingress"></a> [enable\_alertmanager\_ingress](#input\_enable\_alertmanager\_ingress) | Enable Alertmanager ingress configuration. | `bool` | `false` | no |
| <a name="input_enable_monitoring_auth"></a> [enable\_monitoring\_auth](#input\_enable\_monitoring\_auth) | Enable basic authentication for monitoring services (requires Traefik CRDs - enable after first apply) | `bool` | `false` | no |
| <a name="input_enable_node_selector"></a> [enable\_node\_selector](#input\_enable\_node\_selector) | Enable node selectors for component scheduling. | `bool` | `false` | no |
| <a name="input_enable_prometheus_ingress"></a> [enable\_prometheus\_ingress](#input\_enable\_prometheus\_ingress) | Enable Prometheus ingress configuration. | `bool` | `false` | no |
| <a name="input_enable_prometheus_ingress_route"></a> [enable\_prometheus\_ingress\_route](#input\_enable\_prometheus\_ingress\_route) | Enable Prometheus ingress route configuration. | `bool` | `false` | no |
| <a name="input_helm_cleanup_on_fail"></a> [helm\_cleanup\_on\_fail](#input\_helm\_cleanup\_on\_fail) | Cleanup resources on deployment failure. | `bool` | `false` | no |
| <a name="input_helm_disable_webhooks"></a> [helm\_disable\_webhooks](#input\_helm\_disable\_webhooks) | Disable webhooks for Helm release. | `bool` | `false` | no |
| <a name="input_helm_force_update"></a> [helm\_force\_update](#input\_helm\_force\_update) | Force resource updates if needed. | `bool` | `false` | no |
| <a name="input_helm_replace"></a> [helm\_replace](#input\_helm\_replace) | Allow Helm to replace existing resources. | `bool` | `false` | no |
| <a name="input_helm_skip_crds"></a> [helm\_skip\_crds](#input\_helm\_skip\_crds) | Skip CRDs for Helm release. | `bool` | `false` | no |
| <a name="input_helm_timeout"></a> [helm\_timeout](#input\_helm\_timeout) | Timeout for Helm deployment in seconds. | `number` | `600` | no |
| <a name="input_helm_wait"></a> [helm\_wait](#input\_helm\_wait) | Wait for Helm release to be ready. | `bool` | `false` | no |
| <a name="input_helm_wait_for_jobs"></a> [helm\_wait\_for\_jobs](#input\_helm\_wait\_for\_jobs) | Wait for Helm jobs to complete. | `bool` | `false` | no |
| <a name="input_memory_limit"></a> [memory\_limit](#input\_memory\_limit) | Memory limit for containers in the namespace. | `string` | `"256Mi"` | no |
| <a name="input_memory_request"></a> [memory\_request](#input\_memory\_request) | Memory request for containers in the namespace. | `string` | `"128Mi"` | no |
| <a name="input_monitoring_admin_password"></a> [monitoring\_admin\_password](#input\_monitoring\_admin\_password) | Custom password for monitoring services basic auth (empty = auto-generate) | `string` | `""` | no |
| <a name="input_name"></a> [name](#input\_name) | Helm release name for Prometheus stack. | `string` | `"kube-prometheus-stack"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace for Prometheus monitoring stack. | `string` | `"monitoring-system"` | no |
| <a name="input_prometheus_storage_class"></a> [prometheus\_storage\_class](#input\_prometheus\_storage\_class) | Storage class for Prometheus PVC (empty uses cluster default). | `string` | `""` | no |
| <a name="input_prometheus_storage_size"></a> [prometheus\_storage\_size](#input\_prometheus\_storage\_size) | Storage size for Prometheus persistent volume. | `string` | `"8Gi"` | no |
| <a name="input_prometheus_url"></a> [prometheus\_url](#input\_prometheus\_url) | External Prometheus URL if applicable. | `string` | `""` | no |
| <a name="input_traefik_cert_resolver"></a> [traefik\_cert\_resolver](#input\_traefik\_cert\_resolver) | Traefik certificate resolver for TLS. | `string` | `"wildcard"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alertmanager_ingress_url"></a> [alertmanager\_ingress\_url](#output\_alertmanager\_ingress\_url) | External ingress URL for AlertManager web UI |
| <a name="output_alertmanager_port"></a> [alertmanager\_port](#output\_alertmanager\_port) | AlertManager server port |
| <a name="output_alertmanager_service_name"></a> [alertmanager\_service\_name](#output\_alertmanager\_service\_name) | AlertManager service name |
| <a name="output_alertmanager_storage_class"></a> [alertmanager\_storage\_class](#output\_alertmanager\_storage\_class) | Storage class used for AlertManager persistence |
| <a name="output_alertmanager_storage_size"></a> [alertmanager\_storage\_size](#output\_alertmanager\_storage\_size) | Storage size allocated for AlertManager |
| <a name="output_alertmanager_url"></a> [alertmanager\_url](#output\_alertmanager\_url) | Internal service URL for AlertManager (cluster-local) |
| <a name="output_common_labels"></a> [common\_labels](#output\_common\_labels) | Common labels applied to all resources |
| <a name="output_environment_config"></a> [environment\_config](#output\_environment\_config) | Environment configuration summary |
| <a name="output_helm_chart_name"></a> [helm\_chart\_name](#output\_helm\_chart\_name) | Helm chart name |
| <a name="output_helm_chart_version"></a> [helm\_chart\_version](#output\_helm\_chart\_version) | Helm chart version deployed |
| <a name="output_helm_release_name"></a> [helm\_release\_name](#output\_helm\_release\_name) | Helm release name |
| <a name="output_kubectl_commands"></a> [kubectl\_commands](#output\_kubectl\_commands) | Useful kubectl commands for Prometheus stack operations |
| <a name="output_monitoring_admin_password"></a> [monitoring\_admin\_password](#output\_monitoring\_admin\_password) | Admin password for Prometheus and AlertManager basic auth |
| <a name="output_monitoring_admin_username"></a> [monitoring\_admin\_username](#output\_monitoring\_admin\_username) | Admin username for Prometheus and AlertManager basic auth |
| <a name="output_namespace"></a> [namespace](#output\_namespace) | Prometheus stack namespace |
| <a name="output_prometheus_ingress_url"></a> [prometheus\_ingress\_url](#output\_prometheus\_ingress\_url) | External ingress URL for Prometheus web UI |
| <a name="output_prometheus_port"></a> [prometheus\_port](#output\_prometheus\_port) | Prometheus server port |
| <a name="output_prometheus_service_name"></a> [prometheus\_service\_name](#output\_prometheus\_service\_name) | Prometheus service name |
| <a name="output_prometheus_storage_class"></a> [prometheus\_storage\_class](#output\_prometheus\_storage\_class) | Storage class used for Prometheus persistence |
| <a name="output_prometheus_storage_size"></a> [prometheus\_storage\_size](#output\_prometheus\_storage\_size) | Storage size allocated for Prometheus |
| <a name="output_prometheus_url"></a> [prometheus\_url](#output\_prometheus\_url) | Internal service URL for Prometheus (cluster-local) |
<!-- END_TF_DOCS -->