# 🔒 Security Testing Guide for tf-kube-any-compute

## Overview

This guide provides comprehensive information about security testing tools, common issues, and detailed fix suggestions for developers contributing to the tf-kube-any-compute project.

## 🛠️ Security Testing Tools

### 1. Checkov - Comprehensive Policy Scanning

**Purpose**: Static analysis for infrastructure as code security and compliance  
**Install**: `pip install checkov`  
**Documentation**: <https://www.checkov.io/>

#### Common Checkov Issues & Fixes

| Check ID | Description | Fix |
|----------|-------------|-----|
| CKV_K8S_8 | Containers should have resource limits | Add `resources.limits.cpu` and `resources.limits.memory` |
| CKV_K8S_9 | Containers should have resource requests | Add `resources.requests.cpu` and `resources.requests.memory` |
| CKV_K8S_10 | Containers should not run as root | Add `securityContext.runAsNonRoot: true` |
| CKV_K8S_12 | Containers should have readiness probe | Add `readinessProbe` configuration |
| CKV_K8S_13 | Containers should have liveness probe | Add `livenessProbe` configuration |
| CKV_K8S_14 | Containers should have image pull policy | Add `imagePullPolicy: Always` or `IfNotPresent` |
| CKV_K8S_16 | Containers should not allow privilege escalation | Add `securityContext.allowPrivilegeEscalation: false` |
| CKV_K8S_17 | Containers should not run privileged | Remove `privileged: true` or set to `false` |
| CKV_K8S_22 | Containers should use read-only root filesystem | Add `securityContext.readOnlyRootFilesystem: true` |
| CKV_K8S_25 | Minimize wildcard use in RBAC | Specify exact resources instead of `"*"` |
| CKV_K8S_38 | Minimize service account token mounting | Add `automountServiceAccountToken: false` |
| CKV_TF_1 | Module sources should use commit hash | Use `git::https://github.com/user/repo.git?ref=commit-hash` |

#### Example Fix for CKV_K8S_8 (Resource Limits)

**Before:**

```yaml
containers:
- name: app
  image: nginx:latest
```

**After:**

```yaml
containers:
- name: app
  image: nginx:latest
  resources:
    limits:
      cpu: 500m
      memory: 512Mi
    requests:
      cpu: 250m
      memory: 256Mi
```

### 2. Terrascan - Policy-as-Code Scanning

**Purpose**: Policy-based security scanning for cloud infrastructure  
**Install**: `brew install terrascan`  
**Documentation**: <https://runterrascan.io/>

#### Common Terrascan Policies & Fixes

| Policy ID | Description | Fix |
|-----------|-------------|-----|
| AC_K8S_0001 | Containers should not run as root | Add `securityContext.runAsNonRoot: true` |
| AC_K8S_0002 | Containers should not allow privilege escalation | Add `securityContext.allowPrivilegeEscalation: false` |
| AC_K8S_0003 | Containers should not run privileged | Remove `privileged: true` |
| AC_K8S_0004 | Containers should have resource limits | Add resource limits |
| AC_K8S_0005 | Containers should have resource requests | Add resource requests |
| AC_K8S_0006 | Containers should have liveness probe | Add `livenessProbe` |
| AC_K8S_0007 | Containers should have readiness probe | Add `readinessProbe` |
| AC_K8S_0008 | Containers should use read-only root filesystem | Add `securityContext.readOnlyRootFilesystem: true` |
| AC_K8S_0011 | Default deny network policy should exist | Create NetworkPolicy with default deny |
| AC_K8S_0012 | Ingress should have TLS configured | Add `tls` section to Ingress |
| AC_K8S_0013 | Services should not use NodePort | Use ClusterIP or LoadBalancer |
| AC_K8S_0014 | PVCs should have storage size limits | Add storage size limits |
| AC_K8S_0015 | hostPath volumes should not be used | Use PVC or other volume types |
| AC_K8S_0016 | RBAC should be configured | Create ServiceAccount, Role, RoleBinding |
| AC_K8S_0017 | Service accounts should not automount tokens | Add `automountServiceAccountToken: false` |
| AC_K8S_0018 | ClusterRoles should not have wildcard permissions | Specify exact resources |

