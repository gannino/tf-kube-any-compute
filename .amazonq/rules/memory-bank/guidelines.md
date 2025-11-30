# Development Guidelines: tf-kube-any-compute

## Code Quality Standards

### Terraform Formatting
- **Indentation**: 2 spaces (consistent across all .tf files)
- **Line Length**: Prefer 80-120 characters, break long lines logically
- **Block Spacing**: Single blank line between resource blocks
- **Comments**: Use `#` for single-line, descriptive comments above complex logic
- **File Organization**: Group related resources, use consistent ordering

### File Header Pattern
```terraform
###########################
#  Module Name - Purpose  #
###########################
```

### Variable Organization
- **Alphabetical Order**: All variables sorted alphabetically in variables.tf
- **Validation Rules**: Include validation blocks for critical inputs
- **Descriptions**: Clear, concise descriptions for all variables
- **Defaults**: Sensible defaults with optional() for complex objects
- **Sensitive Data**: Mark passwords/tokens with `sensitive = true`

### Documentation Standards
- **README.md**: Every module must have comprehensive README
- **terraform-docs**: Auto-generated documentation using terraform-docs
- **Inline Comments**: Explain "why" not "what" for complex logic
- **Examples**: Provide usage examples in examples/ directory
- **Guides**: Detailed guides in docs/guides/ for complex features

## Structural Conventions

### Module Structure
```
module-name/
├── main.tf              # Primary resource definitions
├── variables.tf         # Input variables (alphabetical)
├── outputs.tf           # Output definitions
├── locals.tf            # Local value computations
├── version.tf           # Provider requirements
├── values.yaml.tpl      # Helm values template
├── templates/           # Additional templates
├── README.md            # Module documentation
└── .tflint.hcl         # Module-specific linting rules
```

### Naming Conventions

#### Resources
```terraform
# Pattern: {service}_{resource_type}
resource "kubernetes_namespace" "traefik_namespace" { }
resource "helm_release" "traefik_release" { }
resource "kubernetes_secret" "traefik_auth_secret" { }
```

#### Variables
```terraform
# Boolean flags
variable "enable_feature" { }
variable "use_option" { }

# Configuration objects
variable "service_config" { }
variable "middleware_config" { }

# Overrides
variable "cpu_arch_override" { }
variable "storage_class_override" { }
```

#### Locals
```terraform
# Computed values
locals {
  service_enabled = var.enable_service || var.services.service
  effective_cpu_arch = var.cpu_arch != "" ? var.cpu_arch : local.detected_arch
  storage_class = local.use_nfs ? "nfs-csi" : "hostpath-storage"
}
```

### Resource Naming Pattern
```terraform
# Namespace: {environment}-{service}-system
namespace = "prod-traefik-system"

# Release: {environment}-{service}
name = "prod-traefik"

# Labels: Consistent key-value pairs
labels = {
  "app.kubernetes.io/name"       = "traefik"
  "app.kubernetes.io/instance"   = "prod-traefik"
  "app.kubernetes.io/managed-by" = "terraform"
}
```

## Semantic Patterns

### Configuration Hierarchy Pattern
```terraform
# 1. System defaults
locals {
  system_defaults = merge({
    cpu_limit = "200m"
    memory_limit = "256Mi"
  }, var.system_defaults)
}

# 2. Service defaults
locals {
  service_defaults = {
    traefik = {
      cpu_limit = local.system_defaults.cpu_limit
      memory_limit = local.system_defaults.memory_limit
    }
  }
}

# 3. User overrides
locals {
  traefik_config = merge(
    local.service_defaults.traefik,
    var.service_overrides.traefik != null ? var.service_overrides.traefik : {}
  )
}
```

### Conditional Resource Creation
```terraform
# Pattern: Use count for optional resources
resource "kubernetes_ingress_v1" "service_ingress" {
  count = var.enable_ingress ? 1 : 0
  # ... configuration
}

# Pattern: Use dynamic blocks for optional nested blocks
dynamic "volume" {
  for_each = var.enable_persistence ? [1] : []
  content {
    # ... volume configuration
  }
}
```

