# Contributing to Headlamp Module

Thank you for your interest in contributing to the Headlamp module! This document provides guidelines for contributing to this module within the tf-kube-any-compute project.

## Development Workflow

### 1. Setup Development Environment

```bash
# Ensure you're in the headlamp module directory
cd helm-headlamp

# Initialize Terraform (if needed)
terraform init

# Validate configuration
terraform validate

# Format code
terraform fmt
```

### 2. Making Changes

When making changes to this module:

1. **Follow existing patterns** - Look at other service modules (helm-grafana, helm-portainer) for consistency
2. **Update documentation** - Keep README.md and variable descriptions current
3. **Add validation** - Include validation rules for new variables
4. **Test thoroughly** - Test on both ARM64 and AMD64 if possible

### 3. Testing Your Changes

```bash
# Validate syntax
terraform validate

# Format code
terraform fmt -recursive

# Run project tests (from root directory)
cd ..
make test-unit
make test-scenarios
```

## Code Standards

### Variable Naming

- Use lowercase with underscores: `enable_headlamp_ingress`
- Prefix boolean variables with `enable_` or `disable_`
- Be descriptive and concise

### Variable Definitions

All variables must include:
- `description` - Clear explanation of purpose and impact
- `type` - Explicit type definition
- `default` - Sensible default value (unless required)
- `validation` - Validation rules where appropriate

Example:
```hcl
variable "cpu_limit" {
  description = "CPU limit for Headlamp containers. Lower values conserve resources, higher values improve performance."
  type        = string
  default     = "200m"

  validation {
    condition     = can(regex("^[0-9]+m?$", var.cpu_limit))
    error_message = "CPU limit must be in the format <number>m (milli-cores) or <number> (cores)."
  }
}
```

### Output Naming

- Use descriptive names: `headlamp_url`, `helm_status`
- Include relevant context in description

### Local Values

- Group related configurations: `helm_config`, `storage_config`
- Use consistent naming patterns
- Add inline comments for complex logic

## File Organization

### Core Files
- `main.tf` - Primary resources and Helm release
- `variables.tf` - All variable definitions
- `locals.tf` - Local values and configuration logic
- `outputs.tf` - Module outputs
- `limit_range.tf` - Resource limit enforcement
- `version.tf` - Terraform and provider requirements

### Template Files
- `templates/*.yaml.tpl` - Helm chart value templates
- Use `${path.module}` for template paths
- Follow terraform templatefile syntax

### Documentation
- `README.md` - User-facing documentation
- `CONTRIBUTING.md` - This file
- `IMPLEMENTATION-SUMMARY.md` - Implementation notes

## Testing Guidelines

### Unit Testing

Test configuration logic and variable validation:

```bash
terraform test
```

### Integration Testing

Test with actual Kubernetes cluster:

```bash
# From project root
terraform plan -target=module.headlamp
terraform apply -target=module.headlamp
```

### Scenario Testing

Test different deployment scenarios:

1. **ARM64 only**: Raspberry Pi cluster
2. **AMD64 only**: Intel/AMD cluster
3. **Mixed cluster**: ARM64 + AMD64 nodes
4. **With KubeVirt**: Verify plugin integration
5. **Different storage**: NFS vs HostPath
6. **With ingress**: Traefik integration

## Architecture Considerations

### ARM64 Support

- Test on Raspberry Pi or ARM64 VMs
- Use `arm64` images when available
- Consider resource constraints on Pi clusters
- Optimize for memory usage

### AMD64 Support

- Test on Intel/AMD servers
- Use `amd64` images for x86 clusters
- Consider cloud provider specific optimizations
- Optimize for performance

### Mixed Clusters

- Test architecture detection logic
- Verify node affinity rules
- Test service placement
- Validate resource allocation

## Integration Points

### Traefik Integration

- Test ingress configuration
- Verify SSL certificate generation
- Test middleware application
- Validate certificate resolvers

### KubeVirt Integration

- Test plugin auto-enablement
- Verify KubeVirt CRD availability
- Test virtual machine management through Headlamp

### Storage Integration

- Test NFS CSI driver
- Test HostPath storage
- Verify PVC creation
- Test storage class selection

## Documentation Updates

When contributing changes:

1. **Update README.md** if changing user-facing features
2. **Update IMPLEMENTATION-SUMMARY.md** for significant changes
3. **Update terraform.tfvars.example** (at project root) if adding new variables
4. **Add comments** in code for complex logic
5. **Update CHANGELOG.md** (at project root) for user-facing changes

## Pull Request Process

### Before Submitting

1. Run `terraform fmt -recursive`
2. Run `terraform validate`
3. Run project test suite: `make test-safe`
4. Update documentation
5. Test on actual cluster (if possible)

### PR Description

Include in your PR:
- **Purpose**: What changes and why
- **Testing**: How you tested the changes
- **Documentation**: What documentation you updated
- **Scenarios**: What deployment scenarios you tested

### Review Checklist

- [ ] Code follows project patterns
- [ ] Documentation is updated
- [ ] Variables have descriptions
- [ ] Validation rules included
- [ ] Tests pass
- [ ] Tested on ARM64 (if applicable)
- [ ] Tested on AMD64 (if applicable)
- [ ] Integration points verified

## Common Issues

### Terraform Validation Errors

**Issue**: `Invalid index` or `Invalid value for input variable`

**Solution**: Check variable types and values match validation rules

### Helm Chart Issues

**Issue**: Helm release fails to install

**Solution**: Check chart version exists in repository, verify values are correct

### Storage Issues

**Issue**: PVC remains pending

**Solution**: Verify storage class exists and has provisioner configured

### Architecture Issues

**Issue**: Pods won't schedule on specific nodes

**Solution**: Check node labels, verify architecture detection, check node affinity

## Getting Help

- **GitHub Issues**: Report bugs or request features
- **Discussions**: Ask questions or discuss ideas
- **Documentation**: Check README.md and project docs
- **Headlamp Docs**: https://headlamp.dev/docs

## Code Review Process

1. Automated checks (linting, validation)
2. Peer review by maintainers
3. Testing verification
4. Documentation review
5. Approval and merge

## Release Process

Changes to the Headlamp module are released as part of the overall project releases:

1. Changes merged to main branch
2. Version bump in project version file
3. Changelog updated
4. Release tagged
5. Helm chart version updated (if needed)

## Best Practices

### Performance

- Use sensible resource limits
- Optimize for target architecture
- Minimize unnecessary replicas
- Use appropriate storage classes

### Security

- Never hardcode secrets
- Use proper RBAC
- Enable TLS in production
- Use Traefik middleware for additional security

### Maintainability

- Keep code DRY (Don't Repeat Yourself)
- Use consistent naming
- Add comments for complex logic
- Document non-obvious decisions

### Usability

- Provide sensible defaults
- Include clear error messages
- Document edge cases
- Provide usage examples

## Thank You

Your contributions help make tf-kube-any-compute better for everyone. We appreciate your time and effort!

---

For project-wide contribution guidelines, see [CONTRIBUTING.md](../CONTRIBUTING.md) in the project root.
