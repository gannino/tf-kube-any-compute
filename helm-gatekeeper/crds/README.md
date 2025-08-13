# Terraform Module

<!-- BEGIN_TF_DOCS -->


## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_http"></a> [http](#requirement\_http) | >= 3.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.0 |
| <a name="requirement_time"></a> [time](#requirement\_time) | >= 0.7 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_http"></a> [http](#provider\_http) | 3.5.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.38.0 |
| <a name="provider_time"></a> [time](#provider\_time) | 0.13.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [kubernetes_manifest.gatekeeper_crds](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [time_sleep.wait_for_crds](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [http_http.gatekeeper_crds](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_chart_name"></a> [chart\_name](#input\_chart\_name) | Name of the Gatekeeper Helm chart | `string` | `"gatekeeper"` | no |
| <a name="input_chart_repo"></a> [chart\_repo](#input\_chart\_repo) | Repository URL for the Gatekeeper Helm chart | `string` | `"https://open-policy-agent.github.io/gatekeeper/charts"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Version of the Gatekeeper Helm chart to deploy | `string` | `null` | no |
| <a name="input_crd_api_version"></a> [crd\_api\_version](#input\_crd\_api\_version) | API version for CRD manifests | `string` | `"apiextensions.k8s.io/v1"` | no |
| <a name="input_crd_wait_duration"></a> [crd\_wait\_duration](#input\_crd\_wait\_duration) | Duration to wait after CRD creation for stabilization | `string` | `"30s"` | no |
| <a name="input_gatekeeper_version"></a> [gatekeeper\_version](#input\_gatekeeper\_version) | Version of Gatekeeper to deploy CRDs for | `string` | `"3.14"` | no |
| <a name="input_helm_cleanup_on_fail"></a> [helm\_cleanup\_on\_fail](#input\_helm\_cleanup\_on\_fail) | Whether to cleanup resources on failure | `bool` | `true` | no |
| <a name="input_helm_timeout"></a> [helm\_timeout](#input\_helm\_timeout) | Timeout for helm operations in seconds | `number` | `900` | no |
| <a name="input_helm_wait"></a> [helm\_wait](#input\_helm\_wait) | Whether to wait for the deployment to be ready | `bool` | `true` | no |
| <a name="input_helm_wait_for_jobs"></a> [helm\_wait\_for\_jobs](#input\_helm\_wait\_for\_jobs) | Whether to wait for jobs to complete | `bool` | `true` | no |
| <a name="input_name"></a> [name](#input\_name) | Name for the Gatekeeper CRDs deployment | `string` | `"gatekeeper"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Kubernetes namespace for Gatekeeper CRDs | `string` | `"gatekeeper"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_crd_names"></a> [crd\_names](#output\_crd\_names) | Names of the deployed Gatekeeper CRDs |
| <a name="output_crd_namespace"></a> [crd\_namespace](#output\_crd\_namespace) | Namespace where Gatekeeper CRDs are deployed |
| <a name="output_crds_ready"></a> [crds\_ready](#output\_crds\_ready) | Indicates when Gatekeeper CRDs are ready for use |

<!-- END_TF_DOCS -->
