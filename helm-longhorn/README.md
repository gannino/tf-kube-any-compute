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

## Destroying Longhorn

### Automated Destroy

The module includes **fully automated cleanup** - no manual intervention required!

Simply run:

```bash
terraform destroy -target=module.longhorn
```

### How It Works

The module uses a **clever dependency chain** to ensure Helm release metadata is deleted BEFORE Helm uninstall attempts to run:

```hcl
# Terraform dependency chain (create order):
1. helmRelease (created first)
2. helmReleaseRemover (depends on helmRelease via triggers)
3. cleanup (depends on helmReleaseRemover)
4. forceNamespaceCleanup (depends on cleanup)

# Terraform destroy order (REVERSE of create):
1. forceNamespaceCleanup (destroyed first)
2. cleanup
3. helmReleaseRemover ← Destroys webhooks & Helm metadata HERE
4. helmRelease ← Finds metadata gone, skips uninstall
```

**The key insight**: `helmReleaseRemover` references `helmRelease` outputs in its triggers, creating an implicit dependency. This causes `helmReleaseRemover` to be destroyed BEFORE `helmRelease`.

### What Actually Happens During Destroy

```
1. forceNamespaceCleanup.destroy provisioner runs
   → Force cleanup if namespace is stuck

2. cleanup.destroy provisioner runs
   → Deletes any remaining workloads and custom resources

3. helmReleaseRemover.destroy provisioner runs (CRITICAL)
   → Deletes admission webhooks (longhorn-webhook-*)
   → Deletes Helm release metadata (secrets/configmaps)
   → Helm release is now "gone" from Kubernetes

4. helmRelease resource destruction
   → Terraform tries to uninstall
   → Finds release metadata already deleted
   → Skips uninstall, marks resource destroyed
   → No timeout, no error!
```

### Critical Configuration

Two settings make this work:

1. **`helm_disable_webhooks = true`** (default)
   - Prevents Helm from running post-delete hooks
   - The longhorn-uninstall job won't execute

2. **Dependency-based destroy ordering**
   - `helmReleaseRemover` triggers reference `helmRelease` outputs
   - This creates implicit dependency: helmRelease → helmReleaseRemover
   - Destroy order is REVERSED: helmReleaseRemover → helmRelease

### What Gets Cleaned Up

The automated cleanup removes **ALL** Longhorn resources:

- ✅ **Webhooks** - Deleted by helmReleaseRemover before Helm uninstall
- ✅ **Helm metadata** - Deleted to skip problematic uninstall
- ✅ **Workloads** - Deployments, daemonsets, statefulsets, pods
- ✅ **Custom Resources** - Volumes, engines, replicas, nodes, settings, etc.
- ✅ **CSI Driver** - Longhorn CSI driver
- ✅ **Storage Classes** - Longhorn and longhorn-static
- ✅ **CRDs** - All Longhorn CRDs
- ✅ **Namespace** - Longhorn namespace

### No Leftovers!

**Important:** Because we skip the Helm uninstall job, our cleanup scripts must do **all the cleanup work** that the uninstall job would have done. The `cleanup` resource handles this comprehensively:

1. Removes finalizers from all custom resources (prevents stuck resources)
2. Deletes workloads (pods, deployments, etc.)
3. Deletes all custom resource types
4. Deletes CRDs (removes webhook configuration from API server)
5. Deletes storage classes
6. Deletes any remaining webhooks

This ensures **complete cleanup** with no leftovers on the cluster!

### Troubleshooting

**Expected Destroy Behavior**:
- Destroy may take **10-15 minutes** to complete (normal Helm timeout)
- You may see Helm uninstall timeout errors - this is expected and OK
- All resources ARE being cleaned up by automated scripts BEFORE Helm uninstall
- Terraform will complete successfully despite timeout errors

**If destroy appears completely stuck**:

1. **Wait for the timeout** - The Helm uninstall will timeout after 10 minutes (default `helm_timeout`), then Terraform will complete

2. **Check for stuck resources:**

   ```bash
   kubectl get namespace prod-longhorn-system
   kubectl get crd | grep longhorn
   ```

3. **Force cleanup (if needed):**

   ```bash
   # Enable force cleanup in terraform.tfvars
   force_namespace_cleanup = true

   # Then run destroy again
   terraform destroy -target=module.longhorn
   ```

4. **Manual cleanup (last resort):**

   ```bash
   # Run the comprehensive cleanup script
   ./scripts/cleanup-longhorn.sh
   ```

5. **Remove stuck Helm release from state:**

   ```bash
   # If Helm destroy is completely stuck after timeout
   terraform state rm 'module.longhorn[0].helm_release.this'
   terraform destroy -target=module.longhorn
   ```

### Why This Approach?

**Problem:** Longhorn's Helm uninstall fails because:
- Admission webhooks block resource deletion during uninstall
- Resources with finalizers take a long time to terminate
- The uninstall process hangs waiting for cleanup
- Terraform can't run cleanup code before Helm uninstall begins

**Solution:** Comprehensive cleanup with dependency ordering:
- `cleanup` script runs FIRST - deletes all workloads, CRDs, webhooks
- `helm_release_remover` runs SECOND - deletes Helm metadata
- `helm_release` destroy runs LAST - tries to uninstall (may timeout, but resources are already gone)
- `ignore_changes = [status]` allows Terraform to complete despite Helm status errors

**Result:** Automated destroy that completes successfully. The cleanup scripts do all the work, and Helm uninstall timeout is acceptable since everything is already deleted.

**Solution:** Use a destroy provisioner on the helm_release resource:
- Runs immediately when helm_release starts destroying
- Deletes admission webhooks BEFORE Helm uninstall
- Combined with `disable_webhooks=true`, prevents post-delete hooks
- Helm uninstall completes without blocking

**Result:** Automated destroy with no manual intervention and no leftovers!

   ```bash
   # Enable force cleanup in terraform.tfvars
   force_namespace_cleanup = true

   # Then run destroy again
   terraform destroy -target=module.longhorn
   ```

3. **Manual cleanup (last resort):**

   ```bash
   # Run the manual cleanup script
   ./scripts/cleanup-longhorn.sh
   ```

### Why This Approach?

