# Release Management Scripts

This directory contains scripts for managing the version lifecycle of the Terraform module, from pre-release validation to post-release community engagement.

## 📋 **Script Overview**

### 🔍 **pre-release-checklist.sh**

Comprehensive pre-release validation checklist.

```bash
# Run full checklist
./scripts/pre-release-checklist.sh

# Run checklist for specific version
./scripts/pre-release-checklist.sh 2.0.1
```

**Checks:**

- ✅ Git working directory is clean
- ✅ On main/master branch
- ✅ Terraform code is formatted
- ✅ Terraform validation passes
- ✅ Documentation is up to date
- ✅ CHANGELOG.md is updated
- ✅ Version increment is valid
- ✅ All tests pass
- ✅ Security scan passes
- ✅ README.md is complete
- ✅ Examples are working
- ✅ LICENSE file is present
- ✅ Terraform Registry requirements met

### ✅ **validate-version.sh**

Validates a specific version for release readiness.

```bash
# Validate specific version
./scripts/validate-version.sh 2.0.1

# Auto-validate next patch version
./scripts/validate-version.sh
```

**Features:**

- Semantic version format validation
- Version increment validation
- CHANGELOG.md entry verification
- Module structure compliance
- Variable documentation checks
- README requirements validation

### 🚀 **release.sh**

Main release automation script with full lifecycle management.

```bash
# Create releases
./scripts/release.sh patch    # 2.0.0 → 2.0.1
./scripts/release.sh minor    # 2.0.0 → 2.1.0
./scripts/release.sh major    # 2.0.0 → 3.0.0

# Options
./scripts/release.sh patch --dry-run    # Preview changes
./scripts/release.sh minor --force      # Skip validations
```

**Process:**

1. **Validation**: Prerequisites, Terraform, tests
2. **Version Update**: Update version.tf with new version
3. **CHANGELOG Check**: Verify release notes exist
4. **Git Tagging**: Create annotated tag with release notes
5. **GitHub Release**: Automated release creation
6. **Registry Notification**: Prepare for Terraform Registry

### 📢 **post-release.sh**

Post-release community engagement and verification.

```bash
# Process latest release
./scripts/post-release.sh

# Process specific version
./scripts/post-release.sh 2.0.1
```

**Tasks:**

- 🔍 Verify GitHub release exists
- 📦 Check Terraform Registry status
- 📝 Generate community announcements
- 🐦 Create social media content
- 📚 Update documentation links
- 📋 Schedule follow-up tasks

## 🛠️ **Make Integration**

All scripts are integrated into the Makefile for easy access:

```bash
# Pre-release validation
make release-check           # Run pre-release checklist
make release-validate VERSION=2.0.1  # Validate specific version

# Release creation
make release-patch          # Create patch release
make release-minor          # Create minor release
make release-major          # Create major release
make release-dry-run        # Preview patch release

# Post-release
make post-release           # Run post-release tasks
```

## 📋 **Typical Release Workflow**

### 1. **Pre-Release Phase**

```bash
# 1. Ensure you're on main/master with clean working directory
git checkout main
git pull origin main
git status

# 2. Update CHANGELOG.md with release notes
# Add entry for new version with features, fixes, and breaking changes

# 3. Run pre-release checklist
make release-check

# 4. Fix any issues found in checklist
terraform fmt -recursive     # Fix formatting
make test-safe               # Ensure tests pass
# Update documentation as needed
```

### 2. **Release Creation**

```bash
# 1. Preview the release (recommended)
make release-dry-run

# 2. Create the actual release
make release-patch          # For bug fixes
make release-minor          # For new features
make release-major          # For breaking changes

# 3. Verify release was created
git tag --list --sort=-version:refname | head -5
```

### 3. **Post-Release Phase**

