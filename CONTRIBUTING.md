# Contributing to tf-kube-any-compute

Thank you for your interest in contributing to tf-kube-any-compute! This project thrives on community contributions and we welcome your involvement in making Kubernetes infrastructure more accessible for homelab enthusiasts and developers.

## 🏠 Project Philosophy

This project is built with the homelab mindset:

- **Start Simple**: Deploy core services first, add complexity gradually
- **Learn by Doing**: Each service teaches different Kubernetes concepts  
- **Architecture Agnostic**: Works on ARM64 Raspberry Pis and AMD64 servers
- **Production Patterns**: Learn industry best practices in your homelab
- **Cost Conscious**: Optimized for resource-constrained environments

## 🤝 How to Contribute

### 1. Ways to Contribute

- **🐛 Bug Reports**: Report issues you encounter
- **💡 Feature Requests**: Suggest new services or improvements
- **📖 Documentation**: Improve READMEs, guides, and examples
- **🔧 Code Contributions**: Add new modules, fix bugs, improve existing code
- **🧪 Testing**: Test on different Kubernetes distributions and architectures
- **💬 Community Support**: Help others in discussions and issues

### 2. Before You Start

- **Check Existing Issues**: Look for existing issues or discussions related to your contribution
- **Start Small**: For first-time contributors, look for "good first issue" labels
- **Discuss Major Changes**: Open an issue to discuss significant changes before implementing
- **Read Documentation**: Familiarize yourself with the project structure and conventions

## 🛠️ Development Setup

### Prerequisites

```bash
# Required tools
terraform >= 1.0
kubectl
helm >= 3.0
make

# Recommended tools
jq
yq
git
pre-commit
```

### Pre-commit Hooks

This project uses comprehensive pre-commit hooks for code quality and security:

```bash
# Install pre-commit
pip install pre-commit

# Install hooks
pre-commit install
pre-commit install --hook-type commit-msg

# Run all checks
pre-commit run --all-files
```

#### Pre-commit Checks

- **🎨 Terraform Format** - Auto-formats `.tf` files
- **📚 Documentation** - Auto-generates module documentation
- **🔎 TFLint** - Terraform linting and best practices
- **🛡️ Security Scanning** - Checkov, Terrascan, secret detection
- **📝 Commit Messages** - Conventional commit format validation
- **🐚 Shell Scripts** - ShellCheck validation
- **📖 Markdown** - Linting and formatting

### Local Development

1. **Fork and Clone**:

   ```bash
   git clone https://github.com/YOUR_USERNAME/tf-kube-any-compute.git
   cd tf-kube-any-compute
   ```

2. **Set Up Environment**:

   ```bash
   # Copy example configuration
   cp terraform.tfvars.example terraform.tfvars
   
   # Edit configuration for your environment
   vi terraform.tfvars
   ```

3. **Initialize Terraform**:

   ```bash
   terraform init
   ```

4. **Create Development Workspace**:

   ```bash
   terraform workspace new dev
   ```

## 📋 Project Structure

```
tf-kube-any-compute/
├── README.md                    # Main project documentation
├── CONTRIBUTING.md             # This file
├── LICENSE                     # MIT license
├── Makefile                    # Build and test commands
├── main.tf                     # Main Terraform configuration
├── variables.tf                # Input variables
├── outputs.tf                  # Output values
├── locals.tf                   # Local computed values
├── provider.tf                 # Provider configurations
├── version.tf                  # Version constraints
├── terraform.tfvars.example    # Example configuration
├── tests.tftest.hcl           # Unit tests
├── test-scenarios.tftest.hcl  # Integration tests
├── helm-<service>/            # Individual service modules
│   ├── README.md              # Service documentation
│   ├── main.tf                # Service deployment
│   ├── variables.tf           # Service variables
│   ├── outputs.tf             # Service outputs
│   ├── version.tf             # Version constraints
│   ├── templates/             # Helm value templates
│   └── ...                    # Service-specific files
└── scripts/                   # Utility scripts
```

## 🎯 Module Development Standards

### Module Structure

Each Helm module should follow this structure:

```
helm-<service>/
├── README.md              # Comprehensive documentation
├── main.tf                # Primary resources
├── variables.tf           # Input variables with validation
├── outputs.tf             # Output values
├── version.tf             # Terraform/provider requirements
├── limit_range.tf         # Resource limits (if applicable)
├── templates/             # Helm value templates
│   └── values.yaml.tpl    # Main values template
└── examples/              # Usage examples (optional)
```

### Code Standards

#### Terraform Style

```hcl
# Use consistent resource naming
resource "kubernetes_namespace" "this" {
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/name"       = var.name
      "app.kubernetes.io/instance"   = var.name
      "app.kubernetes.io/component"  = "namespace"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

# Use descriptive variable names
variable "storage_class" {
  description = "Storage class for persistent volumes"
  type        = string
  default     = "hostpath"
  
  validation {
    condition     = length(var.storage_class) > 0
    error_message = "Storage class cannot be empty."
  }
}

# Include comprehensive outputs
output "namespace" {
  description = "The namespace where the service is deployed"
  value       = kubernetes_namespace.this.metadata[0].name
}
```

#### Variable Validation

```hcl
# Always include validation where appropriate
variable "replicas" {
  description = "Number of replicas for the deployment"
  type        = number
  default     = 1
  
  validation {
    condition     = var.replicas >= 1 && var.replicas <= 10
    error_message = "Replicas must be between 1 and 10."
  }
}

variable "cpu_arch" {
  description = "CPU architecture for node selection"
  type        = string
  default     = "amd64"
  
  validation {
    condition     = contains(["amd64", "arm64"], var.cpu_arch)
    error_message = "CPU architecture must be either 'amd64' or 'arm64'."
  }
}
```

### Documentation Standards

#### Module README Template

Each module README should include:

```markdown
# <Service> Helm Module

Brief description of the service and its purpose.

## Features
- **🎯 Feature 1**: Description
- **📊 Feature 2**: Description

## Usage
### Basic Usage
```hcl
module "service" {
  source = "./helm-service"
  # minimal configuration
}
```

### Advanced Configuration

```hcl
module "service" {
  source = "./helm-service"
  # comprehensive configuration example
}
```

## Requirements

[Provider version table]

## Resources

[Resource list]

## Inputs

[Input variable table]

## Outputs

[Output table]

## Architecture Support

[ARM64/AMD64 specific configurations]

## Troubleshooting

[Common issues and solutions]

## Security Considerations

[Security best practices]

## Contributing

Standard contributing section

```

#### Code Comments

```hcl
# Resource creation with clear purpose
resource "helm_release" "this" {
  name       = var.name
  repository = var.chart_repo
  chart      = var.chart_name
  version    = var.chart_version
  namespace  = kubernetes_namespace.this.metadata[0].name
  
  # Wait for all resources to be ready
  wait          = true
  wait_for_jobs = true
  timeout       = var.helm_timeout
  
  # Enable cleanup on failure
  cleanup_on_fail = true
  force_update    = true
  
  values = [
    templatefile("${path.module}/templates/values.yaml.tpl", {
      # Template variables with clear naming
      namespace           = kubernetes_namespace.this.metadata[0].name
      storage_class      = var.storage_class
      cpu_arch          = var.cpu_arch
      # ... other variables
    })
  ]
  
  depends_on = [
    kubernetes_namespace.this,
    # List explicit dependencies
  ]
}
```

## 🧪 Testing

### Test Types

1. **Unit Tests** (`tests.tftest.hcl`):
   - Test configuration logic
   - Validate variable combinations
   - Check computed values

2. **Integration Tests** (`test-scenarios.tftest.hcl`):
   - Test actual deployments
   - Verify service functionality
   - Test different architectures

### Running Tests

```bash
# Run all tests
make test

# Run specific test types
make test-unit
make test-integration

# Format and validate
make fmt
make validate

# Generate test report
make test-report
```

### Writing Tests

#### Unit Test Example

```hcl
# tests.tftest.hcl
run "test_architecture_detection" {
  command = plan
  
  variables {
    cpu_arch = "arm64"
    enable_service = true
  }
  
  assert {
    condition     = local.final_cpu_arch == "arm64"
    error_message = "Architecture detection failed"
  }
}
```

#### Integration Test Example

```hcl
# test-scenarios.tftest.hcl
run "test_arm64_deployment" {
  command = apply
  
  variables {
    cpu_arch = "arm64"
    enable_prometheus_stack = true
    enable_grafana = true
  }
  
  assert {
    condition = output.enabled_modules != null
    error_message = "Modules should be enabled"
  }
}
```

## 🔄 Pull Request Process

### 1. Preparation

- **Branch Naming**: Use descriptive branch names
  - `feature/add-elasticsearch-module`
  - `fix/prometheus-storage-issue`
  - `docs/improve-contributing-guide`

- **Commit Messages**: Follow conventional commits

  ```
  feat(prometheus): add high availability configuration
  fix(traefik): resolve dashboard authentication issue
  docs(readme): update installation instructions
  test(integration): add ARM64 deployment scenarios
  ```

### 2. Pull Request Template

When opening a PR, include:

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

### 3. Review Process

1. **Automated Checks**: All CI checks must pass
2. **Code Review**: At least one maintainer review
3. **Testing**: Verify tests pass on different architectures
4. **Documentation**: Ensure documentation is updated
5. **Backwards Compatibility**: Maintain compatibility when possible

## 🏗️ Architecture Guidelines

### Multi-Architecture Support

Always consider both ARM64 and AMD64 architectures:

```hcl
# Include architecture constraints
resource "helm_release" "this" {
  # ... other configuration
  
  values = [
    templatefile("${path.module}/templates/values.yaml.tpl", {
      cpu_arch = var.cpu_arch
      # Architecture-specific resource limits
      cpu_limit    = var.cpu_arch == "arm64" ? "200m" : "500m"
      memory_limit = var.cpu_arch == "arm64" ? "256Mi" : "512Mi"
    })
  ]
}
```

### Resource Management

```hcl
# Include resource limits for all deployments
variable "resource_limits" {
  description = "Resource limits for the deployment"
  type = object({
    cpu_limit      = string
    memory_limit   = string
    cpu_request    = string
    memory_request = string
  })
  default = {
    cpu_limit      = "500m"
    memory_limit   = "512Mi"
    cpu_request    = "250m"
    memory_request = "256Mi"
  }
}
```

### Storage Strategy

```hcl
# Support multiple storage classes
variable "storage_class" {
  description = "Storage class for persistent volumes"
  type        = string
  default     = "hostpath"
  
  validation {
    condition = contains([
      "hostpath", "nfs-csi", "nfs-csi-safe", "nfs-csi-fast"
    ], var.storage_class)
    error_message = "Storage class must be one of the supported types."
  }
}
```

## 📊 Performance Considerations

### Resource Optimization

- **Default Limits**: Set conservative defaults that work on Raspberry Pi
- **Scaling Options**: Provide variables for different deployment sizes
- **Architecture Awareness**: Adjust resources based on CPU architecture

### Example Resource Patterns

```hcl
# Pattern for architecture-aware resource limits
locals {
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

## 🔒 Security Guidelines

### Secure Defaults

- **Authentication**: Enable authentication by default
- **TLS**: Use HTTPS for all web interfaces
- **RBAC**: Implement proper Kubernetes RBAC
- **Secrets**: Store sensitive data in Kubernetes secrets

### Security Review Checklist

- [ ] No hardcoded secrets in code
- [ ] Proper RBAC configurations
- [ ] TLS enabled for external access
- [ ] Resource limits to prevent DoS
- [ ] Network policies where appropriate
- [ ] Regular security updates in dependencies

## 🌍 Community Guidelines

### Code of Conduct

- Be respectful and inclusive
- Help newcomers to Kubernetes and homelabs
- Share knowledge and learn from others
- Focus on constructive feedback
- Celebrate community achievements

### Communication

- **Issues**: Use for bug reports and feature requests
- **Discussions**: Use for questions and community support
- **Pull Requests**: Use for code contributions
- **Wiki**: Contribute to community guides and tips

## 🎯 Priority Areas for Contribution

### High Priority

1. **New Service Modules**: Popular services requested by community
2. **Documentation**: Improve module documentation and examples
3. **Testing**: Add more comprehensive test coverage
4. **ARM64 Support**: Ensure all modules work on Raspberry Pi

### Medium Priority

1. **Performance Optimization**: Improve resource usage and startup times
2. **Security Enhancements**: Add security scanning and best practices
3. **Monitoring Integration**: Better observability and metrics
4. **CI/CD Integration**: GitOps and automation improvements

### Community Driven

1. **Tutorial Content**: Step-by-step guides for beginners
2. **Hardware Guides**: Specific hardware setup instructions
3. **Use Case Examples**: Real-world deployment scenarios
4. **Troubleshooting**: Common issues and solutions

## 🚀 Release Process

### Versioning

We follow [Semantic Versioning](https://semver.org/):

- **MAJOR**: Breaking changes
- **MINOR**: New features, backwards compatible
- **PATCH**: Bug fixes, backwards compatible

### Release Checklist

- [ ] All tests pass
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] Version numbers updated
- [ ] Git tag created
- [ ] Release notes written

## 📞 Getting Help

### Resources

- **Documentation**: Check module READMEs and main documentation
- **Issues**: Search existing issues for similar problems
- **Discussions**: Ask questions in GitHub Discussions
- **Wiki**: Community-contributed guides and tips

### Mentorship

New contributors can request mentorship:

- **Good First Issues**: Look for beginner-friendly issues
- **Pair Programming**: Request pair programming sessions
- **Code Review**: Ask for detailed code review feedback
- **Architecture Guidance**: Get help with design decisions

## 🙏 Recognition

We value all contributions:

- **Contributors**: Listed in project README
- **Changelog**: Contributions noted in release notes
- **Community**: Recognized in community discussions
- **Learning**: Opportunity to learn Kubernetes and Infrastructure as Code

---

**Thank you for contributing to tf-kube-any-compute!** Your contributions help make Kubernetes more accessible to homelab enthusiasts and developers worldwide. 🚀

*Happy Homelabbing!* 🏠