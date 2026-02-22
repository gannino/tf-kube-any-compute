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
- **Host OS Requirements**: KVM/QEMU packages must be installed on cluster nodes
- **CDI (Containerized Data Importer)**: Automatically installed for DataVolume support
- **virtctl CLI** (optional): Command-line tool for VM management

### Installing KVM/QEMU on Cluster Nodes

**Ubuntu/Debian:**
```bash
# Install KVM/QEMU stack
sudo apt update
sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients

# Verify KVM is accessible
ls -la /dev/kvm

# Check virtualization support
egrep -c '(vmx|svm)' /proc/cpuinfo
# Non-zero output indicates hardware virtualization support
```

**RHEL/CentOS/Fedora:**
```bash
# Install KVM/QEMU stack
sudo dnf install -y qemu-kvm libvirt virt-install

# Verify KVM is accessible
ls -la /dev/kvm
```

> **Note**: ARM64 nodes (like Raspberry Pi) do not support KVM hardware virtualization. KubeVirt will not work on ARM64 without hardware virtualization extensions.

### Installing virtctl CLI

**virtctl** is the command-line tool for managing KubeVirt virtual machines.

**Linux AMD64:**
```bash
# Download latest virtctl
VERSION=$(curl -s https://api.github.com/repos/kubevirt/kubevirt/releases/latest | grep tag_name | cut -d '"' -f 4)
wget https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/virtctl-${VERSION}-linux-amd64

# Make it executable and move to PATH
chmod +x virtctl-${VERSION}-linux-amd64
sudo mv virtctl-${VERSION}-linux-amd64 /usr/local/bin/virtctl

# Verify installation
virtctl version
```

**Linux ARM64:**
```bash
# Download latest virtctl for ARM64
VERSION=$(curl -s https://api.github.com/repos/kubevirt/kubevirt/releases/latest | grep tag_name | cut -d '"' -f 4)
wget https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/virtctl-${VERSION}-linux-arm64

# Make it executable and move to PATH
chmod +x virtctl-${VERSION}-linux-arm64
sudo mv virtctl-${VERSION}-linux-arm64 /usr/local/bin/virtctl

# Verify installation
virtctl version
```

**macOS:**
```bash
# Download latest virtctl for macOS
VERSION=$(curl -s https://api.github.com/repos/kubevirt/kubevirt/releases/latest | grep tag_name | cut -d '"' -f 4)
wget https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/virtctl-${VERSION}-darwin-amd64

# Make it executable and move to PATH
chmod +x virtctl-${VERSION}-darwin-amd64
sudo mv virtctl-${VERSION}-darwin-amd64 /usr/local/bin/virtctl

# Verify installation
virtctl version
```

**Common virtctl commands:**
```bash
# Start a VM
virtctl start <vm-name>

# Stop a VM
virtctl stop <vm-name>

# Access VM console
virtctl console <vm-name>

# SSH into VM (requires SSH service in VM)
virtctl ssh <vm-name>

# Get VM status
kubectl get vms
kubectl get vmis
```

## Usage