### Architecture Detection Pattern
```terraform
# Detect cluster architecture
data "kubernetes_nodes" "all_nodes" {}

locals {
  # Extract architectures from all nodes
  node_architectures = distinct([
    for node in data.kubernetes_nodes.all_nodes.nodes :
    lookup(node.status[0].node_info[0], "architecture", "amd64")
  ])

  # Determine if mixed cluster
  is_mixed_cluster = length(local.node_architectures) > 1

  # Select primary architecture
  detected_arch = length(local.node_architectures) > 0 ? local.node_architectures[0] : "amd64"
}
```

### Storage Class Selection Pattern
```terraform
locals {
  # Priority: User override > NFS > HostPath > Default
  storage_class = (
    var.service_overrides.service.storage_class != null ?
      var.service_overrides.service.storage_class :
    var.use_nfs_storage ?
      "nfs-csi" :
    var.use_hostpath_storage ?
      "hostpath-storage" :
    var.default_storage_class != "" ?
      var.default_storage_class :
    "default"
  )
}
```

### Helm Values Templating Pattern
```yaml
# values.yaml.tpl - Use templatefile() function
%{ if enable_feature ~}
feature:
  enabled: true
  config: ${config_value}
%{ endif ~}

# Conditional blocks with proper indentation
resources:
%{ if enable_resource_limits ~}
  limits:
    cpu: ${cpu_limit}
    memory: ${memory_limit}
%{ endif ~}
```

### Module Output Pattern
```terraform
# Provide comprehensive outputs
output "service_info" {
  description = "Complete service information"
  value = {
    namespace     = kubernetes_namespace.service.metadata[0].name
    release_name  = helm_release.service.name
    chart_version = helm_release.service.metadata[0].version
    status        = helm_release.service.status
    values        = helm_release.service.metadata[0].values
  }
}
```

## Internal API Usage

### Kubernetes Provider Patterns
```terraform
# Namespace creation
resource "kubernetes_namespace" "service" {
  metadata {
    name = local.namespace
    labels = local.common_labels
    annotations = local.common_annotations
  }
}

# Secret creation with proper encoding
resource "kubernetes_secret" "auth" {
  metadata {
    name      = "${local.release_name}-auth"
    namespace = kubernetes_namespace.service.metadata[0].name
  }

  data = {
    username = base64encode(var.username)
    password = base64encode(var.password)
  }

  type = "Opaque"
}
```

### Helm Provider Patterns
```terraform
# Helm release with comprehensive configuration
resource "helm_release" "service" {
  name       = local.release_name
  namespace  = kubernetes_namespace.service.metadata[0].name
  repository = "https://charts.example.com"
  chart      = "service-chart"
  version    = local.chart_version

  # Timeout and wait configuration
  timeout          = local.helm_timeout
  wait             = local.helm_wait
  wait_for_jobs    = local.helm_wait_for_jobs
  cleanup_on_fail  = local.helm_cleanup_on_fail

  # Values from template
  values = [
    templatefile("${path.module}/values.yaml.tpl", {
      namespace     = local.namespace
      cpu_arch      = local.cpu_arch
      storage_class = local.storage_class
      # ... other variables
    })
  ]

  # Explicit dependencies
  depends_on = [
    kubernetes_namespace.service,
    kubernetes_secret.auth
  ]
}
```

### Random Provider for Password Generation
```terraform
resource "random_password" "admin" {
  length  = 32
  special = true

  # Ensure password meets complexity requirements
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
  min_special = 1
}

# Use generated password with fallback
locals {
  admin_password = var.admin_password != "" ? var.admin_password : random_password.admin.result
}
```

## Code Idioms

### Ternary Operator for Defaults
```terraform
# Pattern: condition ? true_value : false_value
local.cpu_arch = var.cpu_arch != "" ? var.cpu_arch : local.detected_arch
local.storage_class = var.storage_class != null ? var.storage_class : "default"
```

