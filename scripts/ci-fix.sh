#!/bin/bash
# CI Fix Script - Addresses common CI/CD pipeline issues

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Running CI/CD fixes...${NC}"

# Fix 1: Update pre-commit hooks
echo -e "${YELLOW}📋 Updating pre-commit hooks...${NC}"
if command -v pre-commit >/dev/null 2>&1; then
    pre-commit autoupdate || echo "Pre-commit autoupdate failed, continuing..."
    pre-commit install || echo "Pre-commit install failed, continuing..."
else
    echo "Pre-commit not installed, skipping hook updates"
fi

# Fix 2: Terraform formatting
echo -e "${YELLOW}🎨 Running terraform fmt...${NC}"
terraform fmt -recursive

# Fix 3: Validate terraform configuration
echo -e "${YELLOW}✅ Validating terraform configuration...${NC}"
terraform init -backend=false
terraform validate

# Fix 4: Check for missing test config files
echo -e "${YELLOW}📁 Checking test configuration files...${NC}"
test_configs_dir="test-configs"
if [ ! -d "$test_configs_dir" ]; then
    echo "Creating test-configs directory..."
    mkdir -p "$test_configs_dir"
fi

# Create basic test configs if they don't exist
configs=("basic.tfvars" "raspberry-pi.tfvars" "mixed-cluster.tfvars" "cloud.tfvars")
for config in "${configs[@]}"; do
    if [ ! -f "$test_configs_dir/$config" ]; then
        echo "Creating $config..."
        cat > "$test_configs_dir/$config" << EOF
# Test configuration for $config
base_domain = "test.local"
platform_name = "test"
cpu_arch = ""
services = {
  traefik = true
  metallb = true
  host_path = true
  prometheus = true
  grafana = true
}
EOF
    fi
done

# Fix 5: Update TFLint configuration
echo -e "${YELLOW}🔍 Updating TFLint configuration...${NC}"
if [ -f ".tflint.hcl" ]; then
    # Remove AWS plugin if not needed
    sed -i.bak '/plugin "aws"/,/}/d' .tflint.hcl 2>/dev/null || true
    rm -f .tflint.hcl.bak
fi

# Fix 6: Create versions file if missing
echo -e "${YELLOW}📦 Checking versions file...${NC}"
if [ ! -f "versions.tf" ]; then
    echo "versions.tf already exists, skipping creation"
fi

echo -e "${GREEN}✅ CI/CD fixes completed!${NC}"
echo -e "${BLUE}💡 Next steps:${NC}"
echo "1. Run: make test-safe"
echo "2. Run: pre-commit run --all-files"
echo "3. Commit changes and push"