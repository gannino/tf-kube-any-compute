# 🚀 Contributor Quick Start Guide

Welcome to tf-kube-any-compute! This guide will get you up and running as a contributor in minutes.

## 📋 Prerequisites Checklist

Before you start, ensure you have these tools installed:

### Required Tools
- [ ] **Git** - Version control
- [ ] **Terraform** >= 1.0 - Infrastructure as Code
- [ ] **kubectl** - Kubernetes CLI
- [ ] **Helm** >= 3.0 - Kubernetes package manager
- [ ] **Make** - Build automation
- [ ] **Python** >= 3.8 - For pre-commit hooks

### Recommended Tools
- [ ] **Docker** - Container runtime (for testing)
- [ ] **jq** - JSON processor
- [ ] **yq** - YAML processor

## 🛠️ Development Environment Setup

### 1. Fork and Clone

```bash
# Fork the repository on GitHub, then clone your fork
git clone https://github.com/YOUR_USERNAME/tf-kube-any-compute.git
cd tf-kube-any-compute

# Add upstream remote
git remote add upstream https://github.com/gannino/tf-kube-any-compute.git
```

### 2. Install Pre-commit Hooks

```bash
# Install pre-commit (if not already installed)
pip install pre-commit

# Set up pre-commit hooks
make pre-commit-install

# Test the setup
pre-commit run --all-files
```

### 3. Set Up Configuration

```bash
# Copy example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit for your environment (optional for development)
# Most tests work with default values
```

### 4. Initialize Terraform

```bash
# Initialize Terraform
make init

# Validate configuration
make validate
```

## 🧪 Testing Your Setup

Run these commands to verify everything works:

```bash
# Quick validation tests (safe - no deployment)
make test-safe

# Check formatting and linting
make test-lint

# Run unit tests
make test-unit

# Generate documentation
make docs
```

If all tests pass, you're ready to contribute! 🎉

## ⚡ Performance Optimized Development

We've optimized the development experience for contributor productivity:

### Fast Pre-commit (Default)
- **Runtime**: ~2-5 minutes (was ~50 minutes)
- **Scope**: Only changed .tf files
- **Rules**: Essential rules only (disabled expensive checks)
- **Usage**: Automatic on `git commit`

### Full Linting (Optional)
- **Runtime**: ~15-20 minutes
- **Scope**: All modules recursively
- **Rules**: All rules enabled
- **Usage**: `make lint-full` before submitting PR

### What's Optimized

**Pre-commit runs optimized TFLint that:**
- ✅ Only checks changed .tf files (not entire repository)
- ✅ Disables expensive rules:
  - `terraform_module_pinned_source` - not needed for local modules
  - `terraform_standard_module_structure` - we have custom structure
  - `terraform_workspace_remote` - not relevant for local dev
  - `terraform_documented_outputs` - allows debug outputs
- ✅ Uses compact output format
- ✅ Skips if no .tf files changed

**Full linting (`make lint-full`) runs:**
- 🔍 Recursive check on all modules
- 🔍 All TFLint rules enabled
- 🔍 Comprehensive validation

### Available Commands

```bash
make help          # Show all available commands
make lint          # Fast linting (same as pre-commit)
make lint-full     # Thorough linting (all rules, all modules)
make test-quick    # Fast tests (lint + validate)
make test-all      # All tests including full linting
make docs          # Generate terraform-docs
```

### Performance Comparison

| Check Type | Old Time | New Time | Scope |
|------------|----------|----------|-------|
| Pre-commit | ~50 mins | ~2-5 mins | Changed files only |
| Full lint | ~50 mins | ~15-20 mins | All modules |
| CI/CD | ~50 mins | ~5-10 mins | Optimized rules |

## 🔄 Development Workflow

### 1. Create a Feature Branch

```bash
# Update your main branch
git checkout main
git pull upstream main

# Create feature branch
git checkout -b feature/your-feature-name
```

### 2. Make Your Changes

- Edit files as needed
- Follow the coding standards in [CONTRIBUTING.md](CONTRIBUTING.md)
- Add tests for new functionality
- Update documentation

### 3. Test Your Changes

