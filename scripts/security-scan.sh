#!/bin/bash
# shellcheck disable=SC2086  # Variable expansion needed for command args
# ============================================================================
# Security Scanning Script for tf-kube-any-compute
# ============================================================================
#
# Comprehensive security scanning with multiple tools and detailed guidance
# for developers contributing to the repository.
#
# Usage:
#   ./scripts/security-scan.sh [OPTIONS]
#
# Options:
#   --tool TOOL     Run specific tool (checkov, terrascan, tfsec, trivy, secrets)
#   --output DIR    Save results to directory (default: security-results)
#   --format FORMAT Output format (cli, json, sarif, all) (default: cli)
#   --severity LEVEL Minimum severity (low, medium, high, critical) (default: medium)
#   --fix           Show detailed fix suggestions
#   --ci            CI mode (compact output, exit codes)
#   --help          Show this help message
#
# Examples:
#   ./scripts/security-scan.sh --tool checkov --fix
#   ./scripts/security-scan.sh --output ./scan-results --format all
#   ./scripts/security-scan.sh --ci --severity high
#
# ============================================================================

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="${PROJECT_ROOT}/security-results"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# Default options
TOOL=""
FORMAT="cli"
SEVERITY="medium"
SHOW_FIXES=false
CI_MODE=false
VERBOSE=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
# PURPLE='\033[0;35m'  # Unused variable
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ============================================================================
# Helper Functions
# ============================================================================

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_header() {
    echo -e "\n${CYAN}🔒 $1${NC}"
    echo -e "${CYAN}$(printf '=%.0s' {1..60})${NC}"
}

show_help() {
    cat << EOF
🔒 Security Scanning Script for tf-kube-any-compute

USAGE:
    $0 [OPTIONS]

OPTIONS:
    --tool TOOL         Run specific tool (checkov, terrascan, tfsec, trivy, secrets, all)
    --output DIR        Save results to directory (default: security-results)
    --format FORMAT     Output format (cli, json, sarif, all) (default: cli)
    --severity LEVEL    Minimum severity (low, medium, high, critical) (default: medium)
    --fix              Show detailed fix suggestions
    --ci               CI mode (compact output, exit codes)
    --verbose          Verbose output
    --help             Show this help message

EXAMPLES:
    # Run all security scans with fix suggestions
    $0 --fix

    # Run only Checkov with JSON output
    $0 --tool checkov --format json

    # CI mode with high severity only
    $0 --ci --severity high

    # Save all results to custom directory
    $0 --output ./my-scan-results --format all

AVAILABLE TOOLS:
    checkov     - Comprehensive policy and security scanning
    terrascan   - Policy-as-code security scanning
    tfsec       - Terraform security analysis
    trivy       - Vulnerability scanning
    secrets     - Secret detection
    all         - Run all available tools (default)

SECURITY POLICY CATEGORIES:
    🛡️  Infrastructure Security - Resource configurations, access controls
    🔐 Secrets Management - Hardcoded secrets, credential exposure
    🌐 Network Security - Network policies, ingress configurations
    📦 Container Security - Image security, runtime configurations
    🔑 RBAC & Permissions - Role-based access control
    📊 Compliance - Industry standards and best practices

EOF
}

check_tool_availability() {
    local tool=$1
    if command -v "$tool" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

install_instructions() {
    local tool=$1
    case $tool in
        checkov)
            echo "pip install checkov"
            ;;
        terrascan)
            echo "brew install terrascan"
            ;;
        tfsec)
            echo "brew install tfsec"
            ;;
        trivy)
            echo "brew install trivy"
            ;;
        detect-secrets)
            echo "pip install detect-secrets"
            ;;
        *)
            echo "Check tool documentation for installation instructions"
            ;;
    esac
}

# ============================================================================
# Security Scanning Functions
# ============================================================================

