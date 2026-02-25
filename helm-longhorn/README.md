# Longhorn Storage Module

Deploys Longhorn distributed block storage for Kubernetes.

## Features

- Distributed block storage with replication
- Automatic volume snapshots and backups
- Multi-architecture support (ARM64/AMD64)
- Configurable replica count
- Resource limits for production environments

## Usage

```hcl
module "longhorn" {
  source = "./helm-longhorn"

  name      = "prod-longhorn"
  namespace = "prod-longhorn-system"

  cpu_arch      = "amd64"
  replica_count = 3

  set_as_default_storage_class = true
}
```

## Requirements

- Kubernetes 1.21+
- `open-iscsi` installed on all nodes
- At least 3 nodes for HA setup

## Storage Class

After deployment, volumes can use the `longhorn` storage class:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: longhorn
  resources:
    requests:
      storage: 10Gi
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.14 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 3.0 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | ~> 1.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0 |
| <a name="requirement_time"></a> [time](#requirement\_time) | ~> 0.9 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | 3.1.1 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.38.0 |
| <a name="provider_null"></a> [null](#provider\_null) | 3.2.4 |
| <a name="provider_time"></a> [time](#provider\_time) | 0.13.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.this](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_manifest.dashboard_ingress](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_namespace.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [null_resource.cleanup](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [time_sleep.wait_for_crds](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [kubernetes_service.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/service) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_backup_target"></a> [backup\_target](#input\_backup\_target) | Longhorn backup target (NFS or S3) | `string` | `""` | no |
| <a name="input_backup_target_credential_secret"></a> [backup\_target\_credential\_secret](#input\_backup\_target\_credential\_secret) | Secret name for backup target credentials | `string` | `""` | no |
| <a name="input_chart_name"></a> [chart\_name](#input\_chart\_name) | Helm chart name | `string` | `"longhorn"` | no |
| <a name="input_chart_repo"></a> [chart\_repo](#input\_chart\_repo) | Helm repository URL | `string` | `"https://charts.longhorn.io"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Helm chart version | `string` | `"1.7.2"` | no |
| <a name="input_cpu_arch"></a> [cpu\_arch](#input\_cpu\_arch) | CPU architecture | `string` | `"amd64"` | no |
| <a name="input_cpu_limit"></a> [cpu\_limit](#input\_cpu\_limit) | CPU limit | `string` | `"500m"` | no |
| <a name="input_cpu_request"></a> [cpu\_request](#input\_cpu\_request) | CPU request | `string` | `"250m"` | no |
| <a name="input_default_data_path"></a> [default\_data\_path](#input\_default\_data\_path) | Default path for Longhorn data storage on nodes | `string` | `"/opt/longhorn"` | no |
| <a name="input_disable_arch_scheduling"></a> [disable\_arch\_scheduling](#input\_disable\_arch\_scheduling) | Disable architecture-based node scheduling | `bool` | `false` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Domain name for ingress | `string` | `"local"` | no |
| <a name="input_enable_dashboard"></a> [enable\_dashboard](#input\_enable\_dashboard) | Enable Longhorn Dashboard web interface | `bool` | `true` | no |
| <a name="input_enable_ingress"></a> [enable\_ingress](#input\_enable\_ingress) | Enable Traefik ingress for Longhorn Dashboard | `bool` | `true` | no |
| <a name="input_helm_cleanup_on_fail"></a> [helm\_cleanup\_on\_fail](#input\_helm\_cleanup\_on\_fail) | Cleanup resources on failure | `bool` | `true` | no |
| <a name="input_helm_disable_webhooks"></a> [helm\_disable\_webhooks](#input\_helm\_disable\_webhooks) | Disable webhooks for Helm release | `bool` | `false` | no |
| <a name="input_helm_force_update"></a> [helm\_force\_update](#input\_helm\_force\_update) | Force resource updates if needed | `bool` | `false` | no |
| <a name="input_helm_replace"></a> [helm\_replace](#input\_helm\_replace) | Allow Helm to replace existing resources | `bool` | `false` | no |
| <a name="input_helm_skip_crds"></a> [helm\_skip\_crds](#input\_helm\_skip\_crds) | Skip CRDs for Helm release | `bool` | `false` | no |
| <a name="input_helm_timeout"></a> [helm\_timeout](#input\_helm\_timeout) | Timeout for Helm deployment in seconds | `number` | `600` | no |
| <a name="input_helm_wait"></a> [helm\_wait](#input\_helm\_wait) | Wait for Helm release to be ready | `bool` | `true` | no |
| <a name="input_helm_wait_for_jobs"></a> [helm\_wait\_for\_jobs](#input\_helm\_wait\_for\_jobs) | Wait for Helm jobs to complete | `bool` | `true` | no |
| <a name="input_k8s_distribution"></a> [k8s\_distribution](#input\_k8s\_distribution) | Kubernetes distribution (k3s, microk8s, kubernetes, etc.) | `string` | `"microk8s"` | no |
| <a name="input_kubelet_root_dir"></a> [kubelet\_root\_dir](#input\_kubelet\_root\_dir) | Kubelet root directory path (auto-detected based on k8s\_distribution if empty) | `string` | `""` | no |
| <a name="input_memory_limit"></a> [memory\_limit](#input\_memory\_limit) | Memory limit | `string` | `"512Mi"` | no |
| <a name="input_memory_request"></a> [memory\_request](#input\_memory\_request) | Memory request | `string` | `"256Mi"` | no |
| <a name="input_name"></a> [name](#input\_name) | Helm release name | `string` | `"longhorn"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Kubernetes namespace | `string` | `"longhorn-system"` | no |
| <a name="input_replica_count"></a> [replica\_count](#input\_replica\_count) | Number of replicas for volumes | `number` | `3` | no |
| <a name="input_set_as_default_storage_class"></a> [set\_as\_default\_storage\_class](#input\_set\_as\_default\_storage\_class) | Set Longhorn as the default storage class | `bool` | `false` | no |
| <a name="input_traefik_cert_resolver"></a> [traefik\_cert\_resolver](#input\_traefik\_cert\_resolver) | Traefik certificate resolver | `string` | `"default"` | no |
| <a name="input_traefik_ingress_config"></a> [traefik\_ingress\_config](#input\_traefik\_ingress\_config) | Traefik ingress configuration | `any` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_helm_release_name"></a> [helm\_release\_name](#output\_helm\_release\_name) | Name of the Helm release |
| <a name="output_helm_release_status"></a> [helm\_release\_status](#output\_helm\_release\_status) | Status of the Helm release |
| <a name="output_namespace"></a> [namespace](#output\_namespace) | Namespace where Longhorn is deployed |
| <a name="output_storage_class_name"></a> [storage\_class\_name](#output\_storage\_class\_name) | Name of the Longhorn storage class |
<!-- END_TF_DOCS -->
