# Cline AI Assistant Rules

This directory contains comprehensive guidelines and rules for the Cline AI assistant to understand and contribute to the **tf-kube-any-compute** project.

## Project Overview

**tf-kube-any-compute** is a universal Kubernetes infrastructure platform that provides comprehensive, cloud-agnostic Kubernetes deployments designed for tech enthusiasts, homelab builders, and learning environments.

**Repository**: https://github.com/gannino/tf-kube-any-compute

## Rule Files

### 1. [guidelines.md](rules/guidelines.md)
Complete development guidelines covering:
- Code quality standards (Terraform formatting, variable organization)
- Structural conventions (module structure, naming conventions)
- Semantic patterns (configuration hierarchy, conditional resources)
- Internal API usage (Kubernetes and Helm provider patterns)
- Code idioms (ternary operators, null coalescing, merge patterns)
- Testing patterns (Terraform test structure, integration tests)
- Security best practices (sensitive data handling, RBAC)
- Performance optimization (resource limits, Helm timeout management)
- Error handling (validation blocks, dependency management)
- Deprecation handling (backward compatibility patterns)
- Python code standards (LDAP auth)
- JavaScript testing standards (K6)

### 2. [product.md](rules/product.md)
Comprehensive product overview including:
- Purpose and value proposition
- Target users and use cases
- Key features and service categories
- Deployment models (Raspberry Pi, K3s, Cloud, Edge)
- Technical highlights and differentiators
- Configuration philosophy (default first, override hierarchy)
- Supported platforms (Kubernetes distributions, hardware, storage)
- Security features (authentication, network security, access control)
- Testing strategy
- Performance optimization
- Documentation structure
- Version management
- Community and support
- Success metrics
- Future roadmap

### 3. [structure.md](rules/structure.md)
Detailed project structure documentation:
- Directory organization (root level, service modules, documentation, testing)
- Module structure pattern
- Architectural patterns (module composition, configuration hierarchy, data flow)
- Dependency management (storage first, CRDs before resources, Traefik before ingress)
- Resource organization (namespaces, storage classes, node affinity)
- Key components (architecture detection, service configuration, middleware, storage, monitoring)
- Naming conventions (resources, variables, modules)
- File organization principles
- Important files summary
- Module dependencies
- Configuration flow
- Testing structure
- Development workflow
- Key patterns to remember

### 4. [tech.md](rules/tech.md)
Complete technology stack reference:
- Core technologies (Terraform, Kubernetes, Helm)
- Terraform providers
- Service technologies (ingress, monitoring, storage, service mesh, security, container management, automation, node discovery)
- Development tools (code quality, testing, CI/CD, pre-commit hooks)
- DNS providers for SSL automation
- Authentication methods
- Build system (Makefile targets)
- Configuration management
- Version management
- Runtime requirements
- Container registries
- Resource requirements
- Security technologies
- Monitoring technologies
- Storage technologies
- Networking technologies
- Automation technologies
- Development technologies
- Deployment technologies
- Troubleshooting tools
- Performance optimization
- Integration technologies
- Container technologies
- Future technology additions

### 5. [development.md](rules/development.md)
Comprehensive development workflow guide:
- Development setup (prerequisites, initial setup)
- Development workflow (code development, pre-commit validation, testing, commit process, code review)
- Module development (creating new service modules with complete templates)
- Testing new modules (unit tests, integration tests)
- Debugging (debug output, pre-commit hooks, configuration validation)
- Best practices (code quality, testing, documentation, security)
- CI/CD integration (GitHub Actions, GitLab CI)
- Troubleshooting common issues
- Performance optimization
- Resources (documentation, tools, community)
- Getting help

## How to Use These Rules

### For Cline AI Assistant

When working on this project, the Cline AI assistant should:

1. **Read All Rules**: Start by reading all rule files to understand the project context
2. **Follow Patterns**: Adhere to the established patterns and conventions
3. **Use Templates**: Reference the templates when creating new modules or features
4. **Test Everything**: Write tests for all new code following the testing patterns
5. **Document Changes**: Update documentation and examples as needed
6. **Maintain Compatibility**: Ensure backward compatibility when making changes

### Key Principles

1. **Architecture Awareness**: Always consider ARM64 and AMD64 architectures
2. **Multi-Platform Support**: Support K3s, MicroK8s, EKS, GKE, AKS
3. **Configuration Hierarchy**: Follow the override hierarchy (system → service → user → overrides → auto-detection)
4. **Two-Step Deployment**: Use the CRD-safe deployment process
5. **Testing First**: Write tests before or alongside code changes
6. **Security First**: Implement RBAC, TLS, and proper secret management
7. **Documentation**: Keep documentation in sync with code changes
8. **Performance**: Optimize for resource-constrained environments (MicroK8s mode)

### Common Tasks

#### Adding a New Service Module
1. Follow the module structure in `structure.md`
2. Use templates from `development.md`
3. Implement with patterns from `guidelines.md`
4. Write tests following testing patterns
5. Update documentation
6. Test on ARM64 and AMD64

#### Fixing Bugs
1. Understand the context from `product.md` and `tech.md`
2. Follow code patterns from `guidelines.md`
3. Fix the issue maintaining backward compatibility
4. Add or update tests
5. Update documentation if needed
6. Test on all supported platforms

#### Updating Documentation
1. Reference the documentation structure from `structure.md`
2. Follow the documentation standards from `guidelines.md`
3. Keep examples current with code changes
4. Update `product.md` if features change
5. Update `tech.md` if technologies change

## Quick Reference

### Module Structure
```
helm-{service}/
├── main.tf              # Primary resource definitions
├── variables.tf         # Input variables (alphabetical)
├── outputs.tf           # Output definitions
├── locals.tf            # Local value computations
├── version.tf           # Provider requirements
├── values.yaml.tpl      # Helm values template
├── templates/           # Additional templates
├── README.md            # Module documentation
└── .tflint.hcl         # Module-specific linting rules
```

### Naming Conventions
- **Resources**: `{service}_{resource_type}`
- **Namespaces**: `{environment}-{service}-system`
- **Releases**: `{environment}-{service}`
- **Variables**: `enable_{feature}`, `use_{option}`, `{service}_override`

### Configuration Hierarchy
1. System defaults (hardcoded)
2. Service defaults (computed)
3. User variables (terraform.tfvars)
4. Service overrides (fine-grained control)
5. Auto-detection (runtime analysis)

### Testing Commands
```bash
make test-quick           # Fast validation
make test-safe            # Non-destructive tests
make test-all             # Comprehensive tests
make test-unit            # Unit tests
make test-scenarios       # Scenario tests
make test-integration     # Integration tests
```

### Pre-commit Hooks
```bash
make pre-commit-install   # Install hooks
make pre-commit-run      # Run all hooks
make pre-commit-fast      # Fast (changed files only)
```

## Related Resources

### Project Documentation
- [README.md](../README.md) - Project overview and quick start
- [CONTRIBUTING.md](../CONTRIBUTING.md) - Contribution guidelines
- [docs/guides/](../docs/guides/) - Detailed user guides
- [docs/reference/](../docs/reference/) - Technical references
- [examples/](../examples/) - Configuration examples

### AI Assistant Rules
- [.amazonq/rules/](../.amazonq/rules/) - Amazon Q AI assistant rules

### External Resources
- [GitHub Repository](https://github.com/gannino/tf-kube-any-compute)
- [GitHub Issues](https://github.com/gannino/tf-kube-any-compute/issues)

## Maintaining These Rules

These rules should be updated when:
- New services are added to the project
- Development patterns change
- New technologies are introduced
- Best practices evolve
- Documentation structure changes

## Version

**Version**: 1.0.0
**Last Updated**: 2026-01-26
**Maintained By**: Project Contributors

---

**Note**: These rules are designed to help the Cline AI assistant understand the project context and follow established patterns. They should be used in conjunction with the main project documentation and examples.
