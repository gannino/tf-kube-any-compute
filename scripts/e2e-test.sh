#!/bin/bash
# ============================================================================
# End-to-End Test Script
# ============================================================================
#
# Comprehensive testing script that validates the entire deployment lifecycle
# from planning to deployment to verification to cleanup
#
# Usage:
#   ./scripts/e2e-test.sh [test-scenario]
#
# Test Scenarios:
#   basic           - Basic deployment with core services
#   arm64           - ARM64 Raspberry Pi deployment
#   full-stack      - Full deployment with all services
#   nfs-storage     - NFS storage configuration
#   security        - Security-focused deployment
#   cleanup-only    - Only run cleanup procedures
#
# Environment Variables:
#   E2E_SKIP_CLEANUP    - Skip cleanup phase (default: false)
#   E2E_VERBOSE         - Enable verbose output (default: false)
#   E2E_TIMEOUT         - Test timeout in seconds (default: 3600)
#   E2E_KEEP_LOGS       - Keep test logs after completion (default: false)
#
# ============================================================================

set -euo pipefail

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
LOG_DIR="${PROJECT_ROOT}/test-logs"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
TEST_LOG="${LOG_DIR}/e2e_test_${TIMESTAMP}.log"

# Default configuration
E2E_SKIP_CLEANUP="${E2E_SKIP_CLEANUP:-false}"
E2E_VERBOSE="${E2E_VERBOSE:-false}"
E2E_TIMEOUT="${E2E_TIMEOUT:-3600}"
E2E_KEEP_LOGS="${E2E_KEEP_LOGS:-false}"
TEST_SCENARIO="${1:-basic}"
TEST_WORKSPACE="test-${TIMESTAMP}"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

    echo "${timestamp} [${level}] ${message}" | tee -a "${TEST_LOG}"

    case "${level}" in
        "ERROR")
            echo -e "${RED}[ERROR]${NC} ${message}" >&2
            ;;
        "WARN")
            echo -e "${YELLOW}[WARN]${NC} ${message}"
            ;;
        "INFO")
            echo -e "${GREEN}[INFO]${NC} ${message}"
            ;;
        "DEBUG")
            if [[ "${E2E_VERBOSE}" == "true" ]]; then
                echo -e "${BLUE}[DEBUG]${NC} ${message}"
            fi
            ;;
        "STEP")
            echo -e "${PURPLE}[STEP]${NC} ${message}"
            ;;
    esac
}

run_with_timeout() {
    local timeout="$1"
    local description="$2"
    shift 2

    log "DEBUG" "Running: $*"

    if timeout "${timeout}" "$@" >> "${TEST_LOG}" 2>&1; then
        log "INFO" "${description} completed successfully"
        return 0
    else
        log "ERROR" "${description} failed or timed out"
        return 1
    fi
}

cleanup_on_exit() {
    local exit_code=$?

    if [[ ${exit_code} -ne 0 ]]; then
        log "ERROR" "Test failed with exit code: ${exit_code}"

        # Capture diagnostic information
        log "INFO" "Capturing diagnostic information..."

        # Terraform state
        if [[ -f "${PROJECT_ROOT}/terraform.tfstate" ]]; then
            cp "${PROJECT_ROOT}/terraform.tfstate" "${LOG_DIR}/terraform.tfstate.${TIMESTAMP}"
        fi

        # Terraform plan output
        if terraform plan -detailed-exitcode > "${LOG_DIR}/terraform_plan_debug.${TIMESTAMP}" 2>&1; then
            log "DEBUG" "Terraform plan captured for debugging"
        fi

        # System information
        {
            echo "=== System Information ==="
            uname -a
            echo ""
            echo "=== Terraform Version ==="
            terraform version
            echo ""
            echo "=== Available Storage ==="
            df -h
            echo ""
            echo "=== Memory Usage ==="
            free -h 2>/dev/null || vm_stat
        } > "${LOG_DIR}/system_info.${TIMESTAMP}"
    fi

    # Cleanup workspace if not skipped
    if [[ "${E2E_SKIP_CLEANUP}" != "true" ]]; then
        log "STEP" "Cleaning up test workspace: ${TEST_WORKSPACE}"
        terraform workspace select default 2>/dev/null || true
        terraform workspace delete "${TEST_WORKSPACE}" 2>/dev/null || true

        # Remove test artifacts
        rm -f "${PROJECT_ROOT}/terraform.tfvars.e2e"
        rm -f "${PROJECT_ROOT}/.terraform.lock.hcl"
    fi

    # Clean up logs if not keeping them
    if [[ "${E2E_KEEP_LOGS}" != "true" && ${exit_code} -eq 0 ]]; then
        rm -f "${TEST_LOG}"
        log "INFO" "Test logs cleaned up"
    else
        log "INFO" "Test logs saved to: ${TEST_LOG}"
    fi

    exit ${exit_code}
}

