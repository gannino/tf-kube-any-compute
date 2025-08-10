# 🚀 Service Integration Template for tf-kube-any-compute

## 📋 **Overview**

This template provides a standardized approach for integrating new services into the tf-kube-any-compute infrastructure. Follow this guide to ensure consistency, quality, and compatibility with the existing architecture.

## 🏗️ **Service Integration Checklist**

### **Phase 1: Planning & Design**

- [ ] **Service Research**
  - [ ] Verify Helm chart availability and quality
  - [ ] Check ARM64/AMD64 architecture support
  - [ ] Identify resource requirements and constraints
  - [ ] Document service dependencies and integrations

- [ ] **Architecture Compatibility**
  - [ ] Confirm mixed-cluster support requirements
  - [ ] Plan storage requirements (NFS vs HostPath)
  - [ ] Design ingress and networking integration
  - [ ] Consider security and policy implications

- [ ] **Configuration Design**
  - [ ] Define service-specific variables
  - [ ] Plan override hierarchy integration
  - [ ] Design Helm configuration options
  - [ ] Plan resource limit strategies

### **Phase 2: Implementation**

- [ ] **Module Structure**
  - [ ] Create `helm-<service>/` directory
  - [ ] Implement standard module files (see structure below)
  - [ ] Add service to main.tf with proper dependencies
  - [ ] Update variables.tf with service configuration

- [ ] **Testing Implementation**
  - [ ] Add unit tests for service logic
  - [ ] Create scenario tests for different configurations
  - [ ] Implement integration tests for live deployment
  - [ ] Add service-specific diagnostic checks

- [ ] **Documentation**
  - [ ] Create service README with examples
  - [ ] Add troubleshooting guide
  - [ ] Update main project documentation
  - [ ] Document configuration options

### **Phase 3: Validation**

- [ ] **Quality Assurance**
  - [ ] Run complete test suite (`make test-all`)
  - [ ] Validate on ARM64 and AMD64 architectures
  - [ ] Test resource-constrained scenarios
  - [ ] Verify security compliance

- [ ] **Integration Testing**
  - [ ] Deploy on test cluster
  - [ ] Validate service functionality
  - [ ] Test upgrade/rollback scenarios
  - [ ] Verify monitoring and observability

## 📁 **Standard Module Structure**

```
helm-<service>/
├── README.md                    # Service-specific documentation
├── main.tf                      # Primary Helm release configuration
├── variables.tf                 # Service input variables
├── outputs.tf                   # Service outputs
├── locals.tf                    # Local computations and logic
├── version.tf                   # Provider version constraints
├── limit_range.tf               # Resource limits configuration
├── values.yaml.tpl              # Helm values template
├── traefik-ingress.tf          # Ingress configuration (if applicable)
├── pvc.tf                      # Storage configuration (if applicable)
└── templates/                   # Additional templates
    └── service-values.yaml.tpl  # Service-specific value templates
```

## 🔧 **Implementation Templates**

### **1. Main Module Configuration (main.tf)**

```hcl
# ============================================================================
# <SERVICE_NAME> Helm Deployment
# ============================================================================

resource "helm_release" "service" {
  name       = var.name
  repository = var.helm_repository
  chart      = var.helm_chart
  version    = var.helm_chart_version
  namespace  = var.namespace

  # Create namespace if it doesn't exist
  create_namespace = true

  # Helm configuration with service overrides
  timeout          = var.helm_timeout
  disable_webhooks = var.helm_disable_webhooks
  skip_crds        = var.helm_skip_crds
  replace          = var.helm_replace
  force_update     = var.helm_force_update
  cleanup_on_fail  = var.helm_cleanup_on_fail
  wait             = var.helm_wait
  wait_for_jobs    = var.helm_wait_for_jobs

  # Architecture-aware node selection
  dynamic "set" {
    for_each = var.disable_arch_scheduling ? [] : [1]
    content {
      name  = "nodeSelector.kubernetes\\.io/arch"
      value = var.cpu_arch
    }
  }

  # Resource limits
  dynamic "set" {
    for_each = var.cpu_limit != "" ? [1] : []
    content {
      name  = "resources.limits.cpu"
      value = var.cpu_limit
    }
  }

  dynamic "set" {
    for_each = var.memory_limit != "" ? [1] : []
    content {
      name  = "resources.limits.memory"
      value = var.memory_limit
    }
  }

  # Storage configuration
  dynamic "set" {
    for_each = var.storage_class != "" ? [1] : []
    content {
      name  = "persistence.storageClass"
      value = var.storage_class
    }
  }

  # Service-specific values
  values = [
    templatefile("${path.module}/values.yaml.tpl", {
      service_name     = var.name
      namespace        = var.namespace
      domain_name      = var.domain_name
      cpu_arch         = var.cpu_arch
      storage_class    = var.storage_class
      storage_size     = var.storage_size
      # Add service-specific variables
    })
  ]

  depends_on = [
    kubernetes_namespace.service,
    kubernetes_limit_range.service
  ]
}

# Namespace creation
resource "kubernetes_namespace" "service" {
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/part-of"    = "tf-kube-any-compute"
      "service"                      = var.name
    }
  }
}
```

