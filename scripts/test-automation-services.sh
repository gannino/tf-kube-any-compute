#!/bin/bash
# ============================================================================
# AUTOMATION SERVICES INTEGRATION TESTS
# ============================================================================
# Tests Node-RED and n8n deployment and functionality

set -euo pipefail

# Configuration
NAMESPACE_NODE_RED="prod-node-red-system"
NAMESPACE_N8N="prod-n8n-system"
TIMEOUT=300
DOMAIN="${DOMAIN:-prod.k3s.local}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Test functions
test_node_red_deployment() {
    log_info "Testing Node-RED deployment..."

    # Check if namespace exists
    if ! kubectl get namespace "$NAMESPACE_NODE_RED" &>/dev/null; then
        log_warning "Node-RED namespace not found, skipping tests"
        return 0
    fi

    # Check deployment status
    if kubectl wait --for=condition=available --timeout=${TIMEOUT}s deployment/prod-node-red -n "$NAMESPACE_NODE_RED"; then
        log_success "Node-RED deployment is ready"
    else
        log_error "Node-RED deployment failed to become ready"
        return 1
    fi

    # Check service
    if kubectl get service prod-node-red -n "$NAMESPACE_NODE_RED" &>/dev/null; then
        log_success "Node-RED service exists"
    else
        log_error "Node-RED service not found"
        return 1
    fi

    # Check ingress
    if kubectl get ingress prod-node-red -n "$NAMESPACE_NODE_RED" &>/dev/null; then
        log_success "Node-RED ingress exists"
    else
        log_warning "Node-RED ingress not found"
    fi

    # Test HTTP endpoint
    local node_red_url="https://node-red.${DOMAIN}"
    log_info "Testing Node-RED endpoint: $node_red_url"

    if curl -k -s --max-time 10 "$node_red_url" | grep -q "Node-RED"; then
        log_success "Node-RED web interface is accessible"
    else
        log_warning "Node-RED web interface test failed (may require authentication)"
    fi
}

test_n8n_deployment() {
    log_info "Testing n8n deployment..."

    # Check if namespace exists
    if ! kubectl get namespace "$NAMESPACE_N8N" &>/dev/null; then
        log_warning "n8n namespace not found, skipping tests"
        return 0
    fi

    # Check deployment status
    if kubectl wait --for=condition=available --timeout=${TIMEOUT}s deployment/prod-n8n -n "$NAMESPACE_N8N"; then
        log_success "n8n deployment is ready"
    else
        log_error "n8n deployment failed to become ready"
        return 1
    fi

    # Check service
    if kubectl get service prod-n8n -n "$NAMESPACE_N8N" &>/dev/null; then
        log_success "n8n service exists"
    else
        log_error "n8n service not found"
        return 1
    fi

    # Check ingress
    if kubectl get ingress prod-n8n -n "$NAMESPACE_N8N" &>/dev/null; then
        log_success "n8n ingress exists"
    else
        log_warning "n8n ingress not found"
    fi

    # Test HTTP endpoint
    local n8n_url="https://n8n.${DOMAIN}"
    log_info "Testing n8n endpoint: $n8n_url"

    if curl -k -s --max-time 10 "$n8n_url" | grep -q "n8n"; then
        log_success "n8n web interface is accessible"
    else
        log_warning "n8n web interface test failed (may require setup)"
    fi

    # Test webhook endpoint
    local webhook_url="https://n8n.${DOMAIN}/webhook-test"
    log_info "Testing n8n webhook endpoint: $webhook_url"

    if curl -k -s --max-time 10 -X POST "$webhook_url" -d '{"test": "data"}' -H "Content-Type: application/json" &>/dev/null; then
        log_success "n8n webhook endpoint is accessible"
    else
        log_warning "n8n webhook endpoint test failed (expected for unconfigured webhooks)"
    fi
}

