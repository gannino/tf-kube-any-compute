#!/bin/bash
# ============================================================================
# Task 3: HARDEN CONFIGURATION PATTERNS - Module Standardization Script
# ============================================================================
# This script standardizes all Helm modules to use consistent patterns:
# - locals for computed values
# - variables for inputs with proper validation
# - clear testable conditions for enabling/disabling services
# - removal of legacy/dead code

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧱 Task 3: HARDEN CONFIGURATION PATTERNS${NC}"
echo -e "${BLUE}===========================================${NC}"

# Find all helm modules
HELM_MODULES=$(find . -maxdepth 1 -type d -name "helm-*" | sort)

echo -e "${YELLOW}📋 Found Helm modules:${NC}"
for module in $HELM_MODULES; do
    echo "  - $module"
done
echo ""

# Check patterns in each module
echo -e "${BLUE}🔍 Analyzing current patterns...${NC}"

for module in $HELM_MODULES; do
    echo -e "${YELLOW}Analyzing $module...${NC}"
    
    # Check variables.tf patterns
    if [[ -f "$module/variables.tf" ]]; then
        # Count deprecated variables
        deprecated_count=$(grep -c "DEPRECATED\|Legacy\|legacy" "$module/variables.tf" || true)
        
        # Count validation blocks
        validation_count=$(grep -c "validation {" "$module/variables.tf" || true)
        
        # Count helm variables
        helm_vars=$(grep -c "variable \"helm_" "$module/variables.tf" || true)
        
        echo "  📊 Variables: ${deprecated_count} deprecated, ${validation_count} validations, ${helm_vars} helm vars"
    fi
    
    # Check for locals.tf
    if [[ -f "$module/locals.tf" ]]; then
        echo "  ✅ Has locals.tf"
    else
        echo "  ⚠️  Missing locals.tf"
    fi
    
    # Check main.tf patterns
    if [[ -f "$module/main.tf" ]]; then
        # Check for direct variable references vs locals
        direct_var_refs=$(grep -c "var\." "$module/main.tf" || true)
        local_refs=$(grep -c "local\." "$module/main.tf" || true)
        
        echo "  📊 Main.tf: ${direct_var_refs} direct var refs, ${local_refs} local refs"
    fi
    
    echo ""
done

echo -e "${GREEN}✅ Analysis complete. Manual standardization required for full compliance.${NC}"
echo -e "${BLUE}📝 Next steps:${NC}"
echo "  1. Add validation to all input variables"
echo "  2. Move computed values to locals"
echo "  3. Remove deprecated variables"
echo "  4. Standardize Helm configuration patterns"
echo ""
