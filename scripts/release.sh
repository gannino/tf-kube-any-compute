#!/bin/bash

# Terraform Module Release Management Script
# Usage: ./scripts/release.sh [major|minor|patch] [--dry-run] [--force]

set -euo pipefail

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CHANGELOG_FILE="$PROJECT_ROOT/CHANGELOG.md"
VERSION_FILE="$PROJECT_ROOT/version.tf"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
DRY_RUN=false
FORCE=false
BUMP_TYPE=""

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Function to show usage
show_usage() {
    cat << EOF
Terraform Module Release Management

Usage: $0 [major|minor|patch] [options]

Arguments:
  major         Increment major version (breaking changes)
  minor         Increment minor version (new features)
  patch         Increment patch version (bug fixes)

Options:
  --dry-run     Show what would be done without making changes
  --force       Skip validation checks (use with caution)
  --help        Show this help message

Examples:
  $0 patch                    # Release v2.0.1
  $0 minor --dry-run         # Show what v2.1.0 release would do
  $0 major --force           # Force major release v3.0.0

Prerequisites:
  - Clean git working directory
  - All changes committed
  - Up-to-date CHANGELOG.md
  - Terraform validation passes
  - All tests pass

EOF
}

# Function to validate prerequisites
validate_prerequisites() {
    print_step "Validating prerequisites..."
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "Not in a git repository"
        exit 1
    fi
    
    # Check for clean working directory
    if [[ -n "$(git status --porcelain)" ]] && [[ "$FORCE" == "false" ]]; then
        print_error "Working directory is not clean. Commit your changes first."
        git status --short
        exit 1
    fi
    
    # Check if we're on main or master branch
    current_branch=$(git rev-parse --abbrev-ref HEAD)
    if [[ "$current_branch" != "main" && "$current_branch" != "master" ]] && [[ "$FORCE" == "false" ]]; then
        print_error "Not on main/master branch. Current branch: $current_branch"
        exit 1
    fi
    
    # Check for required files
    required_files=("$CHANGELOG_FILE" "$VERSION_FILE" "README.md" "main.tf" "variables.tf" "outputs.tf")
    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            print_error "Required file missing: $file"
            exit 1
        fi
    done
    
    # Check terraform is installed
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed or not in PATH"
        exit 1
    fi
    
    print_status "Prerequisites validated ✓"
}

# Function to get current version
get_current_version() {
    # Try to get version from git tags first
    if git tag --list --sort=-version:refname | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | head -n1 | grep -q .; then
        git tag --list --sort=-version:refname | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | head -n1 | sed 's/^v//'
    else
        # Fallback to version.tf if no tags exist
        if grep -q 'required_version' "$VERSION_FILE"; then
            grep 'required_version' "$VERSION_FILE" | sed -n 's/.*">= *\([0-9]*\.[0-9]*\).*/\1.0/p' | head -n1
        else
            echo "0.0.0"
        fi
    fi
}

# Function to calculate next version
calculate_next_version() {
    local current_version="$1"
    local bump_type="$2"
    
    IFS='.' read -r major minor patch <<< "$current_version"
    
    case "$bump_type" in
        "major")
            echo "$((major + 1)).0.0"
            ;;
        "minor")
            echo "$major.$((minor + 1)).0"
            ;;
        "patch")
            echo "$major.$minor.$((patch + 1))"
            ;;
        *)
            print_error "Invalid bump type: $bump_type"
            exit 1
            ;;
    esac
}

# Function to validate terraform
validate_terraform() {
    print_step "Validating Terraform configuration..."
    
    cd "$PROJECT_ROOT"
    
    # Initialize terraform (backend=false for validation)
    if ! terraform init -backend=false > /dev/null 2>&1; then
        print_error "Terraform init failed"
        exit 1
    fi
    
    # Validate terraform
    if ! terraform validate > /dev/null 2>&1; then
        print_error "Terraform validation failed"
        terraform validate
        exit 1
    fi
    
    # Check terraform formatting
    if ! terraform fmt -check -recursive > /dev/null 2>&1; then
        print_error "Terraform files are not properly formatted"
        print_warning "Run 'terraform fmt -recursive' to fix formatting"
        exit 1
    fi
    
    print_status "Terraform validation passed ✓"
}