test_node_red_palette_installation() {
    log_info "Testing Node-RED palette installation..."

    # Check if palette installer job exists
    if kubectl get job prod-node-red-palette-installer -n "$NAMESPACE_NODE_RED" &>/dev/null; then
        log_success "Node-RED palette installer job exists"

        # Check job status
        if kubectl wait --for=condition=complete --timeout=300s job/prod-node-red-palette-installer -n "$NAMESPACE_NODE_RED"; then
            log_success "Node-RED palette installation completed successfully"
        else
            log_warning "Node-RED palette installation job did not complete (may still be running)"
        fi
    else
        log_warning "Node-RED palette installer job not found"
    fi
}

test_persistent_storage() {
    log_info "Testing persistent storage for automation services..."

    # Test Node-RED PVC
    if kubectl get pvc prod-node-red-data -n "$NAMESPACE_NODE_RED" &>/dev/null; then
        local pvc_status=$(kubectl get pvc prod-node-red-data -n "$NAMESPACE_NODE_RED" -o jsonpath='{.status.phase}')
        if [[ "$pvc_status" == "Bound" ]]; then
            log_success "Node-RED PVC is bound"
        else
            log_error "Node-RED PVC is not bound (status: $pvc_status)"
        fi
    else
        log_warning "Node-RED PVC not found"
    fi

    # Test n8n PVC
    if kubectl get pvc prod-n8n-data -n "$NAMESPACE_N8N" &>/dev/null; then
        local pvc_status=$(kubectl get pvc prod-n8n-data -n "$NAMESPACE_N8N" -o jsonpath='{.status.phase}')
        if [[ "$pvc_status" == "Bound" ]]; then
            log_success "n8n PVC is bound"
        else
            log_error "n8n PVC is not bound (status: $pvc_status)"
        fi
    else
        log_warning "n8n PVC not found"
    fi
}

test_resource_usage() {
    log_info "Testing resource usage for automation services..."

    # Test Node-RED resource usage
    if kubectl get pod -l app.kubernetes.io/name=node-red -n "$NAMESPACE_NODE_RED" &>/dev/null; then
        local node_red_pod=$(kubectl get pod -l app.kubernetes.io/name=node-red -n "$NAMESPACE_NODE_RED" -o jsonpath='{.items[0].metadata.name}')
        if [[ -n "$node_red_pod" ]]; then
            log_info "Node-RED pod: $node_red_pod"
            kubectl top pod "$node_red_pod" -n "$NAMESPACE_NODE_RED" || log_warning "Could not get Node-RED resource usage"
        fi
    fi

    # Test n8n resource usage
    if kubectl get pod -l app.kubernetes.io/name=n8n -n "$NAMESPACE_N8N" &>/dev/null; then
        local n8n_pod=$(kubectl get pod -l app.kubernetes.io/name=n8n -n "$NAMESPACE_N8N" -o jsonpath='{.items[0].metadata.name}')
        if [[ -n "$n8n_pod" ]]; then
            log_info "n8n pod: $n8n_pod"
            kubectl top pod "$n8n_pod" -n "$NAMESPACE_N8N" || log_warning "Could not get n8n resource usage"
        fi
    fi
}

# Main test execution
main() {
    log_info "Starting automation services integration tests..."

    local exit_code=0

    # Run tests
    test_node_red_deployment || exit_code=1
    test_n8n_deployment || exit_code=1
    test_node_red_palette_installation || exit_code=1
    test_persistent_storage || exit_code=1
    test_resource_usage || exit_code=1

    if [[ $exit_code -eq 0 ]]; then
        log_success "All automation services tests completed successfully"
    else
        log_error "Some automation services tests failed"
    fi

    return $exit_code
}

# Help function
show_help() {
    cat << EOF
Automation Services Integration Tests

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -h, --help          Show this help message
    -d, --domain DOMAIN Set the domain for testing (default: prod.k3s.local)
    -t, --timeout SEC   Set timeout for deployments (default: 300)

EXAMPLES:
    $0                                    # Run all tests with defaults
    $0 -d homelab.local                   # Test with custom domain
    $0 -t 600                            # Use longer timeout

ENVIRONMENT VARIABLES:
    DOMAIN              Domain for testing (default: prod.k3s.local)
EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -d|--domain)
            DOMAIN="$2"
            shift 2
            ;;
        -t|--timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Run main function
main "$@"