### Null Coalescing with try()
```terraform
# Safely access nested optional values
local.cpu_limit = try(var.service_overrides.service.cpu_limit, local.default_cpu_limit)
local.memory_limit = try(var.service_overrides.service.memory_limit, local.default_memory_limit)
```

### Merge for Configuration Composition
```terraform
# Merge multiple configuration sources
locals {
  final_config = merge(
    local.base_config,
    local.environment_config,
    var.user_overrides
  )
}
```

### For Expressions for Transformation
```terraform
# Transform list to map
locals {
  service_map = {
    for service in var.services :
    service.name => service.config
  }
}

# Filter and transform
locals {
  enabled_services = [
    for name, config in var.services :
    name if config.enabled
  ]
}
```

### Dynamic Blocks for Conditional Nesting
```terraform
resource "kubernetes_deployment" "app" {
  # ... other configuration

  spec {
    template {
      spec {
        # Conditionally add volumes
        dynamic "volume" {
          for_each = var.enable_persistence ? [1] : []
          content {
            name = "data"
            persistent_volume_claim {
              claim_name = kubernetes_persistent_volume_claim.data[0].metadata[0].name
            }
          }
        }

        # Conditionally add node affinity
        dynamic "affinity" {
          for_each = local.cpu_arch != "" ? [1] : []
          content {
            node_affinity {
              required_during_scheduling_ignored_during_execution {
                node_selector_term {
                  match_expressions {
                    key      = "kubernetes.io/arch"
                    operator = "In"
                    values   = [local.cpu_arch]
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
```

## Testing Patterns

### Terraform Test Structure
```hcl
# tests.tftest.hcl
run "validate_architecture_detection" {
  command = plan

  variables {
    cpu_arch = ""  # Test auto-detection
  }

  assert {
    condition     = local.detected_arch != ""
    error_message = "Architecture detection failed"
  }
}

run "validate_storage_selection" {
  command = plan

  variables {
    use_nfs_storage = true
    nfs_server_address = "192.168.1.100"
  }

  assert {
    condition     = local.storage_class == "nfs-csi"
    error_message = "Storage class selection incorrect"
  }
}
```

### Integration Test Pattern (Bash)
```bash
#!/bin/bash
set -euo pipefail

# Test service health
echo "Testing service health..."
kubectl get pods -n prod-traefik-system
kubectl wait --for=condition=ready pod -l app=traefik -n prod-traefik-system --timeout=300s

# Test ingress connectivity
echo "Testing ingress..."
curl -k https://traefik.prod.k3s.example.com/dashboard/
```

## Security Best Practices

### Sensitive Data Handling
```terraform
# Mark sensitive variables
variable "admin_password" {
  type      = string
  sensitive = true
}

# Mark sensitive outputs
output "admin_password" {
  value     = local.admin_password
  sensitive = true
}
```

### RBAC Pattern
```terraform
resource "kubernetes_service_account" "service" {
  metadata {
    name      = local.service_account_name
    namespace = kubernetes_namespace.service.metadata[0].name
  }
}

resource "kubernetes_role" "service" {
  metadata {
    name      = "${local.release_name}-role"
    namespace = kubernetes_namespace.service.metadata[0].name
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "services"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_role_binding" "service" {
  metadata {
    name      = "${local.release_name}-binding"
    namespace = kubernetes_namespace.service.metadata[0].name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.service.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.service.metadata[0].name
    namespace = kubernetes_namespace.service.metadata[0].name
  }
}
```

## Performance Optimization

### Resource Limits Pattern
```terraform
# MicroK8s mode optimization
locals {
  cpu_limit = var.enable_microk8s_mode ?
    local.system_defaults.microk8s_cpu_limit :
    local.system_defaults.cpu_limit_default

  memory_limit = var.enable_microk8s_mode ?
    local.system_defaults.microk8s_memory_limit :
    local.system_defaults.memory_limit_default
}
```

