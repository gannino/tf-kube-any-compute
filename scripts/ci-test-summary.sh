#!/bin/bash
# ============================================================================
# CI Test Summary Script
# ============================================================================
#
# Generates comprehensive test reports for CI/CD pipeline
# Usage: ./scripts/ci-test-summary.sh [--format json|markdown|console]
#
# ============================================================================

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_FORMAT="${1:-console}"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Colors for console output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Test categories
declare -A TEST_CATEGORIES=(
    ["validation"]="Format, Validate, Lint"
    ["unit-tests"]="Architecture, Storage, Services, Mixed-Cluster"
    ["scenario-tests"]="Raspberry Pi, Mixed, Cloud, Minimal, Production"
    ["security"]="Checkov, Trivy, Terrascan"
    ["integration"]="Makefile Commands, Documentation"
)

# Function to check if test files exist
check_test_files() {
    local missing_files=()

    # Check Terraform test files
    for file in "tests-architecture.tftest.hcl" "tests-storage.tftest.hcl" "tests-services.tftest.hcl" "tests-mixed-cluster.tftest.hcl"; do
        if [[ ! -f "$PROJECT_ROOT/$file" ]]; then
            missing_files+=("$file")
        fi
    done

    # Check test configuration files
    for config in "minimal" "raspberry-pi" "mixed-cluster" "cloud" "production"; do
        if [[ ! -f "$PROJECT_ROOT/test-configs/$config.tfvars" ]]; then
            missing_files+=("test-configs/$config.tfvars")
        fi
    done

    echo "${missing_files[@]}"
}

