# Node Feature Discovery Helm Module

This module deploys [Node Feature Discovery (NFD)](https://kubernetes-sigs.github.io/node-feature-discovery/) to automatically detect and label hardware features on Kubernetes nodes.

## Features

- **🔍 Hardware Detection**: Automatically detects CPU, memory, storage, and network features
- **💾 Enhanced Storage Detection**: Detects NVMe, SATA, USB storage, and high-capacity drives
- **🍓 Raspberry Pi Support**: Special detection for Pi-specific hardware (SD cards, GPIO)
- **🏷️ Automatic Labeling**: Labels nodes with detected features for intelligent scheduling
- **⚖️ Resource Optimized**: Minimal resource footprint for homelab environments

## Storage Detection Features

The module includes enhanced storage detection capabilities:

### Comprehensive Hardware Detection

**Storage Features**
- **NVMe Drives**: `storage.feature/nvme=true`
- **SATA/SCSI Drives**: `storage.feature/sata=true`
- **USB Storage**: `storage.feature/usb=true`
- **High-Capacity Storage**: `storage.feature/high-capacity=true` (>1TB)
- **SD Card Storage**: `storage.feature/sd-card=true` (Raspberry Pi)
- **External Controllers**: `storage.feature/external-controller=true`

**Graphics & Compute**
- **GPU Present**: `gpu.feature/present=true`
- **NUMA Memory**: `feature.node.kubernetes.io/memory-numa=true`
- **Non-Volatile Memory**: `feature.node.kubernetes.io/memory-nv=true`

**Network Capabilities**
- **Wireless**: `network.feature/wireless=true`
- **SR-IOV**: `feature.node.kubernetes.io/network-sriov.capable=true`
- **Network Speed**: `feature.node.kubernetes.io/network-<interface>.speed=<speed>`

**System Information**
- **Container Runtime Ready**: `runtime.feature/container-ready=true`
- **Hardware Vendor**: `feature.node.kubernetes.io/system-os_release.ID=<os>`
- **BIOS Info**: `feature.node.kubernetes.io/system-dmi.bios_vendor=<vendor>`

### Example Node Labels
```bash
# View detected storage features
kubectl get nodes -o json | jq '.items[].metadata.labels' | grep storage

# Example output:
# "storage.feature/nvme": "true"
# "storage.feature/high-capacity": "true"
# "storage.feature/sd-card": "true"
```

## Usage

### Basic Deployment
```hcl
services = {
  node_feature_discovery = true
}
```

### Advanced Configuration
```hcl
service_overrides = {
  node_feature_discovery = {
    cpu_arch = "arm64"  # For Raspberry Pi clusters

    # Resource limits for constrained environments
    cpu_limit      = "100m"
    memory_limit   = "64Mi"
    cpu_request    = "25m"
    memory_request = "32Mi"
  }
}
```

## Scheduling with Storage Features

Use detected storage features for intelligent pod scheduling:

```yaml
# Schedule on nodes with NVMe storage
apiVersion: v1
kind: Pod
spec:
  nodeSelector:
    storage.feature/nvme: "true"
  containers:
  - name: database
    image: postgres:15
```

```yaml
# Schedule on nodes with high-capacity storage
apiVersion: v1
kind: Pod
spec:
  nodeSelector:
    storage.feature/high-capacity: "true"
  containers:
  - name: media-server
    image: plex/plex-media-server
```

```yaml
# Schedule GPU workloads on nodes with graphics cards
apiVersion: v1
kind: Pod
spec:
  nodeSelector:
    gpu.feature/present: "true"
  containers:
  - name: ai-workload
    image: tensorflow/tensorflow:latest-gpu
```

```yaml
# Schedule on wireless-capable nodes
apiVersion: v1
kind: Pod
spec:
  nodeSelector:
    network.feature/wireless: "true"
  containers:
  - name: wifi-manager
    image: hostapd:latest
```

## Architecture Support

- **ARM64**: Optimized for Raspberry Pi with SD card detection
- **AMD64**: Full feature detection for x86 systems
- **Mixed Clusters**: Runs on all nodes to provide comprehensive labeling

## Monitoring Integration

Node Feature Discovery integrates with Prometheus to expose hardware metrics:

```bash
# View NFD metrics
kubectl port-forward -n node-feature-discovery-stack svc/node-feature-discovery 8080:8080
curl http://localhost:8080/metrics
```

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

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_chart_name"></a> [chart\_name](#input\_chart\_name) | Helm chart name. | `string` | `"node-feature-discovery"` | no |
| <a name="input_chart_repo"></a> [chart\_repo](#input\_chart\_repo) | Helm repository name. | `string` | `"https://kubernetes-sigs.github.io/node-feature-discovery/charts"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Helm version. | `string` | `"0.17.3"` | no |
| <a name="input_cpu_arch"></a> [cpu\_arch](#input\_cpu\_arch) | CPU architecture for node selection (amd64, arm64) | `string` | `"amd64"` | no |
| <a name="input_cpu_limit"></a> [cpu\_limit](#input\_cpu\_limit) | CPU limit for the container | `string` | `"200m"` | no |
| <a name="input_cpu_request"></a> [cpu\_request](#input\_cpu\_request) | CPU request for the container | `string` | `"50m"` | no |
| <a name="input_disable_arch_scheduling"></a> [disable\_arch\_scheduling](#input\_disable\_arch\_scheduling) | Disable architecture-based node scheduling (useful for cluster-wide services) | `bool` | `true` | no |
| <a name="input_helm_cleanup_on_fail"></a> [helm\_cleanup\_on\_fail](#input\_helm\_cleanup\_on\_fail) | Cleanup resources on failure | `bool` | `false` | no |
| <a name="input_helm_disable_webhooks"></a> [helm\_disable\_webhooks](#input\_helm\_disable\_webhooks) | Disable webhooks for Helm release | `bool` | `false` | no |
| <a name="input_helm_force_update"></a> [helm\_force\_update](#input\_helm\_force\_update) | Force resource updates if needed | `bool` | `false` | no |
| <a name="input_helm_replace"></a> [helm\_replace](#input\_helm\_replace) | Allow Helm to replace existing resources | `bool` | `false` | no |
| <a name="input_helm_skip_crds"></a> [helm\_skip\_crds](#input\_helm\_skip\_crds) | Skip CRDs for Helm release | `bool` | `false` | no |
| <a name="input_helm_timeout"></a> [helm\_timeout](#input\_helm\_timeout) | Timeout for Helm deployment in seconds | `number` | `120` | no |
| <a name="input_helm_wait"></a> [helm\_wait](#input\_helm\_wait) | Wait for Helm release to be ready | `bool` | `false` | no |
| <a name="input_helm_wait_for_jobs"></a> [helm\_wait\_for\_jobs](#input\_helm\_wait\_for\_jobs) | Wait for Helm jobs to complete | `bool` | `false` | no |
| <a name="input_memory_limit"></a> [memory\_limit](#input\_memory\_limit) | Memory limit for the container | `string` | `"128Mi"` | no |
| <a name="input_memory_request"></a> [memory\_request](#input\_memory\_request) | Memory request for the container | `string` | `"64Mi"` | no |
| <a name="input_name"></a> [name](#input\_name) | Helm name. | `string` | `"node-feature-discovery"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace. | `string` | `"node-feature-discovery-stack"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_namespace"></a> [namespace](#output\_namespace) | n/a |
<!-- END_TF_DOCS -->