### **2. Variables Configuration (variables.tf)**

```hcl
# ============================================================================
# <SERVICE_NAME> Module Variables
# ============================================================================

# Core configuration
variable "name" {
  description = "Name of the <service> deployment"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for <service>"
  type        = string
}

variable "domain_name" {
  description = "Domain name for ingress configuration"
  type        = string
}

# Architecture and placement
variable "cpu_arch" {
  description = "CPU architecture for node selection"
  type        = string
  default     = "amd64"

  validation {
    condition     = contains(["amd64", "arm64"], var.cpu_arch)
    error_message = "CPU architecture must be either 'amd64' or 'arm64'."
  }
}

variable "disable_arch_scheduling" {
  description = "Disable architecture-based node scheduling"
  type        = bool
  default     = false
}

# Helm configuration
variable "helm_repository" {
  description = "Helm repository URL"
  type        = string
  default     = "https://charts.example.com"
}

variable "helm_chart" {
  description = "Helm chart name"
  type        = string
  default     = "<service-chart>"
}

variable "helm_chart_version" {
  description = "Helm chart version"
  type        = string
  default     = ""
}

variable "helm_timeout" {
  description = "Helm deployment timeout in seconds"
  type        = number
  default     = 600

  validation {
    condition     = var.helm_timeout >= 60 && var.helm_timeout <= 3600
    error_message = "Helm timeout must be between 60 and 3600 seconds."
  }
}

variable "helm_disable_webhooks" {
  description = "Disable Helm webhooks"
  type        = bool
  default     = true
}

variable "helm_skip_crds" {
  description = "Skip CRD installation"
  type        = bool
  default     = false
}

variable "helm_replace" {
  description = "Replace existing resources"
  type        = bool
  default     = false
}

variable "helm_force_update" {
  description = "Force Helm update"
  type        = bool
  default     = true
}

variable "helm_cleanup_on_fail" {
  description = "Cleanup resources on deployment failure"
  type        = bool
  default     = true
}

variable "helm_wait" {
  description = "Wait for deployment to be ready"
  type        = bool
  default     = true
}

variable "helm_wait_for_jobs" {
  description = "Wait for jobs to complete"
  type        = bool
  default     = true
}

# Resource configuration
variable "cpu_limit" {
  description = "CPU limit for containers"
  type        = string
  default     = "500m"
}

variable "memory_limit" {
  description = "Memory limit for containers"
  type        = string
  default     = "512Mi"
}

variable "cpu_request" {
  description = "CPU request for containers"
  type        = string
  default     = "100m"
}

variable "memory_request" {
  description = "Memory request for containers"
  type        = string
  default     = "128Mi"
}

# Storage configuration
variable "storage_class" {
  description = "Storage class for persistent volumes"
  type        = string
  default     = ""
}

variable "storage_size" {
  description = "Storage size for persistent volumes"
  type        = string
  default     = "5Gi"
}

# Service-specific variables
variable "enable_ingress" {
  description = "Enable ingress for <service>"
  type        = bool
  default     = true
}

variable "ingress_cert_resolver" {
  description = "Certificate resolver for ingress"
  type        = string
  default     = "wildcard"
}

# Add service-specific variables here
```

### **3. Outputs Configuration (outputs.tf)**

```hcl
# ============================================================================
# <SERVICE_NAME> Module Outputs
# ============================================================================

output "namespace" {
  description = "Kubernetes namespace where <service> is deployed"
  value       = kubernetes_namespace.service.metadata[0].name
}

output "service_name" {
  description = "Name of the <service> service"
  value       = var.name
}

output "helm_release_name" {
  description = "Name of the Helm release"
  value       = helm_release.service.name
}

output "helm_release_status" {
  description = "Status of the Helm release"
  value       = helm_release.service.status
}

output "service_url" {
  description = "URL to access <service>"
  value       = var.enable_ingress ? "https://${var.name}.${var.domain_name}" : ""
}

# Service-specific outputs
output "service_endpoint" {
  description = "Internal service endpoint"
  value       = "${var.name}.${var.namespace}.svc.cluster.local"
}

# Add service-specific outputs here
```

### **4. Helm Values Template (values.yaml.tpl)**

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
  repository: <service-image>
  tag: "latest"
  pullPolicy: IfNotPresent

# Architecture-specific configuration
%{ if cpu_arch == "arm64" ~}
nodeSelector:
  kubernetes.io/arch: arm64
%{ else ~}
nodeSelector:
  kubernetes.io/arch: amd64
%{ endif ~}

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
  port: 80

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

# Security context
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 1000

# Pod security context
podSecurityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 1000

# Service-specific configuration
<service>:
  # Add service-specific configuration here
  config:
    key: value
```

### **5. Integration with Main Module**

Add to `main.tf`:

```hcl
module "<service>" {
  count  = local.services_enabled.<service> ? 1 : 0
  source = "./helm-<service>"
  providers = {
    kubernetes = kubernetes
    helm       = helm
  }

  name                    = "${local.workspace_prefix}-<service>"
  namespace               = "${local.workspace_prefix}-<service>-system"
  domain_name             = local.domain
  cpu_arch                = local.service_configs.<service>.cpu_arch
  disable_arch_scheduling = local.final_disable_arch_scheduling.<service>

  # Storage configuration
  storage_class = local.service_configs.<service>.storage_class
  storage_size  = local.storage_sizes.<service>

  # Resource limits
  cpu_limit      = var.enable_resource_limits ? var.default_cpu_limit : "1000m"
  memory_limit   = var.enable_resource_limits ? var.default_memory_limit : "1Gi"
  cpu_request    = "100m"
  memory_request = "128Mi"

  # Helm configuration
  helm_timeout          = local.helm_configs.<service>.timeout
  helm_disable_webhooks = local.helm_configs.<service>.disable_webhooks
  helm_skip_crds        = local.helm_configs.<service>.skip_crds
  helm_replace          = local.helm_configs.<service>.replace
  helm_force_update     = local.helm_configs.<service>.force_update
  helm_cleanup_on_fail  = local.helm_configs.<service>.cleanup_on_fail
  helm_wait             = local.helm_configs.<service>.wait
  helm_wait_for_jobs    = local.helm_configs.<service>.wait_for_jobs

  # Service-specific configuration
  enable_ingress         = true
  ingress_cert_resolver  = local.cert_resolvers.<service>

  depends_on = [
    # Add dependencies here
    module.traefik,
    module.nfs_csi,
    module.host_path
  ]
}
```

Add to `variables.tf`:

```hcl
# Service enablement
variable "enable_<service>" {
  description = "Enable <service> deployment"
  type        = bool
  default     = null
}

# Service overrides in service_overrides object
<service> = optional(object({
  # Core configuration
  cpu_arch      = optional(string)
  chart_version = optional(string)
  storage_class = optional(string)
  storage_size  = optional(string)

  # Service-specific settings
  enable_feature = optional(bool)

  # Resource limits
  cpu_limit      = optional(string)
  memory_limit   = optional(string)
  cpu_request    = optional(string)
  memory_request = optional(string)

  # Helm deployment options
  helm_timeout          = optional(number)
  helm_wait             = optional(bool)
  helm_wait_for_jobs    = optional(bool)
  helm_disable_webhooks = optional(bool)
  helm_skip_crds        = optional(bool)
  helm_replace          = optional(bool)
  helm_force_update     = optional(bool)
  helm_cleanup_on_fail  = optional(bool)
}))
```

Add to `locals.tf`:

```hcl
# Service enablement
<service> = coalesce(var.enable_<service>, var.services.<service>, true)

# Service configuration
<service> = {
  cpu_arch      = coalesce(try(var.service_overrides.<service>.cpu_arch, null), local.most_common_worker_arch, local.most_common_arch, "amd64")
  storage_class = coalesce(try(var.service_overrides.<service>.storage_class, null), var.storage_class_override.<service>, local.storage_classes.default, "hostpath")
  helm_timeout  = coalesce(try(var.service_overrides.<service>.helm_timeout, null), var.default_helm_timeout)
}

# CPU architectures
<service> = local.service_configs.<service>.cpu_arch

# Helm configurations
<service> = {
  timeout          = coalesce(try(var.service_overrides.<service>.helm_timeout, null), var.default_helm_timeout)
  disable_webhooks = var.default_helm_disable_webhooks
  skip_crds        = var.default_helm_skip_crds
  replace          = var.default_helm_replace
  force_update     = var.default_helm_force_update
  cleanup_on_fail  = var.default_helm_cleanup_on_fail
  wait             = coalesce(try(var.service_overrides.<service>.helm_wait, null), var.default_helm_wait)
  wait_for_jobs    = coalesce(try(var.service_overrides.<service>.helm_wait_for_jobs, null), var.default_helm_wait_for_jobs)
}

