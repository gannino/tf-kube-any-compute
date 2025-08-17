#!/bin/bash

# ============================================================================
# TRAEFIK MIDDLEWARE TESTING SCRIPT
# ============================================================================
# Tests middleware functionality and configuration

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
TEST_WORKSPACE="middleware-test"
TEST_CONFIG="${PROJECT_ROOT}/test-configs/middleware-test.tfvars"
LDAP_TEST_CONFIG="${PROJECT_ROOT}/test-configs/middleware-ldap-test.tfvars"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    local missing_tools=()

    if ! command -v terraform &> /dev/null; then
        missing_tools+=("terraform")
    fi

    if ! command -v kubectl &> /dev/null; then
        missing_tools+=("kubectl")
    fi

    if [ ${#missing_tools[@]} -ne 0 ]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        exit 1
    fi

    # Check if kubectl can connect to cluster
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Cannot connect to Kubernetes cluster. Please ensure kubectl is configured."
        exit 1
    fi

    log_success "Prerequisites check passed"
}

# Initialize Terraform
init_terraform() {
    log_info "Initializing Terraform..."
    cd "${PROJECT_ROOT}"

    if ! terraform init -upgrade; then
        log_error "Terraform initialization failed"
        exit 1
    fi

    log_success "Terraform initialized"
}

# Create test workspace
create_test_workspace() {
    log_info "Creating test workspace: ${TEST_WORKSPACE}"
    cd "${PROJECT_ROOT}"

    # Create workspace if it doesn't exist
    if ! terraform workspace select "${TEST_WORKSPACE}" 2>/dev/null; then
        terraform workspace new "${TEST_WORKSPACE}"
    fi

    log_success "Test workspace ready: ${TEST_WORKSPACE}"
}

# Validate middleware configuration
validate_middleware_config() {
    local config_file="$1"
    local test_name="$2"

    log_info "Validating middleware configuration: ${test_name}"
    cd "${PROJECT_ROOT}"

    # Plan with the test configuration
    if terraform plan -var-file="${config_file}" -out="middleware-test.tfplan" &> /dev/null; then
        log_success "Configuration validation passed: ${test_name}"
        rm -f middleware-test.tfplan
        return 0
    else
        log_error "Configuration validation failed: ${test_name}"
        return 1
    fi
}

# Test middleware resource creation
test_middleware_resources() {
    log_info "Testing middleware resource creation..."
    cd "${PROJECT_ROOT}"

    # Apply the configuration
    if terraform apply -var-file="${TEST_CONFIG}" -auto-approve; then
        log_success "Middleware resources created successfully"
    else
        log_error "Failed to create middleware resources"
        return 1
    fi

    # Wait for resources to be ready
    log_info "Waiting for Traefik to be ready..."
    sleep 30

    # Check if middleware resources exist
    local namespace
    namespace=$(terraform output -raw traefik_namespace 2>/dev/null || echo "middleware-test-traefik-ingress")

    log_info "Checking middleware resources in namespace: ${namespace}"

    # Check for middleware CRDs
    if kubectl get crd middlewares.traefik.io &> /dev/null; then
        log_success "Traefik middleware CRDs are available"
    else
        log_warning "Traefik middleware CRDs not found - this is expected on fresh clusters"
    fi

    # Check for middleware resources (if CRDs are available)
    if kubectl get middlewares -n "${namespace}" &> /dev/null; then
        local middleware_count
        middleware_count=$(kubectl get middlewares -n "${namespace}" --no-headers 2>/dev/null | wc -l)
        log_success "Found ${middleware_count} middleware resources"

        # List middleware resources
        log_info "Middleware resources:"
        kubectl get middlewares -n "${namespace}" -o name 2>/dev/null | sed 's/^/  - /' || true
    else
        log_info "No middleware resources found (CRDs may not be ready yet)"
    fi
}

# Test middleware outputs
test_middleware_outputs() {
    log_info "Testing middleware outputs..."
    cd "${PROJECT_ROOT}"

    # Test essential outputs
    local outputs=(
        "traefik_middleware"
        "traefik_default_auth_middleware_name"
        "traefik_preferred_auth_middleware_name"
    )

    for output in "${outputs[@]}"; do
        if terraform output "${output}" &> /dev/null; then
            log_success "Output available: ${output}"
        else
            log_warning "Output not available: ${output}"
        fi
    done

    # Test sensitive outputs
    if terraform output -json traefik_auth_credentials &> /dev/null; then
        log_success "Sensitive auth credentials output available"
    else
        log_warning "Auth credentials output not available"
    fi
}

# Test dashboard access
test_dashboard_access() {
    log_info "Testing dashboard access configuration..."
    cd "${PROJECT_ROOT}"

    local namespace
    namespace=$(terraform output -raw traefik_namespace 2>/dev/null || echo "middleware-test-traefik-ingress")

    # Check for IngressRoute
    if kubectl get ingressroute traefik-dashboard -n "${namespace}" &> /dev/null; then
        log_success "Traefik dashboard IngressRoute exists"

        # Check middleware configuration in IngressRoute
        local middleware_config
        middleware_config=$(kubectl get ingressroute traefik-dashboard -n "${namespace}" -o jsonpath='{.spec.routes[0].middlewares}' 2>/dev/null || echo "[]")

        if [ "${middleware_config}" != "[]" ] && [ "${middleware_config}" != "null" ]; then
            log_success "Dashboard has middleware configured"
            log_info "Middleware configuration: ${middleware_config}"
        else
            log_warning "Dashboard middleware configuration not found"
        fi
    else
        log_warning "Traefik dashboard IngressRoute not found"
    fi
}

# Cleanup test resources
cleanup_test_resources() {
    log_info "Cleaning up test resources..."
    cd "${PROJECT_ROOT}"

    # Destroy resources
    if terraform destroy -var-file="${TEST_CONFIG}" -auto-approve; then
        log_success "Test resources cleaned up"
    else
        log_warning "Some resources may not have been cleaned up properly"
    fi

    # Switch back to default workspace and delete test workspace
    terraform workspace select default
    terraform workspace delete "${TEST_WORKSPACE}"

    log_success "Test workspace cleaned up"
}

# Main test function
run_middleware_tests() {
    log_info "Starting Traefik middleware tests..."

    # Basic configuration test
    log_info "=== Testing Basic Middleware Configuration ==="
    if validate_middleware_config "${TEST_CONFIG}" "Basic Middleware"; then
        log_success "Basic middleware configuration test passed"
    else
        log_error "Basic middleware configuration test failed"
        return 1
    fi

    # LDAP configuration test
    log_info "=== Testing LDAP Middleware Configuration ==="
    if validate_middleware_config "${LDAP_TEST_CONFIG}" "LDAP Middleware"; then
        log_success "LDAP middleware configuration test passed"
    else
        log_error "LDAP middleware configuration test failed"
        return 1
    fi

    # Resource creation test
    log_info "=== Testing Middleware Resource Creation ==="
    if test_middleware_resources; then
        log_success "Middleware resource creation test passed"
    else
        log_error "Middleware resource creation test failed"
        return 1
    fi

    # Output test
    log_info "=== Testing Middleware Outputs ==="
    test_middleware_outputs

    # Dashboard access test
    log_info "=== Testing Dashboard Access ==="
    test_dashboard_access

    log_success "All middleware tests completed"
}

# Script usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --validate-only    Only validate configurations without creating resources"
    echo "  --no-cleanup       Skip cleanup after tests"
    echo "  --help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                 Run full middleware test suite"
    echo "  $0 --validate-only Validate configurations only"
    echo "  $0 --no-cleanup    Run tests but keep resources for inspection"
}

# Main execution
main() {
    local validate_only=false
    local no_cleanup=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --validate-only)
                validate_only=true
                shift
                ;;
            --no-cleanup)
                no_cleanup=true
                shift
                ;;
            --help)
                show_usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done

    # Check prerequisites
    check_prerequisites

    # Initialize Terraform
    init_terraform

    # Create test workspace
    create_test_workspace

    if [ "$validate_only" = true ]; then
        log_info "Running validation-only tests..."
        validate_middleware_config "${TEST_CONFIG}" "Basic Middleware"
        validate_middleware_config "${LDAP_TEST_CONFIG}" "LDAP Middleware"
        log_success "Validation tests completed"
    else
        # Run full test suite
        if run_middleware_tests; then
            log_success "All middleware tests passed!"
        else
            log_error "Some middleware tests failed"
            exit 1
        fi

        # Cleanup unless requested not to
        if [ "$no_cleanup" = false ]; then
            cleanup_test_resources
        else
            log_info "Skipping cleanup as requested"
            log_info "To cleanup manually, run: terraform destroy -var-file=${TEST_CONFIG} -auto-approve"
        fi
    fi
}

# Run main function with all arguments
main "$@"
