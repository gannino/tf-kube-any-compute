# Architecture Decisions & Coding Standards

**Document Status**: Active
**Last Updated**: 2026-02-15
**Maintainers**: Project maintainers and contributors

## Table of Contents

- [Core Architectural Principles](#core-architectural-principles)
- [Architecture Decision Records](#architecture-decision-records)
- [Coding Standards](#coding-standards)
- [Module Development Standards](#module-development-standards)
- [Integration Patterns](#integration-patterns)
- [Configuration Management](#configuration-management)
- [Documentation Standards](#documentation-standards)
- [Testing Standards](#testing-standards)
- [Security Standards](#security-standards)
- [Performance Standards](#performance-standards)

---

## Core Architectural Principles

### 1. No Hardcoding in Terraform Code

**Principle**: Never hardcode values in `.tf` files other than variables.tf to allow a simple deployment out of the box, with minimal services. All hardcoded values must be in `terraform.tfvars` files, with `locals.tf` providing smart selection and override logic.

**Rationale**:

- Keeps Terraform code clean and environment-agnostic
- Makes hardcoded values explicit and visible
- Enables environment-specific overrides via tfvars
- Maintains flexibility through locals override hierarchy
- Supports the 5-level configuration override system

**Implementation Pattern**:

```hcl
# ❌ BAD - Hardcoded in .tf file
resource "helm_release" "example" {
  timeout = 600  # Hardcoded in code!
}

# ❌ BAD - Hardcoded with variable default
variable "helm_timeout" {
  type    = number
  default = 600  # Still hardcoded, just moved!
}

# ✅ GOOD - Default in tfvars, smart selection in locals
# variables.tf - No default, just definition
variable "helm_timeout" {
  description = "Helm deployment timeout in seconds"
  type        = number
  # No default - forces explicit configuration or smart selection
}

# terraform.tfvars - Environment-specific values
helm_timeout = 600  # Explicit value for this environment

# locals.tf - Smart selection with override hierarchy
locals {
  helm_timeouts = {
    # Simple services: 180s (3 min)
    # Standard services: 600s (10 min)
    # Complex services: 900s (15 min)
    prometheus = coalesce(
      try(var.service_overrides.prometheus.helm_timeout, null),
      var.helm_timeout,  # From tfvars
      900  # Fallback default for complex service
    )

    redis = coalesce(
      try(var.service_overrides.redis.helm_timeout, null),
      var.helm_timeout,  # From tfvars
      180  # Fallback default for simple service
    )
  }
}
```

**When You Need "Hardcoded" Defaults**:

```hcl
# terraform.tfvars.example - Show the pattern
# Service-specific timeouts (seconds)
helm_timeout = 600  # Default timeout for most services

# Per-service overrides (if needed)
helm_timeouts = {
  prometheus = 900  # Complex service needs more time
  redis       = 180  # Simple service needs less
}

# locals.tf - Smart selection with fallbacks
locals {
  service_timeouts = {
    for service in ["prometheus", "redis", "grafana"] : service =>
      coalesce(
        try(var.helm_timeouts[service], null),
        var.helm_timeout,
        try(var.default_timeouts[service], null),
        600  # Absolute fallback
      )
  }
}

# Usage in module
module "prometheus" {
  timeout = local.service_timeouts.prometheus
}
```

**Examples of Proper "Hardcoding"**:

```hcl
# ✅ GOOD - Storage class profiles in tfvars
# terraform.tfvars
storage_profiles = {
  fast      = "nfs-csi-fast"
  reliable  = "nfs-csi-reliable"
  default   = "nfs-csi-safe"
}

# ✅ GOOD - Resource profiles in tfvars
# terraform.tfvars
resource_profiles = {
  small = {
    cpu_limit    = "200m"
    memory_limit = "256Mi"
  }
  medium = {
    cpu_limit    = "500m"
    memory_limit = "512Mi"
  }
  large = {
    cpu_limit    = "2000m"
    memory_limit = "2Gi"
  }
}

# locals.tf - Smart selection based on architecture
locals {
  resource_profile = var.cpu_arch == "arm64" ? "small" : "medium"

  resources = merge(
    var.resource_profiles[var.resource_profile],
    try(var.service_overrides.service.resources, {})
  )
}
```

**Key Benefits**:

1. **Explicit Configuration**: All "hardcoded" values visible in tfvars
2. **Environment Flexibility**: Different tfvars for dev/staging/prod
3. **Smart Overrides**: Locals provide intelligent selection
4. **Override Hierarchy**: Service-specific → User → Default → Fallback
5. **Code Reusability**: Same `.tf` files work across all environments

**Anti-Patterns to Avoid**:

```hcl
# ❌ BAD - Conditional hardcoding in .tf file
locals {
  timeout = var.service_name == "prometheus" ? 900 : 600  # Hardcoded logic!
}

# ✅ GOOD - Lookup from tfvars with fallback
locals {
  timeout = coalesce(
    var.service_timeouts[var.service_name],
    var.default_timeout,
    600  # Only as absolute fallback
  )
}

# ❌ BAD - Hardcoded defaults in variables.tf
variable "image_tag" {
  default = "latest"  # Hardcoded default!
}

# ✅ GOOD - No default, explicit in tfvars
variable "image_tag" {
  description = "Container image tag (set in tfvars)"
}

# terraform.tfvars
image_tag = "v1.2.3"  # Explicit version

# locals.tf - Smart version selection
locals {
  image_tag = coalesce(
    var.image_tag,
    var.default_image_tag,
    "latest"  # Only as absolute fallback
  )
}
```

**Documentation Requirement**:

When using tfvars + locals pattern:

1. **Document in terraform.tfvars.example** with inline comments
2. **Explain smart selection logic in locals.tf comments**
3. **Provide examples of different configurations**
4. **Show override hierarchy in module README**

```hcl
# terraform.tfvars.example
# ============================================================================
# Service Configuration Profiles
# ============================================================================

# Default resource profiles (adjust based on your cluster capacity)
resource_profiles = {
  small = {
    cpu_limit    = "200m"   # Suitable for ARM64/Raspberry Pi
    memory_limit = "256Mi"
  }
  medium = {
    cpu_limit    = "500m"   # Standard for AMD64 cloud
    memory_limit = "512Mi"
  }
  large = {
    cpu_limit    = "2000m"  # High-performance services
    memory_limit = "2Gi"
  }
}

# Select profile for this environment
# Options: "small" (ARM64), "medium" (AMD64), "large" (high-performance)
resource_profile = "medium"

# Per-service overrides (optional)
service_resources = {
  prometheus = "large"  # Monitoring needs more resources
  redis      = "small"  # Cache uses minimal resources
}

# locals.tf will merge these intelligently
```

### 2. Use Module Outputs for Integration

**Principle**: Always reference module outputs for service integration. Never hardcode service endpoints or configuration.

**Rationale**: Module outputs provide automatic service discovery, consistent naming, and workspace-aware configuration.

**Implementation**:

```hcl
# ❌ BAD - Hardcoded service reference
module "authelia" {
  redis_address = "redis.redis-system.svc.cluster.local"  # Hardcoded!
}

# ✅ GOOD - Module output reference
module "redis" {
  source = "./redis"
  # ... configuration ...
}

module "authelia" {
  source = "./helm-authelia"
  redis_enabled          = true
  redis_module_reference = module.redis[0].service_host  # Dynamic!
}
```

**Output Naming Convention**:

```hcl
# Service discovery outputs
output "service_host" {
  description = "Service hostname for service discovery (e.g., module.service_a[0].service_host)"
  value       = "${var.name}.${var.namespace}.svc.cluster.local"
}

output "service_port" {
  description = "Service port for service discovery"
  value       = var.service_port
}

# Configuration outputs
output "configuration_endpoint" {
  description = "Endpoint URL for configuration integration"
  value       = "https://${var.name}.${var.domain_name}"
}

# Credential outputs (sensitive)
output "client_secret" {
  description = "Client secret for OIDC integration"
  value       = random_password.client_secret.result
  sensitive   = true
}
```

### 3. Prefer Helm Releases for Smoother Upgrades

**Principle**: Use Helm releases whenever possible. Only use native Kubernetes resources when Helm charts don't exist or are inadequate.

**Rationale**: Helm provides:
- Standardized upgrade paths
- Rollback capabilities
- Version pinning for reproducibility
- Community-maintained best practices
- Simplified configuration management

**Decision Tree**:

```
Does a high-quality Helm chart exist?
├── Yes → Use Helm release
└── No → Is the service simple and stateless?
    ├── Yes → Consider native Kubernetes
    └── No → Evaluate if Helm chart should be created
```

**Implementation**:

```hcl
# ✅ GOOD - Helm release (preferred)
resource "helm_release" "prometheus" {
  name       = var.name
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.chart_version  # Pinned for reproducibility
  namespace  = kubernetes_namespace.this.metadata[0].name

  timeout    = var.helm_timeout
  wait       = var.helm_wait
  wait_for_jobs = var.helm_wait_for_jobs

  values = [
    templatefile("${path.module}/templates/values.yaml.tpl", {
      # Template variables
    })
  ]
}

# ⚠️ ACCEPTABLE - Native Kubernetes (when Helm unavailable)
resource "kubernetes_deployment" "redis" {
  metadata {
    name      = var.name
    namespace = kubernetes_namespace.this.metadata[0].name
  }

  spec {
    # ... deployment configuration
  }
}
```

**When to Use Native Kubernetes**:
- No Helm chart exists (Redis case)
- Helm chart is unmaintained or poor quality
- Service is simple and stateless
- Deep customization required that Helm doesn't support

**Documentation Requirement**: Always document in module README which pattern is used and why.

### 4. Comprehensive Override Documentation

**Principle**: All override mechanisms and outputs must be well-documented for future integrations.

**Rationale**: Clear documentation enables:
- Service-to-service integration patterns
- Future contributors understand extension points
- Consistent configuration across services
- Easier troubleshooting and debugging

**Implementation**:

```hcl
# variables.tf - Document all override capabilities
variable "storage_class" {
  description = "Storage class for persistent volumes. Auto-detected based on priority: user override > NFS CSI > HostPath > default storage class"
  type        = string
  default     = ""

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", var.storage_class)) || var.storage_class == ""
    error_message = "Storage class must be a valid Kubernetes storage class name or empty for auto-detection."
  }
}

# outputs.tf - Document output usage
output "service_endpoint" {
  description = "Internal service endpoint for module-to-module integration. Usage: module.service_a[0].service_endpoint"
  value       = "${var.name}.${var.namespace}.svc.cluster.local"
}

# README.md - Provide integration examples
## Module Integration

### Using Redis Module Output (Recommended)

```hcl
module "redis" {
  source = "./redis"
}

module "authelia" {
  source = "./helm-authelia"
  redis_module_reference = module.redis[0].service_host
}
```

**Benefits**:
- Automatic service discovery
- Workspace-aware configuration
- No manual hostname management
```

### 5. Configuration Override Hierarchy

**Principle**: Implement a 5-level configuration override hierarchy for maximum flexibility.

**Rationale**: Enables configuration at appropriate levels without code duplication.

**Hierarchy** (in priority order):

1. **System Defaults** - Hardcoded base values in module
2. **Service Defaults** - Per-service baseline settings
3. **User Variables** - terraform.tfvars configuration
4. **Service Overrides** - Fine-grained per-service control
5. **Auto-Detection** - Runtime cluster analysis

**Implementation**:

```hcl
# locals.tf - Configuration merge logic
locals {
  service_config = {
    # Level 5: Auto-detection (highest priority)
    cpu_arch = coalesce(
      # Level 4: Service override
      try(var.service_overrides.service.cpu_arch, null),
      # Level 3: User variable
      var.cpu_arch_override,
      # Auto-detection
      local.detected_cpu_arch,
      # Level 1: System default (lowest priority)
      "amd64"
    )

    storage_class = coalesce(
      try(var.service_overrides.service.storage_class, null),
      var.storage_class_override.service,
      local.storage_classes.default,
      "hostpath"
    )
  }
}
```

---

## Architecture Decision Records

### ADR Template

When making significant architectural decisions, document them using this template:

```markdown
## ADR-XXX: [Decision Title]

**Status**: Accepted | Proposed | Deprecated | Superseded
**Date**: YYYY-MM-DD
**Decision Makers**: @contributors
**Technical Story**: [Link to issue/PR]

### Context

[What is the issue that we're seeing that is motivating this decision or change?]

### Decision

[What is the change that we're proposing and/or doing?]

### Rationale

[Why are we making this design choice? What are the trade-offs? Include pros and cons.]

### Consequences

- [Positive consequences]
- [Negative consequences]
- [How this affects existing systems]

### Alternatives Considered

- [Alternative 1]
- [Alternative 2]
- [Why we rejected them]

### Implementation

[How is this decision implemented? Link to code, PRs, etc.]

### References

- [Related documentation]
- [Similar patterns in other projects]
```

### Key Architecture Decisions

#### ADR-001: Module Count Pattern for Conditional Deployment

**Status**: Accepted
**Date**: 2025-01-15

**Context**: Need to conditionally enable/disable services without complex conditional logic.

**Decision**: Use Terraform `count` pattern with boolean expression.

```hcl
module "service" {
  count = local.services_enabled.service ? 1 : 0
  source = "./helm-service"
}
```

**Rationale**:
- Simple and readable
- Works with Terraform 0.14+ features
- Enables service dependencies via `depends_on`

**Consequences**:
- Positive: Clean conditional logic
- Negative: Module outputs are lists, require `[0]` index
- Affects: All service modules

#### ADR-002: DNS Provider = Certificate Resolver Name

**Status**: Accepted
**Date**: 2025-02-01

**Context**: Need clear, unambiguous certificate resolver naming for multi-DNS deployments.

**Decision**: Name certificate resolvers after DNS providers (e.g., "cloudflare", "route53", "hurricane").

**Rationale**:
- No confusion about which DNS provider backs which resolver
- Easy per-service override
- Self-documenting configuration

**Consequences**:
- Positive: Clear certificate management
- Positive: Easy troubleshooting
- Negative: Longer resolver names than generic "wildcard"

#### ADR-003: Native Kubernetes for Simple Services

**Status**: Accepted
**Date**: 2026-02-10

**Context**: Redis deployment doesn't need Helm complexity.

**Decision**: Use native Kubernetes resources (`kubernetes_deployment`, `kubernetes_service`) for simple, stateless services.

**Rationale**:
- Simpler for basic deployments
- No Helm chart dependency
- Direct control over resources
- Easier customization

**Consequences**:
- Positive: Simpler code for simple services
- Negative: Manual upgrade management
- Affects: Redis, potential future simple services

#### ADR-004: Module Reference Pattern for Service Discovery

**Status**: Accepted
**Date**: 2026-02-12

**Context**: Services need to discover and reference each other without hardcoding.

**Decision**: Services expose outputs for integration; dependent services reference via module outputs.

**Rationale**:
- Automatic service discovery
- Workspace-aware configuration
- No hardcoded endpoints
- Consistent naming

**Consequences**:
- Positive: Automatic configuration
- Positive: Environment-agnostic
- Negative: Module dependency ordering
- Affects: Authelia → Redis, Headlamp → Authelia

---

## Coding Standards

### Terraform Style Guide

#### File Organization

```hcl
# ============================================================================
# Standard file organization for every module
# ============================================================================

# main.tf - Primary resources (release, namespace, core config)
# variables.tf - Input variables with validation
# outputs.tf - Output values with descriptions
# locals.tf - Local computations and logic
# version.tf - Provider and Terraform version requirements
# templates/values.yaml.tpl - Helm values template
# traefik-ingress.tf - Ingress configuration (if applicable)
# pvc.tf - Persistent volume claims (if applicable)
# limit_range.tf - Resource limits (if applicable)
# README.md - Comprehensive documentation
```

#### Naming Conventions

**Resources**:
```hcl
# ✅ GOOD - Descriptive, consistent
resource "helm_release" "this" { }
resource "kubernetes_namespace" "this" { }
resource "kubernetes_deployment" "redis" { }

# ❌ BAD - Inconsistent, unclear
resource "helm_release" "my_release" { }
resource "kubernetes_namespace" "ns" { }
```

**Variables**:
```hcl
# ✅ GOOD - Descriptive, snake_case
variable "storage_class" { }
variable "enable_servicemonitor" { }
variable "cpu_limit" { }

# ❌ BAD - Cryptic, inconsistent
variable "sc" { }
variable "enableSM" { }
variable "cpu" { }
```

**Locals**:
```hcl
# ✅ GOOD - Grouped, descriptive
locals {
  module_config = { }
  resource_limits = { }
  helm_config = { }
}

# ❌ BAD - Unclear, scattered
locals {
  config = { }
  limits = { }
  stuff = { }
}
```

#### Code Formatting

```hcl
# ✅ GOOD - Consistent spacing, aligned
resource "helm_release" "this" {
  name       = var.name
  repository = var.repository
  chart      = var.chart
  version    = var.version
  namespace  = kubernetes_namespace.this.metadata[0].name

  timeout = var.timeout
  wait    = var.wait

  values = [
    templatefile("${path.module}/templates/values.yaml.tpl", {
      namespace        = kubernetes_namespace.this.metadata[0].name
      storage_class    = var.storage_class
      cpu_limit       = var.cpu_limit
      memory_limit    = var.memory_limit
    })
  ]
}

# ❌ BAD - Inconsistent spacing, misaligned
resource "helm_release" "this" {
  name=var.name
  repository = var.repository
  chart=var.chart
  version = var.version
  namespace=kubernetes_namespace.this.metadata[0].name
  timeout = var.timeout
  wait = var.wait
  values = [templatefile("${path.module}/templates/values.yaml.tpl", {
    namespace=kubernetes_namespace.this.metadata[0].name
  storage_class=var.storage_class
  })]
}
```

#### Comments

```hcl
# ✅ GOOD - Clear, purposeful comments
# Create namespace with standard labels
resource "kubernetes_namespace" "this" {
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/part-of"    = "tf-kube-any-compute"
    }
  }
}

# Wait for all resources to be ready before considering deployment successful
# Extended timeout for complex services (Prometheus: 15min, Vault: 10min)
timeout = var.helm_timeout

# ❌ BAD - Obvious comments, noise
resource "kubernetes_namespace" "this" {
  metadata {
    name = var.namespace  # Set namespace
  }
}
# Set timeout
timeout = var.timeout  # Timeout value
```

---

## Module Development Standards

### Required Module Components

Every module MUST include:

#### 1. Main Configuration File (main.tf)

```hcl
# ============================================================================
# <SERVICE_NAME> Service Deployment
# ============================================================================

# Namespace creation
resource "kubernetes_namespace" "this" {
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/part-of"    = "tf-kube-any-compute"
      "app.kubernetes.io/name"       = var.name
    }
  }
}

# Primary deployment (Helm or native Kubernetes)
resource "helm_release" "this" {
  # ... configuration
}
```

#### 2. Variables File (variables.tf)

```hcl
# ============================================================================
# <SERVICE_NAME> Module Variables
# ============================================================================

# Core configuration
variable "name" {
  description = "Name of the <service> deployment"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", var.name))
    error_message = "Name must be a valid Kubernetes resource name."
  }
}

variable "namespace" {
  description = "Kubernetes namespace for <service>"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", var.namespace))
    error_message = "Namespace must be a valid Kubernetes namespace name."
  }
}

# Architecture configuration
variable "cpu_arch" {
  description = "CPU architecture for node selection (amd64, arm64)"
  type        = string
  default     = "amd64"

  validation {
    condition     = contains(["amd64", "arm64"], var.cpu_arch)
    error_message = "CPU architecture must be either 'amd64' or 'arm64'."
  }
}

# Resource configuration
variable "cpu_limit" {
  description = "CPU limit for containers (e.g., '500m', '1')"
  type        = string
  default     = "500m"

  validation {
    condition     = can(regex("^[0-9]+(m)?$", var.cpu_limit))
    error_message = "CPU limit must be in milliscores (e.g., 500m) or cores (e.g., 1)."
  }
}

# ... other variables
```

#### 3. Outputs File (outputs.tf)

```hcl
# ============================================================================
# <SERVICE_NAME> Module Outputs
# ============================================================================

# Basic outputs
output "namespace" {
  description = "Kubernetes namespace where <service> is deployed"
  value       = kubernetes_namespace.this.metadata[0].name
}

output "service_name" {
  description = "Name of the <service> deployment"
  value       = var.name
}

# Service discovery outputs (CRITICAL FOR INTEGRATION)
output "service_host" {
  description = "Service hostname for service discovery (used by other modules via module.service[0].service_host)"
  value       = "${var.name}.${var.namespace}.svc.cluster.local"
}

output "service_port" {
  description = "Service port for service discovery"
  value       = var.service_port
}

# Configuration outputs
output "configuration_endpoint" {
  description = "Endpoint URL for external configuration and integration"
  value       = var.enable_ingress ? "https://${var.name}.${var.domain_name}" : null
}

# Credential outputs (when applicable)
output "client_secret" {
  description = "Client secret for OIDC/OAuth integration (use module.service[0].client_secret)"
  value       = try(random_password.client_secret.result, null)
  sensitive   = true
}
```

#### 4. Locals File (locals.tf)

```hcl
# ============================================================================
# <SERVICE_NAME> Local Values
# ============================================================================

locals {
  # Module configuration
  module_config = {
    namespace = var.namespace
    name      = var.name
  }

  # Common labels for all resources
  common_labels = {
    "app.kubernetes.io/managed-by" = "terraform"
    "app.kubernetes.io/part-of"    = "tf-kube-any-compute"
    "app.kubernetes.io/name"       = var.name
    "app.kubernetes.io/component"  = "<service-type>"
  }

  # Resource configuration
  resources = {
    limits = {
      cpu    = var.cpu_limit
      memory = var.memory_limit
    }
    requests = {
      cpu    = var.cpu_request
      memory = var.memory_request
    }
  }

  # Computed values
  service_endpoint = "${var.name}.${var.namespace}.svc.cluster.local"
}
```

#### 5. Version File (version.tf)

```hcl
# ============================================================================
# Terraform and Provider Version Requirements
# ============================================================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}
```

#### 6. Comprehensive README (README.md)

Required sections:

1. **Overview** - Brief service description
2. **Features** - Key capabilities with emoji icons
3. **Usage Examples** - Basic and advanced configurations
4. **Configuration Variables** - Complete table (auto-generated via terraform-docs)
5. **Outputs** - Complete table with usage examples
6. **Architecture Support** - ARM64/AMD64/mixed cluster
7. **Troubleshooting** - Common issues and solutions
8. **Integration Patterns** - How other services integrate with this one

#### 7. Helm Values Template (templates/values.yaml.tpl)

```yaml
# ============================================================================
# <SERVICE_NAME> Helm Values Template
# ============================================================================

# Global configuration
global:
  serviceName: ${service_name}
  namespace: ${namespace}

# Image configuration
image:
  repository: ${image_repository}
  tag: ${image_tag}
  pullPolicy: IfNotPresent

# Resource configuration
resources:
  limits:
    cpu: ${cpu_limit}
    memory: ${memory_limit}
  requests:
    cpu: ${cpu_request}
    memory: ${memory_request}

# Storage configuration
%{ if storage_class != "" ~}
persistence:
  enabled: true
  storageClass: ${storage_class}
  size: ${storage_size}
%{ endif ~}

# Service configuration
service:
  type: ClusterIP
  port: ${service_port}

# Ingress configuration
%{ if enable_ingress ~}
ingress:
  enabled: true
  className: traefik
  annotations:
    traefik.ingress.kubernetes.io/router.tls: "true"
    traefik.ingress.kubernetes.io/router.tls.certresolver: ${cert_resolver}
  hosts:
    - host: ${service_name}.${domain_name}
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: ${service_name}-tls
      hosts:
        - ${service_name}.${domain_name}
%{ endif ~}
```

### Optional Module Components

These files are included when applicable:

- **traefik-ingress.tf** - Ingress configuration using Traefik
- **pvc.tf** - Persistent volume claims
- **limit_range.tf** - Resource limit ranges
- **servicemonitor.tf** - Prometheus ServiceMonitor
- **rbac.tf** - RBAC resources
- **configmap.tf** - ConfigMap resources
- **secret.tf** - Secret resources

---

## Integration Patterns

### Service-to-Service Integration

#### Pattern 1: Module Output Reference (Preferred)

```hcl
# Service A exposes output
module "redis" {
  source = "./redis"

  output "service_host" {
    description = "Redis service hostname for integration"
    value       = "${var.name}.${var.namespace}.svc.cluster.local"
  }
}

# Service B references Service A output
module "authelia" {
  source = "./helm-authelia"

  redis_enabled          = true
  redis_module_reference = module.redis[0].service_host
}
```

**Documentation Requirements**:

1. Document output in Service A README with usage example
2. Document integration in Service B README
3. Provide alternative manual configuration pattern

#### Pattern 2: Manual Configuration (Fallback)

```hcl
# When module reference not available
module "authelia" {
  source = "./helm-authelia"

  redis_enabled = true
  redis_address = "redis.redis-system.svc.cluster.local"  # Manual
  redis_port    = 6379
}
```

**Documentation Requirements**:

1. Clearly mark as fallback pattern
2. Explain when to use this vs module reference
3. Provide troubleshooting tips for manual configuration

### Multi-Service Integration Example

```hcl
# Monitoring stack integration
module "prometheus" {
  source = "./helm-prometheus-stack"
}

module "grafana" {
  source = "./helm-grafana"

  # Use Prometheus output for datasources
  prometheus_url = module.prometheus[0].service_endpoint
}

module "alertmanager" {
  source = "./helm-alertmanager"

  # Alertmanager integrates with both
  prometheus_url = module.prometheus[0].service_endpoint
  grafana_url    = module.grafana[0].configuration_endpoint
}
```

---

## Configuration Management

### Variable Standards

#### Variable Definition

All variables MUST include:

1. **Description**: Clear, concise explanation of purpose
2. **Type**: Explicit type declaration
3. **Default**: Default value (when appropriate)
4. **Validation**: Input validation (when applicable)

```hcl
variable "storage_class" {
  description = "Storage class for persistent volumes. Auto-detected based on priority chain."
  type        = string
  default     = ""

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", var.storage_class)) || var.storage_class == ""
    error_message = "Storage class must be a valid Kubernetes storage class name or empty for auto-detection."
  }
}
```

#### Variable Naming

- Use **snake_case** for variable names
- Be **descriptive** but **concise**
- Avoid **abbreviations** unless widely understood
- Use **consistent** naming across modules

```hcl
# ✅ GOOD
variable "storage_class" { }
variable "enable_servicemonitor" { }
variable "cpu_limit" { }
variable "helm_timeout" { }

# ❌ BAD
variable "sc" { }
variable "enableSM" { }
variable "cpu" { }
variable "timeout" { }
```

### Output Standards

#### Output Definition

All outputs MUST include:

1. **Description**: Clear explanation of value and usage
2. **Value**: Output value
3. **Sensitive** flag: When output contains secrets

```hcl
# Service discovery output
output "service_host" {
  description = "Service hostname for module-to-module integration. Usage: module.service[0].service_host"
  value       = "${var.name}.${var.namespace}.svc.cluster.local"
}

# Sensitive output
output "admin_password" {
  description = "Admin password for initial login (use terraform output to retrieve)"
  value       = random_password.admin.result
  sensitive   = true
}
```

#### Output Naming

- Use **snake_case** for output names
- Be **descriptive** about purpose
- Include **usage context** in description
- Expose **integration points** as outputs

```hcl
# ✅ GOOD - Descriptive, includes usage context
output "service_host" {
  description = "Service hostname for module-to-module integration. Usage: module.service[0].service_host"
  value       = "${var.name}.${var.namespace}.svc.cluster.local"
}

output "client_secret" {
  description = "OIDC client secret for authentication integration. Use in oidc_config.client_secret"
  value       = random_password.client_secret.result
  sensitive   = true
}

# ❌ BAD - Cryptic, no usage context
output "host" {
  description = "Service host"
  value       = "${var.name}.${var.namespace}.svc.cluster.local"
}

output "secret" {
  description = "Secret"
  value       = random_password.client_secret.result
  sensitive   = true
}
```

### Configuration Override Standards

#### Service Override Object

```hcl
variable "service_overrides" {
  description = "Per-service configuration overrides (highest priority in hierarchy)"
  type = map(object({
    # Core configuration
    cpu_arch      = optional(string)
    storage_class = optional(string)
    storage_size  = optional(string)

    # Resource limits
    cpu_limit      = optional(string)
    memory_limit   = optional(string)
    cpu_request    = optional(string)
    memory_request = optional(string)

    # Helm configuration
    chart_version = optional(string)
    helm_timeout  = optional(number)

    # Service-specific
    enable_feature = optional(bool)
  }))
  default = {}
}
```

#### Override Hierarchy Implementation

```hcl
locals {
  service_config = {
    # 5-level hierarchy in action
    cpu_arch = coalesce(
      # Level 4: Service override (highest)
      try(var.service_overrides.service.cpu_arch, null),
      # Level 3: User variable
      var.cpu_arch_override,
      # Level 2: Service default (implicit in var)
      var.cpu_arch,
      # Level 1: System default
      "amd64"
    )

    storage_class = coalesce(
      try(var.service_overrides.service.storage_class, null),
      var.storage_class_override.service,
      local.detected_storage_class,
      "hostpath"
    )
  }
}
```

---

## Documentation Standards

### Module README Requirements

Every module README MUST include:

#### 1. Overview Section

```markdown
# <Service Name> Module

Brief description of the service and its purpose in the infrastructure.
```

#### 2. Features Section

```markdown
## Features

- **🚀 Feature 1**: Description of capability
- **🔒 Feature 2**: Description of capability
- **📊 Feature 3**: Description of capability
```

#### 3. Usage Section

```markdown
## Usage

### Basic Configuration

```hcl
module "service" {
  source = "./helm-service"
  # minimal required configuration
}
```

### Advanced Configuration

```hcl
module "service" {
  source = "./helm-service"

  cpu_arch      = "arm64"
  storage_class = "nfs-csi-safe"
  enable_feature = true
}
```
```

#### 4. Integration Section (Critical)

```markdown
## Module Integration

### Using Service Outputs (Recommended)

```hcl
module "service_a" {
  source = "./helm-service-a"
}

module "service_b" {
  source = "./helm-service-b"
  dependency_reference = module.service_a[0].service_host
}
```

**Benefits**:
- Automatic service discovery
- Workspace-aware configuration
- No manual hostname management

### Manual Configuration (Alternative)

```hcl
module "service_b" {
  source = "./helm-service-b"
  dependency_address = "service-a.namespace.svc.cluster.local"
}
```
```

#### 5. Architecture Support Section

```markdown
## Architecture Support

- ✅ **AMD64** (x86_64): Full support
- ✅ **ARM64** (aarch64): Full support
- ✅ **Mixed Clusters**: Supported

### Resource Recommendations

**AMD64**:
- CPU: 500m - 2000m
- Memory: 512Mi - 4Gi

**ARM64** (Raspberry Pi):
- CPU: 200m - 1000m
- Memory: 256Mi - 2Gi
```

#### 6. Troubleshooting Section

```markdown
## Troubleshooting

### Service Not Starting

**Problem**: Pods in CrashLoopBackOff state

**Solutions**:
1. Check resource limits: `kubectl describe pod -n <namespace>`
2. Review logs: `kubectl logs -n <namespace> <pod-name>`
3. Verify storage class: `kubectl get storageclass`

### Common Issues

1. **Out of Memory**
   - Symptom: Pod OOMKilled
   - Fix: Increase `memory_limit`

2. **Storage Access Denied**
   - Symptom: PVC in pending state
   - Fix: Verify storage class exists and is default
```

### terraform-docs Configuration

```yaml
# .terraform-docs.yml
version: "~> 0.16"

formatter: "markdown table"

settings:
  anchor: true
  default: true
  description: false
  escape: true
  hide-empty: false
  indent: 2
  required: true
  sensitive: true
  type: true

sections:
  show:
    - header
    - inputs
    - outputs
    - providers
    - requirements

output:
  file: "README.md"
  mode: inject"
  template: |
    <!-- BEGIN_TF_DOCS -->
    {{ .Content }}
    <!-- END_TF_DOCS -->
```

---

## Testing Standards

### Unit Testing Requirements

Every module MUST have unit tests covering:

1. **Configuration Logic**: Override hierarchy, default values
2. **Variable Validation**: Input validation rules
3. **Resource Creation**: Basic resource creation
4. **Output Values**: Output correctness

```hcl
# tests-service.tftest.hcl
run "test_service_configuration" {
  command = plan

  variables {
    cpu_arch = "arm64"
    services = {
      service = true
    }
  }

  assert {
    condition     = local.services_enabled.service == true
    error_message = "Service should be enabled"
  }

  assert {
    condition     = local.service_configs.service.cpu_arch == "arm64"
    error_message = "Service should use ARM64 architecture"
  }
}
```

### Scenario Testing Requirements

Test common deployment scenarios:

1. **ARM64 Raspberry Pi**: Resource-constrained environment
2. **AMD64 Cloud**: Standard cloud deployment
3. **Mixed Cluster**: Multi-architecture environment
4. **MicroK8s**: Specific distribution configuration

```hcl
# test-scenarios.tftest.hcl
run "test_raspberry_pi_deployment" {
  command = plan

  variables {
    cpu_arch = "arm64"
    enable_resource_limits = true

    services = {
      service = true
    }

    service_overrides = {
      service = {
        cpu_limit    = "200m"
        memory_limit = "256Mi"
      }
    }
  }

  assert {
    condition     = local.resource_limits.cpu_limit == "200m"
    error_message = "ARM64 resource limits not applied correctly"
  }
}
```

### Integration Testing Requirements

When applicable, test service integration:

```hcl
run "test_service_integration" {
  command = apply

  variables {
    services = {
      service_a = true
      service_b = true
    }
  }

  # Verify Service B can reference Service A
  assert {
    condition     = module.service_b[0].dependency_reference != null
    error_message = "Service B should reference Service A output"
  }
}
```

---

## Security Standards

### Secret Management

#### Never Hardcode Secrets

```hcl
# ❌ BAD - Hardcoded secret
resource "kubernetes_secret" "db" {
  data = {
    password = "my-password-123"  # NEVER DO THIS!
  }
}

# ✅ GOOD - Use random resource or external secret
resource "random_password" "db" {
  length  = 32
  special = false
}

resource "kubernetes_secret" "db" {
  data = {
    password = random_password.db.result
  }
}
```

#### Mark Sensitive Outputs

```hcl
output "admin_password" {
  description = "Admin password (retrieve via: terraform output admin_password)"
  value       = random_password.admin.result
  sensitive   = true  # ALWAYS mark secrets as sensitive
}
```

#### Document Secret Retrieval

```markdown
## Accessing Credentials

After deployment, retrieve credentials:

```bash
terraform output admin_password
```

**Important**: Store credentials securely. Consider using a secret manager (Vault) for production.
```

### RBAC Standards

#### Principle of Least Privilege

```hcl
# ✅ GOOD - Minimal required permissions
resource "kubernetes_role" "service" {
  rules {
    api_groups = [""]
    resources  = ["configmaps"]
    verbs      = ["get", "list", "watch"]  # Only what's needed
  }
}

# ❌ BAD - Overly permissive
resource "kubernetes_role" "service" {
  rules {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["*"]  # NEVER use wildcard permissions
  }
}
```

### Network Policy Standards

#### Default Deny, Explicit Allow

```hcl
# ✅ GOOD - Explicit allow rules
resource "kubernetes_network_policy" "service" {
  policy_types = ["Ingress", "Egress"]

  ingress {
    from {
      namespace_selector {
        match_labels = {
          name = "allowed-namespace"
        }
      }
    }
  }

  egress {
    to {
      pod_selector {
        match_labels = {
          app = "allowed-service"
        }
      }
    }
  }
}
```

---

## Performance Standards

### Resource Limit Standards

#### Default Resource Limits

All services MUST have resource limits:

```hcl
variable "cpu_limit" {
  description = "CPU limit for containers"
  type        = string
  default     = "500m"  # Sensible default
}

variable "memory_limit" {
  description = "Memory limit for containers"
  type        = string
  default     = "512Mi"  # Sensible default
}
```

#### Architecture-Aware Limits

Provide architecture-specific recommendations:

```hcl
# ARM64 (Raspberry Pi)
cpu_limit    = "200m"
memory_limit = "256Mi"

# AMD64 (Cloud/Server)
cpu_limit    = "1000m"
memory_limit = "1Gi"
```

### Helm Timeout Standards

#### Service-Specific Timeouts

```hcl
# Simple services: 180s (3 min)
# Standard services: 600s (10 min)
# Complex services: 900s (15 min)
# Very complex services: 1800s (30 min)

variable "helm_timeout" {
  description = "Helm deployment timeout in seconds (Simple: 180s, Standard: 600s, Complex: 900s)"
  type        = number
  default     = 600

  validation {
    condition     = var.helm_timeout >= 60 && var.helm_timeout <= 3600
    error_message = "Helm timeout must be between 60 and 3600 seconds."
  }
}
```

---

## Compliance Checklist

Before submitting a module for review, ensure:

### Code Standards

- [ ] No hardcoded values (all configurable via variables)
- [ ] Module outputs defined for integration points
- [ ] Helm releases preferred (native Kubernetes justified)
- [ ] Variables have descriptions, types, defaults
- [ ] Variables have validation where appropriate
- [ ] Outputs have descriptions and usage examples
- [ ] Code follows naming conventions
- [ ] Code is formatted (`terraform fmt`)
- [ ] No obvious security issues
- [ ] Resource limits defined

### Documentation Standards

- [ ] README.md has all required sections
- [ ] Features documented with emoji icons
- [ ] Usage examples provided (basic and advanced)
- [ ] Integration patterns documented
- [ ] Architecture support clearly stated
- [ ] Troubleshooting section covers common issues
- [ ] Configuration variables documented
- [ ] Outputs documented with usage examples
- [ ] Sensitive outputs clearly marked

### Testing Standards

- [ ] Unit tests cover configuration logic
- [ ] Unit tests cover variable validation
- [ ] Scenario tests cover ARM64/AMD64
- [ ] Integration tests cover service dependencies (if applicable)
- [ ] All tests pass (`terraform test`)

### Integration Standards

- [ ] Module outputs for service discovery
- [ ] Service override hierarchy implemented
- [ ] Workspace-aware configuration (if applicable)
- [ ] Kubeconfig detection pattern (if applicable)
- [ ] Integration examples in README

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-02-15 | Initial document |

---

## Related Documentation

- **[CLAUDE.md](../../CLAUDE.md)**: AI assistant guidance and architectural patterns
- **[CONTRIBUTING.md](../../CONTRIBUTING.md)**: Contribution guidelines
- **[CONTRIBUTOR-ROADMAP.md](../../CONTRIBUTOR-ROADMAP.md)**: Strategic improvement roadmap
- **[docs/development/SERVICE-INTEGRATION-TEMPLATE.md](SERVICE-INTEGRATION-TEMPLATE.md)**: Module integration checklist

---

**Maintainers**: Keep this document updated as architectural decisions are made and coding standards evolve.
