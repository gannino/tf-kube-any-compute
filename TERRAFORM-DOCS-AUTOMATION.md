# Terraform Docs Automation

This document describes the comprehensive terraform-docs automation system implemented for tf-kube-any-compute.

## Overview

The terraform-docs automation provides:

- **Consistent Documentation**: Standardized format across all modules
- **CI/CD Integration**: Automated validation in GitHub Actions
- **Local Development**: Pre-commit hooks for immediate feedback
- **Version Management**: Centralized version control
- **Cross-Platform Support**: Works on Linux and macOS

## Architecture

```
.github/
├── versions.yml                    # Centralized version management
└── workflows/
    └── ci-consolidated.yml         # CI integration

.pre-commit-hooks/
├── terraform-docs-automation.sh   # Main automation script
└── terraform-docs-recursive.sh    # Pre-commit wrapper

scripts/
└── install-terraform-docs.sh      # Local installation script

.terraform-docs.yml                # Configuration file
.pre-commit-config.yaml            # Pre-commit integration
Makefile                           # Make commands
```

## Features

### 🔄 Automated Documentation Generation

- **Multi-Module Support**: Processes root and all helm-* modules
- **Consistent Format**: Uses markdown table format with standardized sections
- **Injection Mode**: Updates existing README.md files between markers
- **Error Handling**: Clear feedback on what needs to be fixed

### 🚀 CI/CD Integration

- **Version Consistency**: Uses centralized version from `.github/versions.yml`
- **Validation**: Fails CI if documentation is out of date
- **Clear Errors**: Shows exactly which files and what differences exist
- **Fast Feedback**: Runs in parallel with other CI jobs

### 🛠️ Local Development

- **Pre-commit Hooks**: Automatic validation before commits
- **Make Commands**: Easy-to-use commands for developers
- **Installation**: Automatic terraform-docs installation
- **Cross-Platform**: Works on Linux and macOS

## Usage

### Local Development

```bash
# Install terraform-docs
make docs-install

# Generate documentation for all modules
make docs

# Check if documentation is up to date
make docs-check

# Direct script usage
./.pre-commit-hooks/terraform-docs-automation.sh install
./.pre-commit-hooks/terraform-docs-automation.sh update
./.pre-commit-hooks/terraform-docs-automation.sh check
```

### Pre-commit Integration

The system automatically runs when you commit:

```bash
git add .
git commit -m "Update configuration"
# terraform-docs validation runs automatically
```

### CI/CD Pipeline

Documentation validation runs automatically in GitHub Actions:

- ✅ **Passes**: Documentation is up to date
- ❌ **Fails**: Shows which files need updates and exact differences

## Configuration

### Version Management

Versions are centrally managed in `.github/versions.yml`:

```yaml
terraform_docs_version: "v0.17.0"
```

### Documentation Format

Configuration in `.terraform-docs.yml`:

```yaml
formatter: "markdown table"
output:
  file: "README.md"
  mode: inject
  template: |-
    <!-- BEGIN_TF_DOCS -->
    {{ .Content }}
    <!-- END_TF_DOCS -->
```

### README.md Structure

Each module's README.md should include markers:

```markdown
# Module Name

Description of the module.

<!-- BEGIN_TF_DOCS -->
<!-- Terraform docs will be injected here -->
<!-- END_TF_DOCS -->
```

## Error Handling

### Common Issues and Solutions

#### 1. Documentation Out of Date

**Error**: `Documentation is out of date in helm-traefik`

**Solution**:
```bash
make docs  # Update all documentation
# or
./.pre-commit-hooks/terraform-docs-automation.sh update
```

#### 2. Missing README.md

**Error**: `README.md not found in helm-example`

**Solution**: The script automatically creates README.md with proper markers.

#### 3. Missing Markers

**Error**: `terraform-docs markers not found`

**Solution**: The script automatically adds the required markers:
```markdown
<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
```

#### 4. terraform-docs Not Installed

**Error**: `terraform-docs not found`

**Solution**:
```bash
make docs-install
# or
./.pre-commit-hooks/terraform-docs-automation.sh install
```

## Development Workflow

### Adding New Modules

1. Create module directory with `.tf` files
2. Run `make docs` to generate initial documentation
3. Customize README.md content around the terraform-docs markers
4. Commit changes - pre-commit hooks will validate

### Updating Existing Modules