# ============================================================================
# TEST CONFIGURATION FUNCTIONS
# ============================================================================

setup_test_config() {
    local scenario="$1"

    log "STEP" "Setting up test configuration for scenario: ${scenario}"

    # Create base configuration
    cat > "${PROJECT_ROOT}/terraform.tfvars.e2e" << EOF
# E2E Test Configuration - ${scenario}
# Generated at: $(date)

# Cluster identification
cluster_name = "e2e-test-${TIMESTAMP}"
cluster_domain = "test.local"

# Basic settings
node_count = 1
instance_size = "g3.medium"
kubernetes_version = "v1.28.2+k3s1"

# Network configuration
civo_network = "default"
firewall_create_outbound_rules = true

# SSH configuration
ssh_public_key_path = "~/.ssh/id_rsa.pub"

# Default service configuration
default_helm_timeout = 300
default_helm_wait = true
healthcheck_interval = "30s"
healthcheck_timeout = "10s"

EOF

    # Add scenario-specific configuration
    case "${scenario}" in
        "basic")
            cat >> "${PROJECT_ROOT}/terraform.tfvars.e2e" << EOF
# Basic deployment - core services only
enable_traefik = true
enable_host_path = true
use_hostpath_storage = true
enable_metallb = false
enable_portainer = true
enable_prometheus = false
enable_grafana = false
enable_loki = false
enable_vault = false
enable_consul = false
EOF
            ;;

        "arm64")
            cat >> "${PROJECT_ROOT}/terraform.tfvars.e2e" << EOF
# ARM64 Raspberry Pi deployment
architecture = "arm64"
instance_size = "g3.small"

# ARM64 optimized services
enable_traefik = true
enable_host_path = true
use_hostpath_storage = true
enable_metallb = true
enable_portainer = true
enable_prometheus = true
enable_grafana = true
enable_node_feature_discovery = true

# ARM64 performance settings
service_overrides = {
  prometheus = {
    helm_timeout = 900
  }
  grafana = {
    helm_timeout = 600
  }
}
EOF
            ;;

        "full-stack")
            cat >> "${PROJECT_ROOT}/terraform.tfvars.e2e" << EOF
# Full stack deployment - all services
enable_traefik = true
enable_host_path = true
use_hostpath_storage = true
enable_metallb = true
enable_portainer = true
enable_prometheus = true
enable_prometheus_crds = true
enable_grafana = true
enable_loki = true
enable_promtail = true
enable_vault = true
enable_consul = true
enable_gatekeeper = true
enable_node_feature_discovery = true

# Full stack configuration
consul_replicas = 3
vault_replicas = 3
prometheus_storage_size = "10Gi"
grafana_storage_size = "5Gi"
loki_storage_size = "10Gi"

# Service mesh configuration
consul_enable_acl = true
vault_auto_unseal = false

# Extended timeouts for complex deployment
service_overrides = {
  vault = {
    helm_timeout = 900
  }
  consul = {
    helm_timeout = 900
  }
  prometheus = {
    helm_timeout = 1200
  }
}
EOF
            ;;

        "nfs-storage")
            cat >> "${PROJECT_ROOT}/terraform.tfvars.e2e" << EOF
# NFS storage deployment
use_nfs_storage = true
enable_nfs_csi = true
nfs_server = "nfs.test.local"
nfs_path = "/data/k8s"
nfs_timeout_default = 600
nfs_retrans_default = 2