```hcl
module "kubevirt" {
  source = "./kubevirt-operator"

  namespace     = "kubevirt"
  name          = "kubevirt"
  chart_version = "v1.1.1"
  cdi_version   = "v1.60.3"  # CDI for DataVolume support

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

## Configuration Variables

### Core Configuration

| Variable | Type | Default | Description |
|-----------|------|----------|-------------|
| `namespace` | string | `"kubevirt"` | Kubernetes namespace for KubeVirt deployment |
| `name` | string | `"kubevirt"` | Helm release name for KubeVirt |
| `chart_version` | string | `"v1.1.1"` | KubeVirt version |
| `cdi_version` | string | `"v1.60.3"` | CDI (Containerized Data Importer) version for DataVolume support |
| `chart_name` | string | `"kubevirt"` | Helm chart name |

> **Note**: `chart_repo` is deprecated as KubeVirt uses operator manifests directly.

### Architecture Configuration

| Variable | Type | Default | Description |
|-----------|------|----------|-------------|
| `cpu_arch` | string | `"amd64"` | CPU architecture for node selection (amd64, arm64) |
| `disable_arch_scheduling` | bool | `false` | Disable architecture-based node scheduling |
| `enable_emulation` | bool | `true` | Enable software emulation for nested virtualization |

### Resource Configuration

| Variable | Type | Default | Description |
|-----------|------|----------|-------------|
| `cpu_limit` | string | `"1000m"` | CPU limit for KubeVirt containers |
| `memory_limit` | string | `"1Gi"` | Memory limit for KubeVirt containers |
| `cpu_request` | string | `"500m"` | CPU request for KubeVirt containers |
| `memory_request` | string | `"512Mi"` | Memory request for KubeVirt containers |

### Monitoring Configuration

| Variable | Type | Default | Description |
|-----------|------|----------|-------------|
| `enable_servicemonitor` | bool | `false` | Enable ServiceMonitor for Prometheus metrics collection |

### Namespace Cleanup Configuration

| Variable | Type | Default | Description |
|-----------|------|----------|-------------|
| `force_namespace_cleanup` | bool | `false` | Force cleanup of namespace if deletion gets stuck (WARNING: Only use when namespace is stuck in Terminating phase) |
| `cleanup_timeout` | string | `"15m"` | Timeout for namespace cleanup operations (e.g., 5m, 10m, 30s) |
| `workspace_prefix` | string | `""` | Workspace prefix for kubeconfig file selection (e.g., 'prod', 'sit', 'dev'). Matches main provider.tf logic. |
| `ci_mode` | bool | `false` | Running in CI mode (kubeconfig handled externally) |
| `kubeconfig_path` | string | `""` | Explicit kubeconfig path (overrides automatic detection) |

## Architecture Support

### AMD64 (x86_64)
- Full hardware virtualization support
- Best performance with Intel VT-x or AMD-V

### ARM64
- Software emulation enabled by default
- Suitable for development and testing
- Lower performance than hardware virtualization

## Virtual Machine Examples

### Using DataVolumes (Recommended)

DataVolumes with CDI provide better compatibility and avoid containerDisk mounting issues:

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: testvm-datavolume
spec:
  running: false
  dataVolumeTemplates:
  - metadata:
      name: testvm-disk
    spec:
      storage:
        resources:
          requests:
            storage: 1Gi
      source:
        http:
          url: https://download.cirros-cloud.net/0.6.2/cirros-0.6.2-x86_64-disk.img
  template:
    metadata:
      labels:
        kubevirt.io/vm: testvm-datavolume
    spec:
      domain:
        devices:
          disks:
          - name: datavolumedisk
            disk:
              bus: virtio
          - name: cloudinitdisk
            disk:
              bus: virtio
        resources:
          requests:
            memory: 512Mi
      volumes:
      - name: datavolumedisk
        dataVolume:
          name: testvm-disk
      - name: cloudinitdisk
        cloudInitNoCloud:
          userData: |
            #cloud-config
            password: cirros
            chpasswd: { expire: False }
```

### Using ContainerDisks (Legacy)

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
        resources:
          requests:
            memory: 1024M
      volumes:
      - name: containerdisk
        containerDisk:
          image: quay.io/kubevirt/cirros-container-disk-demo
```

### Managing VMs with virtctl

```bash
# Apply VM manifest
kubectl apply -f testvm-datavolume.yaml

# Start the VM
virtctl start testvm-datavolume

# Watch DataVolume import progress
kubectl get dv -w

# Check VM status
kubectl get vms
kubectl get vmis

# Access VM console
virtctl console testvm-datavolume

# Stop the VM
virtctl stop testvm-datavolume
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

## Resource Requirements

### Minimum
- CPU: 2 cores
- Memory: 4GB RAM
- Storage: 20GB

### Recommended
- CPU: 4+ cores
- Memory: 8GB+ RAM
- Storage: 50GB+

### Production
- CPU: 8+ cores
- Memory: 16GB+ RAM
- Storage: 100GB+
- Multiple nodes for HA

## Testing Checklist

### Pre-Deployment Tests
- [ ] `terraform init` - Initialize modules
- [ ] `terraform validate` - Validate configuration
- [ ] `terraform plan` - Review planned changes

### Deployment Tests (with kubevirt = true)
- [ ] `kubectl get kubevirt -n <namespace>`
- [ ] `kubectl get pods -n <namespace>`
- [ ] `kubectl get crds | grep kubevirt`
- [ ] Deploy test VM
- [ ] Verify VM creation
- [ ] Check Prometheus metrics (if enabled)

### Post-Deployment Tests
```bash
# Verify KubeVirt operator is running
kubectl get pods -n kubevirt

# Verify CRD registration
kubectl get crds | grep kubevirt

# Check KubeVirt status
kubectl get kubevirt -n kubevirt

# Deploy a test VM
kubectl apply -f test-vm-datavolume.yaml
```

## Known Limitations

1. **Hardware Virtualization**: Best performance requires CPU with VT-x/AMD-V
2. **ARM64 Performance**: Software emulation is ~40-60% slower than hardware virtualization
3. **Storage**: VMs require persistent storage (NFS or HostPath)
4. **Network**: May require additional network configuration for VM external access
5. **ARM64 Nodes**: Do not support KVM hardware virtualization (requires software emulation)

## Architecture Notes

### Implementation Details

This module uses direct manifest application (not Helm chart) because:
- KubeVirt's official Helm chart has limited configuration options
- Direct manifests allow finer control over:
  - Architecture-specific node scheduling
  - Resource limits per architecture
  - ServiceMonitor integration
  - Webhook deadlock handling

### Webhook Handling

KubeVirt uses validating webhooks that can cause deletion deadlocks. This module:
- Uses server-side apply to bypass client-side validation
- Automatically cleans up stale webhooks during deployment
- Handles proper deletion ordering during `terraform destroy`

## Resources

- [KubeVirt Documentation](https://kubevirt.io/user-guide/)
- [KubeVirt GitHub](https://github.com/kubevirt/kubevirt)
- [Virtual Machine Examples](https://kubevirt.io/user-guide/virtual_machines/virtual_machine_instances/)
- [CDI Documentation](https://github.com/kubevirt/containerized-data-importer)

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.14 |
| <a name="requirement_http"></a> [http](#requirement\_http) | >= 3.0.0 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | ~> 1.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_http"></a> [http](#provider\_http) | 3.5.0 |
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | 1.19.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.38.0 |
| <a name="provider_null"></a> [null](#provider\_null) | 3.2.4 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [kubectl_manifest.cdi_cr](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.cdi_operator](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.kubevirt_cr](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.kubevirt_operator](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.kubevirt_servicemonitor](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubernetes_namespace.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [null_resource.cleanup_apiservices](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.force_namespace_cleanup](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.wait_for_cdi_operator](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.wait_for_operator](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [http_http.cdi_cr](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |
| [http_http.cdi_operator](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |
| [http_http.kubevirt_cr](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |
| [http_http.kubevirt_operator](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |
| [kubectl_file_documents.cdi_cr](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/data-sources/file_documents) | data source |
| [kubectl_file_documents.cdi_operator](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/data-sources/file_documents) | data source |
| [kubectl_file_documents.kubevirt_operator](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/data-sources/file_documents) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cdi_version"></a> [cdi\_version](#input\_cdi\_version) | CDI (Containerized Data Importer) version for DataVolume support | `string` | `"v1.60.3"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | KubeVirt version | `string` | `"v1.1.1"` | no |
| <a name="input_ci_mode"></a> [ci\_mode](#input\_ci\_mode) | Running in CI mode (kubeconfig handled externally) | `bool` | `false` | no |
| <a name="input_cleanup_timeout"></a> [cleanup\_timeout](#input\_cleanup\_timeout) | Timeout for namespace cleanup operations (e.g., 5m, 10m, 30s) | `string` | `"5m"` | no |
| <a name="input_cpu_arch"></a> [cpu\_arch](#input\_cpu\_arch) | CPU architecture for node selection | `string` | `"amd64"` | no |
| <a name="input_cpu_limit"></a> [cpu\_limit](#input\_cpu\_limit) | CPU limit for KubeVirt containers | `string` | `"1000m"` | no |
| <a name="input_cpu_request"></a> [cpu\_request](#input\_cpu\_request) | CPU request for KubeVirt containers | `string` | `"500m"` | no |
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
| <a name="output_chart_version"></a> [chart\_version](#output\_chart\_version) | KubeVirt version deployed |
| <a name="output_cpu_arch"></a> [cpu\_arch](#output\_cpu\_arch) | CPU architecture used for KubeVirt deployment |
| <a name="output_enable_emulation"></a> [enable\_emulation](#output\_enable\_emulation) | Whether software emulation is enabled for nested virtualization |
| <a name="output_enable_servicemonitor"></a> [enable\_servicemonitor](#output\_enable\_servicemonitor) | Whether Prometheus ServiceMonitor is enabled for metrics collection |
| <a name="output_namespace"></a> [namespace](#output\_namespace) | KubeVirt namespace |
| <a name="output_operator_ready"></a> [operator\_ready](#output\_operator\_ready) | Whether the KubeVirt operator deployment is ready |
| <a name="output_resource_limits"></a> [resource\_limits](#output\_resource\_limits) | Resource limits applied to KubeVirt operator containers |
| <a name="output_status"></a> [status](#output\_status) | KubeVirt deployment status |
<!-- END_TF_DOCS -->
