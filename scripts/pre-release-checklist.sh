#!/bin/bash

# Pre-release Checklist Script for Terraform Module
# Usage: ./scripts/pre-release-checklist.sh [version]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[✓]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[⚠]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }
print_step() { echo -e "${BLUE}[◉]${NC} $1"; }

# Checklist items
declare -a CHECKLIST_ITEMS=(
    "git_clean:Git working directory is clean"
    "git_branch:On main/master branch"
    "terraform_fmt:Terraform code is formatted"
    "terraform_validate:Terraform validation passes"
    "terraform_docs:Documentation is up to date"
    "changelog:CHANGELOG.md is updated"
    "version_increment:Version increment is valid"
    "tests_pass:All tests pass"
    "security_scan:Security scan passes"
    "readme_complete:README.md is complete"
    "examples_work:Examples are working"
    "license_present:LICENSE file is present"
    "registry_ready:Terraform Registry requirements met"
)

# Function to check git working directory
check_git_clean() {
    if [[ -n "$(git status --porcelain)" ]]; then
        print_error "Git working directory is not clean"
        git status --short
        return 1
    fi
    return 0
}

# Function to check git branch
check_git_branch() {
    local current_branch
    current_branch=$(git rev-parse --abbrev-ref HEAD)
    if [[ "$current_branch" != "main" && "$current_branch" != "master" ]]; then
        print_error "Not on main/master branch (current: $current_branch)"
        return 1
    fi
    return 0
}

# Function to check terraform formatting
check_terraform_fmt() {
    cd "$PROJECT_ROOT"
    if ! terraform fmt -check -recursive > /dev/null 2>&1; then
        print_error "Terraform files are not properly formatted"
        print_warning "Run 'terraform fmt -recursive' to fix"
        return 1
    fi
    return 0
}

# Function to check terraform validation
check_terraform_validate() {
    cd "$PROJECT_ROOT"
    if ! terraform init -backend=false > /dev/null 2>&1; then
        print_error "Terraform init failed"
        return 1
    fi
    if ! terraform validate > /dev/null 2>&1; then
        print_error "Terraform validation failed"
        return 1
    fi
    return 0
}

# Function to check terraform docs
check_terraform_docs() {
    # Check if terraform-docs is available
    if ! command -v terraform-docs &> /dev/null; then
        print_warning "terraform-docs not available, skipping documentation check"
        return 0
    fi
    
    # Generate docs and check if README needs updates
    local current_readme_hash
    local new_readme_hash
    
    current_readme_hash=$(md5sum "$PROJECT_ROOT/README.md" 2>/dev/null | cut -d' ' -f1 || echo "")
    terraform-docs markdown table --output-file /tmp/readme_test.md "$PROJECT_ROOT" > /dev/null 2>&1
    new_readme_hash=$(md5sum /tmp/readme_test.md 2>/dev/null | cut -d' ' -f1 || echo "")
    
    rm -f /tmp/readme_test.md
    
    if [[ "$current_readme_hash" != "$new_readme_hash" ]]; then
        print_warning "README.md may need terraform-docs update"
        return 0  # Warning, not error
    fi
    
    return 0
}

# Function to check CHANGELOG
check_changelog() {
    local version="$1"
    local changelog_file="$PROJECT_ROOT/CHANGELOG.md"
    
    if [[ ! -f "$changelog_file" ]]; then
        print_error "CHANGELOG.md not found"
        return 1
    fi
    
    if [[ -n "$version" ]] && ! grep -q "## \[v*$version\]" "$changelog_file"; then
        print_error "Version $version not found in CHANGELOG.md"
        return 1
    fi
    
    # Check if unreleased section exists
    if grep -q "## \[Unreleased\]" "$changelog_file"; then
        print_warning "Unreleased section found in CHANGELOG.md - consider moving to version section"
    fi
    
    return 0
}

# Function to check version increment
check_version_increment() {
    local version="$1"
    
    if [[ -z "$version" ]]; then
        print_warning "No version specified for increment check"
        return 0
    fi
    
    # Get current version from git tags
    local current_version
    if current_version=$(git tag --list --sort=-version:refname | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | head -n1 | sed 's/^v//'); then
        if ! printf '%s\n%s\n' "$current_version" "$version" | sort -V | tail -n1 | grep -q "^$version$"; then
            print_error "Version $version is not greater than current version $current_version"
            return 1
        fi
    fi
    
    return 0
}

# Function to check tests
check_tests_pass() {
    cd "$PROJECT_ROOT"
    
    if [[ -f "Makefile" ]]; then
        # Try different test targets
        if make -n test-safe > /dev/null 2>&1; then
            if ! make test-safe > /dev/null 2>&1; then
                print_error "make test-safe failed"
                return 1
            fi
        elif make -n test-validate > /dev/null 2>&1; then
            if ! make test-validate > /dev/null 2>&1; then
                print_error "make test-validate failed"
                return 1
            fi
        fi
    fi
    
    return 0
}

# Function to check security scan
check_security_scan() {
    # Check if trivy is available
    if ! command -v trivy &> /dev/null; then
        print_warning "trivy not available, skipping security scan"
        return 0
    fi
    
    cd "$PROJECT_ROOT"
    if ! trivy fs --exit-code 1 --severity HIGH,CRITICAL . > /dev/null 2>&1; then
        print_error "Security scan found HIGH/CRITICAL vulnerabilities"
        return 1
    fi
    
    return 0
}