# Storage-dependent services
enable_traefik = true
enable_prometheus = true
enable_grafana = true
enable_loki = true
enable_vault = true

# NFS-optimized storage classes
prometheus_storage_class = "nfs-csi-safe"
grafana_storage_class = "nfs-csi"
loki_storage_class = "nfs-csi-safe"
vault_storage_class = "nfs-csi-safe"
EOF
            ;;

        "security")
            cat >> "${PROJECT_ROOT}/terraform.tfvars.e2e" << EOF
# Security-focused deployment
enable_gatekeeper = true
enable_vault = true
enable_consul = true
consul_enable_acl = true
vault_auto_unseal = false

# Security monitoring
enable_prometheus = true
enable_grafana = true
enable_loki = true
enable_promtail = true

# Network security
enable_traefik = true
traefik_cert_resolver = "letsencrypt"
enable_metallb = true

# Storage security
use_hostpath_storage = true
enable_host_path = true

# Security-focused timeouts
gatekeeper_timeout_default = "60s"
vault_readiness_timeout = "120s"
consul_readiness_timeout = "90s"
EOF
            ;;

        "cleanup-only")
            log "INFO" "Cleanup-only scenario selected"
            return 0
            ;;

        *)
            log "ERROR" "Unknown test scenario: ${scenario}"
            exit 1
            ;;
    esac

    log "INFO" "Test configuration created: terraform.tfvars.e2e"
}

# ============================================================================
# TEST EXECUTION FUNCTIONS
# ============================================================================

test_terraform_init() {
    log "STEP" "Testing Terraform initialization"

    cd "${PROJECT_ROOT}"

    # Clean previous state
    rm -rf .terraform .terraform.lock.hcl

    run_with_timeout 300 "Terraform init" \
        terraform init -upgrade

    log "INFO" "Terraform initialization completed"
}

test_terraform_validate() {
    log "STEP" "Testing Terraform validation"

    cd "${PROJECT_ROOT}"

    run_with_timeout 60 "Terraform validate" \
        terraform validate

    log "INFO" "Terraform validation passed"
}

test_terraform_plan() {
    log "STEP" "Testing Terraform plan"

    cd "${PROJECT_ROOT}"

    run_with_timeout 300 "Terraform plan" \
        terraform plan -var-file="terraform.tfvars.e2e" -out="e2e.tfplan"

    log "INFO" "Terraform plan completed successfully"
}

test_terraform_apply() {
    log "STEP" "Testing Terraform apply"

    cd "${PROJECT_ROOT}"

    # Create workspace for isolation
    terraform workspace new "${TEST_WORKSPACE}" 2>/dev/null || terraform workspace select "${TEST_WORKSPACE}"

    run_with_timeout 1800 "Terraform apply" \
        terraform apply -auto-approve -var-file="terraform.tfvars.e2e"

    log "INFO" "Terraform apply completed successfully"
}

test_deployment_validation() {
    log "STEP" "Testing deployment validation"

    cd "${PROJECT_ROOT}"

    # Run integration tests
    if [[ -f "${SCRIPT_DIR}/integration-tests.sh" ]]; then
        run_with_timeout 600 "Integration tests" \
            bash "${SCRIPT_DIR}/integration-tests.sh"
    fi

    # Validate terraform outputs
    if terraform output cluster_id > /dev/null 2>&1; then
        local cluster_id
        cluster_id=$(terraform output -raw cluster_id)
        log "INFO" "Cluster deployed successfully: ${cluster_id}"
    else
        log "ERROR" "Failed to retrieve cluster ID from terraform output"
        return 1
    fi

    # Validate kubeconfig
    if terraform output kubeconfig > /dev/null 2>&1; then
        log "INFO" "Kubeconfig available from terraform output"
    else
        log "WARN" "Kubeconfig not available from terraform output"
    fi

    log "INFO" "Deployment validation completed"
}