```bash
# 1. Run post-release tasks
make post-release

# 2. Share generated content
# - Post LinkedIn content from linkedin-post-v*.md
# - Share Twitter thread from twitter-thread-v*.md
# - Post GitHub announcement from release-announcement-v*.md

# 3. Monitor and follow up
# - Check Terraform Registry within 24-48 hours
# - Respond to community feedback
# - Plan next release based on feedback
```

## 🔧 **Prerequisites**

### Required Tools

- **git** - Version control
- **terraform** - Infrastructure validation
- **make** - Script execution

### Optional Tools (Enhanced Features)

- **gh** - GitHub CLI for release creation
- **trivy** - Security vulnerability scanning
- **terraform-docs** - Documentation generation
- **yamllint** - YAML validation for GitHub workflows

### Installation (macOS)

```bash
# Required
brew install git terraform make

# Optional (recommended)
brew install gh trivy terraform-docs yamllint
```

## 🎯 **Configuration**

### Environment Variables

```bash
# Optional: Set default values
export VERSION=2.0.1                    # Default version for scripts
export GITHUB_TOKEN=ghp_xxxxxxxxxxxx    # For GitHub CLI operations
```

### Script Configuration

Scripts are designed to work out-of-the-box, but you can customize:

- **Repository URLs**: Auto-detected from git remote
- **Release Notes**: Extracted from CHANGELOG.md
- **Version Detection**: From git tags or version.tf
- **Module Name**: Auto-detected from repository name

## 🚨 **Error Handling**

### Common Issues and Solutions

#### **"Git working directory not clean"**

```bash
# Commit or stash changes
git add .
git commit -m "Prepare for release"
# OR
git stash
```

#### **"Terraform validation failed"**

```bash
# Fix formatting and validate
terraform fmt -recursive
terraform validate

# Check for syntax errors in .tf files
```

#### **"Version already exists"**

```bash
# Check existing tags
git tag --list --sort=-version:refname

# Use --force flag to override (use with caution)
./scripts/release.sh patch --force
```

#### **"CHANGELOG.md missing version entry"**

```bash
# Add entry to CHANGELOG.md for your version
## [2.0.1] - 2025-01-09
### Fixed
- Bug fixes and improvements
```

#### **"Tests failed"**

```bash
# Run tests to see failures
make test-safe
make test-validate

# Fix issues and re-run pre-release check
make release-check
```

## 📊 **Monitoring and Metrics**

### Release Metrics to Track

- **Release frequency**: Time between releases
- **Community adoption**: Download/usage statistics
- **Issue resolution**: Time from report to fix
- **Contributor growth**: New contributors per release

### Registry Monitoring

- **Publication delay**: Time from tag to registry availability
- **Version propagation**: Availability across registry endpoints
- **Usage statistics**: Download counts and adoption metrics

## 🤝 **Contributing to Scripts**

### Adding New Checks

To add new validation checks to the pre-release checklist:

1. Add check function to `pre-release-checklist.sh`
2. Add to `CHECKLIST_ITEMS` array
3. Update documentation

### Customizing Release Process

To modify the release workflow:

1. Edit `release.sh` functions
2. Update error handling and validation
3. Test with `--dry-run` flag
4. Update documentation

### Improving Community Content

To enhance post-release content generation:

1. Edit templates in `post-release.sh`
2. Add new content types (blog posts, videos, etc.)
3. Integrate with additional platforms
4. Update follow-up task templates

## 📚 **Additional Resources**

- **Semantic Versioning**: <https://semver.org/>
- **Terraform Registry**: <https://registry.terraform.io/>
- **GitHub CLI**: <https://cli.github.com/>
- **Keep a Changelog**: <https://keepachangelog.com/>

## 🆘 **Support**

If you encounter issues with the release scripts:

1. Check this README for common solutions
2. Review script output for specific error messages
3. Run with `--dry-run` to preview actions
4. Open GitHub issue with script output and environment details

---

**Last Updated**: 2025-01-09
**Script Version**: 1.0.0
**Compatibility**: macOS, Linux (bash 4.0+)