run_checkov() {
    log_header "Checkov - Comprehensive Policy Scanning"

    if ! check_tool_availability "checkov"; then
        log_error "Checkov not available"
        log_info "Install: $(install_instructions checkov)"
        return 1
    fi

    local output_args=""
    local severity_args=""

    # Configure output format
    case $FORMAT in
        json)
            output_args="--output json --output-file-path ${OUTPUT_DIR}/checkov-${TIMESTAMP}.json"
            ;;
        sarif)
            output_args="--output sarif --output-file-path ${OUTPUT_DIR}/checkov-${TIMESTAMP}.sarif"
            ;;
        all)
            output_args="--output cli --output json --output sarif --output-file-path console,${OUTPUT_DIR}/checkov-${TIMESTAMP}.json,${OUTPUT_DIR}/checkov-${TIMESTAMP}.sarif"
            ;;
        *)
            output_args="--output cli"
            ;;
    esac

    # Configure severity
    case $SEVERITY in
        critical)
            severity_args="--check CKV_*"
            ;;
        high)
            severity_args="--check CKV_*"
            ;;
        *)
            severity_args=""
            ;;
    esac

    log_info "Running Checkov scan..."

    if $CI_MODE; then
        checkov -d "$PROJECT_ROOT" \
            --framework terraform,kubernetes,helm \
            $output_args \
            --compact \
            --quiet \
            --soft-fail || true
    else
        checkov -d "$PROJECT_ROOT" \
            --framework terraform,kubernetes,helm \
            $output_args \
            --soft-fail || true
    fi

    if $SHOW_FIXES; then
        show_checkov_fixes
    fi

    log_success "Checkov scan completed"
}

show_checkov_fixes() {
    cat << 'EOF'

💡 COMMON CHECKOV FIXES:

🛡️  KUBERNETES SECURITY:
• CKV_K8S_8: Add resource limits to containers
  Fix: Add resources.limits.cpu and resources.limits.memory

• CKV_K8S_9: Add resource requests to containers
  Fix: Add resources.requests.cpu and resources.requests.memory

• CKV_K8S_10: Don't run containers as root
  Fix: Add securityContext.runAsNonRoot: true

• CKV_K8S_12: Add readiness probes
  Fix: Add readinessProbe configuration

• CKV_K8S_13: Add liveness probes
  Fix: Add livenessProbe configuration

• CKV_K8S_14: Add image pull policy
  Fix: Add imagePullPolicy: Always or IfNotPresent

• CKV_K8S_16: Don't allow privilege escalation
  Fix: Add securityContext.allowPrivilegeEscalation: false

• CKV_K8S_17: Don't run privileged containers
  Fix: Remove privileged: true or set to false

• CKV_K8S_22: Use read-only root filesystem
  Fix: Add securityContext.readOnlyRootFilesystem: true

• CKV_K8S_25: Minimize wildcard use in RBAC
  Fix: Specify exact resources instead of "*"

• CKV_K8S_38: Minimize service account token mounting
  Fix: Add automountServiceAccountToken: false

🔧 TERRAFORM SECURITY:
• CKV_TF_1: Use commit hash in module sources
  Fix: Use git::https://github.com/user/repo.git?ref=commit-hash

• CKV2_K8S_6: Minimize privilege escalation
  Fix: Apply security contexts consistently

📚 Documentation: https://www.checkov.io/5.Policy%20Index/kubernetes.html

EOF
}

run_terrascan() {
    log_header "Terrascan - Policy-as-Code Scanning"

    if ! check_tool_availability "terrascan"; then
        log_error "Terrascan not available"
        log_info "Install: $(install_instructions terrascan)"
        return 1
    fi

    local output_args=""
    local severity_args=""

    # Configure output format
    case $FORMAT in
        json)
            output_args="--output json --output-file ${OUTPUT_DIR}/terrascan-${TIMESTAMP}.json"
            ;;
        sarif)
            output_args="--output sarif --output-file ${OUTPUT_DIR}/terrascan-${TIMESTAMP}.sarif"
            ;;
        all)
            output_args="--output human --output sarif --output-file ${OUTPUT_DIR}/terrascan-${TIMESTAMP}.sarif"
            ;;
        *)
            output_args="--output human"
            ;;
    esac

    # Configure severity
    case $SEVERITY in
        critical)
            severity_args="--severity critical"
            ;;
        high)
            severity_args="--severity high,critical"
            ;;
        medium)
            severity_args="--severity medium,high,critical"
            ;;
        *)
            severity_args="--severity low,medium,high,critical"
            ;;
    esac

    log_info "Running Terrascan scan..."

    cd "$PROJECT_ROOT"
    terrascan scan \
        --iac-type terraform \
        --policy-type k8s,aws,azure,gcp \
        $severity_args \
        $output_args \
        --verbose || true

    if $SHOW_FIXES; then
        show_terrascan_fixes
    fi

    log_success "Terrascan scan completed"
}

