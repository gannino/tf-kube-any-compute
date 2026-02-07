# KubeVirt Helm Module

This module deploys KubeVirt, a virtual machine management add-on for Kubernetes, enabling you to run and manage virtual machines alongside containers.

## Features

- **Virtual Machine Management**: Run VMs on Kubernetes with full lifecycle management
- **Multi-Architecture Support**: Works on AMD64 and ARM64 (with emulation)
- **Software Emulation**: Enable nested virtualization for development/testing
- **Prometheus Integration**: Optional ServiceMonitor for metrics collection
- **Resource Management**: Configurable CPU and memory limits
- **Security**: Non-root execution with seccomp profiles

## Prerequisites

- Kubernetes cluster with hardware virtualization support (or software emulation)
- Helm 3.x
- For hardware acceleration: CPU with Intel VT-x or AMD-V support

## Usage

```hcl
module "kubevirt" {
  source = "./helm-kubevirt"

  namespace     = "kubevirt"
  name          = "kubevirt"
  chart_version = "0.2.4"

  cpu_arch         = "amd64"
  enable_emulation = true  # Enable for ARM64 or nested virtualization

  cpu_limit      = "1000m"
  memory_limit   = "1Gi"
  cpu_request    = "500m"
  memory_request = "512Mi"

  enable_servicemonitor = true  # Enable Prometheus monitoring

  # Enable automatic cleanup during destroy
  force_namespace_cleanup = true
  cleanup_timeout        = "15m"

  # Kubeconfig configuration (matches main provider.tf logic)
  workspace_prefix  = "prod"   # For prod-config kubeconfig
  ci_mode         = false     # Set to true in CI environments
  kubeconfig_path = ""        # Explicit path if needed
}
```

## Architecture Support

### AMD64 (x86_64)
- Full hardware virtualization support
- Best performance with Intel VT-x or AMD-V

### ARM64
- Software emulation enabled by default
- Suitable for development and testing
- Lower performance than hardware virtualization

## Virtual Machine Examples

### Basic VM
```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: testvm
spec:
  running: false
  template:
    metadata:
      labels:
        kubevirt.io/vm: testvm
    spec:
      domain:
        devices:
          disks:
          - name: containerdisk
            disk:
              bus: virtio
          - name: cloudinitdisk
            disk:
              bus: virtio
        resources:
          requests:
            memory: 1024M
      volumes:
      - name: containerdisk
        containerDisk:
          image: quay.io/kubevirt/cirros-container-disk-demo
      - name: cloudinitdisk
        cloudInitNoCloud:
          userDataBase64: SGkuXG4=
```

## Monitoring

When `enable_servicemonitor = true`, KubeVirt metrics are automatically scraped by Prometheus:

- VM resource usage
- VM lifecycle events
- Virtualization performance metrics
- API server metrics

## Troubleshooting

### Check KubeVirt Status
```bash
kubectl get kubevirt -n kubevirt
kubectl get pods -n kubevirt
```

### Verify Hardware Virtualization
```bash
# On cluster nodes
egrep -c '(vmx|svm)' /proc/cpuinfo
# Non-zero output indicates hardware virtualization support
```

### Enable Software Emulation
If hardware virtualization is not available, ensure `enable_emulation = true` in your configuration.

### Namespace Cleanup Issues

KubeVirt can sometimes leave namespaces stuck in "Terminating" state during `terraform destroy`. To prevent this, enable automatic cleanup:

```hcl
module "kubevirt" {
  # ... other configuration ...

  force_namespace_cleanup = true
  cleanup_timeout        = "15m"
}
```

**Manual Cleanup of Stuck Namespace**

If a namespace is stuck in "Terminating" state, manually clean it up:

```bash
# Delete all VM resources
kubectl delete vm --all -n kubevirt --timeout=30s
kubectl delete vmi --all -n kubevirt --timeout=30s

# Delete KubeVirt custom resources
kubectl delete kubevirt kubevirt -n kubevirt --timeout=60s

# Delete stale API services
kubectl delete apiservice v1alpha3.subresources.kubevirt.io --timeout=30s
kubectl delete apiservice v1.subresources.kubevirt.io --timeout=30s

# Delete KubeVirt CRDs
kubectl get crd -o json | jq '.items[] | select(.metadata.name | contains("kubevirt.io")) | .metadata.name' | \
  xargs -I {} kubectl delete crd {} --timeout=30s

# Force remove namespace finalizers
kubectl get namespace kubevirt -o json | \
  jq 'del(.spec.finalizers)' | \
  kubectl replace --raw "/api/v1/namespaces/kubevirt/finalize" -f -
```

**Kubeconfig Configuration**

The cleanup feature requires proper kubeconfig configuration. It follows the same logic as the main `provider.tf`:

```hcl
# Automatic workspace-based detection (recommended)
workspace_prefix = "prod"  # Uses ~/.kube/prod-config

# CI/CD environments
ci_mode = true  # Uses KUBECONFIG environment variable

# Explicit path (overrides automatic detection)
kubeconfig_path = "/custom/path/to/kubeconfig"
```

**Cleanup Timeout**

Adjust the cleanup timeout based on your environment:

```hcl
cleanup_timeout = "5m"   # Fast cleanup for small clusters
cleanup_timeout = "15m"  # Default for most environments
cleanup_timeout = "30m"  # Large clusters or slow networks
```

## Resources

- [KubeVirt Documentation](https://kubevirt.io/user-guide/)
- [KubeVirt GitHub](https://github.com/kubevirt/kubevirt)
- [Virtual Machine Examples](https://kubevirt.io/user-guide/virtual_machines/virtual_machine_instances/)

<!-- BEGIN_TF_DOCS -->


## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.14 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | ~> 1.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | 1.19.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.38.0 |
| <a name="provider_null"></a> [null](#provider\_null) | 3.2.4 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [kubectl_manifest.kubevirt_cr](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.kubevirt_crd](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.kubevirt_priorityclass](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.kubevirt_rbac](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.kubevirt_servicemonitor](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.kubevirt_operator](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_namespace.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [null_resource.force_namespace_cleanup](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_chart_name"></a> [chart\_name](#input\_chart\_name) | Helm chart name | `string` | `"kubevirt"` | no |
| <a name="input_chart_repo"></a> [chart\_repo](#input\_chart\_repo) | Deprecated - KubeVirt uses operator manifests | `string` | `""` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | KubeVirt version | `string` | `"v1.1.1"` | no |
| <a name="input_ci_mode"></a> [ci\_mode](#input\_ci\_mode) | Running in CI mode (kubeconfig handled externally) | `bool` | `false` | no |
| <a name="input_cleanup_timeout"></a> [cleanup\_timeout](#input\_cleanup\_timeout) | Timeout for namespace cleanup operations (e.g., 5m, 10m, 30s) | `string` | `"15m"` | no |
| <a name="input_cpu_arch"></a> [cpu\_arch](#input\_cpu\_arch) | CPU architecture for node selection | `string` | `"amd64"` | no |
| <a name="input_cpu_limit"></a> [cpu\_limit](#input\_cpu\_limit) | CPU limit for KubeVirt containers | `string` | `"1000m"` | no |
| <a name="input_cpu_request"></a> [cpu\_request](#input\_cpu\_request) | CPU request for KubeVirt containers | `string` | `"500m"` | no |
| <a name="input_disable_arch_scheduling"></a> [disable\_arch\_scheduling](#input\_disable\_arch\_scheduling) | Disable architecture-based node scheduling | `bool` | `false` | no |
| <a name="input_enable_emulation"></a> [enable\_emulation](#input\_enable\_emulation) | Enable software emulation for nested virtualization | `bool` | `true` | no |
| <a name="input_enable_servicemonitor"></a> [enable\_servicemonitor](#input\_enable\_servicemonitor) | Enable ServiceMonitor for Prometheus metrics collection | `bool` | `false` | no |
| <a name="input_force_namespace_cleanup"></a> [force\_namespace\_cleanup](#input\_force\_namespace\_cleanup) | Force cleanup of namespace and KubeVirt resources if deletion gets stuck (WARNING: Only use when namespace is stuck in Terminating phase) | `bool` | `false` | no |
| <a name="input_kubeconfig_path"></a> [kubeconfig\_path](#input\_kubeconfig\_path) | Explicit kubeconfig path (overrides automatic detection). Leave empty to use workspace-based or default kubeconfig. | `string` | `""` | no |
| <a name="input_memory_limit"></a> [memory\_limit](#input\_memory\_limit) | Memory limit for KubeVirt containers | `string` | `"1Gi"` | no |
| <a name="input_memory_request"></a> [memory\_request](#input\_memory\_request) | Memory request for KubeVirt containers | `string` | `"512Mi"` | no |
| <a name="input_name"></a> [name](#input\_name) | Helm release name for KubeVirt | `string` | `"kubevirt"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Kubernetes namespace for KubeVirt deployment | `string` | `"kubevirt"` | no |
| <a name="input_workspace_prefix"></a> [workspace\_prefix](#input\_workspace\_prefix) | Workspace prefix for kubeconfig file selection (e.g., 'prod', 'sit', 'dev'). Matches main provider.tf logic. | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_namespace"></a> [namespace](#output\_namespace) | KubeVirt namespace |
| <a name="output_status"></a> [status](#output\_status) | KubeVirt deployment status |

<!-- END_TF_DOCS -->
