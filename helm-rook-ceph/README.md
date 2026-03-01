# Rook Ceph Storage Orchestrator

Rook Ceph provides distributed block, object, and file storage for Kubernetes clusters.

## Features

- **Distributed Storage**: Ceph-based storage across multiple nodes
- **Multiple Storage Types**: Block (RBD), Object (S3), and File (CephFS)
- **High Availability**: Data replication and fault tolerance
- **Dashboard**: Web-based management interface
- **CSI Integration**: Dynamic volume provisioning

## Configuration

### Basic Setup

```hcl
services = {
  rook_ceph = true
}

service_overrides = {
  rook_ceph = {
    enable_dashboard = true
    enable_ingress   = true
    limit_range_enabled = false  # Recommended: disable for flexible CSI resource allocation
  }
}
```

### CSI Resource Limits (Raspberry Pi)

```hcl
service_overrides = {
  rook_ceph = {
    rook_csi_provisioner_replicas         = 1
    rook_csi_rbd_provisioner_cpu_limit    = "200m"
    rook_csi_rbd_provisioner_memory_limit = "256Mi"
    rook_csi_rbd_plugin_cpu_limit         = "200m"
    rook_csi_rbd_plugin_memory_limit      = "512Mi"
  }
}
```

## Dashboard Access

After deployment, access the Ceph Dashboard at:
```
https://rook-ceph.{platform_name}.{base_domain}
```

Default credentials are stored in the `rook-ceph-dashboard-password` secret.

## ⚠️ Important: Cleanup Challenges

**Rook Ceph has complex cleanup requirements due to its distributed nature and finalizers.**

### Manual Cleanup Required

When destroying the Rook Ceph deployment, you may need to manually remove finalizers:

```bash
# Remove CephCluster finalizers
kubectl patch cephcluster rook-ceph -n prod-rook-ceph-system -p '{"metadata":{"finalizers":[]}}' --type=merge

# Remove finalizers from configmaps and secrets
kubectl get configmap -n prod-rook-ceph-system -o name | xargs -I {} kubectl patch {} -n prod-rook-ceph-system -p '{"metadata":{"finalizers":[]}}' --type=merge
kubectl get secret -n prod-rook-ceph-system -o name | xargs -I {} kubectl patch {} -n prod-rook-ceph-system -p '{"metadata":{"finalizers":[]}}' --type=merge

# Remove namespace finalizers
kubectl patch namespace prod-rook-ceph-system -p '{"metadata":{"finalizers":[]}}' --type=merge
```

### Why Cleanup is Complex

1. **Finalizers**: Rook uses Kubernetes finalizers (`ceph.rook.io/disaster-protection`) to prevent accidental data loss
2. **Distributed State**: Ceph maintains state across multiple nodes and resources
3. **CRD Dependencies**: CephCluster CRD has complex lifecycle management
4. **Terraform Limitations**: Destroy-time provisioners cannot reference variables or locals

### Recommended Approach

For production use, consider:
- **Longhorn**: Simpler distributed storage with easier cleanup
- **NFS-CSI**: Centralized storage without complex finalizers
- **Cloud Storage**: Native storage classes (EBS, GCE PD, Azure Disk)

Rook Ceph is best suited for:
- Environments where manual cleanup is acceptable
- Production clusters with dedicated storage teams
- Use cases requiring S3-compatible object storage

## Storage Path

Rook stores data at `/opt/rook/storage` on each node. Ensure this path has sufficient space.

## Requirements

- **Minimum 3 nodes** for production HA setup
- **Dedicated block devices** or directories for OSDs
- **4GB+ RAM** per node for Ceph components
- **Network connectivity** between all nodes

## Troubleshooting

### Pods Stuck in Pending

Check resource limits and node capacity:
```bash
kubectl describe pod -n prod-rook-ceph-system
```

### Dashboard Not Accessible

Verify ingress and certificate:
```bash
kubectl get ingressroute -n prod-rook-ceph-system
kubectl get certificate -n prod-rook-ceph-system
```

### Namespace Stuck in Terminating

