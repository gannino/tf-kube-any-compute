# Technology Stack - tf-kube-any-compute

## Core Technologies

### Infrastructure as Code
- **Terraform**: >= 1.0 (recommended), >= 0.14 (minimum)
  - HCL2 syntax with advanced features (optional types, dynamic blocks)
  - Native testing framework (terraform test)
  - Workspace support for multi-environment management

### Kubernetes Providers
- **kubernetes**: ~> 2.0 (HashiCorp official provider)
- **helm**: ~> 3.0 (Helm chart deployment)
- **kubectl**: ~> 1.0 (gavinbunney/kubectl for CRD management)
- **random**: ~> 3.0 (password generation)

### Supported Kubernetes Distributions
- **K3s**: Lightweight Kubernetes (primary target)
- **MicroK8s**: Ubuntu's Kubernetes (ARM64 optimized)
- **EKS**: Amazon Elastic Kubernetes Service
- **GKE**: Google Kubernetes Engine
- **AKS**: Azure Kubernetes Service
- **Vanilla Kubernetes**: Standard upstream distributions

## Build System

### Makefile Commands
```bash
# Lifecycle
make init              # Initialize Terraform
make plan              # Preview changes
make apply             # Deploy infrastructure
make destroy           # Remove infrastructure

# Testing
make test-all          # Comprehensive test suite
make test-safe         # Safe tests (no deployment)
make test-unit         # Unit tests only
make test-scenarios    # Scenario tests
make test-integration  # Live cluster tests
make test-security     # Security scanning

# Development
make lint              # Fast linting (changed files)
make lint-full         # Full linting (all files)
make fmt               # Format Terraform files
make docs              # Generate documentation
make debug             # Cluster diagnostics

# CI/CD
make ci-check          # CI validation
make ci-test           # CI test suite
make ci-security       # CI security scanning
```

## Development Tools

### Required
- **terraform**: >= 1.0
- **kubectl**: Latest stable
- **helm**: >= 3.0
- **make**: Build automation

### Recommended
- **tflint**: Terraform linting (v0.50+)
- **terraform-docs**: Documentation generation (v0.18+)
- **pre-commit**: Git hooks framework
- **actionlint**: GitHub Actions validation

### Security Scanning
- **trivy**: Vulnerability and Terraform security (replaces tfsec)
- **checkov**: Policy-as-code scanning
- **terrascan**: Kubernetes security policies
- **detect-secrets**: Secret detection

### Performance Testing
- **k6**: Load testing for services
- **Node.js**: Performance test scripts

## Programming Languages

### Primary
- **HCL (HashiCorp Configuration Language)**: 95% of codebase
  - Terraform modules and configuration
  - Variable definitions and validation
  - Output definitions
  - Test specifications

### Supporting
- **Bash**: 4% of codebase
  - Diagnostic scripts (debug.sh, check-*.sh)
  - CI/CD automation (release.sh, version-manager.sh)
  - Pre-commit hooks
  - Integration test runners

- **JavaScript**: 1% of codebase
  - k6 performance tests (performance-test.js)

- **YAML**: Configuration files
  - GitHub Actions workflows
  - Pre-commit configuration
  - Issue templates
  - Helm values templates

## Version Management

### Centralized Version Control
- **versions.auto.tfvars**: Single source of truth for all versions
- **scripts/version-manager.sh**: Version synchronization tool
- **.github/env.yml**: GitHub Actions environment versions
- **.tool-versions**: asdf version manager configuration

### Version Synchronization
```bash
make versions              # Show all versions
make version-get TOOL=terraform
make version-update TOOL=terraform VERSION=1.6.0
make version-sync          # Sync across all files
```

## CI/CD Pipeline

### GitHub Actions Workflows
- **ci-consolidated.yml**: Main CI pipeline
  - Terraform validation
  - TFLint analysis (optimized)
  - Security scanning (Trivy, Checkov)
  - Unit and scenario tests
  - Documentation validation

- **release-consolidated.yml**: Release automation
  - Version validation
  - Changelog generation
  - GitHub release creation
  - Terraform Registry preparation

### Pre-commit Hooks
- **terraform fmt**: Automatic formatting
- **terraform validate**: Configuration validation
- **tflint**: Optimized linting (changed files only)
- **terraform-docs**: Auto-generate documentation
- **detect-secrets**: Secret scanning

## Testing Framework

### Test Types
1. **Unit Tests** (tests.tftest.hcl)
   - Architecture detection logic
   - Storage class selection
   - Helm configuration
   - Variable validation

2. **Scenario Tests** (test-scenarios.tftest.hcl)
   - ARM64 Raspberry Pi clusters
   - AMD64 cloud clusters
   - Mixed architecture clusters
   - MicroK8s deployments

3. **Integration Tests** (scripts/integration-tests.sh)
   - Live cluster connectivity
   - Service health checks
   - Ingress functionality
   - Storage operations

4. **Security Tests** (make test-security)
   - Trivy vulnerability scanning
   - Checkov policy validation
   - Terrascan Kubernetes policies
   - Secret detection

### Test Execution
```bash
# Fast feedback loop (~2-5 minutes)
make test-quick

# Comprehensive validation (~15-20 minutes)
make test-all

# CI pipeline (~10-15 minutes)
make ci-test
```

## DNS Providers (11 supported)

### Default
- **Hurricane Electric**: Zero-configuration dynamic DNS

### Cloud Providers
- **Cloudflare**: Global CDN and DNS
- **AWS Route53**: Enterprise cloud DNS
- **DigitalOcean**: Developer-friendly DNS
- **Linode**: Developer cloud platform
- **Vultr**: High-performance cloud
- **Hetzner**: European hosting provider

### Domain Registrars
- **Gandi**: Domain registrar DNS
- **Namecheap**: Affordable domain DNS
- **GoDaddy**: Popular domain provider
- **OVH**: European cloud provider

## Monitoring Stack

### Metrics Collection
- **Prometheus**: Time-series database and alerting
- **kube-state-metrics**: Kubernetes object metrics
- **Node Exporter**: System and hardware metrics
- **Metrics Server**: Kubernetes metrics API

### Visualization
- **Grafana**: Dashboard and visualization
  - Pre-configured dashboards (10+)
  - Automatic dashboard import
  - Organized folder structure

### Logging (Optional)
- **Loki**: Log aggregation
- **Promtail**: Log collection agent

## Service Mesh & Security

### Service Mesh
- **Consul**: Service discovery and mesh
  - Connect service mesh
  - Health checking
  - Key-value store

### Secrets Management
- **Vault**: HashiCorp Vault
  - Auto-unsealing
  - Kubernetes authentication
  - Dynamic secrets

### Policy Engine
- **Gatekeeper**: OPA-based policies
  - Admission control
  - Policy validation
  - Audit logging

## Storage Drivers

### NFS
- **NFS CSI Driver**: Dynamic provisioning
  - ReadWriteMany support
  - Static PV creation
  - Automatic folder creation

### HostPath
- **HostPath CSI Driver**: Local storage
  - Single-node clusters
  - Development environments
  - Fast I/O performance

### Cloud Native
- **EBS**: AWS Elastic Block Store
- **GCE PD**: Google Persistent Disk
- **Azure Disk**: Azure managed disks

## Development Commands

### Quick Start
```bash
# Initialize project
make init

# Run tests
make test-safe

# Format and lint
make fmt
make lint

# Generate docs
make docs

# Debug cluster
make debug
```

### Release Process
```bash
# Validate release
make release-check

# Create release
make release-patch    # 2.0.0 → 2.0.1
make release-minor    # 2.0.0 → 2.1.0
make release-major    # 2.0.0 → 3.0.0
```

### Version Management
```bash
# List all versions
make versions

# Update specific tool
make version-update TOOL=terraform VERSION=1.6.0

# Sync versions across files
make version-sync
```
