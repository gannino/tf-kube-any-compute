#!/bin/bash
# Terraform Docs Automation Script
# Handles terraform-docs generation and validation for CI/CD and local development
# Supports both Linux and macOS environments

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
VERSIONS_FILE="${PROJECT_ROOT}/.github/versions.yml"
TERRAFORM_DOCS_CONFIG="${PROJECT_ROOT}/.terraform-docs.yml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get terraform-docs version from versions file
get_terraform_docs_version() {
    if [[ -f "${VERSIONS_FILE}" ]]; then
        grep "terraform_docs_version:" "${VERSIONS_FILE}" | cut -d'"' -f2 | tr -d ' '
    else
        echo "v0.17.0"  # fallback version
    fi
}

# Detect OS and architecture
detect_platform() {
    local os arch
    os=$(uname -s | tr '[:upper:]' '[:lower:]')
    arch=$(uname -m)

    case "${arch}" in
        x86_64) arch="amd64" ;;
        aarch64|arm64) arch="arm64" ;;
        *) arch="amd64" ;;  # fallback
    esac

    case "${os}" in
        darwin) os="darwin" ;;
        linux) os="linux" ;;
        *) os="linux" ;;  # fallback
    esac

    echo "${os}_${arch}"
}

# Install terraform-docs if not present or wrong version
install_terraform_docs() {
    local version platform binary_name install_dir
    version=$(get_terraform_docs_version)
    platform=$(detect_platform)
    binary_name="terraform-docs"
    install_dir="${HOME}/.local/bin"

    # Create install directory if it doesn't exist
    mkdir -p "${install_dir}"

    # Check if terraform-docs exists and has correct version
    if command -v terraform-docs >/dev/null 2>&1; then
        local current_version
        current_version=$(terraform-docs version 2>/dev/null | grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+' || echo "unknown")
        if [[ "${current_version}" == "${version}" ]]; then
            log_info "terraform-docs ${version} already installed"
            return 0
        fi
    fi

    log_info "Installing terraform-docs ${version} for ${platform}..."

    # Download and install terraform-docs
    local download_url temp_dir
    # Convert platform format: darwin_arm64 -> darwin-arm64
    local platform_formatted
    platform_formatted="${platform/_/-}"
    download_url="https://github.com/terraform-docs/terraform-docs/releases/download/${version}/terraform-docs-${version}-${platform_formatted}.tar.gz"

    log_info "Downloading from: ${download_url}"
    temp_dir=$(mktemp -d)

    if curl -sSL "${download_url}" | tar -xz -C "${temp_dir}"; then
        chmod +x "${temp_dir}/terraform-docs"
        mv "${temp_dir}/terraform-docs" "${install_dir}/"
        rm -rf "${temp_dir}"

        # Add to PATH if not already there
        if [[ ":${PATH}:" != *":${install_dir}:"* ]]; then
            export PATH="${install_dir}:${PATH}"
        fi

        log_success "terraform-docs ${version} installed successfully"
    else
        log_error "Failed to download terraform-docs ${version}"
        rm -rf "${temp_dir}"
        return 1
    fi
}

# Find all Terraform modules
find_terraform_modules() {
    # Find all directories with .tf files, excluding .terraform and node_modules
    find "${PROJECT_ROOT}" -type f -name "*.tf" -not -path "*/.terraform/*" -not -path "*/node_modules/*" -exec dirname {} \; | sort -u
}

# Generate terraform-docs for a single module
generate_docs_for_module() {
    local module_dir="$1"
    local mode="${2:-check}"  # check or update
    local relative_path

    if command -v realpath >/dev/null 2>&1; then
        relative_path=$(realpath --relative-to="${PROJECT_ROOT}" "${module_dir}" 2>/dev/null || echo "${module_dir}")
    else
        relative_path="${module_dir#${PROJECT_ROOT}/}"
        [[ "${relative_path}" == "${module_dir}" ]] && relative_path="."
    fi

    log_info "Processing module: ${relative_path}"

    cd "${module_dir}"

    # Check if README.md exists
    if [[ ! -f "README.md" ]]; then
        log_warning "README.md not found in ${relative_path}, creating..."
        cat > README.md << 'EOF'
# Terraform Module

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
EOF
    fi

    # Check if terraform-docs markers exist
    if ! grep -q "<!-- BEGIN_TF_DOCS -->" README.md || ! grep -q "<!-- END_TF_DOCS -->" README.md; then
        log_warning "Adding terraform-docs markers to ${relative_path}/README.md"
        if [[ "${mode}" == "update" ]]; then
            echo "" >> README.md
            echo "<!-- BEGIN_TF_DOCS -->" >> README.md
            echo "<!-- END_TF_DOCS -->" >> README.md
        fi
    fi

    # Generate documentation
    local temp_readme
    temp_readme=$(mktemp)
    cp README.md "${temp_readme}"

    if terraform-docs --config "${TERRAFORM_DOCS_CONFIG}" . > /dev/null 2>&1; then
        if [[ "${mode}" == "check" ]]; then
            if ! diff -q README.md "${temp_readme}" >/dev/null 2>&1; then
                log_error "Documentation is out of date in ${relative_path}"
                log_info "Differences found:"
                diff -u "${temp_readme}" README.md || true
                rm -f "${temp_readme}"
                return 1
            else
                log_success "Documentation is up to date in ${relative_path}"
            fi
        else
            log_success "Documentation updated for ${relative_path}"
        fi
    else
        log_error "Failed to generate documentation for ${relative_path}"
        mv "${temp_readme}" README.md  # restore original
        rm -f "${temp_readme}"
        return 1
    fi

    rm -f "${temp_readme}"
    return 0
}

# Main function
main() {
    local mode="${1:-check}"  # check, update, or install
    local exit_code=0

    case "${mode}" in
        install)
            install_terraform_docs
            return $?
            ;;
        check|update)
            ;;
        *)
            log_error "Usage: $0 {install|check|update}"
            log_info "  install - Install terraform-docs"
            log_info "  check   - Check if documentation is up to date (default)"
            log_info "  update  - Update documentation"
            return 1
            ;;
    esac

    # Ensure terraform-docs is available
    if ! command -v terraform-docs >/dev/null 2>&1; then
        log_info "terraform-docs not found, installing..."
        if ! install_terraform_docs; then
            log_error "Failed to install terraform-docs"
            return 1
        fi
    else
        local current_version
        current_version=$(terraform-docs version 2>/dev/null | grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+' || echo "unknown")
        log_info "Using existing terraform-docs ${current_version}"
    fi

    log_info "Running terraform-docs in ${mode} mode..."

    # Process all modules
    local modules_list
    modules_list=$(find_terraform_modules)

    if [[ -z "${modules_list}" ]]; then
        log_warning "No Terraform modules found"
        return 0
    fi

    local module_count
    module_count=$(echo "${modules_list}" | wc -l)
    log_info "Found ${module_count} Terraform modules"

    while IFS= read -r module; do
        if [[ -n "${module}" ]]; then
            if ! generate_docs_for_module "${module}" "${mode}"; then
                exit_code=1
                if [[ "${mode}" == "check" ]]; then
                    log_error "Run 'make docs' or '$0 update' to fix documentation issues"
                fi
            fi
        fi
    done <<< "${modules_list}"

    if [[ ${exit_code} -eq 0 ]]; then
        log_success "All terraform-docs operations completed successfully"
    else
        log_error "Some terraform-docs operations failed"
    fi

    return ${exit_code}
}

# Run main function with all arguments
main "$@"
