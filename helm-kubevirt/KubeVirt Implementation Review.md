# KubeVirt Implementation Review: ARM64 Compatibility Issues and Improvements

## Critical Issues Found

### 1. **Missing CRD File (BLOCKING)**
**Location:** `helm-kubevirt/main.tf:17`
- **Issue:** References `file("${path.module}/templates/kubevirt-crd.yaml")` but this file doesn't exist
- **Impact:** Terraform will fail during deployment
- **Fix Needed:** Create the CRD file or remove the reference (the CRD is included in the operator template)

### 2. **No Architecture-Based Node Scheduling**
**Location:** `helm-kubevirt/main.tf` and `helm-kubevirt/locals.tf`
- **Issue:** KubeVirt components lack node selectors to schedule on architecture-specific nodes
- **Impact:** KubeVirt pods may schedule on wrong architecture nodes (e.g., ARM64-only pods on AMD64 nodes)
- **Other Services Have This:** All other services (node-red, portainer, home-assistant, etc.) implement node selectors

### 3. **Static Resource Limits**
**Location:** `helm-kubevirt/main.tf` and `helm-kubevirt/variables.tf`
- **Issue:** Resource limits don't consider ARM64 constraints (typically smaller/less powerful)
- **Impact:** May overcommit ARM64 nodes or underutilize AMD64 nodes
- **Example:** `cpu_limit = "1000m"`, `memory_limit = "1Gi"` - same for both architectures

### 4. **No Architecture-Aware Emulation Logic**
**Location:** `helm-kubevirt/templates/kubevirt-cr.yaml.tpl`
- **Issue:** `useEmulation` is a simple boolean without auto-detection
- **Impact:** Users must manually enable emulation for ARM64,容易出错
- **Problem:** Should automatically enable emulation when `cpu_arch == "arm64"`

### 5. **Missing ServiceMonitor Resource**
**Location:** `helm-kubevirt/variables.tf:92`
- **Issue:** `enable_servicemonitor` variable exists but no ServiceMonitor is created
- **Impact:** Prometheus metrics won't be collected even when enabled

### 6. **No Pod Topology Spread Constraints**
**Location:** `helm-kubevirt/templates/kubevirt-operator.yaml.tpl`
- **Issue:** Missing topology spread constraints for high availability
- **Impact:** All KubeVirt pods may land on single node in multi-node ARM64 clusters

## Detailed Recommendations

### Priority 1: Critical Fixes (Must Fix)

#### 1.1 Fix Missing CRD Reference
```terraform
# helm-kubevirt/main.tf - Remove or fix this block:
# resource "kubectl_manifest" "kubevirt_crd" {
#   yaml_body = file("${path.module}/templates/kubevirt-crd.yaml")
# }
# The CRD is already defined in kubevirt-operator.yaml.tpl
```

#### 1.2 Add Node Selector for Architecture
Create `helm-kubevirt/templates/kubevirt-cr-with-node-selector.yaml.tpl`:
```yaml
apiVersion: kubevirt.io/v1
kind: KubeVirt
metadata:
  name: kubevirt
  namespace: ${namespace}
spec:
  certificateRotateStrategy: {}
  configuration:
    developerConfiguration:
      useEmulation: ${use_emulation}
    nodeSelectors:
      workloads: ${node_selector}
  customizeComponents: {}
  imagePullPolicy: IfNotPresent
  workloadUpdateStrategy: {}
```

Update `helm-kubevirt/locals.tf`:
```hcl
locals {
  module_config = {
    namespace     = var.namespace
    name          = var.name
    chart_version = var.chart_version
  }

  common_labels = {
    "app.kubernetes.io/name"       = "kubevirt"
    "app.kubernetes.io/instance"   = var.name
    "app.kubernetes.io/managed-by" = "terraform"
  }

  # Architecture-aware node selector
  node_selector = var.disable_arch_scheduling ? {} : {
    "kubernetes.io/arch" = var.cpu_arch
  }

  # Auto-enable emulation for ARM64
  use_emulation = var.enable_emulation || var.cpu_arch == "arm64"

  template_values = {
    namespace      = var.namespace
    enable_emulation = local.use_emulation
    enable_servicemonitor = var.enable_servicemonitor
    node_selector = local.node_selector
  }
}
```