```bash
# Run tests before committing
make test-safe

# Check specific areas
make test-lint      # Formatting and linting
make test-unit      # Unit tests
make test-scenarios # Scenario tests
make docs          # Update documentation
```

### 4. Commit Your Changes

```bash
# Stage your changes
git add .

# Commit (pre-commit hooks will run automatically)
git commit -m "feat: add new feature description"

# Push to your fork
git push origin feature/your-feature-name
```

### 5. Create Pull Request

1. Go to GitHub and create a Pull Request
2. Fill out the PR template
3. Wait for CI checks to pass
4. Address any review feedback

## 🎯 Good First Issues

Looking for something to work on? Try these beginner-friendly areas:

### Documentation Improvements
- [ ] Fix typos or unclear explanations
- [ ] Add more examples to module READMEs
- [ ] Improve troubleshooting guides
- [ ] Add architecture diagrams

### Testing Enhancements
- [ ] Add more test scenarios
- [ ] Improve test coverage
- [ ] Add integration tests
- [ ] Test on different architectures

### Code Quality
- [ ] Fix linting issues
- [ ] Improve error messages
- [ ] Add input validation
- [ ] Optimize resource usage

### New Features
- [ ] Add support for new services
- [ ] Improve ARM64 compatibility
- [ ] Add new configuration options
- [ ] Enhance monitoring capabilities

## 🔧 Common Development Tasks

### Running Specific Tests

```bash
# Test specific modules
terraform test -filter=tests.tftest.hcl -verbose

# Test specific scenarios
make ci-test-scenarios

# Security scanning
make test-security

# Performance testing (requires k6)
make test-performance
```

### Working with Documentation

```bash
# Generate all module documentation
make docs

# Check documentation is up to date
make docs-check

# Install terraform-docs tool
make docs-install
```

### Debugging Issues

```bash
# Show tool versions
make version

# Environment detection
make detect-environment

# Troubleshooting guide
make troubleshoot

# Debug CI environment
make ci-debug
```

## 🚨 Common Issues and Solutions

### Pre-commit Hooks Failing

```bash
# Update hooks
pre-commit autoupdate

# Run specific hook
pre-commit run terraform-fmt --all-files

# Skip hooks temporarily (not recommended)
git commit --no-verify
```

### Terraform Validation Errors

```bash
# Reinitialize Terraform
rm -rf .terraform .terraform.lock.hcl
make init

# Check for syntax errors
terraform fmt -check -recursive
terraform validate
```

### Test Failures

```bash
# Clean test artifacts
make test-cleanup

# Run tests with verbose output
terraform test -verbose

# Check specific test file
terraform test -filter=tests.tftest.hcl -verbose
```

### Documentation Out of Date

```bash
# Regenerate documentation
make docs

# Check what changed
git diff

# Commit documentation updates
git add . && git commit -m "docs: update module documentation"
```

## 📚 Learning Resources

### Terraform
- [Terraform Documentation](https://terraform.io/docs)
- [Terraform Testing](https://developer.hashicorp.com/terraform/language/tests)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)

### Kubernetes
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Helm Documentation](https://helm.sh/docs/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

### Project Specific
- [Main README](README.md) - Project overview
- [CONTRIBUTING.md](CONTRIBUTING.md) - Detailed contribution guidelines
- [VARIABLES.md](VARIABLES.md) - Configuration options
- [Makefile](Makefile) - Available commands

## 🤝 Getting Help

### Community Support
- **GitHub Issues** - Report bugs or request features
- **GitHub Discussions** - Ask questions and share ideas
- **Pull Request Reviews** - Get feedback on your code

### Mentorship
New contributors can request help with:
- Understanding the codebase
- Choosing good first issues
- Code review feedback
- Architecture decisions

### Contact
- Create an issue with the `help-wanted` label
- Tag maintainers in discussions
- Join community conversations

## 🎉 Recognition

Contributors are recognized through:
- **README Credits** - Listed in project contributors
- **Release Notes** - Contributions mentioned in changelogs
- **Community Highlights** - Featured in discussions
- **Learning Opportunities** - Gain Kubernetes and Terraform expertise

---

**Ready to contribute?** Pick an issue, follow this guide, and join our community of homelab enthusiasts! 🏠🚀

*Questions? Create an issue with the `question` label and we'll help you get started.*