Follow the manual cleanup steps above to remove finalizers.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.14 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 3.0 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | ~> 1.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_helm"></a> [helm](#provider\_helm) | 3.1.1 |
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | 1.19.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.38.0 |
| <a name="provider_null"></a> [null](#provider\_null) | 3.2.4 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | 4.2.1 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [helm_release.this](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubectl_manifest.ceph_cluster](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubernetes_daemonset.storage_prep](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/daemonset) | resource |
| [kubernetes_job.cleanup_stale_data](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/job) | resource |
| [kubernetes_limit_range.namespace_limits](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/limit_range) | resource |
| [kubernetes_manifest.dashboard_ingress](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_namespace.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_secret.dashboard_cert](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_service.ceph_mon_dns](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service) | resource |
| [null_resource.crds_deployed](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.force_namespace_cleanup](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.helm_cleanup](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.wait_for_cleanup](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [tls_private_key.dashboard](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [tls_self_signed_cert.dashboard](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/self_signed_cert) | resource |
| [kubernetes_namespace.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/namespace) | data source |
| [kubernetes_nodes.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/nodes) | data source |
| [kubernetes_service.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/service) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_ceph_image_version"></a> [ceph\_image\_version](#input\_ceph\_image\_version) | Ceph image version (must be compatible with Rook operator version). Rook v1.15.x supports Ceph v18.2.4 (reef), which is stable on ARM64. See: https://github.com/rook/rook/releases | `string` | `"v18.2.4"` | no |
| <a name="input_chart_name"></a> [chart\_name](#input\_chart\_name) | Helm chart name | `string` | `"rook-ceph"` | no |
| <a name="input_chart_repo"></a> [chart\_repo](#input\_chart\_repo) | Helm repository URL | `string` | `"https://charts.rook.io/release"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Helm chart version (use empty string for auto-detection based on architecture) | `string` | `""` | no |
| <a name="input_ci_mode"></a> [ci\_mode](#input\_ci\_mode) | Running in CI mode (kubeconfig handled externally) | `bool` | `false` | no |
| <a name="input_cleanup_cpu_limit"></a> [cleanup\_cpu\_limit](#input\_cleanup\_cpu\_limit) | CPU limit for cleanup Job containers | `string` | `"100m"` | no |
| <a name="input_cleanup_cpu_request"></a> [cleanup\_cpu\_request](#input\_cleanup\_cpu\_request) | CPU request for cleanup Job containers | `string` | `"50m"` | no |
| <a name="input_cleanup_image"></a> [cleanup\_image](#input\_cleanup\_image) | Container image used for cleanup and storage preparation jobs | `string` | `"busybox:latest"` | no |
| <a name="input_cleanup_memory_limit"></a> [cleanup\_memory\_limit](#input\_cleanup\_memory\_limit) | Memory limit for cleanup Job containers | `string` | `"64Mi"` | no |
| <a name="input_cleanup_memory_request"></a> [cleanup\_memory\_request](#input\_cleanup\_memory\_request) | Memory request for cleanup Job containers | `string` | `"32Mi"` | no |
| <a name="input_cleanup_stale_data_on_deploy"></a> [cleanup\_stale\_data\_on\_deploy](#input\_cleanup\_stale\_data\_on\_deploy) | Clean up stale Rook data on host paths before deployment (prevents keyring mismatch on redeployment) | `bool` | `true` | no |
| <a name="input_cleanup_timeout"></a> [cleanup\_timeout](#input\_cleanup\_timeout) | Timeout for namespace cleanup operations (e.g., 5m, 10m, 30s) | `string` | `"5m"` | no |
| <a name="input_cpu_arch"></a> [cpu\_arch](#input\_cpu\_arch) | CPU architecture | `string` | `"amd64"` | no |
| <a name="input_cpu_limit"></a> [cpu\_limit](#input\_cpu\_limit) | CPU limit for containers | `string` | `"500m"` | no |
| <a name="input_cpu_request"></a> [cpu\_request](#input\_cpu\_request) | CPU request for containers | `string` | `"250m"` | no |
| <a name="input_csi_kubelet_dir_path"></a> [csi\_kubelet\_dir\_path](#input\_csi\_kubelet\_dir\_path) | Kubelet directory path for CSI drivers (MicroK8s: /var/snap/microk8s/common/var/lib/kubelet, K3s: /var/lib/rancher/k3s/agent, Standard: /var/lib/kubelet) | `string` | `""` | no |
| <a name="input_dashboard_ssl"></a> [dashboard\_ssl](#input\_dashboard\_ssl) | Enable SSL for Ceph Dashboard | `bool` | `false` | no |
| <a name="input_disable_arch_scheduling"></a> [disable\_arch\_scheduling](#input\_disable\_arch\_scheduling) | Disable architecture-based node scheduling | `bool` | `false` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Domain name for ingress | `string` | `"local"` | no |
| <a name="input_enable_ceph_cluster"></a> [enable\_ceph\_cluster](#input\_enable\_ceph\_cluster) | Deploy CephCluster resource (creates actual Ceph storage cluster) | `bool` | `true` | no |
| <a name="input_enable_dashboard"></a> [enable\_dashboard](#input\_enable\_dashboard) | Enable Ceph Dashboard web interface | `bool` | `true` | no |
| <a name="input_enable_ingress"></a> [enable\_ingress](#input\_enable\_ingress) | Enable Traefik ingress for Ceph Dashboard | `bool` | `true` | no |
| <a name="input_force_namespace_cleanup"></a> [force\_namespace\_cleanup](#input\_force\_namespace\_cleanup) | Force cleanup of namespace and Rook-Ceph resources if deletion gets stuck (WARNING: Only use when namespace is stuck in Terminating phase) | `bool` | `false` | no |
| <a name="input_helm_cleanup_on_fail"></a> [helm\_cleanup\_on\_fail](#input\_helm\_cleanup\_on\_fail) | Cleanup resources on failure | `bool` | `true` | no |
| <a name="input_helm_disable_webhooks"></a> [helm\_disable\_webhooks](#input\_helm\_disable\_webhooks) | Disable webhooks for Helm release | `bool` | `false` | no |
| <a name="input_helm_force_update"></a> [helm\_force\_update](#input\_helm\_force\_update) | Force resource updates if needed | `bool` | `false` | no |
| <a name="input_helm_replace"></a> [helm\_replace](#input\_helm\_replace) | Allow Helm to replace existing resources | `bool` | `false` | no |
| <a name="input_helm_skip_crds"></a> [helm\_skip\_crds](#input\_helm\_skip\_crds) | Skip CRDs for Helm release | `bool` | `false` | no |
| <a name="input_helm_timeout"></a> [helm\_timeout](#input\_helm\_timeout) | Timeout for Helm deployment in seconds | `number` | `600` | no |
| <a name="input_helm_wait"></a> [helm\_wait](#input\_helm\_wait) | Wait for Helm release to be ready | `bool` | `true` | no |
| <a name="input_helm_wait_for_jobs"></a> [helm\_wait\_for\_jobs](#input\_helm\_wait\_for\_jobs) | Wait for Helm jobs to complete | `bool` | `true` | no |
| <a name="input_kubeconfig_path"></a> [kubeconfig\_path](#input\_kubeconfig\_path) | Explicit kubeconfig path (overrides automatic detection). Leave empty to use workspace-based or default kubeconfig. | `string` | `""` | no |
| <a name="input_limit_range_container_max_cpu"></a> [limit\_range\_container\_max\_cpu](#input\_limit\_range\_container\_max\_cpu) | Maximum CPU limit for containers | `string` | `null` | no |
| <a name="input_limit_range_container_max_memory"></a> [limit\_range\_container\_max\_memory](#input\_limit\_range\_container\_max\_memory) | Maximum memory limit for containers | `string` | `null` | no |
| <a name="input_limit_range_enabled"></a> [limit\_range\_enabled](#input\_limit\_range\_enabled) | Enable limit range for namespace | `bool` | `true` | no |
| <a name="input_limit_range_pvc_max_storage"></a> [limit\_range\_pvc\_max\_storage](#input\_limit\_range\_pvc\_max\_storage) | Maximum storage size for PVCs | `string` | `"100Gi"` | no |
| <a name="input_limit_range_pvc_min_storage"></a> [limit\_range\_pvc\_min\_storage](#input\_limit\_range\_pvc\_min\_storage) | Minimum storage size for PVCs | `string` | `"1Gi"` | no |
| <a name="input_memory_limit"></a> [memory\_limit](#input\_memory\_limit) | Memory limit for containers | `string` | `"512Mi"` | no |
| <a name="input_memory_request"></a> [memory\_request](#input\_memory\_request) | Memory request for containers | `string` | `"256Mi"` | no |
| <a name="input_monitor_count"></a> [monitor\_count](#input\_monitor\_count) | Number of Ceph monitors (must be odd number, typically 1, 3, or 5). For initial bootstrap, use 1, then scale up to 3 or 5 for high availability. | `number` | `3` | no |
| <a name="input_name"></a> [name](#input\_name) | Helm release name | `string` | `"rook-ceph"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace for Rook Ceph | `string` | `"rook-ceph"` | no |
| <a name="input_osd_data_size"></a> [osd\_data\_size](#input\_osd\_data\_size) | Storage size for each OSD PVC. Adjust based on available storage. For Raspberry Pi with SD cards, 5-10Gi recommended. For USB/NVMe storage, can be larger. | `string` | `"10Gi"` | no |
| <a name="input_osd_per_node"></a> [osd\_per\_node](#input\_osd\_per\_node) | Number of OSDs to create per node (total OSDs = osd\_per\_node × number of nodes). For Raspberry Pi clusters, 1 OSD per node recommended due to resource constraints. | `number` | `1` | no |
| <a name="input_osd_storage_subdir"></a> [osd\_storage\_subdir](#input\_osd\_storage\_subdir) | Subdirectory within storage\_prep\_host\_path for OSD data (relative path) | `string` | `"rook-storage"` | no |
| <a name="input_rook_csi_provisioner_replicas"></a> [rook\_csi\_provisioner\_replicas](#input\_rook\_csi\_provisioner\_replicas) | Number of CSI provisioner replicas | `number` | `1` | no |
| <a name="input_rook_csi_rbd_plugin_cpu_limit"></a> [rook\_csi\_rbd\_plugin\_cpu\_limit](#input\_rook\_csi\_rbd\_plugin\_cpu\_limit) | CPU limit for RBD plugin | `string` | `"200m"` | no |
| <a name="input_rook_csi_rbd_plugin_memory_limit"></a> [rook\_csi\_rbd\_plugin\_memory\_limit](#input\_rook\_csi\_rbd\_plugin\_memory\_limit) | Memory limit for RBD plugin | `string` | `"512Mi"` | no |
| <a name="input_rook_csi_rbd_provisioner_cpu_limit"></a> [rook\_csi\_rbd\_provisioner\_cpu\_limit](#input\_rook\_csi\_rbd\_provisioner\_cpu\_limit) | CPU limit for RBD provisioner | `string` | `"200m"` | no |
| <a name="input_rook_csi_rbd_provisioner_memory_limit"></a> [rook\_csi\_rbd\_provisioner\_memory\_limit](#input\_rook\_csi\_rbd\_provisioner\_memory\_limit) | Memory limit for RBD provisioner | `string` | `"256Mi"` | no |
| <a name="input_rook_data_dir_host_path"></a> [rook\_data\_dir\_host\_path](#input\_rook\_data\_dir\_host\_path) | Directory on host where Rook stores data (mon, OSD, etc.) | `string` | `"/opt/rook"` | no |
| <a name="input_service_overrides"></a> [service\_overrides](#input\_service\_overrides) | Fine-grained service configuration overrides (highest priority) | <pre>object({<br/>    # Basic configuration<br/>    name               = optional(string)<br/>    namespace          = optional(string)<br/>    chart_version      = optional(string)<br/>    ceph_image_version = optional(string)<br/><br/>    # Resource configuration<br/>    cpu_limit      = optional(string)<br/>    memory_limit   = optional(string)<br/>    cpu_request    = optional(string)<br/>    memory_request = optional(string)<br/><br/>    # Feature toggles<br/>    enable_ceph_cluster = optional(bool)<br/>    enable_dashboard    = optional(bool)<br/>    enable_ingress      = optional(bool)<br/>    dashboard_ssl       = optional(bool)<br/>    limit_range_enabled = optional(bool)<br/><br/>    # Ceph configuration<br/>    monitor_count        = optional(number)<br/>    csi_kubelet_dir_path = optional(string)<br/><br/>    # CSI configuration<br/>    csi = optional(object({<br/>      provisioner_replicas         = optional(number)<br/>      rbd_provisioner_cpu_limit    = optional(string)<br/>      rbd_provisioner_memory_limit = optional(string)<br/>      rbd_plugin_cpu_limit         = optional(string)<br/>      rbd_plugin_memory_limit      = optional(string)<br/>    }))<br/><br/>    # Ingress configuration<br/>    domain_name           = optional(string)<br/>    traefik_cert_resolver = optional(string)<br/><br/>    # Helm configuration<br/>    helm_timeout = optional(number)<br/><br/>    # Cleanup configuration<br/>    cleanup_stale_data_on_deploy = optional(bool)<br/>    force_namespace_cleanup      = optional(bool)<br/>    cleanup_timeout              = optional(string)<br/>  })</pre> | `{}` | no |
| <a name="input_storage_class_name"></a> [storage\_class\_name](#input\_storage\_class\_name) | StorageClass for OSD PVCs (must support block mode). Use 'hostpath' for local storage, 'nfs-csi-fast' for network storage (not recommended for production OSDs). | `string` | `"hostpath"` | no |
| <a name="input_storage_prep_cpu_limit"></a> [storage\_prep\_cpu\_limit](#input\_storage\_prep\_cpu\_limit) | CPU limit for storage preparation DaemonSet containers | `string` | `"100m"` | no |
| <a name="input_storage_prep_cpu_request"></a> [storage\_prep\_cpu\_request](#input\_storage\_prep\_cpu\_request) | CPU request for storage preparation DaemonSet containers | `string` | `"50m"` | no |
| <a name="input_storage_prep_host_path"></a> [storage\_prep\_host\_path](#input\_storage\_prep\_host\_path) | Base host path for local storage provisioner (where OSD PVCs will be created) | `string` | `"/opt/local-path-provisioner"` | no |
| <a name="input_storage_prep_memory_limit"></a> [storage\_prep\_memory\_limit](#input\_storage\_prep\_memory\_limit) | Memory limit for storage preparation DaemonSet containers | `string` | `"64Mi"` | no |
| <a name="input_storage_prep_memory_request"></a> [storage\_prep\_memory\_request](#input\_storage\_prep\_memory\_request) | Memory request for storage preparation DaemonSet containers | `string` | `"32Mi"` | no |
| <a name="input_traefik_cert_resolver"></a> [traefik\_cert\_resolver](#input\_traefik\_cert\_resolver) | Traefik certificate resolver | `string` | `"default"` | no |
| <a name="input_traefik_ingress_config"></a> [traefik\_ingress\_config](#input\_traefik\_ingress\_config) | Traefik ingress configuration | `any` | `null` | no |
| <a name="input_workspace_prefix"></a> [workspace\_prefix](#input\_workspace\_prefix) | Workspace prefix for kubeconfig file selection (e.g., 'prod', 'sit', 'dev'). Matches main provider.tf logic. | `string` | `""` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_ceph_cluster_enabled"></a> [ceph\_cluster\_enabled](#output\_ceph\_cluster\_enabled) | Whether CephCluster resource is deployed |
| <a name="output_ceph_image_version"></a> [ceph\_image\_version](#output\_ceph\_image\_version) | Ceph image version in use |
| <a name="output_chart_version"></a> [chart\_version](#output\_chart\_version) | Deployed chart version |
| <a name="output_csi_kubelet_dir_path"></a> [csi\_kubelet\_dir\_path](#output\_csi\_kubelet\_dir\_path) | CSI kubelet directory path configured |
| <a name="output_dashboard_secret_name"></a> [dashboard\_secret\_name](#output\_dashboard\_secret\_name) | Name of Kubernetes secret containing dashboard password (when dashboard is enabled) |
| <a name="output_dashboard_secret_namespace"></a> [dashboard\_secret\_namespace](#output\_dashboard\_secret\_namespace) | Namespace containing the dashboard password secret |
| <a name="output_dashboard_url"></a> [dashboard\_url](#output\_dashboard\_url) | Ceph Dashboard URL (when dashboard and ingress are enabled) |
| <a name="output_health_check_command"></a> [health\_check\_command](#output\_health\_check\_command) | Command to check Ceph cluster health status |
| <a name="output_helm_release_name"></a> [helm\_release\_name](#output\_helm\_release\_name) | Name of the Helm release |
| <a name="output_helm_release_status"></a> [helm\_release\_status](#output\_helm\_release\_status) | Status of the Helm release |
| <a name="output_monitor_count"></a> [monitor\_count](#output\_monitor\_count) | Number of Ceph monitors configured |
| <a name="output_namespace"></a> [namespace](#output\_namespace) | Namespace where Rook Ceph is deployed |
| <a name="output_service_host"></a> [service\_host](#output\_service\_host) | Rook-Ceph service hostname for service discovery (format: name.namespace.svc.cluster.local) |
| <a name="output_storage_class_cephfs"></a> [storage\_class\_cephfs](#output\_storage\_class\_cephfs) | CephFS (file) storage class name (when CephCluster is enabled) |
| <a name="output_storage_class_rbd"></a> [storage\_class\_rbd](#output\_storage\_class\_rbd) | RBD (block) storage class name (when CephCluster is enabled) |
| <a name="output_storage_classes"></a> [storage\_classes](#output\_storage\_classes) | Map of available storage classes (when CephCluster is enabled) |
| <a name="output_toolbox_command"></a> [toolbox\_command](#output\_toolbox\_command) | Command to run the Ceph toolbox for advanced diagnostics |
<!-- END_TF_DOCS -->
