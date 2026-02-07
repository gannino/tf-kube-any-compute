# Development Workflow: tf-kube-any-compute

## Development Setup

### Prerequisites
```bash
# Required tools
terraform >= 1.0
kubectl >= 1.20
helm >= 3.0
make
bash >= 4.0

# Recommended tools
jq
yq
git
pre-commit
```

### Initial Setup

#### 1. Clone Repository
```bash
git clone https://github.com/gannino/tf-kube-any-compute.git
cd tf-kube-any-compute
```

#### 2. Install Pre-commit Hooks
```bash
# Option 1: Using pip
pip install pre-commit
pre-commit install
pre-commit install --hook-type commit-msg

# Option 2: Using setup script
./setup-pre-commit.sh

# Option 3: Using Makefile
make pre-commit-install
```

#### 3. Initialize Terraform
```bash
make init
# or
terraform init
```

#### 4. Configure Environment
```bash
# Copy example configuration
cp terraform.tfvars.example terraform.tfvars

# Create development workspace
terraform workspace new dev
```

## Development Workflow

### 1. Code Development

#### Create New Feature Branch
```bash
git checkout -b feature/add-new-service
```

#### Edit Files
```bash
# Edit module files
vi helm-new-service/main.tf
vi helm-new-service/variables.tf
vi helm-new-service/values.yaml.tpl
```

#### Run Local Tests
```bash
# Quick validation
make test-quick

# Safe tests (no deployment)
make test-safe

# Full validation
make test-lint
make test-validate
```

### 2. Pre-commit Validation

#### Automatic Checks
```bash
# Stage files
git add .

# Pre-commit runs automatically on commit
git commit -m "feat(new-service): add new service module"
```

#### Manual Pre-commit Run
```bash
# Run all checks manually
pre-commit run --all-files

# Run specific hook
pre-commit run terraform-fmt --all-files
pre-commit run tflint-optimized --all-files
```

#### Pre-commit Hooks
- **terraform-fmt**: Auto-format Terraform files
- **terraform-docs**: Generate documentation
- **tflint-optimized**: Fast linting (changed files only)
- **terraform-validate**: Validate configuration
- **checkov**: Security scanning
- **terrascan**: Security scanning
- **detect-secrets**: Detect secrets in code
- **commit-msg**: Validate commit message format

### 3. Testing Strategy

#### Unit Tests
```bash
# Run unit tests
make test-unit

# Run specific test file
terraform test -filter=tests.tftest.hcl -verbose

# Run architecture tests
terraform test -filter=tests-architecture.tftest.hcl
```

#### Scenario Tests
```bash
# Run scenario tests
make test-scenarios

# Test specific scenario
terraform test -filter=test-scenarios.tftest.hcl -verbose
```

#### Integration Tests
```bash
# Run integration tests (requires deployed infrastructure)
make test-integration

# Test specific service
./scripts/integration-tests.sh --service traefik
```

#### Performance Tests
```bash
# Run performance tests (requires k6)
make test-performance

# Run with custom configuration
k6 run --vus 10 --duration 30s scripts/performance-test.js
```

#### Security Tests
```bash
# Run security scanning
make test-security

# Run individual security tools
./scripts/security-scan.sh
```

### 4. Commit Process

#### Commit Message Format
```bash
# Conventional commits
feat: add new service module
fix: resolve traefik authentication issue
docs: update contributing guide
test: add integration tests for monitoring
refactor: optimize resource limits
style: format terraform files
chore: update dependencies
```

#### Commit Examples
```bash
# Feature addition
git commit -m "feat(prometheus): add high availability configuration"

# Bug fix
git commit -m "fix(traefik): resolve dashboard authentication issue"

# Documentation
git commit -m "docs(readme): update installation instructions"

# Test addition
git commit -m "test(integration): add ARM64 deployment scenarios"
```

### 5. Code Review

#### Pull Request Checklist
- [ ] All tests pass locally
- [ ] Pre-commit hooks succeed
- [ ] Documentation updated
- [ ] Examples provided
- [ ] Tests added/updated
- [ ] Backward compatibility maintained
- [ ] Security review completed
- [ ] Performance considered

#### PR Template
```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Breaking change

## Testing
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing completed

## Architecture Support
- [ ] Tested on AMD64
- [ ] Tested on ARM64
- [ ] Tested on mixed clusters

## Documentation
- [ ] README updated
- [ ] Code comments added
- [ ] Examples provided

## Breaking Changes
List any breaking changes and migration steps
```

## Module Development

### Creating New Service Module

