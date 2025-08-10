#!/bin/bash
# ============================================================================
# Version Sync Script for tf-kube-any-compute
# ============================================================================
#
# Automatically syncs versions from .tool-versions to all configuration files:
# - GitHub Actions workflows
# - Pre-commit hooks
# - Makefiles
# - Documentation
#
# Usage: ./scripts/sync-versions.sh
#
# ============================================================================

set -euo pipefail

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source version manager
source "$SCRIPT_DIR/version-manager.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# ============================================================================
# Sync Functions
# ============================================================================

sync_github_actions() {
    log_info "Syncing GitHub Actions workflows..."

    local workflow_file="$PROJECT_ROOT/.github/workflows/comprehensive-ci.yml"

    if [[ ! -f "$workflow_file" ]]; then
        log_error "GitHub Actions workflow not found: $workflow_file"
        return 1
    fi

    # Create backup
    cp "$workflow_file" "$workflow_file.backup"

    # Update versions in workflow
    local tf_version tflint_version terraform_docs_version checkov_version
    local tfsec_version trivy_version terrascan_version microk8s_channel

    tf_version=$(get_version terraform)
    tflint_version="v$(get_version tflint)"
    terraform_docs_version="v$(get_version terraform-docs)"
    checkov_version=$(get_version checkov)
    tfsec_version=$(get_version tfsec)
    trivy_version=$(get_version trivy)
    terrascan_version=$(get_version terrascan)
    microk8s_channel=$(get_version microk8s)

    # Update the env section
    sed -i.tmp "s/TF_VERSION: \".*\"/TF_VERSION: \"$tf_version\"/" "$workflow_file"
    sed -i.tmp "s/TFLINT_VERSION: \".*\"/TFLINT_VERSION: \"$tflint_version\"/" "$workflow_file"
    sed -i.tmp "s/TERRAFORM_DOCS_VERSION: \".*\"/TERRAFORM_DOCS_VERSION: \"$terraform_docs_version\"/" "$workflow_file"
    sed -i.tmp "s/CHECKOV_VERSION: \".*\"/CHECKOV_VERSION: \"$checkov_version\"/" "$workflow_file"
    sed -i.tmp "s/TFSEC_VERSION: \".*\"/TFSEC_VERSION: \"$tfsec_version\"/" "$workflow_file"
    sed -i.tmp "s/TRIVY_VERSION: \".*\"/TRIVY_VERSION: \"$trivy_version\"/" "$workflow_file"
    sed -i.tmp "s/TERRASCAN_VERSION: \".*\"/TERRASCAN_VERSION: \"$terrascan_version\"/" "$workflow_file"
    sed -i.tmp "s/MICROK8S_CHANNEL: \".*\"/MICROK8S_CHANNEL: \"$microk8s_channel\"/" "$workflow_file"

    # Clean up temp file
    rm -f "$workflow_file.tmp"

    log_success "Updated GitHub Actions workflow"
}

sync_precommit_hooks() {
    log_info "Syncing pre-commit hooks..."

    local precommit_file="$PROJECT_ROOT/.pre-commit-config.yaml"

    if [[ ! -f "$precommit_file" ]]; then
        log_error "Pre-commit config not found: $precommit_file"
        return 1
    fi

    # Create backup
    cp "$precommit_file" "$precommit_file.backup"

    # Get versions
    local detect_secrets_version conventional_commit_version markdownlint_version
    local yamllint_version shellcheck_version

    detect_secrets_version="v1.4.0"  # This needs manual mapping
    conventional_commit_version="v3.0.0"  # This needs manual mapping
    markdownlint_version="v$(get_version markdownlint-cli)"
    yamllint_version="v$(get_version yamllint)"
    shellcheck_version="v$(get_version shellcheck)"

    log_warning "Pre-commit hook versions need manual verification"
    log_info "Current versions detected:"
    echo "  - detect-secrets: $detect_secrets_version"
    echo "  - conventional-pre-commit: $conventional_commit_version"
    echo "  - markdownlint-cli: $markdownlint_version"
    echo "  - yamllint: $yamllint_version"
    echo "  - shellcheck-py: $shellcheck_version"
}

