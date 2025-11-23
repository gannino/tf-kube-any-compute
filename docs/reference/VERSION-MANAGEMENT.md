# 🔧 Version Management System

## Overview

The tf-kube-any-compute project uses a centralized version management system to maintain consistency across all tools, CI/CD pipelines, and development environments.

## 📁 Files Structure

```
tf-kube-any-compute/
├── .tool-versions                    # Central version definitions
├── .github/
│   ├── env.yml                      # GitHub Actions environment variables
│   └── workflows/*.yml              # CI workflows with version references
├── .pre-commit-config.yaml          # Pre-commit hooks with versions
└── scripts/
    ├── version-manager.sh           # Version management CLI
    └── sync-versions.sh             # Automatic version synchronization
```

## 🎯 Core Components

### 1. `.tool-versions` - Central Version Registry

Single source of truth for all tool versions:

```bash
# Core Infrastructure Tools
terraform 1.12.2
kubectl 1.31.0
helm 3.16.0

# Security Scanning Tools
checkov 3.2.0
trivy 0.50.0
terrascan 1.19.1

# Code Quality Tools
tflint 0.47.0
terraform-docs 0.17.0
pre-commit 3.6.0
```

### 2. `scripts/version-manager.sh` - Version Management CLI

```bash
# Get version for specific tool
./scripts/version-manager.sh get terraform

# List all tools and versions
./scripts/version-manager.sh list

# Update version for specific tool
./scripts/version-manager.sh update terraform 1.6.0

# Validate all tool versions
./scripts/version-manager.sh validate

# Generate CI environment variables
./scripts/version-manager.sh generate-ci-env
```

### 3. `scripts/sync-versions.sh` - Automatic Synchronization

Automatically syncs versions across all configuration files.

## 🚀 Usage Guide

### Daily Development

```bash
# Check current versions
make versions

# Get specific tool version
make version-get TOOL=terraform

# Validate all versions are consistent
make version-validate
```

### Updating Tool Versions

```bash
# Update a single tool
make version-update TOOL=terraform VERSION=1.6.0

# Sync changes across all files
make version-sync

# Validate everything is consistent
make version-validate
```

## 📋 Available Make Commands

| Command | Description | Example |
|---------|-------------|---------|
| `make versions` | Show all tool versions | `make versions` |
| `make version-get` | Get version for specific tool | `make version-get TOOL=terraform` |
| `make version-update` | Update version for specific tool | `make version-update TOOL=terraform VERSION=1.6.0` |
| `make version-validate` | Validate all tool versions | `make version-validate` |
| `make version-sync` | Sync versions across config files | `make version-sync` |

## 🔄 Version Update Workflow

### Standard Update Process

```bash
# 1. Update the tool version
make version-update TOOL=terraform VERSION=1.6.0

# 2. Sync across all configuration files
./scripts/sync-versions.sh

# 3. Validate everything is consistent
make version-validate

# 4. Test the changes
make test-safe

# 5. Commit the changes
git add -A
git commit -m "chore: update terraform to 1.6.0"
```

### Bulk Update Process

```bash
# Update multiple tools
make version-update TOOL=terraform VERSION=1.6.0
make version-update TOOL=kubectl VERSION=1.32.0
make version-update TOOL=helm VERSION=3.17.0

# Sync all changes
./scripts/sync-versions.sh

# Validate and test
make version-validate
make test-safe

# Commit all changes
git add -A
git commit -m "chore: update infrastructure tools

- terraform: 1.5.0 → 1.6.0
- kubectl: 1.31.0 → 1.32.0
- helm: 3.16.0 → 3.17.0"
```

## 🔍 Validation and Quality Assurance

### Automatic Validation

The system includes several validation mechanisms:

1. **Duplicate Detection**: Prevents duplicate tool entries
2. **Empty Version Detection**: Ensures all tools have versions
3. **Format Validation**: Validates `.tool-versions` file format
4. **Consistency Checks**: Verifies versions across files match

### Manual Verification

```bash
# Validate all versions
make version-validate

# Check for inconsistencies
./scripts/version-manager.sh validate

# Generate sync report
./scripts/sync-versions.sh
```

## 🛠️ Troubleshooting

### Common Issues

#### Version Not Found

```bash
Error: Version not found for tool 'terraform'
```

**Solution**: Add the tool to `.tool-versions`:
```bash
echo "terraform 1.12.2" >> .tool-versions
```

#### Duplicate Tool Entries

```bash
Error: Duplicate tool entries found: terraform
```

**Solution**: Remove duplicate entries from `.tool-versions`

#### Inconsistent Versions

```bash
Warning: GitHub Actions uses different version than .tool-versions
```

**Solution**: Run version sync:
```bash
./scripts/sync-versions.sh
```

## 📊 Version Alignment Status

### ✅ Aligned Versions

| Tool | Version | Status |
|------|---------|--------|
| Terraform | 1.12.2 | ✅ Consistent |
| TFLint | v0.55.0 | ✅ Consistent |
| Terraform Docs | v0.17.0 | ✅ Consistent |
| Checkov | 3.2.0 | ✅ Consistent |
| Trivy | 0.50.0 | ✅ Consistent |

### Version Update Checklist

When updating versions, check these files:

#### Primary Version Sources
- [ ] `.tool-versions` - **MASTER VERSION FILE**
- [ ] `.github/workflows/versions.yml` - GitHub Actions environment variables

#### GitHub Actions Workflows
- [ ] `.github/workflows/ci-consolidated.yml`
- [ ] `.github/workflows/release-consolidated.yml`

#### Configuration Files
- [ ] `.tflint.hcl` - TFLint version-specific configuration
- [ ] `.pre-commit-config.yaml` - Hook versions
- [ ] `versions.tf` - Terraform provider constraints

#### Documentation
- [ ] `README.md` - Version badges and requirements
- [ ] `CONTRIBUTING.md` - Development tool versions
- [ ] `CHANGELOG.md` - Version update entries

## 📚 Best Practices

### Version Management

1. **Use Semantic Versioning**: Follow semver for internal tools
2. **Test Before Updating**: Always test version updates
3. **Document Breaking Changes**: Note compatibility issues
4. **Batch Related Updates**: Update related tools together
5. **Maintain Compatibility**: Ensure tool compatibility

### Development Workflow

1. **Check Versions First**: Always check current versions before starting work
2. **Update Regularly**: Keep tools reasonably up-to-date
3. **Test Thoroughly**: Test version changes in CI/CD
4. **Document Changes**: Include version changes in commit messages
5. **Communicate Updates**: Notify team of significant version changes

## 🤝 Contributing

### Adding New Tools

1. Add tool to `.tool-versions`:
   ```bash
   echo "newtool 1.0.0" >> .tool-versions
   ```

2. Sync configurations:
   ```bash
   ./scripts/sync-versions.sh
   ```

3. Test and commit:
   ```bash
   make version-validate
   git add -A && git commit -m "feat: add newtool version management"
   ```

This centralized version management system ensures consistency, reduces maintenance overhead, and makes it easy to keep all tools up-to-date across the entire project.
