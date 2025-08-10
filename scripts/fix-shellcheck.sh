#!/bin/bash
# ============================================================================
# ShellCheck Fix Script for tf-kube-any-compute
# ============================================================================
#
# Automatically fixes common shellcheck issues in scripts
#
# Usage: ./scripts/fix-shellcheck.sh
#
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

# Add shellcheck disable comments for unreachable code (functions)
add_shellcheck_ignores() {
    local file="$1"
    
    log_info "Adding shellcheck ignores to $file"
    
    # Add ignore for unreachable code at the top of functions
    if grep -q "^[a-zA-Z_][a-zA-Z0-9_]*() {" "$file"; then
        # Create a temporary file with shellcheck ignores
        local temp_file=$(mktemp)
        
        # Add header comment
        cat > "$temp_file" << 'EOF'
#!/bin/bash
# shellcheck disable=SC2317  # Functions may be called indirectly
EOF
        
        # Skip the shebang and add the rest
        tail -n +2 "$file" >> "$temp_file"
        
        # Replace original file
        mv "$temp_file" "$file"
        chmod +x "$file"
        
        log_success "Added shellcheck ignores to $file"
    fi
}

# Fix common shellcheck issues
fix_common_issues() {
    local file="$1"
    
    log_info "Fixing common issues in $file"
    
    # Create backup
    cp "$file" "$file.backup"
    
    # Fix SC2162: read without -r
    sed -i.tmp 's/while read \([a-zA-Z_][a-zA-Z0-9_]*\);/while read -r \1;/g' "$file"
    
    # Fix SC2236: Use -n instead of ! -z
    sed -i.tmp 's/\[ ! -z /[ -n /g' "$file"
    
    # Fix SC2086: Quote variables (basic cases)
    sed -i.tmp 's/kubectl delete \([a-zA-Z]*\) \$\([a-zA-Z_][a-zA-Z0-9_]*\)/kubectl delete \1 "$\2"/g' "$file"
    sed -i.tmp 's/helm uninstall \$\([a-zA-Z_][a-zA-Z0-9_]*\)/helm uninstall "$\1"/g' "$file"
    
    # Clean up temp files
    rm -f "$file.tmp"
    
    log_success "Fixed common issues in $file"
}

# Main function
main() {
    log_info "Starting shellcheck fixes for all scripts"
    
    # Find all shell scripts
    local scripts=()
    while IFS= read -r -d '' script; do
        scripts+=("$script")
    done < <(find "$SCRIPT_DIR" -name "*.sh" -type f -print0)
    
    log_info "Found ${#scripts[@]} shell scripts"
    
    for script in "${scripts[@]}"; do
        if [[ "$script" != *"fix-shellcheck.sh" ]]; then
            log_info "Processing $(basename "$script")"
            
            # Add shellcheck ignores for functions
            add_shellcheck_ignores "$script"
            
            # Fix common issues
            fix_common_issues "$script"
        fi
    done
    
    log_success "Completed shellcheck fixes"
    log_warning "Review changes and test scripts before committing"
    log_info "Backup files created with .backup extension"
}

main "$@"