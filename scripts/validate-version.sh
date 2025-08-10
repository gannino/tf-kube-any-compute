#!/bin/bash

# Version Validation Script for Terraform Module
# Usage: ./scripts/validate-version.sh [version]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

# Function to validate semantic version format
validate_version_format() {
    local version="$1"

    if [[ ! $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        print_error "Invalid version format: $version"
        print_error "Expected format: X.Y.Z (e.g., 2.0.1)"
        return 1
    fi

    return 0
}

# Function to check if version exists in git tags
check_version_exists() {
    local version="$1"
    local tag="v$version"

    if git tag --list | grep -q "^$tag$"; then
        print_warning "Version $version already exists as git tag $tag"
        return 1
    fi

    return 0
}

# Function to validate version is greater than current
validate_version_increment() {
    local new_version="$1"

    # Get current version from git tags
    local current_version
    if current_version=$(git tag --list --sort=-version:refname | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | head -n1 | sed 's/^v//'); then
        # Compare versions
        if ! printf '%s\n%s\n' "$current_version" "$new_version" | sort -V | tail -n1 | grep -q "^$new_version$"; then
            print_error "New version $new_version is not greater than current version $current_version"
            return 1
        fi

        print_status "Version increment valid: $current_version → $new_version"
    else
        print_status "No existing version tags found. This will be the first release."
    fi

    return 0
}

# Function to check CHANGELOG entry
check_changelog_entry() {
    local version="$1"
    local changelog_file="$PROJECT_ROOT/CHANGELOG.md"

    if [[ ! -f "$changelog_file" ]]; then
        print_warning "CHANGELOG.md not found"
        return 1
    fi

    if ! grep -q "## \[v*$version\]" "$changelog_file"; then
        print_error "Version $version not found in CHANGELOG.md"
        print_error "Please add release notes for version $version"
        return 1
    fi

    print_status "CHANGELOG.md entry found for version $version ✓"
    return 0
}

# Function to validate Terraform module structure
validate_module_structure() {
    print_step "Validating Terraform module structure..."

    local required_files=(
        "main.tf"
        "variables.tf"
        "outputs.tf"
        "versions.tf"
        "README.md"
        "LICENSE"
    )

    local missing_files=()

    for file in "${required_files[@]}"; do
        if [[ ! -f "$PROJECT_ROOT/$file" ]]; then
            missing_files+=("$file")
        fi
    done

    if [[ ${#missing_files[@]} -gt 0 ]]; then
        print_error "Missing required files for Terraform Registry:"
        printf ' - %s\n' "${missing_files[@]}"
        return 1
    fi

    print_status "All required files present ✓"
    return 0
}

# Function to validate variable documentation
validate_variable_docs() {
    print_step "Validating variable documentation..."

    local variables_file="$PROJECT_ROOT/variables.tf"

    # Check if all variables have descriptions
    local undocumented_vars
    if undocumented_vars=$(terraform-config-inspect --json "$PROJECT_ROOT" 2>/dev/null | jq -r '.variables | to_entries[] | select(.value.description == null) | .key' 2>/dev/null); then
        if [[ -n "$undocumented_vars" ]]; then
            print_warning "Variables without descriptions found:"
            echo "$undocumented_vars" | while read -r var; do
                echo "  - $var"
            done
        else
            print_status "All variables have descriptions ✓"
        fi
    else
        print_warning "Could not validate variable documentation (terraform-config-inspect not available)"
    fi

    return 0
}

# Function to validate README requirements
validate_readme() {
    print_step "Validating README.md..."

    local readme_file="$PROJECT_ROOT/README.md"
    local required_sections=(
        "Usage"
        "Requirements"
        "Providers"
        "Inputs"
        "Outputs"
    )

    local missing_sections=()

    for section in "${required_sections[@]}"; do
        if ! grep -qi "## $section\|# $section" "$readme_file"; then
            missing_sections+=("$section")
        fi
    done

    if [[ ${#missing_sections[@]} -gt 0 ]]; then
        print_warning "README.md missing recommended sections:"
        printf ' - %s\n' "${missing_sections[@]}"
    else
        print_status "README.md has all recommended sections ✓"
    fi

    return 0
}

# Function to run comprehensive validation
run_comprehensive_validation() {
    local version="$1"
    local errors=0

    print_status "Running comprehensive validation for version $version..."
    echo

    # Validate version format
    if ! validate_version_format "$version"; then
        ((errors++))
    fi

    # Check if version already exists
    if ! check_version_exists "$version"; then
        ((errors++))
    fi

    # Validate version increment
    if ! validate_version_increment "$version"; then
        ((errors++))
    fi

    # Check CHANGELOG entry
    if ! check_changelog_entry "$version"; then
        ((errors++))
    fi

    # Validate module structure
    if ! validate_module_structure; then
        ((errors++))
    fi

    # Validate variable documentation
    validate_variable_docs

    # Validate README
    validate_readme

    # Run Terraform validation
    print_step "Running Terraform validation..."
    cd "$PROJECT_ROOT"

    if ! terraform init -backend=false > /dev/null 2>&1; then
        print_error "Terraform init failed"
        ((errors++))
    elif ! terraform validate > /dev/null 2>&1; then
        print_error "Terraform validation failed"
        terraform validate
        ((errors++))
    else
        print_status "Terraform validation passed ✓"
    fi

    # Check formatting
    if ! terraform fmt -check -recursive > /dev/null 2>&1; then
        print_error "Terraform files are not properly formatted"
        print_warning "Run 'terraform fmt -recursive' to fix"
        ((errors++))
    else
        print_status "Terraform formatting check passed ✓"
    fi

    echo
    if [[ $errors -eq 0 ]]; then
        print_status "🎉 All validations passed! Version $version is ready for release."
        return 0
    else
        print_error "❌ $errors validation error(s) found. Please fix before releasing."
        return 1
    fi
}

# Function to show usage
show_usage() {
    cat << EOF
Version Validation Script for Terraform Module

Usage: $0 [version]

Arguments:
  version       Semantic version to validate (e.g., 2.0.1)

Examples:
  $0 2.0.1     # Validate version 2.0.1
  $0           # Validate next patch version

This script validates:
  ✓ Semantic version format
  ✓ Version doesn't already exist
  ✓ Version is greater than current
  ✓ CHANGELOG.md has entry for version
  ✓ Required Terraform files exist
  ✓ Terraform validation passes
  ✓ Code formatting is correct
  ✓ Variable documentation completeness
  ✓ README.md structure

EOF
}

# Main function
main() {
    local version="$1"

    if [[ "$version" == "--help" || "$version" == "-h" ]]; then
        show_usage
        exit 0
    fi

    if [[ -z "$version" ]]; then
        # Auto-determine next patch version
        if current_version=$(git tag --list --sort=-version:refname | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | head -n1 | sed 's/^v//'); then
            IFS='.' read -r major minor patch <<< "$current_version"
            version="$major.$minor.$((patch + 1))"
            print_status "Auto-determined next version: $version"
        else
            print_error "No current version found and no version specified"
            show_usage
            exit 1
        fi
    fi

    # Run validation
    if run_comprehensive_validation "$version"; then
        exit 0
    else
        exit 1
    fi
}

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    print_error "Not in a git repository"
    exit 1
fi

# Handle no arguments case
if [[ $# -eq 0 ]]; then
    main ""
else
    main "$1"
fi