# Function to run tests
run_tests() {
    print_step "Running tests..."
    
    cd "$PROJECT_ROOT"
    
    if [[ -f "Makefile" ]]; then
        # Run safe tests if available
        if make -n test-safe > /dev/null 2>&1; then
            if ! make test-safe; then
                print_error "Tests failed"
                exit 1
            fi
        elif make -n test > /dev/null 2>&1; then
            if ! make test; then
                print_error "Tests failed"
                exit 1
            fi
        fi
    fi
    
    print_status "Tests passed ✓"
}

# Function to update version file
update_version_file() {
    local new_version="$1"
    
    print_step "Updating version.tf..."
    
    # Create a backup
    cp "$VERSION_FILE" "$VERSION_FILE.backup"
    
    # Update the version file with new version constraint
    if grep -q "required_version" "$VERSION_FILE"; then
        # Update existing required_version
        sed -i.tmp "s/required_version *= *\"[^\"]*\"/required_version = \">= 1.0\"/" "$VERSION_FILE"
        rm -f "$VERSION_FILE.tmp"
    fi
    
    # Add version comment at the top
    {
        echo "# Module Version: v$new_version"
        echo "# Release Date: $(date '+%Y-%m-%d')"
        echo ""
        cat "$VERSION_FILE"
    } > "$VERSION_FILE.new"
    
    mv "$VERSION_FILE.new" "$VERSION_FILE"
    
    print_status "Version file updated ✓"
}

# Function to update changelog
update_changelog() {
    local new_version="$1"
    local current_version="$2"
    
    print_step "Checking CHANGELOG.md..."
    
    # Check if the new version is already documented
    if grep -q "## \[v*$new_version\]" "$CHANGELOG_FILE"; then
        print_status "Version $new_version already documented in CHANGELOG.md ✓"
        return 0
    fi
    
    if [[ "$FORCE" == "false" ]]; then
        print_error "Version $new_version not found in CHANGELOG.md"
        print_warning "Please update CHANGELOG.md with release notes for v$new_version"
        print_warning "Or use --force to skip this check"
        exit 1
    else
        print_warning "Skipping CHANGELOG.md check due to --force flag"
    fi
}

# Function to create git tag
create_git_tag() {
    local new_version="$1"
    local tag_name="v$new_version"
    
    print_step "Creating git tag..."
    
    # Check if tag already exists
    if git tag --list | grep -q "^$tag_name$"; then
        if [[ "$FORCE" == "false" ]]; then
            print_error "Tag $tag_name already exists"
            exit 1
        else
            print_warning "Tag $tag_name already exists, deleting due to --force"
            git tag -d "$tag_name" || true
        fi
    fi
    
    # Extract release notes from CHANGELOG
    local release_notes_file="/tmp/release_notes_$new_version.md"
    extract_release_notes "$new_version" "$release_notes_file"
    
    # Create annotated tag with release notes
    if [[ -f "$release_notes_file" ]] && [[ -s "$release_notes_file" ]]; then
        git tag -a "$tag_name" -F "$release_notes_file"
    else
        git tag -a "$tag_name" -m "Release $tag_name

Automated release created by release script.
See CHANGELOG.md for detailed release notes."
    fi
    
    # Clean up
    rm -f "$release_notes_file"
    
    print_status "Git tag $tag_name created ✓"
}

# Function to extract release notes from CHANGELOG
extract_release_notes() {
    local version="$1"
    local output_file="$2"
    
    if [[ -f "$CHANGELOG_FILE" ]]; then
        # Extract content between version headers
        awk "/^## \[v*$version\]/{flag=1; next} /^## \[/{flag=0} flag" "$CHANGELOG_FILE" > "$output_file"
        
        # If empty, create a basic release note
        if [[ ! -s "$output_file" ]]; then
            echo "Release $version

See CHANGELOG.md for detailed release notes." > "$output_file"
        fi
    else
        echo "Release $version

Automated release created by release script." > "$output_file"
    fi
}

# Function to push changes
push_changes() {
    local new_version="$1"
    local tag_name="v$new_version"
    
    print_step "Pushing changes to remote..."
    
    # Add and commit changes
    git add .
    git commit -m "chore: release $tag_name

- Update version.tf
- Automated release preparation
[skip ci]" || true
    
    # Push commits and tags
    git push origin HEAD
    git push origin "$tag_name"
    
    print_status "Changes pushed to remote ✓"
}

