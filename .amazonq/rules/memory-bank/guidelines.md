# Development Guidelines - tf-kube-any-compute

## Code Quality Standards

### Terraform Formatting
- **Indentation**: 2 spaces (enforced by `terraform fmt`)
- **Line Length**: No hard limit, but prefer readability over compactness
- **Block Spacing**: Single blank line between resource blocks
- **Comments**: Use `#` for single-line, avoid inline comments for complex logic
- **File Organization**: Group related resources, separate with comment headers

### HCL Conventions
```hcl
# ============================================================================
# Section Header - Use 76 character separator lines
# ============================================================================

# Resource blocks with descriptive names
resource "kubernetes_namespace" "service_namespace" {
  metadata {
    name = local.namespace
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/part-of"    = "tf-kube-any-compute"
    }
  }
}

# Use locals for complex logic
locals {
  # Descriptive comment explaining the logic
  storage_class = (
    var.storage_class != "" ? var.storage_class :
    var.use_nfs_storage ? "nfs-csi" :
    var.use_hostpath_storage ? "hostpath" :
    "default"
  )
}
```

### Variable Naming
- **Snake Case**: `cpu_arch`, `storage_class`, `enable_persistence`
- **Boolean Prefix**: `enable_*`, `use_*`, `disable_*`
- **Descriptive Names**: Avoid abbreviations unless universally understood
- **Consistency**: Use same terminology across modules (e.g., `cpu_arch` not `architecture`)

### Resource Naming Pattern
```hcl
# Format: {environment}-{service}-{resource_type}
resource "kubernetes_namespace" "namespace" {
  metadata {
    name = "${var.environment}-${var.service_name}-system"
  }
}

# Helm releases use service name
resource "helm_release" "service" {
  name      = var.environment
  namespace = kubernetes_namespace.namespace.metadata[0].name
}
```

## Structural Conventions

### Module Structure (Standard Pattern)
Every Helm module follows this structure:
```
helm-{service}/
├── main.tf              # Namespace + Helm release
├── variables.tf         # Input variables
├── outputs.tf           # Module outputs
├── locals.tf            # Configuration logic
├── version.tf           # Provider versions
├── limit_range.tf       # Resource limits
├── static-pv.tf         # Static PVs (optional)
├── traefik-ingress.tf   # Ingress routes (optional)
├── servicemonitor.tf    # Prometheus monitoring (optional)
└── templates/
    └── {service}-values.yaml.tpl
```

### File Ordering
1. **Terraform Configuration**: `terraform {}` block
2. **Provider Configuration**: `provider {}` blocks
3. **Data Sources**: `data {}` blocks
4. **Locals**: `locals {}` blocks
5. **Resources**: `resource {}` blocks (alphabetical by type)
6. **Outputs**: `output {}` blocks

### Variable Definitions
```hcl
variable "cpu_arch" {
  description = "CPU architecture for node selection (amd64, arm64)"
  type        = string
  default     = "amd64"

  validation {
    condition     = contains(["amd64", "arm64"], var.cpu_arch)
    error_message = "CPU architecture must be either 'amd64' or 'arm64'."
  }
}

variable "enable_persistence" {
  description = "Enable persistent storage for service data"
  type        = bool
  default     = true
}

variable "service_overrides" {
  description = "Service-specific configuration overrides"
  type = object({
    cpu_limit    = optional(string)
    memory_limit = optional(string)
  })
  default = {}
}
```

## Semantic Patterns

### Configuration Override Hierarchy
Implement cascading configuration with `coalesce()`:
```hcl
locals {
  service_configs = {
    traefik = {
      cpu_arch = coalesce(
        try(var.service_overrides.traefik.cpu_arch, null),
        try(var.cpu_arch_override.traefik, null),
        local.cpu_arch,
        "amd64"
      )
    }
  }
}
```

### Conditional Resource Creation
Use `count` for simple conditionals:
```hcl
resource "kubernetes_persistent_volume" "static_pv" {
  count = var.enable_persistence && var.use_nfs_storage ? 1 : 0

  metadata {
    name = "${var.environment}-${var.service_name}-pv"
  }
  # ... rest of configuration
}
```

### Dynamic Blocks for Repeated Configuration
```hcl
resource "kubernetes_deployment" "service" {
  spec {
    template {
      spec {
        # Dynamic volume mounts
        dynamic "volume" {
          for_each = var.enable_persistence ? [1] : []
          content {
            name = "data"
            persistent_volume_claim {
              claim_name = kubernetes_persistent_volume_claim.pvc[0].metadata[0].name
            }
          }
        }
      }
    }
  }
}
```

### Architecture-Aware Scheduling
```hcl
# Node selector for architecture
node_selector = var.disable_arch_scheduling ? {} : {
  "kubernetes.io/arch" = var.cpu_arch
}

# Affinity for mixed clusters
affinity = var.disable_arch_scheduling ? {} : {
  nodeAffinity = {
    requiredDuringSchedulingIgnoredDuringExecution = {
      nodeSelectorTerms = [{
        matchExpressions = [{
          key      = "kubernetes.io/arch"
          operator = "In"
          values   = [var.cpu_arch]
        }]
      }]
    }
  }
}
```

## Internal API Usage

### Helm Release Pattern
```hcl
resource "helm_release" "service" {
  name       = var.environment
  repository = var.chart_repository
  chart      = var.chart_name
  version    = var.chart_version
  namespace  = kubernetes_namespace.namespace.metadata[0].name

  # Helm behavior configuration
  timeout          = var.helm_timeout
  wait             = var.helm_wait
  wait_for_jobs    = var.helm_wait_for_jobs
  cleanup_on_fail  = var.helm_cleanup_on_fail
  force_update     = var.helm_force_update
  disable_webhooks = var.helm_disable_webhooks
  skip_crds        = var.helm_skip_crds
  replace          = var.helm_replace

  # Values from template
  values = [
    templatefile("${path.module}/templates/${var.service_name}-values.yaml.tpl", {
      # Pass all necessary variables
      cpu_arch      = var.cpu_arch
      storage_class = local.storage_class
      # ... other variables
    })
  ]

  # Dependencies
  depends_on = [
    kubernetes_namespace.namespace,
    kubernetes_limit_range.limit_range,
  ]
}
```

### Kubernetes Resource Labels
Standard labels for all resources:
```hcl
labels = {
  "app.kubernetes.io/name"       = var.service_name
  "app.kubernetes.io/instance"   = var.environment
  "app.kubernetes.io/version"    = var.chart_version
  "app.kubernetes.io/component"  = var.component_name
  "app.kubernetes.io/part-of"    = "tf-kube-any-compute"
  "app.kubernetes.io/managed-by" = "terraform"
}
```

### Traefik IngressRoute Pattern
```hcl
resource "kubectl_manifest" "ingress_route" {
  count = var.enable_ingress ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "traefik.io/v1alpha1"
    kind       = "IngressRoute"
    metadata = {
      name      = "${var.environment}-${var.service_name}"
      namespace = kubernetes_namespace.namespace.metadata[0].name
    }
    spec = {
      entryPoints = ["websecure"]
      routes = [{
        match = "Host(`${var.service_name}.${var.domain_name}`)"
        kind  = "Rule"
        services = [{
          name = var.service_name
          port = var.service_port
        }]
        middlewares = var.middleware_names
      }]
      tls = {
        certResolver = var.cert_resolver
      }
    }
  })

  depends_on = [helm_release.service]
}
```

## Code Idioms

### Safe Navigation with try()
```hcl
# Safely access nested optional values
cpu_limit = try(var.service_overrides.cpu_limit, var.default_cpu_limit, "200m")

# Check if value exists before using
enable_feature = try(var.service_overrides.enable_feature, false)
```

### Ternary Operator for Simple Logic
```hcl
# Simple conditional
storage_class = var.use_nfs_storage ? "nfs-csi" : "hostpath"

# Chained conditionals
storage_class = (
  var.storage_class != "" ? var.storage_class :
  var.use_nfs_storage ? "nfs-csi" :
  var.use_hostpath_storage ? "hostpath" :
  "default"
)
```

### String Interpolation
```hcl
# Simple interpolation
name = "${var.environment}-${var.service_name}"

# Complex interpolation with conditionals
url = "https://${var.service_name}.${var.platform_name}.${var.base_domain}"

# Avoid unnecessary interpolation
name = var.service_name  # Good
name = "${var.service_name}"  # Unnecessary
```