#### 1.3 Add Node Selector to Operator
Update `helm-kubevirt/templates/kubevirt-operator.yaml.tpl`:
```yaml
spec:
  replicas: 2
  selector:
    matchLabels:
      kubevirt.io: virt-operator
  template:
    metadata:
      labels:
        kubevirt.io: virt-operator
    spec:
      serviceAccountName: kubevirt-operator
%{if node_selector != "" ~}
      nodeSelector:
        kubernetes.io/arch: ${node_selector}
%{endif ~}
      containers:
        - name: virt-operator
          image: quay.io/kubevirt/virt-operator:${kubevirt_version}
```

### Priority 2: Architecture-Specific Optimizations

#### 2.1 Dynamic Resource Limits Based on Architecture
Update `helm-kubevirt/main.tf`:
```terraform
module "kubevirt" {
  count  = local.services_enabled.kubevirt ? 1 : 0
  source = "./helm-kubevirt"
  providers = {
    kubernetes = kubernetes
    kubectl    = kubectl
  }
  name                    = "${local.workspace_prefix}-kubevirt"
  namespace               = "${local.workspace_prefix}-kubevirt-system"
  cpu_arch                = coalesce(
    try(var.service_overrides.kubevirt.cpu_arch, null),
    try(var.cpu_arch_override.kubevirt, null),
    local.cpu_arch
  )

  # Architecture-aware resource defaults
  cpu_limit      = coalesce(
    try(var.service_overrides.kubevirt.cpu_limit, null),
    local.cpu_arch == "arm64" ? "500m" : "1000m"  # ARM64: 0.5 cores, AMD64: 1 core
  )
  memory_limit   = coalesce(
    try(var.service_overrides.kubevirt.memory_limit, null),
    local.cpu_arch == "arm64" ? "512Mi" : "1Gi"  # ARM64: 512MB, AMD64: 1GB
  )
  cpu_request    = coalesce(
    try(var.service_overrides.kubevirt.cpu_request, null),
    local.cpu_arch == "arm64" ? "250m" : "500m"
  )
  memory_request = coalesce(
    try(var.service_overrides.kubevirt.memory_request, null),
    local.cpu_arch == "arm64" ? "256Mi" : "512Mi"
  )

  # Auto-enable emulation for ARM64
  enable_emulation = coalesce(
    try(var.service_overrides.kubevirt.enable_emulation, null),
    local.cpu_arch == "arm64"  # Force emulation on ARM64
  )

  enable_servicemonitor = coalesce(
    try(var.service_overrides.kubevirt.enable_servicemonitor, null),
    local.services_enabled.prometheus_crds
  )

  disable_arch_scheduling = try(var.disable_arch_scheduling.kubevirt, false)

  chart_version = coalesce(
    try(var.service_overrides.kubevirt.chart_version, null),
    "v1.1.1"
  )
}
```

#### 2.2 Add ServiceMonitor Resource
Create `helm-kubevirt/templates/servicemonitor.yaml.tpl`:
```yaml
%{if enable_servicemonitor ~}
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: kubevirt
  namespace: ${namespace}
  labels:
    app.kubernetes.io/name: kubevirt
    app.kubernetes.io/component: monitoring
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: kubevirt
  endpoints:
    - port: metrics
      interval: 30s
      path: /metrics
%{endif ~}
```

Update `helm-kubevirt/main.tf`:
```terraform
resource "kubectl_manifest" "kubevirt_servicemonitor" {
  count = var.enable_servicemonitor ? 1 : 0
  yaml_body = templatefile("${path.module}/templates/servicemonitor.yaml.tpl", {
    namespace = kubernetes_namespace.this.metadata[0].name
    enable_servicemonitor = var.enable_servicemonitor
  })

  depends_on = [kubectl_manifest.kubevirt_cr]
}
```

### Priority 3: ARM64-Specific Enhancements

#### 3.1 Add Topology Spread Constraints
Update `helm-kubevirt/templates/kubevirt-operator.yaml.tpl`:
```yaml
spec:
  replicas: 2
  selector:
    matchLabels:
      kubevirt.io: virt-operator
  template:
    metadata:
      labels:
        kubevirt.io: virt-operator
    spec:
      serviceAccountName: kubevirt-operator
%{if node_selector != "" ~}
      nodeSelector:
        kubernetes.io/arch: ${node_selector}
%{endif ~}
      # Distribute pods across nodes for HA
      topologySpreadConstraints:
        - maxSkew: 1
          topologyKey: kubernetes.io/hostname
          whenUnsatisfiable: ScheduleAnyway
          labelSelector:
            matchLabels:
              kubevirt.io: virt-operator
      containers:
        - name: virt-operator
          image: quay.io/kubevirt/virt-operator:${kubevirt_version}
```

#### 3.2 Add ARM64-Specific Configuration Documentation
Update `KUBEVIRT-IMPLEMENTATION.md`:
```markdown
## ARM64-Specific Configuration

### Raspberry Pi Clusters
For Raspberry Pi or other ARM64 hardware:

```hcl
service_overrides = {
  kubevirt = {
    cpu_arch = "arm64"  # Critical for ARM64 clusters

    # Emulation is automatically enabled for ARM64
    # but you can explicitly disable if you have hardware virtualization
    enable_emulation = true

    # Reduced resource limits for ARM64 hardware
    cpu_limit      = "500m"   # 0.5 CPU cores
    memory_limit   = "512Mi"  # 512MB RAM
    cpu_request    = "250m"
    memory_request = "256Mi"
  }
}
```

### ARM64 Performance Considerations
- **Software Emulation**: Enabled by default, ~40-60% performance penalty
- **Resource Limits**: Automatically reduced to prevent overcommit
- **Storage**: Use fast SSD/NVMe for better I/O performance
- **Network**: Consider MetalLB for external VM access
```

### Priority 4: Mixed Architecture Support

#### 4.1 Detect Mixed Clusters
The codebase already has mixed cluster detection in `locals.tf`, but KubeVirt doesn't use it.

Add to `helm-kubevirt/main.tf`:
```terraform
module "kubevirt" {
  count  = local.services_enabled.kubevirt ? 1 : 0
  source = "./helm-kubevirt"

  # In mixed clusters, let user explicitly choose architecture
  cpu_arch = local.is_mixed_cluster ? (
    try(var.service_overrides.kubevirt.cpu_arch, local.most_common_worker_arch)
  ) : (
    coalesce(
      try(var.service_overrides.kubevirt.cpu_arch, null),
      try(var.cpu_arch_override.kubevirt, null),
      local.cpu_arch
    )
  )

  # Warn in mixed clusters
  disable_arch_scheduling = local.is_mixed_cluster ? false : (
    try(var.disable_arch_scheduling.kubevirt, false)
  )
}
```

## Summary of Required Changes

### Files to Modify:
1. `helm-kubevirt/main.tf` - Add node selectors, fix CRD issue, add ServiceMonitor
2. `helm-kubevirt/locals.tf` - Add node selector logic and auto-emulation
3. `helm-kubevirt/variables.tf` - Add topology spread constraint variables
4. `helm-kubevirt/templates/kubevirt-operator.yaml.tpl` - Add node selector and topology constraints
5. `helm-kubevirt/templates/kubevirt-cr.yaml.tpl` - Update with node selector
6. Create `helm-kubevirt/templates/servicemonitor.yaml.tpl`
7. Update `KUBEVIRT-IMPLEMENTATION.md` - Add ARM64-specific documentation
8. Update `examples/kubevirt-example.tfvars` - Add ARM64 examples

### Key Improvements:
✅ Architecture-aware node scheduling
✅ Automatic emulation on ARM64
✅ Dynamic resource limits based on architecture
✅ ServiceMonitor integration
✅ Topology spread constraints for HA
✅ Mixed cluster support
✅ ARM64-specific documentation

### Testing Recommendations:
1. Deploy on pure ARM64 cluster (Raspberry Pi)
2. Deploy on pure AMD64 cluster
3. Deploy on mixed architecture cluster
4. Verify node selectors are applied correctly
5. Test VM creation and operation on ARM64
6. Verify resource limits respect architecture
7. Test Prometheus metrics collection
8. Test high availability with topology constraints