#### 1. Create Module Structure
```bash
mkdir helm-new-service
cd helm-new-service

# Create standard files
touch main.tf
touch variables.tf
touch outputs.tf
touch locals.tf
touch version.tf
touch values.yaml.tpl
touch README.md
touch .tflint.hcl
mkdir -p templates
```

#### 2. Implement Main Resources
```terraform
# main.tf
###########################
#  New Service - Purpose  #
###########################

# Namespace
resource "kubernetes_namespace" "this" {
  metadata {
    name = local.namespace
    labels = local.common_labels
  }
}

# Helm release
resource "helm_release" "this" {
  name       = local.release_name
  namespace  = kubernetes_namespace.this.metadata[0].name
  repository = var.chart_repository
  chart      = var.chart_name
  version    = local.chart_version

  # Timeout and wait configuration
  timeout          = local.helm_timeout
  wait             = local.helm_wait
  wait_for_jobs    = local.helm_wait_for_jobs
  cleanup_on_fail  = local.helm_cleanup_on_fail

  # Values from template
  values = [
    templatefile("${path.module}/templates/values.yaml.tpl", {
      namespace     = local.namespace
      cpu_arch      = local.cpu_arch
      storage_class = local.storage_class
    })
  ]

  depends_on = [
    kubernetes_namespace.this
  ]
}
```

#### 3. Define Variables
```terraform
# variables.tf
###########################
#  Variables - Input     #
###########################

variable "chart_name" {
  description = "Helm chart name"
  type        = string
  default     = "service-chart"
}

variable "chart_repository" {
  description = "Helm chart repository URL"
  type        = string
  default     = "https://charts.example.com"
}

variable "chart_version" {
  description = "Helm chart version (empty = latest)"
  type        = string
  default     = ""

  validation {
    condition     = var.chart_version == "" || can(regex("^\\d+\\.\\d+\\.\\d+", var.chart_version))
    error_message = "Chart version must be empty or in semantic version format (e.g., 1.2.3)."
  }
}

variable "cpu_arch" {
  description = "CPU architecture for node selection"
  type        = string
  default     = ""

  validation {
    condition     = var.cpu_arch == "" || contains(["amd64", "arm64"], var.cpu_arch)
    error_message = "CPU architecture must be 'amd64', 'arm64', or empty for auto-detection."
  }
}

variable "storage_class" {
  description = "Storage class for persistent volumes"
  type        = string
  default     = ""
}
```

#### 4. Define Outputs
```terraform
# outputs.tf
###########################
#  Outputs - Results     #
###########################

output "namespace" {
  description = "The namespace where the service is deployed"
  value       = kubernetes_namespace.this.metadata[0].name
}

output "release_name" {
  description = "The Helm release name"
  value       = helm_release.this.name
}

output "chart_version" {
  description = "The deployed chart version"
  value       = helm_release.this.metadata[0].version
}

output "status" {
  description = "The Helm release status"
  value       = helm_release.this.status
}

output "service_info" {
  description = "Complete service information"
  value = {
    namespace     = kubernetes_namespace.this.metadata[0].name
    release_name  = helm_release.this.name
    chart_version = helm_release.this.metadata[0].version
    status        = helm_release.this.status
  }
}
```

#### 5. Define Locals
```terraform
# locals.tf
###########################
#  Locals - Computed     #
###########################

locals {
  # Namespace configuration
  namespace = "${var.environment}-${var.name}-system"

  # Release name
  release_name = "${var.environment}-${var.name}"

  # Chart version (default to latest if not specified)
  chart_version = var.chart_version != "" ? var.chart_version : null

  # Helm timeout
  helm_timeout = coalesce(
    var.helm_timeout,
    var.default_helm_timeout,
    600
  )

  # Common labels
  common_labels = {
    "app.kubernetes.io/name"       = var.name
    "app.kubernetes.io/instance"   = local.release_name
    "app.kubernetes.io/managed-by" = "terraform"
  }

  # Resource limits based on architecture
  resource_limits = var.cpu_arch == "arm64" ? {
    cpu_limit      = "200m"
    memory_limit   = "256Mi"
    cpu_request    = "100m"
    memory_request = "128Mi"
  } : {
    cpu_limit      = "500m"
    memory_limit   = "512Mi"
    cpu_request    = "250m"
    memory_request = "256Mi"
  }
}
```