# Function to create GitHub release
create_github_release() {
    local new_version="$1"
    local tag_name="v$new_version"
    
    print_step "Creating GitHub release..."
    
    # Check if gh CLI is available
    if ! command -v gh &> /dev/null; then
        print_warning "GitHub CLI (gh) not found. Skipping GitHub release creation."
        print_warning "Create the release manually at: https://github.com/gannino/tf-kube-any-compute/releases/new?tag=$tag_name"
        return 0
    fi
    
    # Extract release notes
    local release_notes_file="/tmp/release_notes_$new_version.md"
    extract_release_notes "$new_version" "$release_notes_file"
    
    # Create GitHub release
    if [[ -f "$release_notes_file" ]] && [[ -s "$release_notes_file" ]]; then
        gh release create "$tag_name" \
            --title "Release $tag_name" \
            --notes-file "$release_notes_file" \
            --verify-tag
    else
        gh release create "$tag_name" \
            --title "Release $tag_name" \
            --notes "See CHANGELOG.md for release notes." \
            --verify-tag
    fi
    
    # Clean up
    rm -f "$release_notes_file"
    
    print_status "GitHub release created ✓"
}

# Function to display release summary
show_release_summary() {
    local current_version="$1"
    local new_version="$2"
    local bump_type="$3"
    
    cat << EOF

${GREEN}🎉 Release Summary${NC}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Release Type:     ${BLUE}$bump_type${NC}
📊 Version Change:   ${YELLOW}v$current_version${NC} → ${GREEN}v$new_version${NC}
🏷️  Git Tag:         ${GREEN}v$new_version${NC}
📅 Release Date:     ${BLUE}$(date '+%Y-%m-%d %H:%M:%S')${NC}

🔗 Next Steps:
   • Verify release at: https://github.com/gannino/tf-kube-any-compute/releases/tag/v$new_version
   • Submit to Terraform Registry (if not automated)
   • Announce to community
   • Update documentation if needed

📦 Terraform Registry:
   The module will be automatically available in Terraform Registry
   within 24-48 hours if the repository is already registered.

EOF
}

# Main execution function
main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            major|minor|patch)
                BUMP_TYPE="$1"
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --force)
                FORCE=true
                shift
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Validate arguments
    if [[ -z "$BUMP_TYPE" ]]; then
        print_error "Missing required argument: bump type (major|minor|patch)"
        show_usage
        exit 1
    fi
    
    # Show what we're doing
    print_status "Terraform Module Release Script"
    print_status "Bump Type: $BUMP_TYPE"
    print_status "Dry Run: $DRY_RUN"
    print_status "Force: $FORCE"
    echo
    
    # Get current and next versions
    current_version=$(get_current_version)
    new_version=$(calculate_next_version "$current_version" "$BUMP_TYPE")
    
    print_status "Current Version: v$current_version"
    print_status "New Version: v$new_version"
    echo
    
    if [[ "$DRY_RUN" == "true" ]]; then
        print_warning "DRY RUN MODE - No changes will be made"
        echo
        print_step "Would perform the following actions:"
        echo "  1. Validate prerequisites"
        echo "  2. Validate Terraform configuration"
        echo "  3. Run tests"
        echo "  4. Update version.tf to v$new_version"
        echo "  5. Validate CHANGELOG.md has v$new_version entry"
        echo "  6. Create git tag v$new_version"
        echo "  7. Push changes and tag to remote"
        echo "  8. Create GitHub release"
        echo
        print_status "Dry run completed. Use without --dry-run to perform actual release."
        exit 0
    fi
    
    # Confirm with user
    if [[ "$FORCE" == "false" ]]; then
        echo -n "Proceed with release v$current_version → v$new_version? (y/N): "
        read -r confirmation
        if [[ "$confirmation" != "y" && "$confirmation" != "Y" ]]; then
            print_status "Release cancelled by user"
            exit 0
        fi
    fi
    
    # Execute release steps
    validate_prerequisites
    validate_terraform
    run_tests
    update_version_file "$new_version"
    update_changelog "$new_version" "$current_version"
    create_git_tag "$new_version"
    push_changes "$new_version"
    create_github_release "$new_version"
    
    # Show summary
    show_release_summary "$current_version" "$new_version" "$BUMP_TYPE"
    
    print_status "Release v$new_version completed successfully! 🎉"
}

# Handle script interruption
cleanup() {
    if [[ -f "$VERSION_FILE.backup" ]]; then
        print_warning "Restoring version.tf backup due to interruption..."
        mv "$VERSION_FILE.backup" "$VERSION_FILE"
    fi
    print_error "Release process interrupted"
    exit 1
}

trap cleanup INT TERM

# Run main function with all arguments
main "$@"