show_terrascan_fixes() {
    cat << 'EOF'

💡 COMMON TERRASCAN POLICY FIXES:

🔐 SECURITY POLICIES:
• AC_K8S_0001: Ensure containers do not run as root
  Fix: Add securityContext.runAsNonRoot: true

• AC_K8S_0002: Ensure containers do not allow privilege escalation
  Fix: Add securityContext.allowPrivilegeEscalation: false

• AC_K8S_0003: Ensure containers do not run privileged
  Fix: Remove privileged: true or set to false

• AC_K8S_0004: Ensure containers have resource limits
  Fix: Add resources.limits.cpu and resources.limits.memory

• AC_K8S_0005: Ensure containers have resource requests
  Fix: Add resources.requests.cpu and resources.requests.memory

• AC_K8S_0006: Ensure containers have liveness probe
  Fix: Add livenessProbe configuration

• AC_K8S_0007: Ensure containers have readiness probe
  Fix: Add readinessProbe configuration

• AC_K8S_0008: Ensure containers use read-only root filesystem
  Fix: Add securityContext.readOnlyRootFilesystem: true

🌐 NETWORK POLICIES:
• AC_K8S_0011: Ensure default deny network policy exists
  Fix: Create NetworkPolicy with default deny rules

• AC_K8S_0012: Ensure ingress has TLS configured
  Fix: Add tls section to Ingress spec

• AC_K8S_0013: Ensure services do not use NodePort
  Fix: Use ClusterIP or LoadBalancer instead of NodePort

💾 STORAGE POLICIES:
• AC_K8S_0014: Ensure PVCs have storage size limits
  Fix: Add storage size limits to PVC spec

• AC_K8S_0015: Ensure hostPath volumes are not used
  Fix: Use PVC or other volume types instead of hostPath

🔑 RBAC POLICIES:
• AC_K8S_0016: Ensure RBAC is configured
  Fix: Create ServiceAccount, Role, and RoleBinding

• AC_K8S_0017: Ensure service accounts do not automount tokens
  Fix: Add automountServiceAccountToken: false

• AC_K8S_0018: Ensure ClusterRoles do not have wildcard permissions
  Fix: Specify exact resources instead of "*"

📚 Documentation: https://runterrascan.io/docs/policies/

EOF
}

run_tfsec() {
    log_header "TFSec - Terraform Security Analysis"

    if ! check_tool_availability "tfsec"; then
        log_error "TFSec not available"
        log_info "Install: $(install_instructions tfsec)"
        return 1
    fi

    local output_args=""
    local severity_args=""

    # Configure output format
    case $FORMAT in
        json)
            output_args="--format json --out ${OUTPUT_DIR}/tfsec-${TIMESTAMP}.json"
            ;;
        sarif)
            output_args="--format sarif --out ${OUTPUT_DIR}/tfsec-${TIMESTAMP}.sarif"
            ;;
        all)
            output_args="--format json --out ${OUTPUT_DIR}/tfsec-${TIMESTAMP}.json"
            ;;
        *)
            output_args=""
            ;;
    esac

    # Configure severity
    case $SEVERITY in
        critical)
            severity_args="--minimum-severity CRITICAL"
            ;;
        high)
            severity_args="--minimum-severity HIGH"
            ;;
        medium)
            severity_args="--minimum-severity MEDIUM"
            ;;
        *)
            severity_args="--minimum-severity LOW"
            ;;
    esac

    log_info "Running TFSec scan..."

    cd "$PROJECT_ROOT"
    tfsec . \
        $output_args \
        $severity_args \
        --soft-fail || true

    if $SHOW_FIXES; then
        show_tfsec_fixes
    fi

    log_success "TFSec scan completed"
}

show_tfsec_fixes() {
    cat << 'EOF'

💡 COMMON TFSEC FIXES:

🛡️  KUBERNETES SECURITY:
• AVD-KSV-0001: Add resource limits to containers
  Fix: Add resources.limits.cpu and resources.limits.memory

• AVD-KSV-0012: Set runAsNonRoot: true
  Fix: Add securityContext.runAsNonRoot: true

• AVD-KSV-0014: Set readOnlyRootFilesystem: true
  Fix: Add securityContext.readOnlyRootFilesystem: true

• AVD-KSV-0017: Set allowPrivilegeEscalation: false
  Fix: Add securityContext.allowPrivilegeEscalation: false

• AVD-KSV-0020: Don't run as root user
  Fix: Add securityContext.runAsUser: 1000

• AVD-KSV-0030: Apply security context
  Fix: Add comprehensive securityContext configuration

🔧 GENERAL SECURITY:
• Use specific image tags instead of 'latest'
  Fix: Specify exact version tags (e.g., nginx:1.21.0)

• Enable security contexts for all containers
  Fix: Add securityContext to all container specifications

• Configure network policies for isolation
  Fix: Create NetworkPolicy resources for pod isolation

• Use read-only root filesystems
  Fix: Mount writable volumes only where necessary

• Implement proper RBAC
  Fix: Create specific ServiceAccounts, Roles, and RoleBindings

📚 Documentation: https://aquasecurity.github.io/tfsec/

EOF
}

run_trivy() {
    log_header "Trivy - Vulnerability & Terraform Security Scanning"

    if ! check_tool_availability "trivy"; then
        log_error "Trivy not available"
        log_info "Install: $(install_instructions trivy)"
        return 1
    fi

    local output_args=""
    local severity_args=""

    # Configure output format
    case $FORMAT in
        json)
            output_args="--format json --output ${OUTPUT_DIR}/trivy-${TIMESTAMP}.json"
            ;;
        sarif)
            output_args="--format sarif --output ${OUTPUT_DIR}/trivy-${TIMESTAMP}.sarif"
            ;;
        all)
            output_args="--format json --output ${OUTPUT_DIR}/trivy-${TIMESTAMP}.json"
            ;;
        *)
            output_args=""
            ;;
    esac

    # Configure severity
    case $SEVERITY in
        critical)
            severity_args="--severity CRITICAL"
            ;;
        high)
            severity_args="--severity HIGH,CRITICAL"
            ;;
        medium)
            severity_args="--severity MEDIUM,HIGH,CRITICAL"
            ;;
        *)
            severity_args="--severity LOW,MEDIUM,HIGH,CRITICAL"
            ;;
    esac

    log_info "Running Trivy filesystem scan (includes Terraform security)..."

    cd "$PROJECT_ROOT"
    # Trivy filesystem scan includes both vulnerabilities and Terraform security
    trivy fs . \
        $output_args \
        $severity_args \
        --ignore-unfixed \
        --scanners vuln,config,secret || true

    log_info "Running Trivy config scan for Terraform..."
    # Additional config-only scan for detailed Terraform analysis
    trivy config . \
        $severity_args \
        --format table || true

    if $SHOW_FIXES; then
        show_trivy_fixes
    fi

    log_success "Trivy scan completed"
}