#### 6. Create Helm Values Template
```yaml
# templates/values.yaml.tpl
###########################
#  Helm Values Template    #
###########################

image:
  repository: ${image_repository}
  tag: ${image_tag}
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: ${service_port}

resources:
%{ if enable_resource_limits ~}
  limits:
    cpu: ${cpu_limit}
    memory: ${memory_limit}
  requests:
    cpu: ${cpu_request}
    memory: ${memory_request}
%{ endif ~}

%{ if enable_persistence ~}
persistence:
  enabled: true
  storageClass: ${storage_class}
  size: ${storage_size}
%{ endif ~}

nodeSelector:
%{ if cpu_arch != "" ~}
  kubernetes.io/arch: ${cpu_arch}
%{ endif ~}

tolerations: []
affinity: {}
```

#### 7. Create Module README
```markdown
# New Service Helm Module

Brief description of the service and its purpose.

## Features
- **Feature 1**: Description
- **Feature 2**: Description

## Usage

### Basic Usage
```hcl
module "new_service" {
  source = "./helm-new-service"

  name        = "new-service"
  environment = "prod"
}
```

### Advanced Configuration
```hcl
module "new_service" {
  source = "./helm-new-service"

  name        = "new-service"
  environment = "prod"

  cpu_arch      = "arm64"
  storage_class = "nfs-csi"

  helm_timeout = 900
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| helm | ~> 3.0 |
| kubernetes | ~> 2.0 |

## Providers

| Name | Version |
|------|---------|
| kubernetes | ~> 2.0 |
| helm | ~> 3.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Service name | `string` | n/a | yes |
| environment | Environment name | `string` | n/a | yes |
| chart_name | Helm chart name | `string` | `"service-chart"` | no |
| chart_repository | Helm chart repository | `string` | `"https://charts.example.com"` | no |
| chart_version | Helm chart version | `string` | `""` | no |
| cpu_arch | CPU architecture | `string` | `""` | no |
| storage_class | Storage class | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| namespace | The namespace where the service is deployed |
| release_name | The Helm release name |
| chart_version | The deployed chart version |
| status | The Helm release status |
| service_info | Complete service information |

## Architecture Support

### ARM64
- Resource limits: 200m CPU / 256Mi memory
- Optimized for Raspberry Pi clusters
- MicroK8s mode compatible

### AMD64
- Resource limits: 500m CPU / 512Mi memory
- Optimized for cloud environments
- Full feature support

## Troubleshooting

### Common Issues

**Issue**: Service fails to start
```bash
# Check pod logs
kubectl logs -n prod-new-service-system -l app=new-service

# Check pod status
kubectl get pods -n prod-new-service-system -l app=new-service
```

**Issue**: Storage not accessible
```bash
# Check PVC status
kubectl get pvc -n prod-new-service-system

# Check storage class
kubectl get storageclass
```

## Security Considerations

- RBAC configured with least privilege
- Resource limits to prevent DoS
- TLS enabled for external access
- Secrets stored in Kubernetes Secrets

## Contributing

See [CONTRIBUTING.md](../../CONTRIBUTING.md) for contribution guidelines.
```

### Testing New Module

#### 1. Write Unit Tests
```hcl
# Create tests.tftest.hcl in module directory
run "test_basic_deployment" {
  command = plan

  variables {
    name        = "test-service"
    environment = "test"
  }

  assert {
    condition     = helm_release.this.name == "test-test-service"
    error_message = "Release name incorrect"
  }

  assert {
    condition     = kubernetes_namespace.this.metadata[0].name == "test-test-service-system"
    error_message = "Namespace name incorrect"
  }
}

run "test_arm64_deployment" {
  command = plan

  variables {
    name        = "test-service"
    environment = "test"
    cpu_arch     = "arm64"
  }

  assert {
    condition     = local.resource_limits.cpu_limit == "200m"
    error_message = "ARM64 resource limits not applied"
  }
}
```

#### 2. Run Tests
```bash
# Run module tests
cd helm-new-service
terraform test

# Run with verbose output
terraform test -verbose
```

#### 3. Integration Testing
```bash
# Deploy module
terraform apply -var="name=new-service" -var="environment=dev"

# Verify deployment
kubectl get pods -n dev-new-service-system
kubectl get svc -n dev-new-service-system

# Test service
kubectl port-forward -n dev-new-service-system svc/new-service 8080:80
curl http://localhost:8080
```

## Debugging

### Enable Debug Output
```bash
# Enable Terraform debug logging
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform-debug.log

# Run Terraform with debug
terraform apply
```

### Check Pre-commit Hooks
```bash
# List all hooks
pre-commit run --all-files --show-diff-on-failure

# Run specific hook in debug mode
pre-commit run terraform-fmt --all-files -v
```

### Validate Configuration
```bash
# Validate Terraform configuration
terraform validate

# Validate module
cd helm-new-service
terraform validate

# Check Terraform version
terraform version
```

## Best Practices

### Code Quality
1. **Follow Naming Conventions**: Use consistent naming across all modules
2. **Add Validation**: Include validation blocks for critical inputs
3. **Document Everything**: Add descriptions to all variables, outputs, and resources
4. **Use Locals**: Computed values should be in locals.tf
5. **Separate Concerns**: Keep files focused on specific responsibilities

### Testing
1. **Write Tests**: Always write tests for new functionality
2. **Test Edge Cases**: Consider ARM64/AMD64, mixed clusters, resource limits
3. **Mock External Dependencies**: Use test configurations for external services
4. **Test Security**: Verify RBAC, secrets, and access controls
5. **Performance Testing**: Test resource usage and startup times

### Documentation
1. **Update README**: Every module needs comprehensive README
2. **Add Examples**: Provide usage examples in examples/ directory
3. **Document Changes**: Update CHANGELOG.md for significant changes
4. **Comment Code**: Explain "why" not "what" for complex logic
5. **Keep It Current**: Documentation should match code

### Security
1. **No Hardcoded Secrets**: Never commit passwords or API keys
2. **Use RBAC**: Implement proper role-based access control
3. **Enable TLS**: Use HTTPS for all external services
4. **Resource Limits**: Set limits to prevent DoS
5. **Regular Updates**: Keep dependencies updated

## CI/CD Integration

### GitHub Actions
```yaml
# .github/workflows/ci-consolidated.yml
name: CI

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.5.0