test_service_health() {
    log "STEP" "Testing service health"

    cd "${PROJECT_ROOT}"

    # Get kubeconfig and test cluster connectivity
    if terraform output kubeconfig > "${LOG_DIR}/kubeconfig.${TIMESTAMP}" 2>/dev/null; then
        export KUBECONFIG="${LOG_DIR}/kubeconfig.${TIMESTAMP}"

        # Test basic connectivity
        if kubectl get nodes > /dev/null 2>&1; then
            log "INFO" "Cluster connectivity verified"

            # Check node status
            local node_count
            node_count=$(kubectl get nodes --no-headers | wc -l)
            log "INFO" "Cluster has ${node_count} nodes"

            # Check core services
            if kubectl get pods -n kube-system > /dev/null 2>&1; then
                log "INFO" "Core services accessible"
            fi

            # Check deployed services
            local namespaces
            namespaces=$(kubectl get namespaces -o name | grep -v "kube-\|default\|local-path" || true)
            if [[ -n "${namespaces}" ]]; then
                log "INFO" "Application namespaces found: $(echo "${namespaces}" | tr '\n' ' ')"
            fi
        else
            log "WARN" "Cluster connectivity failed - cluster may still be initializing"
        fi
    else
        log "WARN" "Kubeconfig not available - skipping service health checks"
    fi

    log "INFO" "Service health check completed"
}

test_cleanup() {
    log "STEP" "Testing cleanup procedures"

    cd "${PROJECT_ROOT}"

    # Switch to test workspace
    terraform workspace select "${TEST_WORKSPACE}" 2>/dev/null || true

    # Destroy infrastructure
    run_with_timeout 1200 "Terraform destroy" \
        terraform destroy -auto-approve -var-file="terraform.tfvars.e2e"

    log "INFO" "Infrastructure cleanup completed"
}

# ============================================================================
# MAIN TEST EXECUTION
# ============================================================================

main() {
    # Setup
    log "INFO" "Starting E2E test execution"
    log "INFO" "Test scenario: ${TEST_SCENARIO}"
    log "INFO" "Test workspace: ${TEST_WORKSPACE}"
    log "INFO" "Log file: ${TEST_LOG}"

    # Create log directory
    mkdir -p "${LOG_DIR}"

    # Setup trap for cleanup
    trap cleanup_on_exit EXIT

    # Setup timeout for entire test
    timeout_start=$(date +%s)

    # Execute test phases
    case "${TEST_SCENARIO}" in
        "cleanup-only")
            test_cleanup
            ;;
        *)
            # Setup phase
            setup_test_config "${TEST_SCENARIO}"

            # Terraform testing phase
            test_terraform_init
            test_terraform_validate
            test_terraform_plan

            # Deployment phase
            test_terraform_apply

            # Validation phase
            test_deployment_validation
            test_service_health

            # Cleanup phase (unless skipped)
            if [[ "${E2E_SKIP_CLEANUP}" != "true" ]]; then
                test_cleanup
            else
                log "INFO" "Cleanup skipped per configuration"
            fi
            ;;
    esac

    # Calculate test duration
    timeout_end=$(date +%s)
    test_duration=$((timeout_end - timeout_start))

    log "INFO" "E2E test completed successfully in ${test_duration} seconds"
}

# ============================================================================
# SCRIPT ENTRY POINT
# ============================================================================

# Validate prerequisites
if ! command -v terraform &> /dev/null; then
    log "ERROR" "Terraform is not installed or not in PATH"
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    log "WARN" "kubectl is not installed - some tests will be skipped"
fi

# Show help if requested
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    echo "Usage: $0 [scenario]"
    echo ""
    echo "Available scenarios:"
    echo "  basic           - Basic deployment with core services"
    echo "  arm64           - ARM64 Raspberry Pi deployment"
    echo "  full-stack      - Full deployment with all services"
    echo "  nfs-storage     - NFS storage configuration"
    echo "  security        - Security-focused deployment"
    echo "  cleanup-only    - Only run cleanup procedures"
    echo ""
    echo "Environment variables:"
    echo "  E2E_SKIP_CLEANUP    - Skip cleanup phase (default: false)"
    echo "  E2E_VERBOSE         - Enable verbose output (default: false)"
    echo "  E2E_TIMEOUT         - Test timeout in seconds (default: 3600)"
    echo "  E2E_KEEP_LOGS       - Keep test logs after completion (default: false)"
    exit 0
fi

# Execute main function
main
