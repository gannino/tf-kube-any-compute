#!/bin/bash
# Update tool versions across all GitHub Actions workflows
# Usage: ./scripts/update-versions.sh [terraform_version] [tflint_version]

set -e

TERRAFORM_VERSION=${1:-"1.12.2"}
TFLINT_VERSION=${2:-"v0.47.0"}

echo "🔄 Updating versions across GitHub Actions workflows..."
echo "   Terraform: $TERRAFORM_VERSION"
echo "   TFLint: $TFLINT_VERSION"

# Update versions.yml
cat > .github/versions.yml << EOF
# Centralized Version Management
# This file defines all tool versions used across GitHub Actions workflows
# Update versions here and they will be automatically used by all workflows

terraform:
  version: "$TERRAFORM_VERSION"
  min_version: "1.5.0"
  compatibility_test_versions:
    - "1.5.0"
    - "1.6.0"
    - "$TERRAFORM_VERSION"

tflint:
  version: "$TFLINT_VERSION"

actions:
  checkout: "v4"
  setup_terraform: "v3"
  upload_artifact: "v4"
  cache: "v4"
  github_script: "v7"

# Usage in workflows:
# 1. Load this file using a reusable action
# 2. Reference versions using: \${{ fromJson(steps.versions.outputs.data).terraform.version }}
EOF

# Update workflow files
find .github/workflows -name "*.yml" -type f | while read -r file; do
    echo "📝 Updating $file"

    # Update Terraform version in env blocks
    sed -i.bak "s/TF_VERSION: \"[^\"]*\"/TF_VERSION: \"$TERRAFORM_VERSION\"/g" "$file"

    # Update TFLint version in env blocks
    sed -i.bak "s/TFLINT_VERSION: \"[^\"]*\"/TFLINT_VERSION: \"$TFLINT_VERSION\"/g" "$file"

    # Update hardcoded terraform_version in setup steps
    sed -i.bak "s/terraform_version: \"[^\"]*\"/terraform_version: \"$TERRAFORM_VERSION\"/g" "$file"
    sed -i.bak "s/terraform_version: [0-9][^\"]*$/terraform_version: \"$TERRAFORM_VERSION\"/g" "$file"

    # Remove backup files
    rm -f "$file.bak"
done

echo "✅ Version update complete!"
echo ""
echo "📋 Summary:"
echo "   - Updated .github/versions.yml"
echo "   - Updated all workflow files in .github/workflows/"
echo ""
echo "🔍 Verify changes:"
echo "   git diff .github/"
echo ""
echo "💡 Better approach for future:"
echo "   1. Update versions in .github/versions.yml"
echo "   2. Use reusable workflows to load versions automatically"
echo "   3. Run this script only when needed for legacy workflows"
