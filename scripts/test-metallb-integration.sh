#!/bin/bash
# ============================================================================
# MetalLB Integration Tests
# ============================================================================
# Tests MetalLB functionality in live cluster
# Usage: ./scripts/test-metallb-integration.sh [--verbose]

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

VERBOSE=false
if [[ "${1:-}" == "--verbose" ]]; then
    VERBOSE=true
fi

log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

verbose() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${BLUE}[DEBUG]${NC} $1"
    fi
}

# Test MetalLB deployment
test_metallb_deployment() {
    log "Testing MetalLB deployment..."

    # Check if MetalLB namespace exists
    if kubectl get namespace | grep -q metallb; then
        success "MetalLB namespace found"
        METALLB_NS=$(kubectl get namespace | grep metallb | awk '{print $1}')
        verbose "MetalLB namespace: $METALLB_NS"
    else
        error "MetalLB namespace not found"
        return 1
    fi

    # Check MetalLB pods
    local controller_pods=$(kubectl get pods -n "$METALLB_NS" -l app=metallb,component=controller --no-headers 2>/dev/null | wc -l)
    local speaker_pods=$(kubectl get pods -n "$METALLB_NS" -l app=metallb,component=speaker --no-headers 2>/dev/null | wc -l)

    if [[ $controller_pods -gt 0 ]]; then
        success "MetalLB controller pods: $controller_pods"
    else
        error "No MetalLB controller pods found"
        return 1
    fi

    if [[ $speaker_pods -gt 0 ]]; then
        success "MetalLB speaker pods: $speaker_pods"
    else
        error "No MetalLB speaker pods found"
        return 1
    fi

    # Check pod status
    local failed_pods=$(kubectl get pods -n "$METALLB_NS" --no-headers | grep -v Running | grep -v Completed | wc -l)
    if [[ $failed_pods -eq 0 ]]; then
        success "All MetalLB pods are running"
    else
        warning "$failed_pods MetalLB pods are not running"
        if [[ "$VERBOSE" == "true" ]]; then
            kubectl get pods -n "$METALLB_NS"
        fi
    fi
}

# Test MetalLB configuration
test_metallb_config() {
    log "Testing MetalLB configuration..."

    # Check IPAddressPool
    if kubectl get ipaddresspool -A --no-headers 2>/dev/null | wc -l | grep -q "^[1-9]"; then
        success "IPAddressPool configured"
        if [[ "$VERBOSE" == "true" ]]; then
            kubectl get ipaddresspool -A
        fi
    else
        error "No IPAddressPool found"
        return 1
    fi

    # Check L2Advertisement or BGPAdvertisement
    local l2_adverts=$(kubectl get l2advertisement -A --no-headers 2>/dev/null | wc -l)
    local bgp_adverts=$(kubectl get bgpadvertisement -A --no-headers 2>/dev/null | wc -l)

    if [[ $l2_adverts -gt 0 ]]; then
        success "L2Advertisement configured (L2 mode)"
        verbose "L2 advertisements: $l2_adverts"
    elif [[ $bgp_adverts -gt 0 ]]; then
        success "BGPAdvertisement configured (BGP mode)"
        verbose "BGP advertisements: $bgp_adverts"

        # Check BGP peers if in BGP mode
        local bgp_peers=$(kubectl get bgppeer -A --no-headers 2>/dev/null | wc -l)
        if [[ $bgp_peers -gt 0 ]]; then
            success "BGP peers configured: $bgp_peers"
        else
            warning "No BGP peers found (may be intentional)"
        fi
    else
        error "No L2Advertisement or BGPAdvertisement found"
        return 1
    fi
}

# Test MetalLB LoadBalancer service
test_metallb_loadbalancer() {
    log "Testing MetalLB LoadBalancer functionality..."

    # Look for LoadBalancer services
    local lb_services=$(kubectl get svc --all-namespaces --no-headers | grep LoadBalancer | wc -l)

    if [[ $lb_services -gt 0 ]]; then
        success "LoadBalancer services found: $lb_services"

        # Check if services have external IPs
        local services_with_ip=$(kubectl get svc --all-namespaces --no-headers | grep LoadBalancer | grep -v '<pending>' | wc -l)
        local pending_services=$(kubectl get svc --all-namespaces --no-headers | grep LoadBalancer | grep '<pending>' | wc -l)

        if [[ $services_with_ip -gt 0 ]]; then
            success "Services with external IP: $services_with_ip"
        fi

        if [[ $pending_services -gt 0 ]]; then
            warning "Services pending IP assignment: $pending_services"
        fi

        if [[ "$VERBOSE" == "true" ]]; then
            echo "LoadBalancer services:"
            kubectl get svc --all-namespaces | grep LoadBalancer
        fi
    else
        warning "No LoadBalancer services found (may be intentional)"
    fi
}

# Test MetalLB metrics (if enabled)
test_metallb_metrics() {
    log "Testing MetalLB metrics..."

    # Check if metrics are exposed
    local metrics_endpoints=$(kubectl get endpoints -A --no-headers | grep -i metallb | grep -i metrics | wc -l)

    if [[ $metrics_endpoints -gt 0 ]]; then
        success "MetalLB metrics endpoints found: $metrics_endpoints"
    else
        warning "No MetalLB metrics endpoints found (may be disabled)"
        return 0
    fi

    # Check ServiceMonitor if Prometheus Operator is available
    if kubectl get crd servicemonitors.monitoring.coreos.com >/dev/null 2>&1; then
        local service_monitors=$(kubectl get servicemonitor -A --no-headers | grep -i metallb | wc -l)
        if [[ $service_monitors -gt 0 ]]; then
            success "MetalLB ServiceMonitor found: $service_monitors"
        else
            warning "No MetalLB ServiceMonitor found (may be disabled)"
        fi
    else
        verbose "Prometheus Operator not available, skipping ServiceMonitor check"
    fi
}

# Main test execution
main() {
    echo "🧪 MetalLB Integration Tests"
    echo "============================"
    echo

    local tests_passed=0
    local tests_failed=0

    # Run tests
    if test_metallb_deployment; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi
    echo

    if test_metallb_config; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi
    echo

    if test_metallb_loadbalancer; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi
    echo

    if test_metallb_metrics; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi
    echo

    # Summary
    echo "📊 Test Summary"
    echo "==============="
    success "Tests passed: $tests_passed"
    if [[ $tests_failed -gt 0 ]]; then
        error "Tests failed: $tests_failed"
        exit 1
    else
        success "All MetalLB integration tests passed! 🎉"
    fi
}

# Check prerequisites
if ! command -v kubectl >/dev/null 2>&1; then
    error "kubectl is required but not installed"
    exit 1
fi

if ! kubectl cluster-info >/dev/null 2>&1; then
    error "Cannot connect to Kubernetes cluster"
    exit 1
fi

# Run tests
main "$@"