### Helm Timeout Management
```terraform
# Service-specific timeouts
locals {
  helm_timeout = coalesce(
    try(var.service_overrides.service.helm_timeout, null),
    var.helm_timeouts.service,
    var.default_helm_timeout
  )
}
```

## Error Handling

### Validation Blocks
```terraform
variable "cpu_arch" {
  type    = string
  default = ""

  validation {
    condition     = var.cpu_arch == "" || contains(["amd64", "arm64"], var.cpu_arch)
    error_message = "CPU architecture must be 'amd64', 'arm64', or empty for auto-detection."
  }
}

variable "metallb_address_pool" {
  type = string

  validation {
    condition     = can(regex("^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)-(...)$", var.metallb_address_pool))
    error_message = "MetalLB address pool must be in format 'IP1-IP2' with valid IPv4 addresses."
  }
}
```

### Dependency Management
```terraform
# Explicit dependencies for proper ordering
resource "helm_release" "service" {
  # ... configuration

  depends_on = [
    kubernetes_namespace.service,
    helm_release.traefik,  # Ensure ingress controller exists
    kubernetes_storage_class.nfs  # Ensure storage is ready
  ]
}
```

## Deprecation Handling

### Backward Compatibility Pattern
```terraform
# Support legacy variable with deprecation warning
variable "domain_name" {
  description = "DEPRECATED: Use base_domain and platform_name instead"
  type        = string
  default     = null
}

# Migration logic in locals
locals {
  # Use new variables if set, fall back to legacy
  effective_base_domain = var.base_domain != "local" ?
    var.base_domain :
    (var.domain_name != null ?
      split(".", var.domain_name)[1] :
      "local"
    )
}
```

## Python Code Standards (LDAP Auth)

### Security Patterns
```python
# Rate limiting
login_attempts = {}
MAX_ATTEMPTS = 5
BLOCK_TIME = 300

def check_rate_limit(ip):
    now = time.time()
    if ip in login_attempts:
        attempts, last_attempt = login_attempts[ip]
        if now - last_attempt < BLOCK_TIME and attempts >= MAX_ATTEMPTS:
            return False
    return True

# Input sanitization
def sanitize_username(username):
    if not username or len(username) > 64:
        return None
    if not re.match(r'^[a-zA-Z0-9._@-]+$', username):
        return None
    return username.strip()

# HMAC token signing
def create_signed_token(username):
    timestamp = str(int(time.time()))
    data = f"{username}:{timestamp}"
    signature = hmac.new(secret_key.encode(), data.encode(), hashlib.sha256).hexdigest()
    return base64.b64encode(f"{data}:{signature}".encode()).decode()
```

### Logging Pattern
```python
# Structured logging with security awareness
print(f"[INFO] Auth successful for: {username[:3]}***")  # Partial masking
print(f"[WARN] Rate limit exceeded for IP: {client_ip}")
print(f"[ERROR] LDAP Error: {str(e)[:100]}")  # Truncate errors
print(f"[DEBUG] Cookie set for domain: .{parent_domain}")
```

## JavaScript Testing Standards (K6)

### Test Structure Pattern
```javascript
// Configuration object
const config = {
  baseDomain: __ENV.BASE_DOMAIN || 'prod.k3s.example.com',
  endpoints: {
    service: __ENV.SERVICE_URL || 'http://service.domain.com'
  },
  timeout: '10s'
};

// Helper functions
function makeRequest(url, options = {}, tags = {}) {
  const params = {
    timeout: config.timeout,
    headers: { 'User-Agent': config.userAgent },
    tags: { name: url, ...tags },
    ...options
  };
  return http.get(url, params);
}

// Test scenarios
export default function() {
  const scenarios = [testScenario1, testScenario2];
  const scenario = scenarios[Math.floor(Math.random() * scenarios.length)];
  scenario();
  sleep(1);
}
```