show_trivy_fixes() {
    cat << 'EOF'

💡 COMMON TRIVY FIXES (Vulnerabilities + Terraform Security):

🔄 DEPENDENCY UPDATES:
• Update dependencies to latest secure versions
  Fix: Update package.json, requirements.txt, go.mod, etc.

• Use specific image tags with known security status
  Fix: Replace 'latest' tags with specific versions

• Apply security patches to base images
  Fix: Use updated base images or apply patches

• Review and update Helm chart versions
  Fix: Update Chart.yaml dependencies to latest secure versions

🐳 CONTAINER SECURITY:
• Scan container images for vulnerabilities
  Fix: Use trivy image <image-name> to scan specific images

• Use minimal base images (distroless, alpine)
  Fix: Switch to smaller, more secure base images

• Remove unnecessary packages and files
  Fix: Use multi-stage builds to minimize attack surface

• Keep container runtime updated
  Fix: Update Docker, containerd, or other runtime

🔧 TERRAFORM SECURITY (replaces tfsec):
• AVD-KSV-0001: Add resource limits to containers
  Fix: Add resources.limits.cpu and resources.limits.memory

• AVD-KSV-0012: Set runAsNonRoot: true
  Fix: Add securityContext.runAsNonRoot: true

• AVD-KSV-0014: Set readOnlyRootFilesystem: true
  Fix: Add securityContext.readOnlyRootFilesystem: true

• AVD-KSV-0017: Set allowPrivilegeEscalation: false
  Fix: Add securityContext.allowPrivilegeEscalation: false

• Use specific image tags instead of 'latest'
  Fix: Specify exact version tags (e.g., nginx:1.21.0)

🔐 SECRET DETECTION:
• Remove hardcoded secrets from code
  Fix: Use environment variables or secret management

• Use .gitignore for sensitive files
  Fix: Prevent committing sensitive configuration

📦 PACKAGE MANAGEMENT:
• Audit and update package dependencies
  Fix: Run npm audit, pip-audit, or equivalent tools

• Use dependency scanning in CI/CD
  Fix: Integrate vulnerability scanning in build pipeline

• Pin dependency versions
  Fix: Use exact versions instead of ranges

📚 Documentation: https://aquasecurity.github.io/trivy/
🔄 tfsec Migration: https://github.com/aquasecurity/tfsec#tfsec-is-joining-the-trivy-family

EOF
}

run_secrets_scan() {
    log_header "Secret Detection Scanning"

    log_info "Scanning for potential secrets..."

    # Basic grep-based secret detection
    local secret_patterns=(
        "password"
        "secret"
        "key"
        "token"
        "credential"
        "api_key"
        "access_key"
        "private_key"
        "auth"
    )

    local found_secrets=false

    for pattern in "${secret_patterns[@]}"; do
        if git ls-files | xargs grep -l "$pattern" | grep -v ".git\|Makefile\|README\|test\|\.md\|\.yaml\|\.yml\|scripts/" 2>/dev/null; then
            found_secrets=true
        fi
    done

    if $found_secrets; then
        log_warning "Potential secrets found in files above"
        if $SHOW_FIXES; then
            show_secrets_fixes
        fi
    else
        log_success "No obvious secrets found"
    fi

    # Advanced secret detection with detect-secrets
    if check_tool_availability "detect-secrets"; then
        log_info "Running detect-secrets scan..."

        local output_file="${OUTPUT_DIR}/secrets-${TIMESTAMP}.txt"

        if [[ "$FORMAT" == "json" || "$FORMAT" == "all" ]]; then
            detect-secrets scan --all-files > "${OUTPUT_DIR}/secrets-${TIMESTAMP}.json" || true
        else
            detect-secrets scan --all-files > "$output_file" || true
        fi

        log_success "detect-secrets scan completed"
    else
        log_info "Install detect-secrets for advanced secret detection: $(install_instructions detect-secrets)"
    fi
}