      - name: Terraform Format Check
        run: terraform fmt -check -recursive

      - name: Terraform Init
        run: terraform init

      - name: Terraform Validate
        run: terraform validate

      - name: Run Tests
        run: make test-safe
```

### GitLab CI
```yaml
# .gitlab-ci.yml
stages:
  - validate
  - test

terraform:validate:
  stage: validate
  script:
    - terraform fmt -check -recursive
    - terraform init
    - terraform validate

terraform:test:
  stage: test
  script:
    - make test-safe
```

## Troubleshooting Common Issues

### Pre-commit Issues
```bash
# Pre-commit not found
pip install pre-commit

# Hook fails
pre-commit clean
pre-commit install

# Permission denied
chmod +x .pre-commit-hooks/*.sh
```

### Terraform Issues
```bash
# State locked
terraform force-unlock <LOCK_ID>

# Provider not found
terraform init -upgrade

# Version conflict
terraform version
```

### Testing Issues
```bash
# Test fails
terraform test -filter=<test-file> -verbose

# Module not found
terraform get

# Configuration error
terraform validate
```

## Performance Optimization

### Pre-commit Optimization
```bash
# Fast pre-commit (changed files only)
make pre-commit-fast

# Full pre-commit (all files)
make pre-commit-full

# Skip slow hooks
SKIP=terraform-docs pre-commit run --all-files
```

### Terraform Optimization
```bash
# Use parallel execution
TF_PARALLELISM=4 terraform apply

# Disable refresh
terraform apply -refresh=false

# Use targeted apply
terraform apply -target=module.new_service
```

### Testing Optimization
```bash
# Run specific tests
terraform test -filter=tests.tftest.hcl

# Skip integration tests
SKIP_INTEGRATION=1 make test-safe

# Use test cache
terraform test -refresh=false
```

## Resources

### Documentation
- [Terraform Documentation](https://terraform.io/docs)
- [Helm Documentation](https://helm.sh/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs)

### Tools
- [Terraform Language Server](https://github.com/hashicorp/terraform-ls)
- [TFLint](https://github.com/terraform-linters/tflint)
- [terraform-docs](https://github.com/terraform-docs/terraform-docs)

### Community
- [Terraform Community](https://discuss.hashicorp.com/c/terraform/39)
- [Kubernetes Community](https://kubernetes.io/community)
- [Helm Community](https://helm.sh/community)

## Getting Help

### Internal Resources
- `.amazonq/rules/` - Amazon Q AI assistant rules
- `docs/guides/` - Detailed user guides
- `docs/reference/` - Technical references
- `examples/` - Configuration examples

### External Resources
- [GitHub Issues](https://github.com/gannino/tf-kube-any-compute/issues)
- [GitHub Discussions](https://github.com/gannino/tf-kube-any-compute/discussions)
- [Project Wiki](https://github.com/gannino/tf-kube-any-compute/wiki)
