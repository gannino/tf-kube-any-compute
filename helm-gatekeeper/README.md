# Gatekeeper Policy Engine Module

This module deploys Open Policy Agent (OPA) Gatekeeper to enforce security policies and governance rules in your Kubernetes cluster.

## Overview

Gatekeeper is a policy engine that allows administrators to define and enforce policies for Kubernetes resources using the Rego language. This module provides:

- **Policy Engine**: OPA Gatekeeper for admission control
- **Security Policies**: Built-in security constraints
- **Resource Policies**: CPU and memory requirements
- **Storage Policies**: PVC size limits
- **Webhook Admission**: Real-time policy enforcement

## Features

### Security Policies
- **Security Context Requirements**: Enforces `runAsNonRoot`, `readOnlyRootFilesystem`, and `allowPrivilegeEscalation: false`
- **Privileged Container Prevention**: Blocks containers running in privileged mode
- **Resource Requirements**: Ensures CPU and memory limits/requests are specified

### Storage Policies
- **PVC Size Limits**: Configurable maximum storage sizes per storage class
- **Storage Class Validation**: Prevents oversized volumes

### Architecture Support
- **Multi-Architecture**: Supports AMD64 and ARM64 node scheduling
- **High Availability**: Runs with 2 replicas by default
- **Security Hardened**: Non-root containers with security contexts

## Configuration

### Basic Configuration

```hcl
module "gatekeeper" {
  source = "./helm-gatekeeper"
  
  name      = "my-gatekeeper"
  namespace = "gatekeeper-system"
  
  # Enable policy enforcement
  enable_policies = true
  
  # CPU architecture
  cpu_arch = "amd64"  # or "arm64"
}
```

### Policy Configuration

```hcl
module "gatekeeper" {
  source = "./helm-gatekeeper"
  
  # Storage policies
  enable_hostpath_policy  = true
  hostpath_max_size      = "20Gi"
  hostpath_storage_class = "hostpath"
  
  # Security policies
  enable_security_policies = true
  
  # Resource requirement policies
  enable_resource_policies = true
}
```

### Resource Sizing

```hcl
module "gatekeeper" {
  source = "./helm-gatekeeper"
  
  # Resource allocation
  cpu_limit      = "1000m"
  memory_limit   = "1Gi"
  cpu_request    = "200m"
  memory_request = "512Mi"
}
```

## Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `namespace` | string | `"gatekeeper-stack"` | Kubernetes namespace |
| `name` | string | `"gatekeeper"` | Helm release name |
| `chart_version` | string | `"3.15.1"` | Gatekeeper chart version |
| `enable_policies` | bool | `true` | Enable policy enforcement |
| `enable_hostpath_policy` | bool | `true` | Enable PVC size limits |
| `hostpath_max_size` | string | `"10Gi"` | Maximum PVC size for hostpath |
| `hostpath_storage_class` | string | `"hostpath"` | Storage class for size limits |
| `enable_security_policies` | bool | `true` | Enable security constraints |
| `enable_resource_policies` | bool | `false` | Enable resource requirements |
| `cpu_arch` | string | `"amd64"` | Target CPU architecture |
| `cpu_limit` | string | `"500m"` | CPU limit per replica |
| `memory_limit` | string | `"512Mi"` | Memory limit per replica |
| `cpu_request` | string | `"100m"` | CPU request per replica |
| `memory_request` | string | `"256Mi"` | Memory request per replica |

## Policy Types

### 1. Storage Policies

**PVC Size Limits**: Prevents creation of PVCs larger than specified limits.

```yaml
# Example violation
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: large-volume
spec:
  storageClassName: hostpath
  resources:
    requests:
      storage: 50Gi  # Violates 10Gi limit
```

### 2. Security Policies

**Security Context Requirements**: Ensures containers run with proper security settings.

```yaml
# Compliant pod
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
  containers:
  - name: app
    image: nginx:alpine
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop: ["ALL"]
```

**Privileged Container Prevention**: Blocks privileged containers.

```yaml
# This will be blocked
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: privileged-container
    securityContext:
      privileged: true  # Violation
```

### 3. Resource Policies

**Resource Requirements**: Ensures all containers specify CPU and memory limits/requests.

