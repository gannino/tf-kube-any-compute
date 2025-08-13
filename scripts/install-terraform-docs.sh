#!/bin/bash
# Terraform Docs Installation Script
# Installs terraform-docs for local development with version consistency

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
VERSIONS_FILE="${PROJECT_ROOT}/.github/versions.yml"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Get version from versions file
get_version() {
    if [[ -f "${VERSIONS_FILE}" ]]; then
        grep "terraform_docs_version:" "${VERSIONS_FILE}" | cut -d'"' -f2 | tr -d ' '
    else
        echo "v0.17.0"  # fallback
    fi
}

# Main installation
main() {
    log_info "Installing terraform-docs for local development..."

    # Use the automation script
    if [[ -f "${PROJECT_ROOT}/.pre-commit-hooks/terraform-docs-automation.sh" ]]; then
        "${PROJECT_ROOT}/.pre-commit-hooks/terraform-docs-automation.sh" install
    else
        log_error "Automation script not found"
        exit 1
    fi

    # Verify installation
    if command -v terraform-docs >/dev/null 2>&1; then
        local version
        version=$(terraform-docs version 2>/dev/null | grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+' || echo "unknown")
        log_success "terraform-docs ${version} installed and ready"

        # Show usage
        echo ""
        log_info "Usage examples:"
        echo "  make docs          # Generate docs for all modules"
        echo "  make docs-check    # Check if docs are up to date"
        echo "  terraform-docs .   # Generate docs for current directory"
        echo ""
    else
        log_error "Installation verification failed"
        exit 1
    fi
}

main "$@"