### List and Map Operations
```hcl
# Merge maps with defaults
final_config = merge(
  local.default_config,
  var.service_overrides
)

# Flatten nested lists
all_services = flatten([
  local.core_services,
  local.optional_services,
])

# Filter lists
enabled_services = [
  for service, enabled in var.services : service if enabled
]
```

## Testing Patterns

### Unit Test Structure
```hcl
# tests.tftest.hcl
run "test_architecture_detection" {
  command = plan

  variables {
    cpu_arch = ""  # Empty for auto-detection
  }

  assert {
    condition     = local.detected_arch != ""
    error_message = "Architecture detection failed"
  }
}
```

### Scenario Test Pattern
```hcl
# test-scenarios.tftest.hcl
run "raspberry_pi_cluster" {
  command = plan

  variables {
    cpu_arch             = "arm64"
    enable_microk8s_mode = true
    use_hostpath_storage = true
  }

  assert {
    condition     = local.cpu_arch == "arm64"
    error_message = "ARM64 architecture not applied"
  }
}
```

## Documentation Standards

### Module Documentation
Use terraform-docs format:
```hcl
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |

## Providers

| Name | Version |
|------|---------|
| kubernetes | ~> 2.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [kubernetes_namespace.namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cpu_arch | CPU architecture | `string` | `"amd64"` | no |

## Outputs

| Name | Description |
|------|-------------|
| namespace | Namespace name |
<!-- END_TF_DOCS -->
```

### Inline Comments
```hcl
# GOOD: Explain WHY, not WHAT
# Use coalesce to implement override hierarchy: service > global > default
cpu_arch = coalesce(var.service_cpu_arch, var.global_cpu_arch, "amd64")

# BAD: Obvious comment
# Set cpu_arch variable
cpu_arch = var.cpu_arch
```

## Security Best Practices

### Sensitive Data Handling
```hcl
# Mark sensitive outputs
output "admin_password" {
  value     = random_password.admin.result
  sensitive = true
}

# Use random provider for passwords
resource "random_password" "admin" {
  length  = 16
  special = true
}

# Never hardcode secrets
# BAD: password = "admin123"
# GOOD: password = var.admin_password
```

### Resource Limits
```hcl
# Always define resource limits for production
resource "kubernetes_limit_range" "limit_range" {
  metadata {
    name      = "${var.environment}-limits"
    namespace = kubernetes_namespace.namespace.metadata[0].name
  }

  spec {
    limit {
      type = "Container"
      default = {
        cpu    = var.default_cpu_limit
        memory = var.default_memory_limit
      }
      default_request = {
        cpu    = var.default_cpu_request
        memory = var.default_memory_request
      }
    }
  }
}
```

## Performance Optimization

### Minimize Provider Calls
```hcl
# GOOD: Single data source call
data "kubernetes_nodes" "all" {
  metadata {}
}

locals {
  node_count = length(data.kubernetes_nodes.all.nodes)
  arm64_nodes = [
    for node in data.kubernetes_nodes.all.nodes :
    node if node.metadata[0].labels["kubernetes.io/arch"] == "arm64"
  ]
}

# BAD: Multiple data source calls
data "kubernetes_nodes" "count" {}
data "kubernetes_nodes" "arm64" {}
```

### Efficient Conditionals
```hcl
# GOOD: Single evaluation
locals {
  should_create = var.enabled && var.environment == "production"
}

resource "kubernetes_resource" "example" {
  count = local.should_create ? 1 : 0
}

# BAD: Repeated evaluation
resource "kubernetes_resource" "example" {
  count = var.enabled && var.environment == "production" ? 1 : 0
}
```

## Error Handling

### Validation Rules
```hcl
variable "cpu_arch" {
  type = string

  validation {
    condition     = contains(["amd64", "arm64"], var.cpu_arch)
    error_message = "CPU architecture must be 'amd64' or 'arm64'."
  }
}

variable "storage_size" {
  type = string

  validation {
    condition     = can(regex("^[0-9]+[GMK]i$", var.storage_size))
    error_message = "Storage size must be in format: 10Gi, 500Mi, etc."
  }
}
```

### Graceful Degradation
```hcl
# Provide sensible defaults when optional values are missing
locals {
  cpu_limit = try(
    var.service_overrides.cpu_limit,
    var.enable_microk8s_mode ? "200m" : "1000m",
    "500m"
  )
}
```
