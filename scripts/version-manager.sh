#!/bin/bash
# ============================================================================
# Version Manager for tf-kube-any-compute
# ============================================================================
#
# Centralized version management script that reads from .tool-versions
# and provides functions to get versions for use in CI, scripts, and configs.
#
# Usage:
#   source scripts/version-manager.sh
#   get_version terraform
#   get_version_env TF_VERSION terraform
#
# ============================================================================

set -euo pipefail

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TOOL_VERSIONS_FILE="$PROJECT_ROOT/.tool-versions"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# Core Functions
# ============================================================================

# Get version for a specific tool
get_version() {
    local tool_name="$1"
    
    if [[ ! -f "$TOOL_VERSIONS_FILE" ]]; then
        echo "Error: .tool-versions file not found at $TOOL_VERSIONS_FILE" >&2
        return 1
    fi
    
    # Extract version from .tool-versions file
    local version
    version=$(grep "^$tool_name " "$TOOL_VERSIONS_FILE" | awk '{print $2}' | head -1)
    
    if [[ -z "$version" ]]; then
        echo "Error: Version not found for tool '$tool_name'" >&2
        return 1
    fi
    
    echo "$version"
}

# Get version and export as environment variable
get_version_env() {
    local env_var="$1"
    local tool_name="$2"
    
    local version
    version=$(get_version "$tool_name")
    
    if [[ $? -eq 0 ]]; then
        export "$env_var"="$version"
        echo "Exported $env_var=$version"
    else
        return 1
    fi
}

# List all available tools and versions
list_versions() {
    echo -e "${BLUE}Available Tool Versions:${NC}"
    echo "========================"
    
    if [[ ! -f "$TOOL_VERSIONS_FILE" ]]; then
        echo -e "${RED}Error: .tool-versions file not found${NC}"
        return 1
    fi
    
    # Skip comments and empty lines
    grep -v '^#' "$TOOL_VERSIONS_FILE" | grep -v '^$' | while read -r tool version; do
        printf "%-20s %s\n" "$tool" "$version"
    done
}

# Update version for a specific tool
update_version() {
    local tool_name="$1"
    local new_version="$2"
    
    if [[ ! -f "$TOOL_VERSIONS_FILE" ]]; then
        echo -e "${RED}Error: .tool-versions file not found${NC}"
        return 1
    fi
    
    # Check if tool exists
    if grep -q "^$tool_name " "$TOOL_VERSIONS_FILE"; then
        # Update existing tool
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS sed
            sed -i '' "s/^$tool_name .*/$tool_name $new_version/" "$TOOL_VERSIONS_FILE"
        else
            # Linux sed
            sed -i "s/^$tool_name .*/$tool_name $new_version/" "$TOOL_VERSIONS_FILE"
        fi
        echo -e "${GREEN}Updated $tool_name to version $new_version${NC}"
    else
        # Add new tool
        echo "$tool_name $new_version" >> "$TOOL_VERSIONS_FILE"
        echo -e "${GREEN}Added $tool_name version $new_version${NC}"
    fi
}

# Validate that all tools have versions
validate_versions() {
    echo -e "${BLUE}Validating tool versions...${NC}"
    
    local errors=0
    
    # Check for duplicate tool entries
    local duplicates
    duplicates=$(grep -v '^#' "$TOOL_VERSIONS_FILE" | grep -v '^$' | awk '{print $1}' | sort | uniq -d)
    
    if [[ -n "$duplicates" ]]; then
        echo -e "${RED}Error: Duplicate tool entries found:${NC}"
        echo "$duplicates"
        errors=$((errors + 1))
    fi
    
    # Check for empty versions
    local empty_versions
    empty_versions=$(grep -v '^#' "$TOOL_VERSIONS_FILE" | grep -v '^$' | awk 'NF < 2 {print $1}')
    
    if [[ -n "$empty_versions" ]]; then
        echo -e "${RED}Error: Tools with missing versions:${NC}"
        echo "$empty_versions"
        errors=$((errors + 1))
    fi
    
    if [[ $errors -eq 0 ]]; then
        echo -e "${GREEN}All tool versions are valid${NC}"
        return 0
    else
        echo -e "${RED}Found $errors validation errors${NC}"
        return 1
    fi
}

# Generate environment variables for CI
generate_ci_env() {
    echo -e "${BLUE}Generating CI environment variables...${NC}"
    
    # Core infrastructure tools
    get_version_env "TF_VERSION" "terraform"
    get_version_env "KUBECTL_VERSION" "kubectl"
    get_version_env "HELM_VERSION" "helm"
    
    # Security tools
    get_version_env "CHECKOV_VERSION" "checkov"
    get_version_env "TFSEC_VERSION" "tfsec"
    get_version_env "TRIVY_VERSION" "trivy"
    get_version_env "TERRASCAN_VERSION" "terrascan"
    
    # Code quality tools
    get_version_env "TFLINT_VERSION" "tflint"
    get_version_env "TERRAFORM_DOCS_VERSION" "terraform-docs"
    get_version_env "PRE_COMMIT_VERSION" "pre-commit"
    
    # CI/CD tools
    get_version_env "ACTIONLINT_VERSION" "actionlint"
    get_version_env "YAMLLINT_VERSION" "yamllint"
    get_version_env "MARKDOWNLINT_VERSION" "markdownlint-cli"
    get_version_env "SHELLCHECK_VERSION" "shellcheck"
    
    # Language runtimes
    get_version_env "PYTHON_VERSION" "python"
    get_version_env "NODE_VERSION" "node"
    get_version_env "GO_VERSION" "go"
    
    # Kubernetes tools
    get_version_env "MICROK8S_CHANNEL" "microk8s"
    get_version_env "K3S_VERSION" "k3s"
}