sync_makefile() {
    log_info "Syncing Makefile versions..."

    # Makefile uses the version manager script, so no direct sync needed
    log_success "Makefile uses version-manager.sh - no sync required"
}

sync_documentation() {
    log_info "Syncing documentation versions..."

    local readme_file="$PROJECT_ROOT/README.md"

    if [[ ! -f "$readme_file" ]]; then
        log_error "README.md not found: $readme_file"
        return 1
    fi

    # Update version references in README
    local terraform_version helm_version kubectl_version

    terraform_version=$(get_version terraform)
    helm_version=$(get_version helm)
    kubectl_version=$(get_version kubectl)

    log_info "Key versions for documentation:"
    echo "  - Terraform: $terraform_version"
    echo "  - Helm: $helm_version"
    echo "  - kubectl: $kubectl_version"

    log_warning "Documentation versions should be updated manually"
}

generate_version_report() {
    log_info "Generating version sync report..."

    local report_file="$PROJECT_ROOT/VERSION-SYNC-REPORT.md"

    cat > "$report_file" << EOF
# Version Sync Report

**Generated**: $(date)
**Script**: scripts/sync-versions.sh

## Tool Versions

$(./scripts/version-manager.sh list)

## Sync Status

### ✅ GitHub Actions
- Workflow: .github/workflows/comprehensive-ci.yml
- Status: Synced automatically
- Backup: .github/workflows/comprehensive-ci.yml.backup

### ⚠️ Pre-commit Hooks
- Config: .pre-commit-config.yaml
- Status: Manual verification required
- Backup: .pre-commit-config.yaml.backup

### ✅ Makefile
- File: Makefile
- Status: Uses version-manager.sh (no sync needed)

### ⚠️ Documentation
- File: README.md
- Status: Manual update recommended

## Next Steps

1. Review and commit synced files
2. Manually verify pre-commit hook versions
3. Update documentation with current versions
4. Test all tools with new versions

## Commands

\`\`\`bash
# Validate all versions
make version-validate

# Check for outdated versions
make version-check-outdated

# Get specific version
make version-get TOOL=terraform

# Update specific version
make version-update TOOL=terraform VERSION=1.6.0
\`\`\`

EOF

    log_success "Generated version sync report: $report_file"
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
    log_info "Starting version synchronization..."

    # Validate versions first
    if ! validate_versions; then
        log_error "Version validation failed. Please fix .tool-versions first."
        exit 1
    fi

    # Sync all configuration files
    sync_github_actions
    sync_precommit_hooks
    sync_makefile
    sync_documentation

    # Generate report
    generate_version_report

    log_success "Version synchronization completed!"

    echo ""
    log_info "Summary of changes:"
    echo "  - Updated GitHub Actions workflow"
    echo "  - Created backups of modified files"
    echo "  - Generated version sync report"
    echo ""
    log_warning "Manual actions required:"
    echo "  - Verify pre-commit hook versions"
    echo "  - Update documentation versions"
    echo "  - Test updated configurations"
    echo ""
    log_info "Run 'make version-validate' to verify all versions"
}

# Show help
show_help() {
    cat << EOF
Version Sync Script for tf-kube-any-compute

DESCRIPTION:
    Automatically syncs versions from .tool-versions to all configuration files

USAGE:
    $0 [OPTIONS]

OPTIONS:
    --help, -h    Show this help message

WHAT IT DOES:
    1. Validates .tool-versions file
    2. Updates GitHub Actions workflows
    3. Provides guidance for pre-commit hooks
    4. Generates version sync report
    5. Creates backups of modified files

INTEGRATION:
    # Run as part of version update workflow
    make version-update TOOL=terraform VERSION=1.6.0
    ./scripts/sync-versions.sh
    git add -A && git commit -m "chore: update terraform to 1.6.0"

EOF
}

# Handle command line arguments
case "${1:-}" in
    --help|-h)
        show_help
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac
