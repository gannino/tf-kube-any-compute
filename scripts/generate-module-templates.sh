#!/bin/bash
# ============================================================================
# Task 3: HARDEN CONFIGURATION PATTERNS - Module Template Generator
# ============================================================================
# This script generates standardized locals.tf files for all helm modules
# following the pattern established with helm-traefik

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧱 Task 3: HARDEN CONFIGURATION PATTERNS - Template Generation${NC}"
echo -e "${BLUE}============================================================${NC}"

# Function to create standardized locals.tf for a module
create_module_locals() {
    local module_dir="$1"
    local module_name=$(basename "$module_dir" | sed 's/helm-//')
    local service_name="$module_name"
    
    # Special name mappings
    case "$module_name" in
        "prometheus-stack") service_name="prometheus" ;;
        "prometheus-stack-crds") service_name="prometheus_crds" ;;
        "host-path") service_name="host_path" ;;
        "nfs-csi") service_name="nfs_csi" ;;
        "node-feature-discovery") service_name="node_feature_discovery" ;;
    esac
    
    echo -e "${YELLOW}📝 Creating locals.tf for $module_dir...${NC}"
    
    cat > "$module_dir/locals.tf" << EOF
# ============================================================================
# HELM-${module_name^^} MODULE - STANDARDIZED CONFIGURATION PATTERNS
# ============================================================================
# This module follows the standardized patterns for Task 3:
# - locals for computed values
# - variables for inputs with validation
# - clear conditions for service enablement
# ============================================================================

locals {
  # ============================================================================
  # COMPUTED VALUES - All derived/computed values use locals
  # ============================================================================
  
  # Module configuration with defaults and overrides
  module_config = {
    # Core settings
    namespace     = var.namespace
    name          = var.name
    chart_name    = var.chart_name
    chart_repo    = var.chart_repo
    chart_version = var.chart_version
    
    # Architecture and node selection
    cpu_arch = var.cpu_arch
    
    # Resource limits
    cpu_limit      = var.cpu_limit
    memory_limit   = var.memory_limit
    cpu_request    = var.cpu_request
    memory_request = var.memory_request
  }
  
  # Helm configuration with validation
  helm_config = {
    timeout          = var.helm_timeout
    disable_webhooks = var.helm_disable_webhooks
    skip_crds        = var.helm_skip_crds
    replace          = var.helm_replace
    force_update     = var.helm_force_update
    cleanup_on_fail  = var.helm_cleanup_on_fail
    wait             = var.helm_wait
    wait_for_jobs    = var.helm_wait_for_jobs
  }
  
  # Computed labels
  common_labels = {
    "app.kubernetes.io/name"       = local.module_config.name
    "app.kubernetes.io/component"  = "$service_name"
    "app.kubernetes.io/managed-by" = "terraform"
    "app.kubernetes.io/part-of"    = "infrastructure"
  }
  
  # Template values for Helm chart
  template_values = {
    CPU_ARCH       = local.module_config.cpu_arch
    CPU_LIMIT      = local.module_config.cpu_limit
    MEMORY_LIMIT   = local.module_config.memory_limit
    CPU_REQUEST    = local.module_config.cpu_request
    MEMORY_REQUEST = local.module_config.memory_request
  }
}
EOF

    echo -e "${GREEN}✅ Created locals.tf for $module_dir${NC}"
}

# Function to add validation to variables.tf
add_variable_validation() {
    local module_dir="$1"
    local vars_file="$module_dir/variables.tf"
    
    if [[ ! -f "$vars_file" ]]; then
        echo -e "${RED}❌ No variables.tf found in $module_dir${NC}"
        return
    fi
    
    echo -e "${YELLOW}🔧 Adding validation to $vars_file...${NC}"
    
    # Check if cpu_arch validation exists
    if ! grep -q "validation {" "$vars_file"; then
        echo -e "${BLUE}📝 Need to add validation blocks manually to $vars_file${NC}"
    else
        echo -e "${GREEN}✅ Validation blocks already exist in $vars_file${NC}"
    fi
}

# Find all helm modules
HELM_MODULES=$(find . -maxdepth 1 -type d -name "helm-*" | sort)

echo -e "${YELLOW}📋 Found Helm modules:${NC}"
for module in $HELM_MODULES; do
    echo "  - $module"
done
echo ""

# Process each module
for module in $HELM_MODULES; do
    # Skip traefik as it's already done
    if [[ "$module" == "./helm-traefik" ]]; then
        echo -e "${GREEN}✅ Skipping $module (already standardized)${NC}"
        continue
    fi
    
    create_module_locals "$module"
    add_variable_validation "$module"
    echo ""
done

echo -e "${GREEN}✨ Task 3 template generation complete!${NC}"
echo -e "${BLUE}📝 Next steps:${NC}"
echo "  1. Review generated locals.tf files"
echo "  2. Add validation blocks to variables.tf files"
echo "  3. Update main.tf files to use locals instead of direct vars"
echo "  4. Test with terraform validate"
echo ""
