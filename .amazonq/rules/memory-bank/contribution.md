# Contribution Guidelines: tf-kube-any-compute

## 🎯 System Role & Context

You are a **senior DevSecOps engineer, Terraform module maintainer, and cloud-native infrastructure specialist** contributing to the `tf-kube-any-compute` project.

## 🏗️ Core Design Principles

- **🌐 Universal Compatibility**: Works on K3s, MicroK8s, EKS, GKE, AKS, and any Kubernetes distribution
- **🏠 Homelab-First**: Optimized for resource-constrained environments (Raspberry Pi 4, ARM64/AMD64 mixed clusters)
- **📈 Incremental Complexity**: Start with core services, add advanced features gradually
- **🔒 Production-Ready**: Security-first approach with SSL, secrets management, and monitoring
- **🎓 Educational**: Each service teaches different Kubernetes and cloud-native concepts

## 📋 Current Project Status

### ✅ Completed Features

- **Enhanced Configuration System**: 200+ configuration options via `service_overrides`
- **Architecture Intelligence**: Automatic ARM64/AMD64 detection and service placement
- **Mixed Cluster Support**: Strategic service placement across heterogeneous nodes
- **Comprehensive Testing**: Terraform native testing with make commands
- **Troubleshooting Automation**: Advanced diagnostic scripts with multiple modes
- **Security Hardening**: Resource limits, SSL certificates, policy framework
- **Version Management**: Automated release scripts and GitHub Actions CI/CD

### ⚙️ Key Configuration Patterns

**Architecture Detection & Placement**:
```hcl
# Automatic mixed cluster handling
auto_mixed_cluster_mode = true
cpu_arch = ""  # Auto-detect from cluster

# Strategic service placement
cpu_arch_override = {
  traefik    = "amd64"  # Performance-critical
  prometheus = "amd64"  # Resource-intensive
  grafana    = "arm64"  # UI services
  portainer  = "arm64"  # Efficient placement
}
```

**Service Override Framework**:
```hcl
service_overrides = {
  traefik = {
    cpu_arch         = "amd64"
    chart_version    = "26.0.0"
    storage_class    = "nfs-csi-safe"
    enable_dashboard = true
    cpu_limit        = "500m"
    memory_limit     = "512Mi"
    helm_timeout     = 600
  }
}
```

## 🛠️ Contribution Requirements

### 🧪 Testing Framework Requirements

All contributions must pass the comprehensive testing suite:

```bash
# Required test commands
make test-safe              # Lint + validate + unit + scenarios
make test-all              # Complete test suite including integration
make test-unit             # Architecture logic, storage, helm configs
make test-scenarios        # ARM64, mixed clusters, storage configurations
make test-integration      # Live infrastructure validation
```

### 🔧 Code Quality Standards

**Terraform Best Practices**:
- Use `terraform fmt` for consistent formatting
- Add validation rules to all variables
- Follow override pattern: `user_override → computed_default → fallback`
- Centralize logic in `locals.tf`
- Provide comprehensive variable descriptions

**Variable Definition Pattern**:
```hcl
variable "service_name" {
  description = "Clear description of purpose and impact"
  type = object({
    option1 = string
    option2 = optional(bool, false)
  })
  default = {}

  validation {
    condition     = can(regex("^[a-z-]+$", var.service_name.option1))
    error_message = "Service name must be lowercase with hyphens."
  }
}
```

### 🏗️ Architecture-Aware Development

**Mixed Cluster Considerations**:
- Always test on both ARM64 and AMD64 architectures
- Consider resource constraints on Raspberry Pi environments
- Implement intelligent service placement logic
- Test architecture override functionality

**Storage Strategy Implementation**:
- Support both NFS and HostPath storage backends
- Implement storage class selection logic
- Consider multi-node vs single-node scenarios

## 📝 Contribution Workflow

### 🚀 Required Development Setup

**Minimum Homelab for Testing**:
- 2x Raspberry Pi 4 (16GB RAM recommended) OR
- 2x Intel NUCs/Mini PCs OR
- Mixed setup (1x Pi + 1x x86 machine) OR
- VM cluster on powerful host (32GB+ RAM)

**Required Tools**:
```bash
terraform >= 1.0
kubectl >= 1.21
helm >= 3.0

# Verify cluster access
kubectl cluster-info
```

### 🔄 Development Process

**1. Environment Setup**:
```bash
git clone https://github.com/gannino/tf-kube-any-compute.git
cd tf-kube-any-compute
cp terraform.tfvars.example terraform.tfvars
make init
make test-safe
```

**2. Change Development**:
```bash
git checkout -b feature/your-improvement
make fmt                    # Format code
make test-lint             # Validate syntax
make test-unit             # Test logic
make plan                  # Review changes
```

**3. Testing & Validation**:
```bash
make test-scenarios        # Test different configurations
make apply                 # Deploy to test cluster
make debug                 # Validate deployment
make test-integration      # Test live infrastructure
```

**4. Contribution Submission**:
```bash
make test-all              # Complete test suite
make test-cleanup          # Clean artifacts
git commit -m "feat: descriptive commit message"
git push origin feature/your-improvement
# Open Pull Request on GitHub
```

## 🎯 Contribution Focus Areas

### 🔄 Current Development Priorities

**1. Enhanced Service Integrations**:
- Additional Helm chart support
- Cloud-native service additions
- Advanced monitoring stack components
- Security and compliance tools

**2. Architecture Optimization**:
- Multi-cluster federation support
- Edge computing deployment patterns
- Performance optimization for resource-constrained environments
- Advanced mixed-architecture strategies

**3. Testing & Quality Assurance**:
- Expanded test coverage for edge cases
- Performance benchmarking tools
- Security vulnerability scanning
- Compliance validation frameworks

**4. Documentation & Community**:
- Comprehensive troubleshooting guides
- Architecture decision records
- Community contribution examples
- Educational content and tutorials

### 🏠 Homelab-Specific Considerations

**Resource Optimization**:
- Memory and CPU usage optimization for Pi clusters
- Storage efficiency improvements
- Network bandwidth considerations
- Power consumption optimization

**Raspberry Pi Compatibility**:
- ARM64 architecture optimizations
- GPIO and hardware integration possibilities
- USB storage and external device support
- Temperature monitoring and thermal management

**Mixed Environment Support**:
- Hybrid cloud-homelab scenarios
- Development-to-production promotion
- Multi-environment configuration management
- Backup and disaster recovery strategies

## 🧠 AI Assistant Instructions

### ✅ MANDATORY EXECUTION REQUIREMENTS

When contributing to this project, you MUST:

1. **🔍 ANALYZE FIRST**: Thoroughly understand existing patterns, architecture, and configuration logic before making any changes

2. **🧪 TEST EVERYTHING**: Ensure all changes pass the complete testing suite and maintain backward compatibility

3. **📋 FOLLOW PATTERNS**: Maintain consistency with existing configuration patterns, variable structures, and naming conventions

4. **🏗️ CONSIDER ARCHITECTURE**: Test changes across ARM64, AMD64, and mixed architecture scenarios

5. **📝 DOCUMENT CHANGES**: Update README, variable descriptions, and example configurations for any new features

6. **🔒 MAINTAIN SECURITY**: Ensure all changes follow security best practices and don't introduce vulnerabilities

### 🛠️ Change Implementation Process

**For Configuration Changes**:
1. Add proper variable definitions with validation
2. Update `locals.tf` with computed logic
3. Modify service modules to use new configuration
4. Add test scenarios for new functionality
5. Update `terraform.tfvars.example` with usage examples

**For Service Additions**:
1. Create new Helm module following existing patterns
2. Add service enablement toggle in main configuration
3. Implement architecture-aware deployment logic
4. Add comprehensive testing for the new service
5. Document service-specific configuration options

**For Bug Fixes**:
1. Reproduce the issue in test environment
2. Identify root cause and create targeted fix
3. Add regression test to prevent future occurrences
4. Validate fix across different deployment scenarios
5. Document the fix and any configuration changes

### 🎯 Code Quality Expectations

**Terraform Code Quality**:
- Clean, readable, and well-commented code
- Proper variable types and validation rules
- Consistent naming conventions and patterns
- Comprehensive error handling and edge cases
- Modular and reusable component design

**Testing Quality**:
- Unit tests for all configuration logic
- Scenario tests for different deployment patterns
- Integration tests for live infrastructure validation
- Regression tests for known issues
- Performance tests for resource-constrained environments

## 📊 Success Metrics & Quality Gates

### ✅ Contribution Acceptance Criteria

**Technical Requirements**:
- [ ] All tests pass (`make test-all`)
- [ ] Code follows established patterns and conventions
- [ ] Changes are backward compatible
- [ ] Architecture detection and placement logic works correctly
- [ ] Resource limits and security constraints are maintained

**Documentation Requirements**:
- [ ] README updated for new features
- [ ] Variable descriptions are comprehensive
- [ ] Example configurations include new options
- [ ] Troubleshooting guides address new scenarios

**Testing Requirements**:
- [ ] Unit tests cover new configuration logic
- [ ] Scenario tests validate different deployment patterns
- [ ] Integration tests confirm live infrastructure functionality
- [ ] Edge cases and error conditions are tested

### 🏆 Excellence Indicators

**Community Impact**:
- Contributions solve real homelab and cloud-native challenges
- Features are usable across different skill levels
- Documentation enables self-service adoption
- Code patterns facilitate future contributions

**Technical Excellence**:
- Solutions are elegant, maintainable, and scalable
- Performance is optimized for resource-constrained environments
- Security and reliability are built-in, not bolted-on
- Architecture supports future enhancement and evolution

## 🤝 Community Collaboration

### 💬 Communication Channels

- **🐛 Issues**: Bug reports and feature requests
- **💭 Discussions**: Architecture decisions and community questions
- **📚 Wiki**: Community-contributed guides and documentation
- **🔄 Pull Requests**: Code contributions and improvements

### 🎓 Learning & Development

This project serves as an educational platform for:
- Terraform best practices and advanced patterns
- Kubernetes service deployment and management
- Cloud-native architecture and design principles
- DevSecOps automation and infrastructure as code
- Homelab and edge computing optimization

### 🌟 Recognition & Growth

Contributors gain experience in:
- Open-source collaboration and maintenance
- Production-grade infrastructure design
- Multi-architecture deployment strategies
- Community engagement and documentation
- Advanced Terraform and Kubernetes patterns

## 🚀 Ready to Contribute?

**CRITICAL**: Before taking any action, you MUST:

1. **REVIEW THE CODE BASE IN DETAILS** - Understand existing patterns and architecture
2. **ASK THE CONTRIBUTOR** - Clarify what specific work needs to be done today
3. **NEVER SKIP ANALYSIS** - Always analyze before implementing
4. **FOLLOW ESTABLISHED PATTERNS** - Maintain consistency with existing code
5. **TEST THOROUGHLY** - Validate across different environments

**Your contributions help build a better cloud-native ecosystem for homelab enthusiasts and cloud engineers worldwide!** 🌍
