# Version Update Checklist

## Files That Require Updates When Versions Change

### 🎯 Primary Version Sources
- [ ] `.tool-versions` - **MASTER VERSION FILE**
- [ ] `.github/workflows/versions.yml` - GitHub Actions environment variables

### 🔧 GitHub Actions Workflows
- [ ] `.github/workflows/ci.yml`
- [ ] `.github/workflows/enhanced-ci.yml`
- [ ] `.github/workflows/test.yml`
- [ ] `.github/workflows/release.yml`
- [ ] `.github/workflows/release-readiness.yml`
- [ ] `.github/workflows/comprehensive-ci.yml`
- [ ] `.github/workflows/release-integration.yml`
- [ ] `.github/workflows/release-readiness-fixed.yml`

### 📝 Configuration Files
- [ ] `.tflint.hcl` - TFLint version-specific configuration
- [ ] `.pre-commit-config.yaml` - Hook versions (rev: tags)
- [ ] `versions.tf` - Terraform provider constraints
- [ ] `Makefile` - Tool version references (if any)

### 📚 Documentation
- [ ] `README.md` - Version badges and requirements
- [ ] `CONTRIBUTING.md` - Development tool versions
- [ ] `CHANGELOG.md` - Version update entries

### 🔍 Files to Check (May Need Updates)
- [ ] `scripts/version-manager.sh` - If it exists
- [ ] `docker-compose.yml` - If using containerized tools
- [ ] `Dockerfile` - If building custom images
- [ ] `.devcontainer/devcontainer.json` - VS Code dev container
- [ ] `.vscode/settings.json` - VS Code workspace settings

## 🚀 Update Process

### 1. Update Master Files
```bash
# Update .tool-versions
vim .tool-versions

# Update GitHub Actions env
vim .github/workflows/versions.yml
```

### 2. Sync All Workflows
```bash
# Update all workflow files with new versions
find .github/workflows -name "*.yml" -exec sed -i 's/TF_VERSION: "1.12.2"/TF_VERSION: "NEW_VERSION"/g' {} \;
```

### 3. Update Configuration Files
```bash
# Update pre-commit hooks
pre-commit autoupdate

# Check TFLint compatibility
tflint --version
```

### 4. Test Changes
```bash
make test-safe
make ci-validate
```

### 5. Document Changes
```bash
# Update CHANGELOG.md
echo "- Updated Terraform to vX.X.X" >> CHANGELOG.md
```

## 🔄 Automated Update Script

```bash
#!/bin/bash
# scripts/update-versions.sh

OLD_TF_VERSION="1.12.2"
NEW_TF_VERSION="$1"

if [ -z "$NEW_TF_VERSION" ]; then
  echo "Usage: $0 <new_terraform_version>"
  exit 1
fi

# Update .tool-versions
sed -i "s/terraform $OLD_TF_VERSION/terraform $NEW_TF_VERSION/g" .tool-versions

# Update all workflows
find .github/workflows -name "*.yml" -exec sed -i "s/TF_VERSION: \"$OLD_TF_VERSION\"/TF_VERSION: \"$NEW_TF_VERSION\"/g" {} \;

echo "Updated Terraform version from $OLD_TF_VERSION to $NEW_TF_VERSION"
echo "Please review changes and test before committing"
```

## 📋 Version-Specific Notes

### Terraform Updates
- Check `versions.tf` for provider compatibility
- Test with `terraform init -upgrade`
- Validate all modules work with new version

### TFLint Updates
- Check `.tflint.hcl` configuration compatibility
- Update plugin versions if needed
- Test linting rules still work

### Pre-commit Hook Updates
- Run `pre-commit autoupdate`
- Test hooks with `pre-commit run --all-files`
- Check for breaking changes in hook behavior

### Security Tool Updates
- Checkov: May have new rules
- Trivy: Database updates automatically
- Terrascan: Check policy compatibility

## ⚠️ Breaking Change Checklist

When updating major versions:
- [ ] Test all scenarios in `test-configs/`
- [ ] Check provider compatibility matrix
- [ ] Update minimum version requirements
- [ ] Document breaking changes in CHANGELOG.md
- [ ] Consider deprecation warnings