# Function to generate console report
generate_console_report() {
    echo -e "${BLUE}============================================================================${NC}"
    echo -e "${BLUE}tf-kube-any-compute CI Test Summary${NC}"
    echo -e "${BLUE}============================================================================${NC}"
    echo ""
    echo -e "${CYAN}Generated:${NC} $TIMESTAMP"
    echo -e "${CYAN}Project:${NC} tf-kube-any-compute"
    echo -e "${CYAN}Location:${NC} $PROJECT_ROOT"
    echo ""

    # Environment detection
    echo -e "${YELLOW}🔍 Environment Detection:${NC}"
    if [[ "${CI:-}" == "true" ]]; then
        echo -e "  ✅ Running in CI environment"
    else
        echo -e "  🖥️  Running in local environment"
    fi

    if [[ "${GITHUB_ACTIONS:-}" == "true" ]]; then
        echo -e "  ✅ GitHub Actions detected"
    fi
    echo ""

    # Test file status
    echo -e "${YELLOW}📁 Test Files Status:${NC}"
    local missing_files
    missing_files=($(check_test_files))

    if [[ ${#missing_files[@]} -eq 0 ]]; then
        echo -e "  ✅ All test files present"
    else
        echo -e "  ⚠️  Missing files detected:"
        for file in "${missing_files[@]}"; do
            echo -e "    ❌ $file"
        done
    fi
    echo ""

    # Test categories
    echo -e "${YELLOW}🧪 Test Categories:${NC}"
    for category in "${!TEST_CATEGORIES[@]}"; do
        echo -e "  📋 ${category^}: ${TEST_CATEGORIES[$category]}"
    done
    echo ""

    # Available commands
    echo -e "${YELLOW}🚀 Available CI Commands:${NC}"
    echo -e "  ${GREEN}make ci-test-fast${NC}           - Quick validation + unit tests"
    echo -e "  ${GREEN}make ci-test-comprehensive${NC}  - Full test suite"
    echo -e "  ${GREEN}make ci-test-scenarios${NC}      - Deployment scenario tests"
    echo -e "  ${GREEN}make ci-security${NC}            - Security scanning"
    echo -e "  ${GREEN}make ci-validate-all${NC}        - All validation checks"
    echo -e "  ${GREEN}make ci-debug${NC}               - Debug CI environment"
    echo ""

    # Tool versions
    echo -e "${YELLOW}🔧 Tool Versions:${NC}"
    if command -v terraform >/dev/null 2>&1; then
        echo -e "  ✅ $(terraform version | head -1)"
    else
        echo -e "  ❌ Terraform: not available"
    fi

    if command -v kubectl >/dev/null 2>&1; then
        echo -e "  ✅ kubectl: $(kubectl version --client --short 2>/dev/null | head -1 || echo 'available')"
    else
        echo -e "  ❌ kubectl: not available"
    fi

    if command -v helm >/dev/null 2>&1; then
        echo -e "  ✅ helm: $(helm version --short 2>/dev/null || echo 'available')"
    else
        echo -e "  ❌ Helm: not available"
    fi
    echo ""

    # Recommendations
    echo -e "${YELLOW}💡 Recommendations:${NC}"
    if [[ ${#missing_files[@]} -gt 0 ]]; then
        echo -e "  🔧 Fix missing test files before running CI"
    fi
    echo -e "  🧪 Run ${GREEN}make ci-test-fast${NC} for quick local validation"
    echo -e "  🔍 Use ${GREEN}make ci-debug${NC} to troubleshoot issues"
    echo -e "  📚 Check README.md for detailed documentation"
    echo ""

    echo -e "${BLUE}============================================================================${NC}"
}

# Function to generate JSON report
generate_json_report() {
    local missing_files
    missing_files=($(check_test_files))

    cat << EOF
{
  "timestamp": "$TIMESTAMP",
  "project": "tf-kube-any-compute",
  "location": "$PROJECT_ROOT",
  "environment": {
    "ci": "${CI:-false}",
    "github_actions": "${GITHUB_ACTIONS:-false}"
  },
  "test_files": {
    "missing_count": ${#missing_files[@]},
    "missing_files": [$(printf '"%s",' "${missing_files[@]}" | sed 's/,$//')],
    "status": $([ ${#missing_files[@]} -eq 0 ] && echo '"complete"' || echo '"incomplete"')
  },
  "test_categories": {
$(for category in "${!TEST_CATEGORIES[@]}"; do
    echo "    \"$category\": \"${TEST_CATEGORIES[$category]}\","
done | sed '$ s/,$//')
  },
  "tools": {
    "terraform": "$(command -v terraform >/dev/null 2>&1 && terraform version | head -1 | cut -d' ' -f2 || echo 'not_available')",
    "kubectl": "$(command -v kubectl >/dev/null 2>&1 && echo 'available' || echo 'not_available')",
    "helm": "$(command -v helm >/dev/null 2>&1 && echo 'available' || echo 'not_available')"
  },
  "commands": {
    "fast": "make ci-test-fast",
    "comprehensive": "make ci-test-comprehensive",
    "scenarios": "make ci-test-scenarios",
    "security": "make ci-security",
    "validate": "make ci-validate-all",
    "debug": "make ci-debug"
  }
}
EOF
}

# Function to generate Markdown report
generate_markdown_report() {
    local missing_files
    missing_files=($(check_test_files))

    cat << EOF
# tf-kube-any-compute CI Test Summary

**Generated:** $TIMESTAMP
**Project:** tf-kube-any-compute
**Location:** \`$PROJECT_ROOT\`

## 🔍 Environment Detection

$(if [[ "${CI:-}" == "true" ]]; then echo "- ✅ Running in CI environment"; else echo "- 🖥️ Running in local environment"; fi)
$(if [[ "${GITHUB_ACTIONS:-}" == "true" ]]; then echo "- ✅ GitHub Actions detected"; fi)

## 📁 Test Files Status

$(if [[ ${#missing_files[@]} -eq 0 ]]; then
    echo "✅ All test files present"
else
    echo "⚠️ Missing files detected:"
    for file in "${missing_files[@]}"; do
        echo "- ❌ \`$file\`"
    done
fi)

## 🧪 Test Categories

$(for category in "${!TEST_CATEGORIES[@]}"; do
    echo "- **${category^}**: ${TEST_CATEGORIES[$category]}"
done)

## 🚀 Available CI Commands

| Command | Description |
|---------|-------------|
| \`make ci-test-fast\` | Quick validation + unit tests |
| \`make ci-test-comprehensive\` | Full test suite |
| \`make ci-test-scenarios\` | Deployment scenario tests |
| \`make ci-security\` | Security scanning |
| \`make ci-validate-all\` | All validation checks |
| \`make ci-debug\` | Debug CI environment |

## 🔧 Tool Versions

$(if command -v terraform >/dev/null 2>&1; then
    echo "- ✅ $(terraform version | head -1)"
else
    echo "- ❌ Terraform: not available"
fi)
$(if command -v kubectl >/dev/null 2>&1; then
    echo "- ✅ kubectl: available"
else
    echo "- ❌ kubectl: not available"
fi)
$(if command -v helm >/dev/null 2>&1; then
    echo "- ✅ Helm: available"
else
    echo "- ❌ Helm: not available"
fi)

## 💡 Recommendations

$(if [[ ${#missing_files[@]} -gt 0 ]]; then
    echo "- 🔧 Fix missing test files before running CI"
fi)
- 🧪 Run \`make ci-test-fast\` for quick local validation
- 🔍 Use \`make ci-debug\` to troubleshoot issues
- 📚 Check README.md for detailed documentation
EOF
}

# Main execution
main() {
    cd "$PROJECT_ROOT"

    case "$OUTPUT_FORMAT" in
        "json")
            generate_json_report
            ;;
        "markdown")
            generate_markdown_report
            ;;
        "console"|*)
            generate_console_report
            ;;
    esac
}

# Execute main function
main "$@"
