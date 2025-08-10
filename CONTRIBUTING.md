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

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.14 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 3.0 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | ~> 1.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.38.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_consul"></a> [consul](#module\_consul) | ./helm-consul | n/a |
| <a name="module_gatekeeper"></a> [gatekeeper](#module\_gatekeeper) | ./helm-gatekeeper | n/a |
| <a name="module_grafana"></a> [grafana](#module\_grafana) | ./helm-grafana | n/a |
| <a name="module_host_path"></a> [host\_path](#module\_host\_path) | ./helm-host-path | n/a |
| <a name="module_loki"></a> [loki](#module\_loki) | ./helm-loki | n/a |
| <a name="module_metallb"></a> [metallb](#module\_metallb) | ./helm-metallb | n/a |
| <a name="module_nfs_csi"></a> [nfs\_csi](#module\_nfs\_csi) | ./helm-nfs-csi | n/a |
| <a name="module_node_feature_discovery"></a> [node\_feature\_discovery](#module\_node\_feature\_discovery) | ./helm-node-feature-discovery | n/a |
| <a name="module_portainer"></a> [portainer](#module\_portainer) | ./helm-portainer | n/a |
| <a name="module_prometheus"></a> [prometheus](#module\_prometheus) | ./helm-prometheus-stack | n/a |
| <a name="module_prometheus_crds"></a> [prometheus\_crds](#module\_prometheus\_crds) | ./helm-prometheus-stack-crds | n/a |
| <a name="module_promtail"></a> [promtail](#module\_promtail) | ./helm-promtail | n/a |
| <a name="module_traefik"></a> [traefik](#module\_traefik) | ./helm-traefik | n/a |
| <a name="module_vault"></a> [vault](#module\_vault) | ./helm-vault | n/a |

## Resources

| Name | Type |
|------|------|
| [kubernetes_nodes.all_nodes](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/nodes) | data source |
| [kubernetes_nodes.k3s_masters](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/nodes) | data source |
| [kubernetes_nodes.k3s_workers](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/nodes) | data source |
| [kubernetes_nodes.k8s_masters](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/nodes) | data source |
| [kubernetes_nodes.k8s_masters_legacy](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/nodes) | data source |
| [kubernetes_nodes.k8s_workers](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/nodes) | data source |
| [kubernetes_nodes.microk8s_masters](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/nodes) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_auto_mixed_cluster_mode"></a> [auto\_mixed\_cluster\_mode](#input\_auto\_mixed\_cluster\_mode) | Automatically configure services for mixed architecture clusters | `bool` | `true` | no |
| <a name="input_base_domain"></a> [base\_domain](#input\_base\_domain) | Base domain name (e.g., 'example.com') | `string` | `"local"` | no |
| <a name="input_cert_resolver_override"></a> [cert\_resolver\_override](#input\_cert\_resolver\_override) | Override the default cert resolver for specific services | <pre>object({<br/>    traefik      = optional(string)<br/>    prometheus   = optional(string)<br/>    grafana      = optional(string)<br/>    alertmanager = optional(string)<br/>    consul       = optional(string)<br/>    vault        = optional(string)<br/>    portainer    = optional(string)<br/>  })</pre> | `{}` | no |
| <a name="input_cpu_arch"></a> [cpu\_arch](#input\_cpu\_arch) | CPU architecture for node selection (leave empty for auto-detection) | `string` | `""` | no |
| <a name="input_cpu_arch_override"></a> [cpu\_arch\_override](#input\_cpu\_arch\_override) | Per-service CPU architecture overrides for mixed clusters | <pre>object({<br/>    traefik                = optional(string)<br/>    metallb                = optional(string)<br/>    nfs_csi                = optional(string)<br/>    host_path              = optional(string)<br/>    prometheus             = optional(string)<br/>    prometheus_crds        = optional(string)<br/>    grafana                = optional(string)<br/>    loki                   = optional(string)<br/>    promtail               = optional(string)<br/>    consul                 = optional(string)<br/>    vault                  = optional(string)<br/>    gatekeeper             = optional(string)<br/>    portainer              = optional(string)<br/>    node_feature_discovery = optional(string)<br/>  })</pre> | `{}` | no |
| <a name="input_default_cpu_limit"></a> [default\_cpu\_limit](#input\_default\_cpu\_limit) | Default CPU limit for containers when resource limits are enabled | `string` | `"500m"` | no |
| <a name="input_default_helm_cleanup_on_fail"></a> [default\_helm\_cleanup\_on\_fail](#input\_default\_helm\_cleanup\_on\_fail) | Default value for Helm cleanup on fail | `bool` | `true` | no |
| <a name="input_default_helm_disable_webhooks"></a> [default\_helm\_disable\_webhooks](#input\_default\_helm\_disable\_webhooks) | Default value for Helm disable webhooks | `bool` | `true` | no |
| <a name="input_default_helm_force_update"></a> [default\_helm\_force\_update](#input\_default\_helm\_force\_update) | Default value for Helm force update | `bool` | `true` | no |
| <a name="input_default_helm_replace"></a> [default\_helm\_replace](#input\_default\_helm\_replace) | Default value for Helm replace | `bool` | `false` | no |
| <a name="input_default_helm_skip_crds"></a> [default\_helm\_skip\_crds](#input\_default\_helm\_skip\_crds) | Default value for Helm skip CRDs | `bool` | `false` | no |
| <a name="input_default_helm_timeout"></a> [default\_helm\_timeout](#input\_default\_helm\_timeout) | Default timeout for Helm deployments in seconds | `number` | `600` | no |
| <a name="input_default_helm_wait"></a> [default\_helm\_wait](#input\_default\_helm\_wait) | Default value for Helm wait | `bool` | `true` | no |
| <a name="input_default_helm_wait_for_jobs"></a> [default\_helm\_wait\_for\_jobs](#input\_default\_helm\_wait\_for\_jobs) | Default value for Helm wait for jobs | `bool` | `true` | no |
| <a name="input_default_memory_limit"></a> [default\_memory\_limit](#input\_default\_memory\_limit) | Default memory limit for containers when resource limits are enabled | `string` | `"512Mi"` | no |
| <a name="input_default_storage_class"></a> [default\_storage\_class](#input\_default\_storage\_class) | Default storage class to use when not specified (empty = auto-detection) | `string` | `""` | no |
| <a name="input_disable_arch_scheduling"></a> [disable\_arch\_scheduling](#input\_disable\_arch\_scheduling) | Disable architecture-based scheduling for specific services (useful for development) | <pre>object({<br/>    traefik                = optional(bool, false)<br/>    metallb                = optional(bool, false)<br/>    nfs_csi                = optional(bool, false)<br/>    host_path              = optional(bool, false)<br/>    prometheus             = optional(bool, false)<br/>    prometheus_crds        = optional(bool, false)<br/>    grafana                = optional(bool, false)<br/>    loki                   = optional(bool, false)<br/>    promtail               = optional(bool, false)<br/>    consul                 = optional(bool, false)<br/>    vault                  = optional(bool, false)<br/>    gatekeeper             = optional(bool, false)<br/>    portainer              = optional(bool, false)<br/>    node_feature_discovery = optional(bool, false)<br/>  })</pre> | `{}` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | DEPRECATED: Use base\_domain and platform\_name instead. Legacy domain name configuration | `string` | `null` | no |
| <a name="input_enable_consul"></a> [enable\_consul](#input\_enable\_consul) | Enable Consul service mesh (DEPRECATED: use services.consul) | `bool` | `null` | no |
| <a name="input_enable_debug_outputs"></a> [enable\_debug\_outputs](#input\_enable\_debug\_outputs) | Enable debug outputs for troubleshooting | `bool` | `false` | no |
| <a name="input_enable_gatekeeper"></a> [enable\_gatekeeper](#input\_enable\_gatekeeper) | Enable Gatekeeper policy engine (DEPRECATED: use services.gatekeeper) | `bool` | `false` | no |
| <a name="input_enable_grafana"></a> [enable\_grafana](#input\_enable\_grafana) | Enable standalone Grafana dashboard (DEPRECATED: use services.grafana) | `bool` | `null` | no |
| <a name="input_enable_grafana_persistence"></a> [enable\_grafana\_persistence](#input\_enable\_grafana\_persistence) | Enable persistent storage for Grafana (DEPRECATED: use service\_overrides.grafana.enable\_persistence) | `bool` | `null` | no |
| <a name="input_enable_host_path"></a> [enable\_host\_path](#input\_enable\_host\_path) | Enable host path CSI driver (DEPRECATED: use services.host\_path) | `bool` | `null` | no |
| <a name="input_enable_loki"></a> [enable\_loki](#input\_enable\_loki) | Enable Loki log aggregation (DEPRECATED: use services.loki) | `bool` | `null` | no |
| <a name="input_enable_metallb"></a> [enable\_metallb](#input\_enable\_metallb) | Enable MetalLB load balancer (DEPRECATED: use services.metallb) | `bool` | `null` | no |
| <a name="input_enable_microk8s_mode"></a> [enable\_microk8s\_mode](#input\_enable\_microk8s\_mode) | Enable MicroK8s mode | `bool` | `false` | no |
| <a name="input_enable_nfs_csi"></a> [enable\_nfs\_csi](#input\_enable\_nfs\_csi) | Enable NFS CSI driver (DEPRECATED: use services.nfs\_csi) | `bool` | `null` | no |
| <a name="input_enable_node_feature_discovery"></a> [enable\_node\_feature\_discovery](#input\_enable\_node\_feature\_discovery) | Enable Node Feature Discovery (DEPRECATED: use services.node\_feature\_discovery) | `bool` | `null` | no |
| <a name="input_enable_portainer"></a> [enable\_portainer](#input\_enable\_portainer) | Enable Portainer container management (DEPRECATED: use services.portainer) | `bool` | `null` | no |
| <a name="input_enable_prometheus"></a> [enable\_prometheus](#input\_enable\_prometheus) | Enable Prometheus monitoring stack (DEPRECATED: use services.prometheus) | `bool` | `null` | no |
| <a name="input_enable_prometheus_crds"></a> [enable\_prometheus\_crds](#input\_enable\_prometheus\_crds) | Enable Prometheus CRDs (DEPRECATED: use services.prometheus\_crds) | `bool` | `null` | no |
| <a name="input_enable_prometheus_ingress_route"></a> [enable\_prometheus\_ingress\_route](#input\_enable\_prometheus\_ingress\_route) | Enable Prometheus ingress route (DEPRECATED: use service\_overrides.prometheus.enable\_ingress) | `bool` | `null` | no |
| <a name="input_enable_promtail"></a> [enable\_promtail](#input\_enable\_promtail) | Enable Promtail log collection (DEPRECATED: use services.promtail) | `bool` | `null` | no |
| <a name="input_enable_resource_limits"></a> [enable\_resource\_limits](#input\_enable\_resource\_limits) | Enable resource limits for resource-constrained environments | `bool` | `true` | no |
| <a name="input_enable_traefik"></a> [enable\_traefik](#input\_enable\_traefik) | Enable Traefik ingress controller (DEPRECATED: use services.traefik) | `bool` | `null` | no |
| <a name="input_enable_vault"></a> [enable\_vault](#input\_enable\_vault) | Enable Vault secrets management (DEPRECATED: use services.vault) | `bool` | `null` | no |
| <a name="input_grafana_admin_password"></a> [grafana\_admin\_password](#input\_grafana\_admin\_password) | Custom password for Grafana admin (empty = auto-generate) | `string` | `""` | no |
| <a name="input_grafana_node_name"></a> [grafana\_node\_name](#input\_grafana\_node\_name) | Specific node name to run Grafana (DEPRECATED: use service\_overrides.grafana.node\_name) | `string` | `""` | no |
| <a name="input_helm_timeouts"></a> [helm\_timeouts](#input\_helm\_timeouts) | Custom timeout values for specific Helm deployments (advanced users only) | <pre>object({<br/>    traefik                = optional(number, 600) # 10 minutes - ingress controller needs time<br/>    metallb                = optional(number, 300) # 5 minutes - load balancer setup<br/>    nfs_csi                = optional(number, 300) # 5 minutes - storage driver setup<br/>    host_path              = optional(number, 180) # 3 minutes - storage driver<br/>    prometheus_stack       = optional(number, 900) # 15 minutes - complex monitoring stack<br/>    prometheus_stack_crds  = optional(number, 300) # 5 minutes - CRD installation<br/>    grafana                = optional(number, 600) # 10 minutes - dashboard setup + persistence<br/>    consul                 = optional(number, 600) # 10 minutes - service mesh setup<br/>    vault                  = optional(number, 600) # 10 minutes - secrets management setup<br/>    portainer              = optional(number, 300) # 5 minutes - container management UI<br/>    gatekeeper             = optional(number, 300) # 5 minutes - policy engine<br/>    node_feature_discovery = optional(number, 180) # 3 minutes - node labeling<br/>    loki                   = optional(number, 300) # 5 minutes - log aggregation setup<br/>    promtail               = optional(number, 180) # 3 minutes - log collection daemonset<br/>  })</pre> | `{}` | no |
| <a name="input_le_email"></a> [le\_email](#input\_le\_email) | Email address for Let's Encrypt certificate notifications | `string` | `""` | no |
| <a name="input_letsencrypt_email"></a> [letsencrypt\_email](#input\_letsencrypt\_email) | Email address for Let's Encrypt certificate notifications (DEPRECATED: use le\_email) | `string` | `""` | no |
| <a name="input_metallb_address_pool"></a> [metallb\_address\_pool](#input\_metallb\_address\_pool) | IP address range for MetalLB load balancer | `string` | `"192.168.1.200-192.168.1.210"` | no |
| <a name="input_monitoring_admin_password"></a> [monitoring\_admin\_password](#input\_monitoring\_admin\_password) | Custom password for monitoring services (Prometheus/AlertManager) admin (empty = auto-generate) | `string` | `""` | no |
| <a name="input_nfs_path"></a> [nfs\_path](#input\_nfs\_path) | NFS server path (DEPRECATED: use nfs\_server\_path) | `string` | `""` | no |
| <a name="input_nfs_server"></a> [nfs\_server](#input\_nfs\_server) | NFS server IP address (DEPRECATED: use nfs\_server\_address) | `string` | `""` | no |
| <a name="input_nfs_server_address"></a> [nfs\_server\_address](#input\_nfs\_server\_address) | NFS server IP address for persistent storage | `string` | `"192.168.1.100"` | no |
| <a name="input_nfs_server_path"></a> [nfs\_server\_path](#input\_nfs\_server\_path) | NFS server path for persistent storage | `string` | `"/mnt/k8s-storage"` | no |
| <a name="input_platform_name"></a> [platform\_name](#input\_platform\_name) | Platform identifier (e.g., 'k3s', 'eks', 'gke', 'aks', 'microk8s') | `string` | `"k3s"` | no |
| <a name="input_portainer_admin_password"></a> [portainer\_admin\_password](#input\_portainer\_admin\_password) | Custom password for Portainer admin (empty = auto-generate) | `string` | `""` | no |
| <a name="input_service_overrides"></a> [service\_overrides](#input\_service\_overrides) | Service-specific configuration overrides for fine-grained control | <pre>object({<br/>    traefik = optional(object({<br/>      # Core configuration<br/>      cpu_arch      = optional(string)<br/>      chart_version = optional(string)<br/>      storage_class = optional(string)<br/>      storage_size  = optional(string)<br/><br/>      # Service-specific settings<br/>      enable_dashboard   = optional(bool)<br/>      dashboard_password = optional(string)<br/>      cert_resolver      = optional(string)<br/><br/>      # Resource limits<br/>      cpu_limit      = optional(string)<br/>      memory_limit   = optional(string)<br/>      cpu_request    = optional(string)<br/>      memory_request = optional(string)<br/><br/>      # Helm deployment options<br/>      helm_timeout          = optional(number)<br/>      helm_wait             = optional(bool)<br/>      helm_wait_for_jobs    = optional(bool)<br/>      helm_disable_webhooks = optional(bool)<br/>      helm_skip_crds        = optional(bool)<br/>      helm_replace          = optional(bool)<br/>      helm_force_update     = optional(bool)<br/>      helm_cleanup_on_fail  = optional(bool)<br/>    }))<br/><br/>    prometheus = optional(object({<br/>      # Core configuration<br/>      cpu_arch      = optional(string)<br/>      chart_version = optional(string)<br/>      storage_class = optional(string)<br/>      storage_size  = optional(string)<br/><br/>      # Service-specific settings<br/>      enable_ingress              = optional(bool)<br/>      enable_alertmanager_ingress = optional(bool)<br/>      retention_period            = optional(string)<br/>      monitoring_admin_password   = optional(string)<br/><br/>      # Resource limits<br/>      cpu_limit      = optional(string)<br/>      memory_limit   = optional(string)<br/>      cpu_request    = optional(string)<br/>      memory_request = optional(string)<br/><br/>      # Helm deployment options<br/>      helm_timeout          = optional(number)<br/>      helm_wait             = optional(bool)<br/>      helm_wait_for_jobs    = optional(bool)<br/>      helm_disable_webhooks = optional(bool)<br/>      helm_skip_crds        = optional(bool)<br/>      helm_replace          = optional(bool)<br/>      helm_force_update     = optional(bool)<br/>      helm_cleanup_on_fail  = optional(bool)<br/>    }))<br/><br/>    grafana = optional(object({<br/>      # Core configuration<br/>      cpu_arch      = optional(string)<br/>      chart_version = optional(string)<br/>      storage_class = optional(string)<br/>      storage_size  = optional(string)<br/><br/>      # Service-specific settings<br/>      enable_persistence = optional(bool)<br/>      node_name          = optional(string)<br/>      admin_user         = optional(string)<br/>      admin_password     = optional(string)<br/><br/>      # Resource limits<br/>      cpu_limit      = optional(string)<br/>      memory_limit   = optional(string)<br/>      cpu_request    = optional(string)<br/>      memory_request = optional(string)<br/><br/>      # Helm deployment options<br/>      helm_timeout          = optional(number)<br/>      helm_wait             = optional(bool)<br/>      helm_wait_for_jobs    = optional(bool)<br/>      helm_disable_webhooks = optional(bool)<br/>      helm_skip_crds        = optional(bool)<br/>      helm_replace          = optional(bool)<br/>      helm_force_update     = optional(bool)<br/>      helm_cleanup_on_fail  = optional(bool)<br/>    }))<br/><br/>    metallb = optional(object({<br/>      # Service-specific settings<br/>      address_pool = optional(string)<br/><br/>      # Resource limits<br/>      cpu_limit      = optional(string)<br/>      memory_limit   = optional(string)<br/>      cpu_request    = optional(string)<br/>      memory_request = optional(string)<br/><br/>      # Helm deployment options<br/>      helm_timeout          = optional(number)<br/>      helm_wait             = optional(bool)<br/>      helm_wait_for_jobs    = optional(bool)<br/>      helm_disable_webhooks = optional(bool)<br/>      helm_skip_crds        = optional(bool)<br/>      helm_replace          = optional(bool)<br/>      helm_force_update     = optional(bool)<br/>      helm_cleanup_on_fail  = optional(bool)<br/>    }))<br/><br/>    vault = optional(object({<br/>      # Core configuration<br/>      cpu_arch      = optional(string)<br/>      chart_version = optional(string)<br/>      storage_class = optional(string)<br/>      storage_size  = optional(string)<br/><br/>      # Resource limits<br/>      cpu_limit      = optional(string)<br/>      memory_limit   = optional(string)<br/>      cpu_request    = optional(string)<br/>      memory_request = optional(string)<br/><br/>      # Helm deployment options<br/>      helm_timeout          = optional(number)<br/>      helm_wait             = optional(bool)<br/>      helm_wait_for_jobs    = optional(bool)<br/>      helm_disable_webhooks = optional(bool)<br/>      helm_skip_crds        = optional(bool)<br/>      helm_replace          = optional(bool)<br/>      helm_force_update     = optional(bool)<br/>      helm_cleanup_on_fail  = optional(bool)<br/>    }))<br/><br/>    consul = optional(object({<br/>      # Core configuration<br/>      cpu_arch      = optional(string)<br/>      chart_version = optional(string)<br/>      storage_class = optional(string)<br/>      storage_size  = optional(string)<br/><br/>      # Resource limits<br/>      cpu_limit      = optional(string)<br/>      memory_limit   = optional(string)<br/>      cpu_request    = optional(string)<br/>      memory_request = optional(string)<br/><br/>      # Helm deployment options<br/>      helm_timeout          = optional(number)<br/>      helm_wait             = optional(bool)<br/>      helm_wait_for_jobs    = optional(bool)<br/>      helm_disable_webhooks = optional(bool)<br/>      helm_skip_crds        = optional(bool)<br/>      helm_replace          = optional(bool)<br/>      helm_force_update     = optional(bool)<br/>      helm_cleanup_on_fail  = optional(bool)<br/>    }))<br/><br/>    portainer = optional(object({<br/>      # Core configuration<br/>      cpu_arch      = optional(string)<br/>      chart_version = optional(string)<br/>      storage_class = optional(string)<br/>      storage_size  = optional(string)<br/><br/>      # Service-specific settings<br/>      admin_password = optional(string)<br/><br/>      # Resource limits<br/>      cpu_limit      = optional(string)<br/>      memory_limit   = optional(string)<br/>      cpu_request    = optional(string)<br/>      memory_request = optional(string)<br/><br/>      # Helm deployment options<br/>      helm_timeout          = optional(number)<br/>      helm_wait             = optional(bool)<br/>      helm_wait_for_jobs    = optional(bool)<br/>      helm_disable_webhooks = optional(bool)<br/>      helm_skip_crds        = optional(bool)<br/>      helm_replace          = optional(bool)<br/>      helm_force_update     = optional(bool)<br/>      helm_cleanup_on_fail  = optional(bool)<br/>    }))<br/><br/>    loki = optional(object({<br/>      # Core configuration<br/>      cpu_arch      = optional(string)<br/>      chart_version = optional(string)<br/>      storage_class = optional(string)<br/>      storage_size  = optional(string)<br/><br/>      # Resource limits<br/>      cpu_limit      = optional(string)<br/>      memory_limit   = optional(string)<br/>      cpu_request    = optional(string)<br/>      memory_request = optional(string)<br/><br/>      # Helm deployment options<br/>      helm_timeout          = optional(number)<br/>      helm_wait             = optional(bool)<br/>      helm_wait_for_jobs    = optional(bool)<br/>      helm_disable_webhooks = optional(bool)<br/>      helm_skip_crds        = optional(bool)<br/>      helm_replace          = optional(bool)<br/>      helm_force_update     = optional(bool)<br/>      helm_cleanup_on_fail  = optional(bool)<br/>    }))<br/><br/>    nfs_csi = optional(object({<br/>      # Helm deployment options<br/>      helm_timeout          = optional(number)<br/>      helm_wait             = optional(bool)<br/>      helm_wait_for_jobs    = optional(bool)<br/>      helm_disable_webhooks = optional(bool)<br/>      helm_skip_crds        = optional(bool)<br/>      helm_replace          = optional(bool)<br/>      helm_force_update     = optional(bool)<br/>      helm_cleanup_on_fail  = optional(bool)<br/>    }))<br/><br/>    host_path = optional(object({<br/>      # Helm deployment options<br/>      helm_timeout          = optional(number)<br/>      helm_wait             = optional(bool)<br/>      helm_wait_for_jobs    = optional(bool)<br/>      helm_disable_webhooks = optional(bool)<br/>      helm_skip_crds        = optional(bool)<br/>      helm_replace          = optional(bool)<br/>      helm_force_update     = optional(bool)<br/>      helm_cleanup_on_fail  = optional(bool)<br/>    }))<br/><br/>    node_feature_discovery = optional(object({<br/>      # Helm deployment options<br/>      helm_timeout          = optional(number)<br/>      helm_wait             = optional(bool)<br/>      helm_wait_for_jobs    = optional(bool)<br/>      helm_disable_webhooks = optional(bool)<br/>      helm_skip_crds        = optional(bool)<br/>      helm_replace          = optional(bool)<br/>      helm_force_update     = optional(bool)<br/>      helm_cleanup_on_fail  = optional(bool)<br/>    }))<br/><br/>    gatekeeper = optional(object({<br/>      # Gatekeeper-specific options<br/>      gatekeeper_version = optional(string)<br/>      # Helm deployment options<br/>      helm_timeout          = optional(number)<br/>      helm_wait             = optional(bool)<br/>      helm_wait_for_jobs    = optional(bool)<br/>      helm_disable_webhooks = optional(bool)<br/>      helm_skip_crds        = optional(bool)<br/>      helm_replace          = optional(bool)<br/>      helm_force_update     = optional(bool)<br/>      helm_cleanup_on_fail  = optional(bool)<br/>    }))<br/><br/>    prometheus_crds = optional(object({<br/>      # Helm deployment options<br/>      helm_timeout          = optional(number)<br/>      helm_wait             = optional(bool)<br/>      helm_wait_for_jobs    = optional(bool)<br/>      helm_disable_webhooks = optional(bool)<br/>      helm_skip_crds        = optional(bool)<br/>      helm_replace          = optional(bool)<br/>      helm_force_update     = optional(bool)<br/>      helm_cleanup_on_fail  = optional(bool)<br/>    }))<br/><br/>    promtail = optional(object({<br/>      # Helm deployment options<br/>      helm_timeout          = optional(number)<br/>      helm_wait             = optional(bool)<br/>      helm_wait_for_jobs    = optional(bool)<br/>      helm_disable_webhooks = optional(bool)<br/>      helm_skip_crds        = optional(bool)<br/>      helm_replace          = optional(bool)<br/>      helm_force_update     = optional(bool)<br/>      helm_cleanup_on_fail  = optional(bool)<br/>    }))<br/>  })</pre> | `{}` | no |
| <a name="input_services"></a> [services](#input\_services) | Service enablement configuration - choose your stack components | <pre>object({<br/>    # Core infrastructure services<br/>    traefik   = optional(bool, true)<br/>    metallb   = optional(bool, true)<br/>    nfs_csi   = optional(bool, true)<br/>    host_path = optional(bool, true)<br/><br/>    # Monitoring and observability stack<br/>    prometheus      = optional(bool, true)<br/>    prometheus_crds = optional(bool, true)<br/>    grafana         = optional(bool, true)<br/>    loki            = optional(bool, true)<br/>    promtail        = optional(bool, true)<br/><br/>    # Service mesh and security<br/>    consul     = optional(bool, true)<br/>    vault      = optional(bool, true)<br/>    gatekeeper = optional(bool, false)<br/><br/>    # Management and discovery<br/>    portainer              = optional(bool, true)<br/>    node_feature_discovery = optional(bool, true)<br/>  })</pre> | `{}` | no |
| <a name="input_storage_class_override"></a> [storage\_class\_override](#input\_storage\_class\_override) | Override the default storage class selection logic | <pre>object({<br/>    prometheus   = optional(string)<br/>    grafana      = optional(string)<br/>    loki         = optional(string)<br/>    alertmanager = optional(string)<br/>    consul       = optional(string)<br/>    vault        = optional(string)<br/>    traefik      = optional(string)<br/>    portainer    = optional(string)<br/>  })</pre> | `{}` | no |
| <a name="input_traefik_cert_resolver"></a> [traefik\_cert\_resolver](#input\_traefik\_cert\_resolver) | Default certificate resolver for Traefik SSL certificates | `string` | `"wildcard"` | no |
| <a name="input_traefik_dashboard_password"></a> [traefik\_dashboard\_password](#input\_traefik\_dashboard\_password) | Custom password for Traefik dashboard (empty = auto-generate) | `string` | `""` | no |
| <a name="input_use_hostpath_storage"></a> [use\_hostpath\_storage](#input\_use\_hostpath\_storage) | Use hostPath storage (takes effect when use\_nfs\_storage is false) | `bool` | `true` | no |
| <a name="input_use_nfs_storage"></a> [use\_nfs\_storage](#input\_use\_nfs\_storage) | Use NFS storage as primary storage backend | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_applied_service_configs"></a> [applied\_service\_configs](#output\_applied\_service\_configs) | Applied service configurations showing override hierarchy results |
| <a name="output_cert_resolver_debug"></a> [cert\_resolver\_debug](#output\_cert\_resolver\_debug) | n/a |
| <a name="output_cluster_info"></a> [cluster\_info](#output\_cluster\_info) | Cluster information and configuration summary |
| <a name="output_cpu_arch_debug"></a> [cpu\_arch\_debug](#output\_cpu\_arch\_debug) | n/a |
| <a name="output_debug_storage_config"></a> [debug\_storage\_config](#output\_debug\_storage\_config) | n/a |
| <a name="output_detected_architecture"></a> [detected\_architecture](#output\_detected\_architecture) | Auto-detected CPU architecture and cluster analysis |
| <a name="output_enabled_services"></a> [enabled\_services](#output\_enabled\_services) | Summary of enabled services and their status |
| <a name="output_helm_debug"></a> [helm\_debug](#output\_helm\_debug) | n/a |
| <a name="output_mixed_cluster_strategy"></a> [mixed\_cluster\_strategy](#output\_mixed\_cluster\_strategy) | Strategy and recommendations for mixed architecture clusters |
| <a name="output_service_outputs"></a> [service\_outputs](#output\_service\_outputs) | Detailed outputs from all deployed services |
| <a name="output_service_urls"></a> [service\_urls](#output\_service\_urls) | Quick access URLs for deployed services |
| <a name="output_storage_configuration"></a> [storage\_configuration](#output\_storage\_configuration) | Storage configuration details and available storage classes |
| <a name="output_storage_debug"></a> [storage\_debug](#output\_storage\_debug) | n/a |
<!-- END_TF_DOCS -->