Longhorn's Helm chart includes a post-delete hook (`longhorn-uninstall` job) that
can fail if admission webhooks are still present. Our pre-destroy cleanup removes
these webhooks BEFORE Helm uninstall starts, ensuring the uninstall job can
complete successfully.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.14 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 3.0 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | ~> 1.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.20 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.0 |
| <a name="requirement_time"></a> [time](#requirement\_time) | ~> 0.9 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_helm"></a> [helm](#provider\_helm) | 3.1.1 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.38.0 |
| <a name="provider_null"></a> [null](#provider\_null) | 3.2.4 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [helm_release.this](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_manifest.dashboard_ingress](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_namespace.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [null_resource.cleanup](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.cleanup_crds](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.crds_deployed](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.force_namespace_cleanup](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.helm_release_remover](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [kubernetes_service.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/service) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_backup_credential_secret"></a> [backup\_credential\_secret](#input\_backup\_credential\_secret) | Kubernetes secret name for backup target credentials (S3/MinIO access keys) | `string` | `""` | no |
| <a name="input_backup_target"></a> [backup\_target](#input\_backup\_target) | Longhorn backup target URL (e.g., 'nfs://server:/path' or 's3://bucket@region/') | `string` | `""` | no |
| <a name="input_chart_name"></a> [chart\_name](#input\_chart\_name) | Helm chart name | `string` | `"longhorn"` | no |
| <a name="input_chart_repo"></a> [chart\_repo](#input\_chart\_repo) | Helm repository URL | `string` | `"https://charts.longhorn.io"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Helm chart version | `string` | `"1.11.0"` | no |
| <a name="input_ci_mode"></a> [ci\_mode](#input\_ci\_mode) | Running in CI mode (kubeconfig handled externally) | `bool` | `false` | no |
| <a name="input_cleanup_timeout"></a> [cleanup\_timeout](#input\_cleanup\_timeout) | Timeout for namespace cleanup operations (e.g., 5m, 10m, 30s) | `string` | `"5m"` | no |
| <a name="input_cpu_arch"></a> [cpu\_arch](#input\_cpu\_arch) | CPU architecture | `string` | `"amd64"` | no |
| <a name="input_cpu_limit"></a> [cpu\_limit](#input\_cpu\_limit) | CPU limit | `string` | `"500m"` | no |
| <a name="input_cpu_request"></a> [cpu\_request](#input\_cpu\_request) | CPU request | `string` | `"250m"` | no |
| <a name="input_default_data_path"></a> [default\_data\_path](#input\_default\_data\_path) | Default path for Longhorn data storage on nodes | `string` | `"/opt/longhorn"` | no |
| <a name="input_disable_arch_scheduling"></a> [disable\_arch\_scheduling](#input\_disable\_arch\_scheduling) | Disable architecture-based node scheduling | `bool` | `false` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Domain name for ingress | `string` | `"local"` | no |
| <a name="input_enable_dashboard"></a> [enable\_dashboard](#input\_enable\_dashboard) | Enable Longhorn Dashboard web interface | `bool` | `true` | no |
| <a name="input_enable_ingress"></a> [enable\_ingress](#input\_enable\_ingress) | Enable Traefik ingress for Longhorn Dashboard | `bool` | `true` | no |
| <a name="input_force_namespace_cleanup"></a> [force\_namespace\_cleanup](#input\_force\_namespace\_cleanup) | Force cleanup of namespace and Longhorn resources if deletion gets stuck (WARNING: Only use when namespace is stuck in Terminating phase) | `bool` | `false` | no |
| <a name="input_helm_cleanup_on_fail"></a> [helm\_cleanup\_on\_fail](#input\_helm\_cleanup\_on\_fail) | Cleanup resources on failure | `bool` | `true` | no |
| <a name="input_helm_disable_webhooks"></a> [helm\_disable\_webhooks](#input\_helm\_disable\_webhooks) | Disable webhooks for Helm release (required to prevent uninstall blocking by admission webhooks) | `bool` | `true` | no |
| <a name="input_helm_force_update"></a> [helm\_force\_update](#input\_helm\_force\_update) | Force resource updates if needed | `bool` | `false` | no |
| <a name="input_helm_replace"></a> [helm\_replace](#input\_helm\_replace) | Allow Helm to replace existing resources | `bool` | `false` | no |
| <a name="input_helm_skip_crds"></a> [helm\_skip\_crds](#input\_helm\_skip\_crds) | Skip CRDs for Helm release | `bool` | `false` | no |
| <a name="input_helm_timeout"></a> [helm\_timeout](#input\_helm\_timeout) | Timeout for Helm deployment in seconds | `number` | `600` | no |
| <a name="input_helm_wait"></a> [helm\_wait](#input\_helm\_wait) | Wait for Helm release to be ready | `bool` | `true` | no |
| <a name="input_helm_wait_for_jobs"></a> [helm\_wait\_for\_jobs](#input\_helm\_wait\_for\_jobs) | Wait for Helm jobs to complete | `bool` | `true` | no |
| <a name="input_k8s_distribution"></a> [k8s\_distribution](#input\_k8s\_distribution) | Kubernetes distribution (k3s, microk8s, kubernetes, etc.) | `string` | `"microk8s"` | no |
| <a name="input_kubeconfig_path"></a> [kubeconfig\_path](#input\_kubeconfig\_path) | Explicit kubeconfig path (overrides automatic detection). Leave empty to use workspace-based or default kubeconfig. | `string` | `""` | no |
| <a name="input_kubelet_root_dir"></a> [kubelet\_root\_dir](#input\_kubelet\_root\_dir) | Kubelet root directory path (auto-detected based on k8s\_distribution if empty) | `string` | `""` | no |
| <a name="input_memory_limit"></a> [memory\_limit](#input\_memory\_limit) | Memory limit | `string` | `"512Mi"` | no |
| <a name="input_memory_request"></a> [memory\_request](#input\_memory\_request) | Memory request | `string` | `"256Mi"` | no |
| <a name="input_name"></a> [name](#input\_name) | Helm release name | `string` | `"longhorn"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Kubernetes namespace | `string` | `"longhorn-system"` | no |
| <a name="input_replica_count"></a> [replica\_count](#input\_replica\_count) | Number of replicas for volumes | `number` | `3` | no |
| <a name="input_set_as_default_storage_class"></a> [set\_as\_default\_storage\_class](#input\_set\_as\_default\_storage\_class) | Set Longhorn as the default storage class | `bool` | `false` | no |
| <a name="input_traefik_cert_resolver"></a> [traefik\_cert\_resolver](#input\_traefik\_cert\_resolver) | Traefik certificate resolver | `string` | `"default"` | no |
| <a name="input_traefik_ingress_config"></a> [traefik\_ingress\_config](#input\_traefik\_ingress\_config) | Traefik ingress configuration | `any` | `null` | no |
| <a name="input_workspace_prefix"></a> [workspace\_prefix](#input\_workspace\_prefix) | Workspace prefix for kubeconfig file selection (e.g., 'prod', 'sit', 'dev'). Matches main provider.tf logic. | `string` | `""` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_backup_target"></a> [backup\_target](#output\_backup\_target) | Backup target URL configured for Longhorn |
| <a name="output_backup_target_info"></a> [backup\_target\_info](#output\_backup\_target\_info) | Backup target information (Helm creates BackupTarget CRD named 'default' when backup\_target is configured) |
| <a name="output_helm_release_name"></a> [helm\_release\_name](#output\_helm\_release\_name) | Name of the Helm release |
| <a name="output_helm_release_status"></a> [helm\_release\_status](#output\_helm\_release\_status) | Status of the Helm release |
| <a name="output_namespace"></a> [namespace](#output\_namespace) | Namespace where Longhorn is deployed |
| <a name="output_service_host"></a> [service\_host](#output\_service\_host) | Longhorn service hostname for service discovery (format: name.namespace.svc.cluster.local) |
| <a name="output_storage_class_name"></a> [storage\_class\_name](#output\_storage\_class\_name) | Name of the Longhorn storage class |
<!-- END_TF_DOCS -->
