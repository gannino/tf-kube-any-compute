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

| Name | Source | Version |
|------|--------|---------|
| <a name="module_crds"></a> [crds](#module\_crds) | ./crds | n/a |
| <a name="module_policies"></a> [policies](#module\_policies) | ./policies | n/a |

## Resources

| Name | Type |
|------|------|
| [helm_release.this](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_limit_range.namespace_limits](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/limit_range) | resource |
| [kubernetes_namespace.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_resources.gatekeeper_crds](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/resources) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_chart_name"></a> [chart\_name](#input\_chart\_name) | Helm chart name. | `string` | `"gatekeeper"` | no |
| <a name="input_chart_repo"></a> [chart\_repo](#input\_chart\_repo) | Helm repository name. | `string` | `"https://open-policy-agent.github.io/gatekeeper/charts"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Helm version. | `string` | `"3.15.1"` | no |
| <a name="input_container_max_cpu"></a> [container\_max\_cpu](#input\_container\_max\_cpu) | Maximum CPU limit for containers | `string` | `"500m"` | no |
| <a name="input_container_max_memory"></a> [container\_max\_memory](#input\_container\_max\_memory) | Maximum memory limit for containers | `string` | `"512Mi"` | no |
| <a name="input_cpu_arch"></a> [cpu\_arch](#input\_cpu\_arch) | CPU architecture for node selection (amd64, arm64) | `string` | `"amd64"` | no |
| <a name="input_cpu_limit"></a> [cpu\_limit](#input\_cpu\_limit) | CPU limit for the container | `string` | `"500m"` | no |
| <a name="input_cpu_request"></a> [cpu\_request](#input\_cpu\_request) | CPU request for the container | `string` | `"100m"` | no |
| <a name="input_crd_api_version"></a> [crd\_api\_version](#input\_crd\_api\_version) | API version for CRD operations | `string` | `"apiextensions.k8s.io/v1"` | no |
| <a name="input_crd_wait_timeout"></a> [crd\_wait\_timeout](#input\_crd\_wait\_timeout) | Timeout for CRD readiness checks | `string` | `"60s"` | no |
| <a name="input_disable_arch_scheduling"></a> [disable\_arch\_scheduling](#input\_disable\_arch\_scheduling) | Disable architecture-based node scheduling (useful for cluster-wide services) | `bool` | `false` | no |
| <a name="input_enable_hostpath_policy"></a> [enable\_hostpath\_policy](#input\_enable\_hostpath\_policy) | Enable hostpath PVC size limit policy | `bool` | `true` | no |
| <a name="input_enable_policies"></a> [enable\_policies](#input\_enable\_policies) | Enable Gatekeeper policies. | `bool` | `true` | no |
| <a name="input_enable_resource_policies"></a> [enable\_resource\_policies](#input\_enable\_resource\_policies) | Enable resource requirement policies (CPU/memory limits) | `bool` | `false` | no |
| <a name="input_enable_security_policies"></a> [enable\_security\_policies](#input\_enable\_security\_policies) | Enable security-related policies (security context, privileged containers) | `bool` | `true` | no |
| <a name="input_gatekeeper_version"></a> [gatekeeper\_version](#input\_gatekeeper\_version) | Gatekeeper version for CRD deployment (should match chart version) | `string` | `"3.15"` | no |
| <a name="input_helm_cleanup_on_fail"></a> [helm\_cleanup\_on\_fail](#input\_helm\_cleanup\_on\_fail) | Cleanup resources on failure | `bool` | `false` | no |
| <a name="input_helm_disable_webhooks"></a> [helm\_disable\_webhooks](#input\_helm\_disable\_webhooks) | Disable webhooks for Helm release | `bool` | `false` | no |
| <a name="input_helm_force_update"></a> [helm\_force\_update](#input\_helm\_force\_update) | Force resource updates if needed | `bool` | `false` | no |
| <a name="input_helm_replace"></a> [helm\_replace](#input\_helm\_replace) | Allow Helm to replace existing resources | `bool` | `false` | no |
| <a name="input_helm_skip_crds"></a> [helm\_skip\_crds](#input\_helm\_skip\_crds) | Skip CRDs for Helm release | `bool` | `false` | no |
| <a name="input_helm_timeout"></a> [helm\_timeout](#input\_helm\_timeout) | Timeout for Helm deployment in seconds | `number` | `120` | no |
| <a name="input_helm_wait"></a> [helm\_wait](#input\_helm\_wait) | Wait for Helm release to be ready | `bool` | `true` | no |
| <a name="input_helm_wait_for_jobs"></a> [helm\_wait\_for\_jobs](#input\_helm\_wait\_for\_jobs) | Wait for Helm jobs to complete | `bool` | `true` | no |
| <a name="input_hostpath_max_size"></a> [hostpath\_max\_size](#input\_hostpath\_max\_size) | Maximum allowed size for hostpath PVCs | `string` | `"10Gi"` | no |
| <a name="input_hostpath_storage_class"></a> [hostpath\_storage\_class](#input\_hostpath\_storage\_class) | Storage class name for hostpath policy | `string` | `"hostpath"` | no |
| <a name="input_limit_range_enabled"></a> [limit\_range\_enabled](#input\_limit\_range\_enabled) | Enable limit range for the namespace | `bool` | `true` | no |
| <a name="input_memory_limit"></a> [memory\_limit](#input\_memory\_limit) | Memory limit for the container | `string` | `"512Mi"` | no |
| <a name="input_memory_request"></a> [memory\_request](#input\_memory\_request) | Memory request for the container | `string` | `"256Mi"` | no |
| <a name="input_name"></a> [name](#input\_name) | Helm name. | `string` | `"gatekeeper"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace. | `string` | `"gatekeeper-stack"` | no |
| <a name="input_pvc_max_storage"></a> [pvc\_max\_storage](#input\_pvc\_max\_storage) | Maximum storage for persistent volume claims | `string` | `"10Gi"` | no |
| <a name="input_pvc_min_storage"></a> [pvc\_min\_storage](#input\_pvc\_min\_storage) | Minimum storage for persistent volume claims | `string` | `"1Gi"` | no |
| <a name="input_service_overrides"></a> [service\_overrides](#input\_service\_overrides) | Override values for existing helm deployment configurations | `map(any)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_gatekeeper_configuration"></a> [gatekeeper\_configuration](#output\_gatekeeper\_configuration) | Gatekeeper configuration details |
| <a name="output_helm_release"></a> [helm\_release](#output\_helm\_release) | Helm release information |
| <a name="output_namespace"></a> [namespace](#output\_namespace) | The namespace where Gatekeeper is deployed |
| <a name="output_policy_configuration"></a> [policy\_configuration](#output\_policy\_configuration) | Policy configuration details |
| <a name="output_resource_limits"></a> [resource\_limits](#output\_resource\_limits) | Resource limit configuration |
<!-- END_TF_DOCS -->
