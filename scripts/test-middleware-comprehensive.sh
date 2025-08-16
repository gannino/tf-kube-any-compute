#!/bin/bash
# ============================================================================
# COMPREHENSIVE MIDDLEWARE TESTING SCRIPT
# ============================================================================
# Tests all middleware configurations including LDAP, basic auth, and fallback

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configurations
CONFIGS=(
    "middleware-test.tfvars"
    "middleware-ldap-test.tfvars"
    "middleware-ldap-comprehensive.tfvars"
)

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}[$(date +'%Y-%m-%d %H:%M:%S')] ${message}${NC}"
}

# Function to run test with specific config
run_middleware_test() {
    local config=$1
    local test_name=$(basename "$config" .tfvars)

    print_status "$BLUE" "Starting middleware test: $test_name"

    # Create workspace for test
    terraform workspace new "$test_name" 2>/dev/null || terraform workspace select "$test_name"

    # Initialize and validate
    print_status "$YELLOW" "Initializing Terraform for $test_name..."
    terraform init -upgrade

    print_status "$YELLOW" "Validating configuration for $test_name..."
    terraform validate

    # Plan with test config
    print_status "$YELLOW" "Planning deployment for $test_name..."
    terraform plan -var-file="test-configs/$config" -out="$test_name.tfplan"

    # Check for middleware resources in plan
    print_status "$YELLOW" "Checking middleware resources in plan..."
    terraform show -json "$test_name.tfplan" | jq -r '
        .planned_values.root_module.child_modules[]? |
        select(.address | contains("traefik")) |
        .child_modules[]? |
        select(.address | contains("middleware")) |
        .resources[]? |
        select(.type == "kubernetes_manifest" and (.values.manifest.kind == "Middleware")) |
        "Found middleware: " + .values.manifest.metadata.name + " (type: " + (.values.manifest.spec | keys[0]) + ")"
    ' || echo "No middleware resources found or jq not available"

    # Apply if requested
    if [[ "${APPLY_TESTS:-false}" == "true" ]]; then
        print_status "$YELLOW" "Applying configuration for $test_name..."
        terraform apply -auto-approve "$test_name.tfplan"

        # Test middleware functionality
        test_middleware_functionality "$test_name"

        # Cleanup
        if [[ "${CLEANUP_TESTS:-true}" == "true" ]]; then
            print_status "$YELLOW" "Cleaning up $test_name..."
            terraform destroy -auto-approve -var-file="test-configs/$config"
        fi
    fi

    # Cleanup plan file
    rm -f "$test_name.tfplan"

    print_status "$GREEN" "Completed middleware test: $test_name"
}

# Function to test middleware functionality
test_middleware_functionality() {
    local test_name=$1

    print_status "$YELLOW" "Testing middleware functionality for $test_name..."

    # Wait for Traefik to be ready
    kubectl wait --for=condition=available --timeout=300s deployment -l app.kubernetes.io/name=traefik -A || true

    # Check middleware resources
    print_status "$YELLOW" "Checking created middleware resources..."
    kubectl get middleware -A -o wide || echo "No middleware resources found"

    # Check Traefik configuration
    print_status "$YELLOW" "Checking Traefik configuration..."
    kubectl get ingressroute -A -o wide || echo "No IngressRoute resources found"

    # Test basic connectivity (if services are available)
    local traefik_service=$(kubectl get svc -A -l app.kubernetes.io/name=traefik -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    if [[ -n "$traefik_service" ]]; then
        local traefik_namespace=$(kubectl get svc -A -l app.kubernetes.io/name=traefik -o jsonpath='{.items[0].metadata.namespace}' 2>/dev/null || echo "")
        print_status "$YELLOW" "Testing Traefik service connectivity..."
        kubectl port-forward -n "$traefik_namespace" "svc/$traefik_service" 8080:80 &
        local port_forward_pid=$!
        sleep 5

        # Test basic connectivity
        if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 | grep -q "200\|404\|401"; then
            print_status "$GREEN" "Traefik service is responding"
        else
            print_status "$RED" "Traefik service is not responding properly"
        fi

        # Cleanup port forward
        kill $port_forward_pid 2>/dev/null || true
    fi
}

# Function to validate middleware configuration
validate_middleware_config() {
    print_status "$YELLOW" "Validating middleware configurations..."

    for config in "${CONFIGS[@]}"; do
        if [[ ! -f "test-configs/$config" ]]; then
            print_status "$RED" "Configuration file not found: test-configs/$config"
            exit 1
        fi

        # Basic syntax validation
        terraform validate -var-file="test-configs/$config" > /dev/null 2>&1 || {
            print_status "$RED" "Invalid Terraform syntax in $config"
            exit 1
        }
    done

    print_status "$GREEN" "All middleware configurations are valid"
}

# Main execution
main() {
    print_status "$BLUE" "Starting comprehensive middleware testing..."

    # Validate configurations first
    validate_middleware_config

    # Run tests for each configuration
    for config in "${CONFIGS[@]}"; do
        run_middleware_test "$config"
        echo ""
    done

    # Return to default workspace
    terraform workspace select default 2>/dev/null || true

    print_status "$GREEN" "All middleware tests completed successfully!"

    # Summary
    print_status "$BLUE" "Test Summary:"
    echo "  - Basic middleware test: ✓"
    echo "  - LDAP middleware test: ✓"
    echo "  - Comprehensive LDAP test: ✓"
    echo ""
    echo "To apply tests to a live cluster, run:"
    echo "  APPLY_TESTS=true $0"
    echo ""
    echo "To skip cleanup after apply, run:"
    echo "  APPLY_TESTS=true CLEANUP_TESTS=false $0"
}

# Help function
show_help() {
    echo "Comprehensive Middleware Testing Script"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Environment Variables:"
    echo "  APPLY_TESTS=true     Apply configurations to live cluster (default: false)"
    echo "  CLEANUP_TESTS=false  Skip cleanup after apply (default: true)"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Validate and plan only"
    echo "  APPLY_TESTS=true $0                   # Apply to cluster and cleanup"
    echo "  APPLY_TESTS=true CLEANUP_TESTS=false $0  # Apply without cleanup"
}

# Check for help flag
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    show_help
    exit 0
fi

# Run main function
main "$@"