```yaml
# Compliant container
containers:
- name: app
  resources:
    limits:
      cpu: "500m"
      memory: "512Mi"
    requests:
      cpu: "100m"
      memory: "256Mi"
```

## Deployment Examples

### Development Environment

```hcl
module "gatekeeper" {
  source = "./helm-gatekeeper"
  
  namespace = "dev-gatekeeper"
  
  # Relaxed policies for development
  enable_policies          = true
  enable_security_policies = false  # Allow flexible security for dev
  enable_resource_policies = false  # Don't enforce resource limits
  
  # Smaller resource allocation
  cpu_limit    = "200m"
  memory_limit = "256Mi"
}
```

### Production Environment

```hcl
module "gatekeeper" {
  source = "./helm-gatekeeper"
  
  namespace = "prod-gatekeeper"
  
  # Strict policies for production
  enable_policies          = true
  enable_security_policies = true
  enable_resource_policies = true
  
  # Strict storage limits
  hostpath_max_size = "5Gi"
  
  # Higher resource allocation
  cpu_limit      = "1000m"
  memory_limit   = "1Gi"
  cpu_request    = "500m"
  memory_request = "512Mi"
}
```

### Multi-Architecture Cluster

```hcl
module "gatekeeper_amd64" {
  source = "./helm-gatekeeper"
  
  namespace = "gatekeeper-amd64"
  cpu_arch  = "amd64"
}

module "gatekeeper_arm64" {
  source = "./helm-gatekeeper"
  
  namespace = "gatekeeper-arm64"
  cpu_arch  = "arm64"
}
```

## Monitoring and Troubleshooting

### Check Policy Status

```bash
# View constraint templates
kubectl get constrainttemplates

# View active constraints
kubectl get constraints

# Check policy violations
kubectl get events --field-selector reason=FailedCreate

# View gatekeeper logs
kubectl logs -n gatekeeper-system deployment/gatekeeper-controller-manager
```

### Policy Validation

```bash
# Test a policy constraint
kubectl apply --dry-run=server -f test-pod.yaml

# View constraint status
kubectl describe pvcsize pvc-size-limit-hostpath
```

### Common Issues

1. **Webhook Not Ready**: Wait for Gatekeeper to be fully deployed
2. **Policy Violations**: Check event logs for specific policy failures
3. **Resource Constraints**: Increase CPU/memory if policies are slow to enforce

### Debugging Policies

```bash
# Check constraint template syntax
kubectl get constrainttemplate pvcsize -o yaml

# View detailed constraint information
kubectl describe constraint pvc-size-limit-hostpath

# Test policy logic with dry-run
kubectl apply --dry-run=server -f test-resource.yaml
```

## Security Considerations

1. **Namespace Exclusions**: System namespaces are excluded from policies
2. **Webhook Security**: Admission controller uses TLS for secure communication
3. **RBAC**: Gatekeeper requires cluster-admin permissions for admission control
4. **Policy Bypass**: Emergency procedures should be documented for policy bypass

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  API Server     │────│   Gatekeeper    │────│   OPA Engine    │
│                 │    │   Webhook       │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Kubernetes    │    │  Constraint     │    │   Rego          │
│   Resources     │    │  Templates      │    │   Policies      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Integration

### With Other Modules

```hcl
# Enable gatekeeper with other security tools
module "gatekeeper" {
  source = "./helm-gatekeeper"
  # ... configuration
}

module "prometheus" {
  source = "./helm-prometheus-stack"
  # Monitor gatekeeper metrics
}

module "grafana" {
  source = "./helm-grafana"
  # Visualize policy violations
}
```

### Custom Policies

Create additional constraint templates in the `policies/` directory for custom requirements.

## Compliance

This module helps achieve compliance with:

- **Pod Security Standards**: Implements restricted pod security policies
- **CIS Kubernetes Benchmark**: Enforces security best practices
- **SOC 2**: Provides access controls and audit trails
- **GDPR**: Ensures data protection through resource isolation

## Version Compatibility

- **Kubernetes**: 1.20+
- **Helm**: 3.0+
- **Terraform**: 1.0+
- **OPA Gatekeeper**: 3.15.1

## Support

For issues and troubleshooting:

1. Check Gatekeeper documentation: https://open-policy-agent.github.io/gatekeeper/
2. Review constraint template syntax
3. Validate Rego policy logic
4. Monitor webhook admission logs