# Storage sizes
<service> = "5Gi"

# Certificate resolvers
<service> = coalesce(var.cert_resolver_override.<service>, var.traefik_cert_resolver)
```

## 🧪 **Testing Requirements**

### **Unit Tests**

Add to `tests.tftest.hcl`:

```hcl
# Test <service> configuration
run "test_<service>_configuration" {
  command = plan

  variables {
    services = {
      <service> = true
    }

    service_overrides = {
      <service> = {
        cpu_arch      = "arm64"
        storage_class = "nfs-csi-safe"
        storage_size  = "10Gi"
      }
    }
  }

  assert {
    condition     = local.services_enabled.<service> == true
    error_message = "<Service> should be enabled"
  }

  assert {
    condition     = local.service_configs.<service>.cpu_arch == "arm64"
    error_message = "<Service> should use ARM64 architecture"
  }

  assert {
    condition     = local.service_configs.<service>.storage_class == "nfs-csi-safe"
    error_message = "<Service> should use NFS safe storage class"
  }
}
```

### **Scenario Tests**

Add to `test-scenarios.tftest.hcl`:

```hcl
# Test <service> in resource-constrained environment
run "test_<service>_resource_constrained" {
  command = plan

  variables {
    enable_microk8s_mode   = true
    enable_resource_limits = true

    services = {
      <service> = true
    }

    service_overrides = {
      <service> = {
        cpu_limit    = "200m"
        memory_limit = "256Mi"
        storage_size = "2Gi"
      }
    }
  }

  assert {
    condition     = local.storage_sizes.<service> == "2Gi"
    error_message = "<Service> should use smaller storage in constrained environment"
  }
}
```

## 📋 **Documentation Requirements**

### **Service README Template**

```markdown
# <Service Name> Integration

## Overview

Brief description of the service and its purpose within the tf-kube-any-compute infrastructure.

## Configuration

### Basic Configuration

```hcl
services = {
  <service> = true
}
```

### Advanced Configuration

```hcl
service_overrides = {
  <service> = {
    cpu_arch      = "arm64"
    storage_class = "nfs-csi-safe"
    storage_size  = "10Gi"
    enable_feature = true
  }
}
```

## Architecture Support

- ✅ AMD64 (x86_64)
- ✅ ARM64 (aarch64)
- ✅ Mixed clusters

## Storage Requirements

- Default: 5Gi
- Recommended: NFS-CSI for production
- Fallback: HostPath for development

## Dependencies

- Traefik (for ingress)
- Storage driver (NFS-CSI or HostPath)

## Troubleshooting

### Common Issues

1. **Service not starting**
   - Check resource limits
   - Verify storage class availability
   - Check node architecture compatibility

2. **Ingress not working**
   - Verify Traefik is running
   - Check certificate resolver configuration
   - Validate DNS resolution

### Diagnostic Commands

```bash
# Check service status
kubectl get pods -n <namespace>

# Check service logs
kubectl logs -l app=<service> -n <namespace>

# Check ingress configuration
kubectl get ingressroute -n <namespace>
```

## Examples

### Raspberry Pi Cluster

```hcl
services = {
  <service> = true
}

service_overrides = {
  <service> = {
    cpu_arch      = "arm64"
    cpu_limit     = "200m"
    memory_limit  = "256Mi"
    storage_class = "hostpath"
    storage_size  = "2Gi"
  }
}
```

### High-Performance Cluster

```hcl
service_overrides = {
  <service> = {
    cpu_arch      = "amd64"
    cpu_limit     = "2000m"
    memory_limit  = "4Gi"
    storage_class = "nfs-csi-fast"
    storage_size  = "50Gi"
  }
}
```
```

## 🚀 **Contribution Workflow**

1. **Fork Repository** - Create your own fork
2. **Create Feature Branch** - `git checkout -b feature/add-<service>`
3. **Implement Service** - Follow this template
4. **Add Tests** - Comprehensive test coverage
5. **Update Documentation** - README and examples
6. **Test Thoroughly** - `make test-all`
7. **Submit Pull Request** - Include detailed description

## 📊 **Quality Gates**

- [ ] All tests pass (`make test-all`)
- [ ] Documentation is complete
- [ ] ARM64/AMD64 compatibility verified
- [ ] Resource constraints tested
- [ ] Security best practices followed
- [ ] Integration with existing services validated

---

*This template ensures consistency and quality across all service integrations in tf-kube-any-compute.*