# Generate GitHub Actions environment file
generate_github_env() {
    local output_file="$1"
    
    echo -e "${BLUE}Generating GitHub Actions environment file: $output_file${NC}"
    
    cat > "$output_file" << 'EOF'
# ============================================================================
# GitHub Actions Environment Variables
# ============================================================================
# 
# Auto-generated from .tool-versions
# Do not edit manually - run scripts/version-manager.sh generate-github-env
#
# ============================================================================

env:
EOF
    
    # Add versions from .tool-versions
    grep -v '^#' "$TOOL_VERSIONS_FILE" | grep -v '^$' | while read -r tool version; do
        # Convert tool name to environment variable format
        local env_var
        env_var=$(echo "$tool" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
        
        # Special cases for common tools
        case "$tool" in
            terraform)
                echo "  TF_VERSION: \"$version\"" >> "$output_file"
                ;;
            terraform-docs)
                echo "  TERRAFORM_DOCS_VERSION: \"$version\"" >> "$output_file"
                ;;
            markdownlint-cli)
                echo "  MARKDOWNLINT_VERSION: \"$version\"" >> "$output_file"
                ;;
            pre-commit)
                echo "  PRE_COMMIT_VERSION: \"$version\"" >> "$output_file"
                ;;
            microk8s)
                echo "  MICROK8S_CHANNEL: \"$version\"" >> "$output_file"
                ;;
            *)
                echo "  ${env_var}_VERSION: \"$version\"" >> "$output_file"
                ;;
        esac
    done
    
    echo -e "${GREEN}Generated GitHub Actions environment file: $output_file${NC}"
}

# Generate pre-commit versions
generate_precommit_versions() {
    echo -e "${BLUE}Generating pre-commit hook versions...${NC}"
    
    # Output versions for pre-commit configuration
    echo "Pre-commit hook versions:"
    echo "========================"
    
    # Terraform hooks
    echo "antonbabenko/pre-commit-terraform: v$(get_version tflint)"
    
    # Security hooks
    echo "bridgecrewio/checkov: $(get_version checkov)"
    echo "Yelp/detect-secrets: v$(get_version pre-commit)"
    
    # Documentation hooks
    echo "igorshubovych/markdownlint-cli: v$(get_version markdownlint-cli)"
    echo "adrienverge/yamllint: v$(get_version yamllint)"
    
    # Shell hooks
    echo "shellcheck-py/shellcheck-py: v$(get_version shellcheck)"
    
    # Conventional commits
    echo "compilerla/conventional-pre-commit: v$(get_version pre-commit)"
}

# Check for outdated versions (placeholder for future enhancement)
check_outdated() {
    echo -e "${YELLOW}Checking for outdated versions...${NC}"
    echo "This feature will be implemented to check against latest releases"
    echo "Current versions:"
    list_versions
}

# ============================================================================
# CLI Interface
# ============================================================================

show_help() {
    cat << EOF
Version Manager for tf-kube-any-compute

USAGE:
    $0 COMMAND [ARGS]

COMMANDS:
    get TOOL                    Get version for specific tool
    list                        List all tools and versions
    update TOOL VERSION         Update version for specific tool
    validate                    Validate all tool versions
    generate-ci-env             Generate CI environment variables
    generate-github-env FILE    Generate GitHub Actions env file
    generate-precommit          Generate pre-commit versions
    check-outdated              Check for outdated versions
    help                        Show this help message

EXAMPLES:
    $0 get terraform
    $0 list
    $0 update terraform 1.6.0
    $0 validate
    $0 generate-github-env .github/env.yml

INTEGRATION:
    # In scripts
    source scripts/version-manager.sh
    TF_VERSION=\$(get_version terraform)
    
    # In Makefiles
    include scripts/version-manager.sh
    
    # In GitHub Actions
    - name: Load versions
      run: source scripts/version-manager.sh && generate_ci_env

EOF
}

# Main CLI handler
main() {
    case "${1:-help}" in
        get)
            if [[ $# -lt 2 ]]; then
                echo "Error: Tool name required"
                echo "Usage: $0 get TOOL"
                exit 1
            fi
            get_version "$2"
            ;;
        list)
            list_versions
            ;;
        update)
            if [[ $# -lt 3 ]]; then
                echo "Error: Tool name and version required"
                echo "Usage: $0 update TOOL VERSION"
                exit 1
            fi
            update_version "$2" "$3"
            ;;
        validate)
            validate_versions
            ;;
        generate-ci-env)
            generate_ci_env
            ;;
        generate-github-env)
            if [[ $# -lt 2 ]]; then
                echo "Error: Output file required"
                echo "Usage: $0 generate-github-env FILE"
                exit 1
            fi
            generate_github_env "$2"
            ;;
        generate-precommit)
            generate_precommit_versions
            ;;
        check-outdated)
            check_outdated
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo "Error: Unknown command '$1'"
            echo "Run '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi