#!/bin/bash
# Security Test Runner Script for tf-kube-any-compute
# Enhanced security testing with detailed reporting

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
RESULTS_DIR="security-results"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
REPORT_FILE="${RESULTS_DIR}/security-report-${TIMESTAMP}.md"

# Create results directory
mkdir -p "$RESULTS_DIR"

echo -e "${BLUE}🛡️  tf-kube-any-compute Security Test Suite${NC}"
echo -e "${BLUE}=============================================${NC}"
echo ""

# Initialize report
cat > "$REPORT_FILE" << EOF
# Security Scan Report

**Generated:** $(date)
**Repository:** tf-kube-any-compute
**Branch:** $(git branch --show-current 2>/dev/null || echo "unknown")
**Commit:** $(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

## Executive Summary

This report contains the results of comprehensive security scanning for the tf-kube-any-compute Terraform infrastructure.

## Scan Results

EOF

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to add section to report
add_section() {
    local title="$1"
    local content="$2"
    echo -e "\n### $title\n" >> "$REPORT_FILE"
    echo -e "$content\n" >> "$REPORT_FILE"
}

# Function to run Checkov
run_checkov() {
    echo -e "${CYAN}🔍 Running Checkov security scan...${NC}"

    if command_exists checkov; then
        local checkov_output="${RESULTS_DIR}/checkov-${TIMESTAMP}.json"
        local checkov_cli="${RESULTS_DIR}/checkov-${TIMESTAMP}.txt"

        # Run Checkov with multiple outputs
        checkov -d . \
            --framework terraform \
            --output cli \
            --output json \
            --output-file-path "$checkov_cli,$checkov_output" \
            --soft-fail || true

        echo -e "${GREEN}✅ Checkov scan completed${NC}"

        # Extract key metrics for report
        if [[ -f "$checkov_output" ]]; then
            local passed=$(jq -r '.summary.passed // 0' "$checkov_output" 2>/dev/null || echo "0")
            local failed=$(jq -r '.summary.failed // 0' "$checkov_output" 2>/dev/null || echo "0")
            local skipped=$(jq -r '.summary.skipped // 0' "$checkov_output" 2>/dev/null || echo "0")

            add_section "Checkov Results" "- **Passed:** $passed
- **Failed:** $failed
- **Skipped:** $skipped
- **Details:** See \`$checkov_cli\` for full output"
        fi
    else
        echo -e "${YELLOW}⚠️  Checkov not installed${NC}"
        add_section "Checkov Results" "❌ **Not Available** - Install with: \`pip install checkov\`"
    fi
}

# Function to run TfSec
run_tfsec() {
    echo -e "${CYAN}🔍 Running TfSec security scan...${NC}"

    if command_exists tfsec; then
        local tfsec_output="${RESULTS_DIR}/tfsec-${TIMESTAMP}.json"
        local tfsec_cli="${RESULTS_DIR}/tfsec-${TIMESTAMP}.txt"

        # Run TfSec with JSON output
        tfsec . \
            --format json \
            --out "$tfsec_output" \
            --soft-fail || true

        # Also get human-readable output
        tfsec . \
            --format default \
            --out "$tfsec_cli" \
            --soft-fail || true

        echo -e "${GREEN}✅ TfSec scan completed${NC}"

        # Extract metrics
        if [[ -f "$tfsec_output" ]]; then
            local total_issues=$(jq -r '.results | length' "$tfsec_output" 2>/dev/null || echo "0")
            local critical=$(jq -r '[.results[] | select(.severity == "CRITICAL")] | length' "$tfsec_output" 2>/dev/null || echo "0")
            local high=$(jq -r '[.results[] | select(.severity == "HIGH")] | length' "$tfsec_output" 2>/dev/null || echo "0")
            local medium=$(jq -r '[.results[] | select(.severity == "MEDIUM")] | length' "$tfsec_output" 2>/dev/null || echo "0")

            add_section "TfSec Results" "- **Total Issues:** $total_issues
- **Critical:** $critical
- **High:** $high
- **Medium:** $medium
- **Details:** See \`$tfsec_cli\` for full output"
        fi
    else
        echo -e "${YELLOW}⚠️  TfSec not installed${NC}"
        add_section "TfSec Results" "❌ **Not Available** - Install with: \`brew install tfsec\`"
    fi
}

# Function to run Trivy
run_trivy() {
    echo -e "${CYAN}🔍 Running Trivy vulnerability scan...${NC}"

    if command_exists trivy; then
        local trivy_output="${RESULTS_DIR}/trivy-${TIMESTAMP}.json"
        local trivy_cli="${RESULTS_DIR}/trivy-${TIMESTAMP}.txt"

        # Run Trivy filesystem scan
        trivy fs . \
            --format json \
            --output "$trivy_output" \
            --severity HIGH,CRITICAL || true

        # Human-readable output
        trivy fs . \
            --format table \
            --output "$trivy_cli" \
            --severity HIGH,CRITICAL || true

        echo -e "${GREEN}✅ Trivy scan completed${NC}"

        # Extract vulnerability count
        if [[ -f "$trivy_output" ]]; then
            local vuln_count=$(jq -r '[.Results[]? | select(.Vulnerabilities) | .Vulnerabilities | length] | add // 0' "$trivy_output" 2>/dev/null || echo "0")

            add_section "Trivy Results" "- **Vulnerabilities Found:** $vuln_count (HIGH/CRITICAL)
- **Details:** See \`$trivy_cli\` for full output"
        fi
    else
        echo -e "${YELLOW}⚠️  Trivy not installed${NC}"
        add_section "Trivy Results" "❌ **Not Available** - Install with: \`brew install trivy\`"
    fi
}

# Function to run secrets detection
run_secrets_scan() {
    echo -e "${CYAN}🔍 Running secrets detection...${NC}"

    local secrets_output="${RESULTS_DIR}/secrets-${TIMESTAMP}.txt"

    if command_exists gitleaks; then
        # Run GitLeaks
        gitleaks detect \
            --source . \
            --no-git \
            --report-format json \
            --report-path "${RESULTS_DIR}/gitleaks-${TIMESTAMP}.json" || true

        # Summary output
        gitleaks detect \
            --source . \
            --no-git > "$secrets_output" 2>&1 || true

        echo -e "${GREEN}✅ GitLeaks scan completed${NC}"
        add_section "Secrets Detection (GitLeaks)" "- **Results:** See \`$secrets_output\`"
    else
        echo -e "${CYAN}Running basic pattern matching...${NC}"

        # Basic secrets pattern matching
        {
            echo "=== Potential Secrets Pattern Analysis ==="
            echo ""
            git ls-files 2>/dev/null | xargs grep -l "password\|secret\|key\|token\|api_key\|access_key" 2>/dev/null | \
                grep -v ".git\|Makefile\|README\|test\|\.md\|CHANGELOG\|security-test.sh" || echo "No obvious secrets found"
            echo ""
            echo "=== Files with Sensitive Patterns ==="
            git ls-files 2>/dev/null | xargs grep -Hn "password\|secret\|key\|token" 2>/dev/null | \
                grep -v ".git\|Makefile\|README\|test\|\.md\|CHANGELOG\|security-test.sh" | head -10 || echo "No sensitive patterns found"
        } > "$secrets_output"

        add_section "Secrets Detection (Basic)" "- **Method:** Pattern matching
- **Results:** See \`$secrets_output\`
- **Recommendation:** Install GitLeaks for better detection: \`brew install gitleaks\`"
    fi
}

# Function to analyze Terraform configuration
analyze_terraform_config() {
    echo -e "${CYAN}🔍 Analyzing Terraform configuration...${NC}"

    local config_analysis="${RESULTS_DIR}/terraform-analysis-${TIMESTAMP}.txt"

    {
        echo "=== Terraform Security Configuration Analysis ==="
        echo ""

        echo "--- Security Context Usage ---"
        grep -r "securityContext" . --include="*.tf" || echo "No securityContext configurations found"
        echo ""

        echo "--- Network Policy References ---"
        grep -r "NetworkPolicy\|network_policy" . --include="*.tf" || echo "No network policies found"
        echo ""

        echo "--- RBAC Configuration ---"
        grep -r "rbac\|ClusterRole\|Role\|ServiceAccount" . --include="*.tf" || echo "No RBAC configurations found"
        echo ""

        echo "--- Pod Security Standards ---"
        grep -r "podSecurityStandards\|pod-security" . --include="*.tf" || echo "No pod security standards found"
        echo ""

        echo "--- TLS/SSL Configuration ---"
        grep -r "tls\|ssl\|certificate" . --include="*.tf" | head -10 || echo "No TLS/SSL configurations found"
        echo ""

        echo "--- Resource Quotas and Limits ---"
        grep -r "resources\|limits\|requests" . --include="*.tf" | head -10 || echo "No resource limits found"

    } > "$config_analysis"

    add_section "Terraform Configuration Analysis" "- **Security contexts, RBAC, TLS, and resource configurations analyzed**
- **Details:** See \`$config_analysis\`"
}

# Function to generate recommendations
generate_recommendations() {
    echo -e "${CYAN}📋 Generating security recommendations...${NC}"

    add_section "Security Recommendations" "
#### Immediate Actions
1. **Review Critical/High Findings:** Address any critical or high-severity issues found by scanners
2. **Update Dependencies:** Ensure all Helm charts and container images are using latest secure versions
3. **Enable Security Policies:** Consider enabling Pod Security Standards and Network Policies in production

#### Best Practices
1. **Regular Scanning:** Integrate security scanning into CI/CD pipeline (already configured)
2. **Least Privilege:** Ensure services run with minimal required permissions
3. **Network Segmentation:** Implement network policies to restrict inter-pod communication
4. **Secrets Management:** Use Kubernetes secrets or external secret management systems
5. **Monitoring:** Enable security monitoring and audit logging

#### Compliance
1. **CIS Benchmarks:** Consider implementing CIS Kubernetes Benchmark recommendations
2. **Pod Security Standards:** Enable restricted pod security standards for production namespaces
3. **RBAC:** Implement fine-grained RBAC policies
4. **Image Security:** Use image scanning and admission controllers

#### Future Enhancements
1. **OPA Gatekeeper:** Consider enabling OPA Gatekeeper for policy enforcement
2. **Service Mesh:** Implement service mesh for enhanced security and observability
3. **Runtime Security:** Consider tools like Falco for runtime security monitoring
"
}

# Main execution
echo -e "${BLUE}Starting comprehensive security scan...${NC}"
echo ""

# Run all security tests
run_checkov
echo ""

run_tfsec
echo ""

run_trivy
echo ""

run_secrets_scan
echo ""

analyze_terraform_config
echo ""

generate_recommendations

# Finalize report
echo -e "\n---\n" >> "$REPORT_FILE"
echo -e "*Report generated by tf-kube-any-compute security test suite*" >> "$REPORT_FILE"

echo -e "${GREEN}🎉 Security scan completed!${NC}"
echo -e "${CYAN}📄 Report saved to: $REPORT_FILE${NC}"
echo -e "${CYAN}📁 All results in: $RESULTS_DIR/${NC}"
echo ""

# Summary
echo -e "${BLUE}📊 Scan Summary:${NC}"
echo -e "  📄 Report: $REPORT_FILE"
echo -e "  📁 Results: $RESULTS_DIR/"
echo -e "  🔍 Tools used: Checkov, TfSec, Trivy, Secrets Detection"
echo -e "  📋 Next: Review findings and implement recommendations"
echo ""