show_secrets_fixes() {
    cat << 'EOF'

💡 SECRET MANAGEMENT FIXES:

🔐 ENVIRONMENT VARIABLES:
• Move secrets to environment variables
  Fix: Use TF_VAR_* environment variables for Terraform

• Use Kubernetes secrets
  Fix: Create Secret resources and mount as volumes or env vars

• Implement external secret management
  Fix: Use HashiCorp Vault, AWS Secrets Manager, etc.

📁 FILE MANAGEMENT:
• Add sensitive files to .gitignore
  Fix: Prevent committing sensitive files

• Use terraform.tfvars.example templates
  Fix: Provide examples without real values

• Separate configuration from secrets
  Fix: Use separate files for sensitive configuration

🔧 TERRAFORM BEST PRACTICES:
• Use terraform variables for sensitive data
  Fix: Define sensitive = true in variable blocks

• Use data sources for secrets
  Fix: Retrieve secrets from external sources at runtime

• Implement proper state file security
  Fix: Use remote state with encryption

🛡️  SECURITY MEASURES:
• Rotate secrets regularly
  Fix: Implement secret rotation policies

• Use least privilege access
  Fix: Grant minimal required permissions

• Audit secret access
  Fix: Monitor and log secret usage

📚 Documentation: https://www.terraform.io/docs/language/values/variables.html#suppressing-values-in-cli-output

EOF
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --tool)
                TOOL="$2"
                shift 2
                ;;
            --output)
                OUTPUT_DIR="$2"
                shift 2
                ;;
            --format)
                FORMAT="$2"
                shift 2
                ;;
            --severity)
                SEVERITY="$2"
                shift 2
                ;;
            --fix)
                SHOW_FIXES=true
                shift
                ;;
            --ci)
                CI_MODE=true
                shift
                ;;
            --verbose)
                VERBOSE=true  # Used for future enhancement
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # Create output directory
    mkdir -p "$OUTPUT_DIR"

    # Change to project root
    cd "$PROJECT_ROOT"

    log_header "Security Scanning for tf-kube-any-compute"
    log_info "Project: $PROJECT_ROOT"
    log_info "Output: $OUTPUT_DIR"
    log_info "Format: $FORMAT"
    log_info "Severity: $SEVERITY"
    log_info "Timestamp: $TIMESTAMP"

    # Run specific tool or all tools
    case $TOOL in
        checkov)
            run_checkov
            ;;
        terrascan)
            run_terrascan
            ;;
        tfsec)
            run_tfsec
            ;;
        trivy)
            run_trivy
            ;;
        secrets)
            run_secrets_scan
            ;;
        all|"")
            run_checkov
            run_terrascan
            run_tfsec
            run_trivy
            run_secrets_scan
            ;;
        *)
            log_error "Unknown tool: $TOOL"
            log_info "Available tools: checkov, terrascan, tfsec, trivy, secrets, all"
            exit 1
            ;;
    esac

    # Generate summary report
    if [[ $FORMAT == "all" || $FORMAT == "json" ]]; then
        generate_summary_report
    fi

    log_success "Security scanning completed!"
    log_info "Results saved to: $OUTPUT_DIR"

    if $SHOW_FIXES; then
        echo -e "\n${CYAN}📚 Additional Resources:${NC}"
        echo "• Kubernetes Security Best Practices: https://kubernetes.io/docs/concepts/security/"
        echo "• Terraform Security Guide: https://learn.hashicorp.com/tutorials/terraform/security"
        echo "• OWASP Kubernetes Security Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Kubernetes_Security_Cheat_Sheet.html"
    fi
}

generate_summary_report() {
    local summary_file="${OUTPUT_DIR}/security-report-${TIMESTAMP}.md"

    cat > "$summary_file" << EOF
# Security Scan Report

**Project**: tf-kube-any-compute
**Timestamp**: $(date)
**Scan ID**: $TIMESTAMP

## Scan Configuration

- **Tools**: $TOOL
- **Format**: $FORMAT
- **Severity**: $SEVERITY
- **Output Directory**: $OUTPUT_DIR

## Tools Used

EOF

    for tool in checkov terrascan tfsec trivy; do
        if check_tool_availability "$tool"; then
            echo "- ✅ $tool" >> "$summary_file"
        else
            echo "- ❌ $tool (not available)" >> "$summary_file"
        fi
    done

    cat >> "$summary_file" << EOF

## Results

Results are available in the following formats:
- CLI output (console)
- JSON format (machine-readable)
- SARIF format (GitHub Security tab)

## Next Steps

1. Review security findings in individual tool outputs
2. Apply suggested fixes from tool documentation
3. Re-run scans to verify fixes
4. Integrate security scanning into CI/CD pipeline

## Resources

- [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/)
- [Terraform Security Guide](https://learn.hashicorp.com/tutorials/terraform/security)
- [OWASP Kubernetes Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Kubernetes_Security_Cheat_Sheet.html)

EOF

    log_success "Summary report generated: $summary_file"
}

# Run main function
main "$@"