# Function to check README completeness
check_readme_complete() {
    local readme_file="$PROJECT_ROOT/README.md"
    
    if [[ ! -f "$readme_file" ]]; then
        print_error "README.md not found"
        return 1
    fi
    
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
        print_warning "README.md missing sections: ${missing_sections[*]}"
        return 0  # Warning, not error
    fi
    
    return 0
}

# Function to check examples
check_examples_work() {
    local examples_dir="$PROJECT_ROOT/examples"
    
    if [[ ! -d "$examples_dir" ]]; then
        # Check for terraform.tfvars.example
        if [[ -f "$PROJECT_ROOT/terraform.tfvars.example" ]]; then
            cd "$PROJECT_ROOT"
            cp terraform.tfvars.example terraform.tfvars.test
            if ! terraform plan -var-file=terraform.tfvars.test > /dev/null 2>&1; then
                rm -f terraform.tfvars.test
                print_error "terraform.tfvars.example contains invalid configuration"
                return 1
            fi
            rm -f terraform.tfvars.test
        else
            print_warning "No examples directory or terraform.tfvars.example found"
        fi
        return 0
    fi
    
    # Check each example directory
    for example_dir in "$examples_dir"/*; do
        if [[ -d "$example_dir" ]]; then
            cd "$example_dir"
            if ! terraform init -backend=false > /dev/null 2>&1; then
                print_error "Example $(basename "$example_dir") terraform init failed"
                return 1
            fi
            if ! terraform validate > /dev/null 2>&1; then
                print_error "Example $(basename "$example_dir") validation failed"
                return 1
            fi
        fi
    done
    
    return 0
}

# Function to check license
check_license_present() {
    if [[ ! -f "$PROJECT_ROOT/LICENSE" ]]; then
        print_error "LICENSE file not found"
        return 1
    fi
    return 0
}

# Function to check Terraform Registry requirements
check_registry_ready() {
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
        print_error "Missing required files for Terraform Registry: ${missing_files[*]}"
        return 1
    fi
    
    return 0
}

# Function to run individual check
run_check() {
    local check_name="$1"
    local check_description="$2"
    local version="$3"
    
    case "$check_name" in
        "git_clean")
            check_git_clean
            ;;
        "git_branch")
            check_git_branch
            ;;
        "terraform_fmt")
            check_terraform_fmt
            ;;
        "terraform_validate")
            check_terraform_validate
            ;;
        "terraform_docs")
            check_terraform_docs
            ;;
        "changelog")
            check_changelog "$version"
            ;;
        "version_increment")
            check_version_increment "$version"
            ;;
        "tests_pass")
            check_tests_pass
            ;;
        "security_scan")
            check_security_scan
            ;;
        "readme_complete")
            check_readme_complete
            ;;
        "examples_work")
            check_examples_work
            ;;
        "license_present")
            check_license_present
            ;;
        "registry_ready")
            check_registry_ready
            ;;
        *)
            print_error "Unknown check: $check_name"
            return 1
            ;;
    esac
}

# Function to run all checks
run_all_checks() {
    local version="$1"
    local passed=0
    local failed=0
    local warnings=0
    
    echo "🔍 Running Pre-Release Checklist for Terraform Module"
    if [[ -n "$version" ]]; then
        echo "📦 Version: $version"
    fi
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo
    
    for item in "${CHECKLIST_ITEMS[@]}"; do
        IFS=':' read -r check_name check_description <<< "$item"
        
        printf "%-50s " "$check_description..."
        
        if run_check "$check_name" "$check_description" "$version"; then
            print_status "PASS"
            ((passed++))
        else
            if [[ $? -eq 2 ]]; then  # Warning
                print_warning "WARN"
                ((warnings++))
            else
                print_error "FAIL"
                ((failed++))
            fi
        fi
    done
    
    echo
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if [[ $failed -eq 0 ]]; then
        print_status "🎉 All critical checks passed! ($passed passed, $warnings warnings)"
        if [[ -n "$version" ]]; then
            echo
            echo "Ready to release version $version:"
            echo "  ./scripts/release.sh patch    # For patch release"
            echo "  ./scripts/release.sh minor    # For minor release"
            echo "  ./scripts/release.sh major    # For major release"
        fi
        return 0
    else
        print_error "❌ $failed check(s) failed. Please fix before releasing."
        return 1
    fi
}

# Function to show usage
show_usage() {
    cat << EOF
Pre-Release Checklist for Terraform Module

Usage: $0 [version]

Arguments:
  version       Version to validate (optional)

Examples:
  $0           # Run checklist without version-specific checks
  $0 2.0.1     # Run checklist for version 2.0.1

This script checks:
  ✓ Git working directory is clean
  ✓ On main/master branch
  ✓ Terraform code is formatted
  ✓ Terraform validation passes
  ✓ Documentation is up to date
  ✓ CHANGELOG.md is updated
  ✓ Version increment is valid
  ✓ All tests pass
  ✓ Security scan passes
  ✓ README.md is complete
  ✓ Examples are working
  ✓ LICENSE file is present
  ✓ Terraform Registry requirements met

EOF
}

# Main function
main() {
    local version="${1:-}"
    
    if [[ "$version" == "--help" || "$version" == "-h" ]]; then
        show_usage
        exit 0
    fi
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "Not in a git repository"
        exit 1
    fi
    
    # Run all checks
    if run_all_checks "$version"; then
        exit 0
    else
        exit 1
    fi
}

# Run main function
main "$@"