1. Modify Terraform configuration
2. Run `make docs-check` to see if docs need updates
3. Run `make docs` to update documentation
4. Commit changes

### Version Updates

1. Update `terraform_docs_version` in `.github/versions.yml`
2. Run `make docs-install` to update local installation
3. Test with `make docs-check`
4. Commit version update

## Troubleshooting

### Debug Mode

Enable verbose output:

```bash
# Check what the automation script is doing
bash -x ./.pre-commit-hooks/terraform-docs-automation.sh check
```

### Manual Installation

If automatic installation fails:

```bash
# Download manually
VERSION="v0.17.0"
PLATFORM="linux_amd64"  # or darwin_amd64 for macOS
curl -sSL "https://terraform-docs.io/dl/${VERSION}/terraform-docs-${VERSION}-${PLATFORM}.tar.gz" | tar -xz
sudo mv terraform-docs /usr/local/bin/
```

### CI/CD Issues

Check GitHub Actions logs for:

1. **Installation failures**: Network issues or version problems
2. **Permission errors**: File system permissions
3. **Git differences**: Exact changes needed

### Pre-commit Issues

```bash
# Reinstall pre-commit hooks
pre-commit uninstall
pre-commit install

# Run specific hook
pre-commit run terraform-docs-automation --all-files

# Skip hooks temporarily
git commit --no-verify -m "Skip pre-commit for this commit"
```

## Best Practices

### Documentation Standards

1. **Keep descriptions clear**: Use concise, helpful descriptions
2. **Use examples**: Include usage examples in module README.md
3. **Update regularly**: Run `make docs` after configuration changes
4. **Review changes**: Check generated docs before committing

### CI/CD Integration

1. **Fast feedback**: Documentation validation runs early in CI
2. **Clear errors**: CI shows exactly what needs to be fixed
3. **Consistent versions**: Use centralized version management
4. **Parallel execution**: Runs alongside other validations

### Local Development

1. **Pre-commit hooks**: Always use pre-commit for immediate feedback
2. **Make commands**: Use standardized make commands
3. **Version consistency**: Keep local tools in sync with CI
4. **Regular updates**: Update terraform-docs version regularly

## Advanced Configuration

### Custom Templates

Modify `.terraform-docs.yml` for custom output:

```yaml
content: |-
  {{ .Header }}

  ## Custom Section

  {{ .Requirements }}
  {{ .Providers }}
  {{ .Modules }}
  {{ .Resources }}
  {{ .Inputs }}
  {{ .Outputs }}
```

### Module-Specific Configuration

Create `.terraform-docs.yml` in specific modules for custom behavior:

```yaml
# helm-traefik/.terraform-docs.yml
header-from: HEADER.md
footer-from: FOOTER.md
```

### Integration with Other Tools

The automation integrates with:

- **TFLint**: Runs alongside linting
- **Terraform validate**: Complements validation
- **Security scanning**: Part of comprehensive CI
- **Release automation**: Ensures docs are current

## Migration Guide

### From Manual Process

1. Remove manual terraform-docs commands from scripts
2. Add markers to existing README.md files
3. Run `make docs` to generate initial documentation
4. Set up pre-commit hooks
5. Update CI/CD to use new automation

### From Other Automation

1. Review existing configuration
2. Migrate settings to `.terraform-docs.yml`
3. Update version management
4. Test with `make docs-check`
5. Update CI/CD workflows

## Support

### Getting Help

1. **Documentation**: This file and inline script comments
2. **Make commands**: `make help` for available commands
3. **Script help**: `./.pre-commit-hooks/terraform-docs-automation.sh --help`
4. **GitHub Issues**: Report problems or request features

### Contributing

1. **Test changes**: Use `make docs-check` and `make docs`
2. **Update documentation**: Keep this file current
3. **Version compatibility**: Test with different terraform-docs versions
4. **Cross-platform**: Test on Linux and macOS

## Changelog

### v1.0.0 (Current)

- ✅ Comprehensive automation script
- ✅ CI/CD integration
- ✅ Pre-commit hooks
- ✅ Version management
- ✅ Cross-platform support
- ✅ Error handling and debugging
- ✅ Make command integration
- ✅ Documentation and examples

### Future Enhancements

- 🔄 Module-specific templates
- 🔄 Integration with terraform registry
- 🔄 Automated version updates
- 🔄 Performance optimizations
- 🔄 Additional output formats