#### Example Fix for AC_K8S_0011 (Network Policy)

**Create Default Deny NetworkPolicy:**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

### 3. TFSec - Terraform Security Analysis (DEPRECATED)

**⚠️ DEPRECATION NOTICE**: TFSec is deprecated and joining the Trivy family. Use Trivy for Terraform security scanning.  
**Migration**: <https://github.com/aquasecurity/tfsec#tfsec-is-joining-the-trivy-family>  
**Replacement**: Use `trivy config .` for Terraform security analysis

#### Common TFSec Issues & Fixes

| Rule ID | Description | Fix |
|---------|-------------|-----|
| AVD-KSV-0001 | Containers should have resource limits | Add resource limits |
| AVD-KSV-0012 | Containers should run as non-root | Add `runAsNonRoot: true` |
| AVD-KSV-0014 | Containers should use read-only root filesystem | Add `readOnlyRootFilesystem: true` |
| AVD-KSV-0017 | Containers should not allow privilege escalation | Add `allowPrivilegeEscalation: false` |
| AVD-KSV-0020 | Containers should not run as root user | Add `runAsUser: 1000` |
| AVD-KSV-0030 | Containers should apply security context | Add comprehensive securityContext |

#### Example Fix for AVD-KSV-0030 (Security Context)

**Complete Security Context:**

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  runAsGroup: 1000
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
  capabilities:
    drop:
    - ALL
  seccompProfile:
    type: RuntimeDefault
```

### 4. Trivy - Vulnerability & Terraform Security Scanning

**Purpose**: Comprehensive vulnerability scanner for containers, infrastructure, and Terraform security (replaces TFSec)  
**Install**: `brew install trivy`  
**Documentation**: <https://aquasecurity.github.io/trivy/>  
**TFSec Migration**: <https://github.com/aquasecurity/tfsec#tfsec-is-joining-the-trivy-family>

#### Common Vulnerability Types & Fixes

| Category | Issue | Fix |
|----------|-------|-----|
| Dependencies | Outdated packages | Update to latest secure versions |
| Container Images | Vulnerable base images | Use updated or minimal base images |
| Terraform Security | Insecure configurations | Apply security contexts and resource limits |
| Configuration | Insecure defaults | Apply security hardening |
| Secrets | Exposed credentials | Use secret management systems |

#### Example Fixes for Container Security

**Use Minimal Base Images:**

```dockerfile
# Instead of
FROM ubuntu:latest

# Use
FROM gcr.io/distroless/java:11
# or
FROM alpine:3.18
```

**Pin Specific Versions:**

```yaml
# Instead of
image: nginx:latest

# Use
image: nginx:1.25.3-alpine
```

### 5. Secret Detection

**Purpose**: Detect hardcoded secrets and credentials  
**Install**: `pip install detect-secrets`  
**Documentation**: <https://github.com/Yelp/detect-secrets>

#### Common Secret Types & Fixes

| Secret Type | Example | Fix |
|-------------|---------|-----|
| API Keys | `api_key = "sk-1234567890abcdef"` | Use environment variables |
| Passwords | `password = "mypassword123"` | Use Kubernetes secrets |
| Private Keys | `-----BEGIN PRIVATE KEY----- [REDACTED]` | Use secret management |
| Tokens | `token = "ghp_1234567890abcdef"` | Use external secret stores |

#### Example Fixes for Secret Management

**Environment Variables:**

```bash
# Instead of hardcoding
export API_KEY="sk-1234567890abcdef"

# Use
export TF_VAR_api_key="$API_KEY"
```

**Kubernetes Secrets:**

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: api-credentials
type: Opaque
data:
  api-key: <base64-encoded-value>
```

**Terraform Variables:**

```hcl
variable "api_key" {
  description = "API key for external service"
  type        = string
  sensitive   = true
}
```

## 🚀 Running Security Tests

### Pre-commit Hooks

Install and run pre-commit hooks:

```bash
pip install pre-commit
pre-commit install
pre-commit run --all-files
```

### Manual Security Scanning

Run comprehensive security tests:

```bash
# All security tools
make test-security

# Individual tools
make test-security-checkov
make test-security-terrascan
make test-security-tfsec
make test-security-trivy
make test-security-secrets
```

### Custom Security Script

Use the comprehensive security scanning script:

```bash
# Run all tools with fix suggestions
./scripts/security-scan.sh --fix

# Run specific tool
./scripts/security-scan.sh --tool checkov --format json

# CI mode
./scripts/security-scan.sh --ci --severity high
```

## 🔧 Common Security Patterns

### 1. Secure Container Configuration

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: secure-app
spec:
  template:
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        runAsGroup: 1000
        fsGroup: 1000
      containers:
      - name: app
        image: nginx:1.25.3-alpine
        imagePullPolicy: Always
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop:
            - ALL
        resources:
          limits:
            cpu: 500m
            memory: 512Mi
          requests:
            cpu: 250m
            memory: 256Mi
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
        volumeMounts:
        - name: tmp
          mountPath: /tmp
        - name: cache
          mountPath: /var/cache/nginx
      volumes:
      - name: tmp
        emptyDir: {}
      - name: cache
        emptyDir: {}
      automountServiceAccountToken: false
```

### 2. Network Security

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: app-network-policy
spec:
  podSelector:
    matchLabels:
      app: secure-app
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: database
    ports:
    - protocol: TCP
      port: 5432
```

### 3. RBAC Configuration

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-service-account
automountServiceAccountToken: false
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: app-role
rules:
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: app-role-binding
subjects:
- kind: ServiceAccount
  name: app-service-account
roleRef:
  kind: Role
  name: app-role
  apiGroup: rbac.authorization.k8s.io
```

## 📋 Security Checklist

### Before Committing

- [ ] Run `pre-commit run --all-files`
- [ ] No hardcoded secrets or credentials
- [ ] All containers have resource limits
- [ ] Security contexts configured
- [ ] Non-root user specified
- [ ] Read-only root filesystem where possible
- [ ] Liveness and readiness probes added
- [ ] Network policies defined
- [ ] RBAC properly configured
- [ ] Image tags are specific (not `latest`)

### Before Merging

- [ ] All security scans pass
- [ ] Security issues addressed or documented
- [ ] Breaking changes documented
- [ ] Security review completed
- [ ] Tests updated for security changes

### Production Deployment

- [ ] Secrets managed externally
- [ ] Network segmentation implemented
- [ ] Monitoring and alerting configured
- [ ] Backup and recovery tested
- [ ] Incident response plan updated

## 🆘 Getting Help

### Common Issues

1. **Pre-commit hooks failing**: Check tool installation and configuration
2. **False positives**: Add to appropriate ignore files or baselines
3. **Complex security fixes**: Consult tool documentation and examples
4. **CI/CD integration**: Use provided GitHub Actions workflows

### Resources

- **Project Issues**: <https://github.com/gannino/tf-kube-any-compute/issues>
- **Security Documentation**: This guide and tool-specific docs
- **Community Support**: GitHub Discussions
- **Security Reporting**: Follow responsible disclosure practices

### Tool Documentation

- [Checkov Documentation](https://www.checkov.io/)
- [Terrascan Documentation](https://runterrascan.io/)
- [TFSec Documentation](https://aquasecurity.github.io/tfsec/)
- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- [Kubernetes Security](https://kubernetes.io/docs/concepts/security/)
- [Terraform Security](https://learn.hashicorp.com/tutorials/terraform/security)

## 🔄 Continuous Improvement

Security is an ongoing process. This guide and tools are regularly updated to address new threats and best practices. Contributions and feedback are welcome to improve the security posture of the project.
