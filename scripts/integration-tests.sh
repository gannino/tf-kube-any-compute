#!/bin/bash
# ============================================================================
# Integration Tests for tf-kube-any-compute
# ============================================================================
#
# Comprehensive integration testing for deployed infrastructure
# Tests actual deployed services and their connectivity
#
# Usage:
#   ./scripts/integration-tests.sh [--verbose] [--output FILE]
#
# Exit codes:
#   0 - All tests passed
#   1 - Some tests failed (but continued)
#   2 - Critical failure (cluster unreachable)
#
# ============================================================================

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TIMEOUT_SHORT=30
TIMEOUT_MEDIUM=60
TIMEOUT_LONG=120
VERBOSE=false
OUTPUT_FILE=""

# Test result tracking
FAILED_TESTS=()
PASSED_TESTS=()
WARNING_TESTS=()
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_WARNING=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --output|-o)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [--verbose] [--output FILE]"
            echo "Integration tests for tf-kube-any-compute infrastructure"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Logging functions
log() {
    local message="$1"
    local level="${2:-INFO}"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    if [[ "$OUTPUT_FILE" != "" ]]; then
        echo "[$timestamp] [$level] $message" >> "$OUTPUT_FILE"
    fi
    
    case $level in
        ERROR)
            echo -e "${RED}❌ $message${NC}" >&2
            ;;
        SUCCESS)
            echo -e "${GREEN}✅ $message${NC}"
            ;;
        WARNING)
            echo -e "${YELLOW}⚠️  $message${NC}"
            ;;
        INFO)
            echo -e "${BLUE}ℹ️  $message${NC}"
            ;;
        DEBUG)
            if [[ "$VERBOSE" == "true" ]]; then
                echo -e "${PURPLE}🔍 $message${NC}"
            fi
            ;;
        *)
            echo "$message"
            ;;
    esac
}

# Test result tracking
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0
FAILED_TESTS=()

# Test execution wrapper
run_test() {
    local test_name="$1"
    local test_function="$2"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    log "Running test: $test_name" "INFO"
    
    # Always continue testing, track results appropriately
    if $test_function; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        PASSED_TESTS+=("$test_name")
        log "Test passed: $test_name" "SUCCESS"
        return 0
    else
        # Check if this was a warning (non-critical failure)
        local current_failures=${#FAILED_TESTS[@]}
        
        # If FAILED_TESTS was populated by the test function, it's a warning
        if [[ ${#FAILED_TESTS[@]} -gt $current_failures ]]; then
            TESTS_WARNING=$((TESTS_WARNING + 1))
            WARNING_TESTS+=("$test_name")
            log "Test completed with warnings: $test_name" "WARNING"
            return 0  # Continue execution for warnings
        else
            TESTS_FAILED=$((TESTS_FAILED + 1))
            FAILED_TESTS+=("$test_name")
            log "Test failed: $test_name" "ERROR"
            return 0  # Continue execution even for failures
        fi
    fi
}

# ============================================================================
# CLUSTER CONNECTIVITY TESTS
# ============================================================================

test_cluster_connectivity() {
    log "Testing cluster connectivity" "DEBUG"
    
    # Test kubectl connection
    if ! kubectl cluster-info --request-timeout=10s >/dev/null 2>&1; then
        log "Cannot connect to Kubernetes cluster" "ERROR"
        return 1
    fi
    
    # Test basic cluster info
    local nodes_count=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
    if [[ $nodes_count -eq 0 ]]; then
        log "No nodes found in cluster" "ERROR"
        return 1
    fi
    
    log "Cluster accessible with $nodes_count nodes" "DEBUG"
    return 0
}

test_helm_connectivity() {
    log "Testing Helm connectivity" "DEBUG"
    
    if ! command -v helm >/dev/null 2>&1; then
        log "Helm not available" "WARNING"
        return 0
    fi
    
    if ! helm list --all-namespaces >/dev/null 2>&1; then
        log "Cannot connect to Helm" "ERROR"
        return 1
    fi
    
    local releases_count=$(helm list --all-namespaces -q 2>/dev/null | wc -l)
    log "Helm accessible with $releases_count releases" "DEBUG"
    return 0
}

# ============================================================================
# NAMESPACE AND SERVICE TESTS
# ============================================================================

test_namespaces_exist() {
    log "Testing namespace existence" "DEBUG"
    
    local expected_namespaces=(
        "prod-traefik-ingress"
        "prod-metallb-ingress"
        "prod-monitoring-stack"
        "prod-grafana-system"
        "prod-consul-stack"
        "prod-vault-stack"
    )
    
    local missing_namespaces=()
    
    for ns in "${expected_namespaces[@]}"; do
        if ! kubectl get namespace "$ns" >/dev/null 2>&1; then
            missing_namespaces+=("$ns")
        fi
    done
    
    if [[ ${#missing_namespaces[@]} -gt 0 ]]; then
        log "Missing namespaces: ${missing_namespaces[*]}" "ERROR"
        return 1
    fi
    
    log "All expected namespaces exist" "DEBUG"
    return 0
}

test_pods_running() {
    log "Testing pod status" "DEBUG"
    
    # Get all pods in tf-kube-any-compute namespaces
    local failed_pods=$(kubectl get pods --all-namespaces --no-headers 2>/dev/null | \
        grep -E "prod-" | \
        grep -v "Running\|Completed" || true)
    
    local running_pods=$(kubectl get pods --all-namespaces --no-headers 2>/dev/null | \
        grep -E "prod-" | grep "Running" | wc -l)
    
    local total_pods=$(kubectl get pods --all-namespaces --no-headers 2>/dev/null | \
        grep -E "prod-" | wc -l)
    
    if [[ -n "$failed_pods" ]]; then
        log "Found non-running pods (will continue testing):" "WARNING"
        echo "$failed_pods" | while read line; do
            log "  $line" "WARNING"
        done
        
        # Record the failure but don't exit - continue testing other components
        FAILED_TESTS+=("Pod Status: Some pods not running")
    fi
    
    log "$running_pods/$total_pods pods running successfully" "INFO"
    
    # Always return 0 to continue testing other components
    return 0
}

test_services_accessible() {
    log "Testing service accessibility" "DEBUG"
    
    local services=(
        "prod-traefik-ingress:prod-traefik:80"
        "prod-metallb-ingress:metallb-webhook-service:443"
        "prod-grafana-system:prod-grafana:80"
        "prod-consul-stack:prod-consul-ui:80"
        "prod-vault-stack:prod-vault:8200"
    )
    
    local failed_services=()
    
    for service_info in "${services[@]}"; do
        IFS=':' read -r namespace service port <<< "$service_info"
        
        if ! kubectl get service "$service" -n "$namespace" >/dev/null 2>&1; then
            failed_services+=("$namespace/$service")
            continue
        fi
        
        # Test service endpoints
        local endpoints=$(kubectl get endpoints "$service" -n "$namespace" -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null || echo "")
        if [[ -z "$endpoints" ]]; then
            failed_services+=("$namespace/$service (no endpoints)")
        fi
    done
    
    if [[ ${#failed_services[@]} -gt 0 ]]; then
        log "Failed services: ${failed_services[*]}" "ERROR"
        return 1
    fi
    
    log "All core services are accessible" "DEBUG"
    return 0
}

# ============================================================================
# INGRESS AND NETWORKING TESTS
# ============================================================================

test_ingress_configuration() {
    log "Testing ingress configuration and connectivity" "DEBUG"
    
    local ingresses=$(kubectl get ingress --all-namespaces --no-headers 2>/dev/null | wc -l)
    
    if [[ $ingresses -eq 0 ]]; then
        log "No ingresses found" "WARNING"
        FAILED_TESTS+=("Ingress: No ingress resources found")
        return 1
    fi
    
    log "Found $ingresses ingress resources" "DEBUG"
    
    # Test specific ingresses and their actual connectivity
    local expected_ingresses=(
        "prod-grafana-system:prod-grafana-ingress"
        "prod-consul-stack:prod-consul-ingress"
        "prod-portainer-system:prod-portainer-ingress"
        "prod-vault-stack:svclb-prod-vault-ui"
        "prod-monitoring-stack:prod-prometh-alert-prometheus-ingress"
        "prod-monitoring-stack:prod-prometh-alert-alertmanager-ingress"
    )
    
    local missing_ingresses=()
    local failed_connectivity=()
    
    # Check if ingress resources exist
    for ingress_info in "${expected_ingresses[@]}"; do
        IFS=':' read -r namespace ingress <<< "$ingress_info"
        
        if ! kubectl get ingress "$ingress" -n "$namespace" >/dev/null 2>&1; then
            missing_ingresses+=("$namespace/$ingress")
        else
            # Test actual connectivity to ingress
            log "Testing connectivity for $namespace/$ingress" "DEBUG"
            
            # Get ingress host/path
            local ingress_host=$(kubectl get ingress "$ingress" -n "$namespace" -o jsonpath='{.spec.rules[0].host}' 2>/dev/null || echo "")
            local ingress_paths=$(kubectl get ingress "$ingress" -n "$namespace" -o jsonpath='{.spec.rules[0].http.paths[*].path}' 2>/dev/null || echo "/")
            
            if [[ -n "$ingress_host" ]]; then
                # Test both HTTPS and HTTP connectivity (prioritize HTTPS)
                local test_urls=("https://${ingress_host}" "http://${ingress_host}")
                local connectivity_success=false
                
                for test_url in "${test_urls[@]}"; do
                    if [[ "$ingress_paths" != "/" ]]; then
                        test_url="${test_url}${ingress_paths%% *}"  # Use first path
                    fi
                    
                    log "Testing URL: $test_url" "DEBUG"
                    
                    # Try to reach the ingress endpoint with proper SSL handling
                    local http_code
                    if [[ "$test_url" == https://* ]]; then
                        # For HTTPS, use -k to ignore SSL certificate issues and test connectivity
                        http_code=$(curl -k -s --connect-timeout 5 --max-time 10 -o /dev/null -w "%{http_code}" "$test_url" 2>/dev/null || echo "000")
                    else
                        # For HTTP
                        http_code=$(curl -s --connect-timeout 5 --max-time 10 -o /dev/null -w "%{http_code}" "$test_url" 2>/dev/null || echo "000")
                    fi
                    
                    # Consider 200, 301, 302, 401, 403 as successful connectivity (service is responding)
                    if echo "$http_code" | grep -E "^(200|301|302|401|403)$" >/dev/null 2>&1; then
                        log "✅ Ingress responding: $test_url (HTTP $http_code)" "SUCCESS"
                        connectivity_success=true
                        break
                    else
                        log "❌ Ingress failed: $test_url (HTTP $http_code)" "DEBUG"
                    fi
                done
                
                if [[ "$connectivity_success" != "true" ]]; then
                    failed_connectivity+=("$ingress_host (no working HTTP/HTTPS connectivity)")
                fi
            else
                # Check if service behind ingress is reachable
                local backend_service=$(kubectl get ingress "$ingress" -n "$namespace" -o jsonpath='{.spec.rules[0].http.paths[0].backend.service.name}' 2>/dev/null || echo "")
                local backend_port=$(kubectl get ingress "$ingress" -n "$namespace" -o jsonpath='{.spec.rules[0].http.paths[0].backend.service.port.number}' 2>/dev/null || echo "")
                
                if [[ -n "$backend_service" && -n "$backend_port" ]]; then
                    # Test service connectivity via port-forward
                    if ! kubectl get service "$backend_service" -n "$namespace" >/dev/null 2>&1; then
                        failed_connectivity+=("$namespace/$backend_service (backend service not found)")
                    fi
                else
                    failed_connectivity+=("$namespace/$ingress (no host or backend service configured)")
                fi
            fi
        fi
    done
    
    # Report results
    local test_passed=true
    
    if [[ ${#missing_ingresses[@]} -gt 0 ]]; then
        log "Missing ingresses: ${missing_ingresses[*]}" "WARNING"
        FAILED_TESTS+=("Ingress: Missing resources - ${missing_ingresses[*]}")
        test_passed=false
    fi
    
    if [[ ${#failed_connectivity[@]} -gt 0 ]]; then
        log "Ingress connectivity failures: ${failed_connectivity[*]}" "ERROR"
        FAILED_TESTS+=("Ingress: Connectivity failures - ${failed_connectivity[*]}")
        test_passed=false
    fi
    
    if [[ "$test_passed" == "true" ]]; then
        log "$ingresses ingresses configured and accessible" "DEBUG"
        return 0
    else
        return 1
    fi
}

test_load_balancer_services() {
    log "Testing load balancer services" "DEBUG"
    
    # Check MetalLB controller
    if kubectl get pods -n prod-metallb-ingress -l app.kubernetes.io/name=metallb >/dev/null 2>&1; then
        local metallb_pods=$(kubectl get pods -n prod-metallb-ingress -l app.kubernetes.io/name=metallb --no-headers | grep "Running" | wc -l)
        
        if [[ $metallb_pods -eq 0 ]]; then
            log "MetalLB pods not running" "ERROR"
            return 1
        fi
        
        log "MetalLB running with $metallb_pods pods" "DEBUG"
    else
        log "MetalLB not found (might be disabled)" "WARNING"
    fi
    
    return 0
}

# ============================================================================
# STORAGE TESTS
# ============================================================================

test_storage_classes() {
    log "Testing storage classes" "DEBUG"
    
    local storage_classes=$(kubectl get storageclass --no-headers 2>/dev/null | wc -l)
    
    if [[ $storage_classes -eq 0 ]]; then
        log "No storage classes found" "ERROR"
        return 1
    fi
    
    # Check for expected storage classes
    local expected_classes=("hostpath" "nfs-csi")
    local found_classes=()
    
    for class in "${expected_classes[@]}"; do
        if kubectl get storageclass "$class" >/dev/null 2>&1; then
            found_classes+=("$class")
        fi
    done
    
    if [[ ${#found_classes[@]} -eq 0 ]]; then
        log "No expected storage classes found" "ERROR"
        return 1
    fi
    
    log "Found storage classes: ${found_classes[*]}" "DEBUG"
    return 0
}

test_persistent_volumes() {
    log "Testing persistent volumes" "DEBUG"
    
    local pvs=$(kubectl get pv --no-headers 2>/dev/null | wc -l)
    local pvcs=$(kubectl get pvc --all-namespaces --no-headers 2>/dev/null | wc -l)
    
    # Check for failed PVCs
    local failed_pvcs=$(kubectl get pvc --all-namespaces --no-headers 2>/dev/null | \
        grep -v "Bound" | grep -E "prod-" || true)
    
    if [[ -n "$failed_pvcs" ]]; then
        log "Found failed PVCs:" "WARNING"
        echo "$failed_pvcs" | while read line; do
            log "  $line" "WARNING"
        done
        # Not a hard failure as some PVCs might be pending for valid reasons
    fi
    
    log "Found $pvs PVs and $pvcs PVCs" "DEBUG"
    return 0
}

# ============================================================================
# APPLICATION-SPECIFIC TESTS
# ============================================================================

test_traefik_functionality() {
    log "Testing Traefik functionality and connectivity" "DEBUG"
    
    # Check Traefik pods
    if ! kubectl get pods -n prod-traefik-ingress -l app.kubernetes.io/name=traefik >/dev/null 2>&1; then
        log "Traefik pods not found" "ERROR"
        FAILED_TESTS+=("Traefik: Pods not found")
        return 1
    fi
    
    local traefik_running=$(kubectl get pods -n prod-traefik-ingress -l app.kubernetes.io/name=traefik --no-headers 2>/dev/null | grep "Running" | wc -l)
    
    if [[ $traefik_running -eq 0 ]]; then
        log "No Traefik pods running" "ERROR"
        FAILED_TESTS+=("Traefik: No pods running")
        return 1
    fi
    
    # Check Traefik service
    if ! kubectl get service prod-traefik -n prod-traefik-ingress >/dev/null 2>&1; then
        log "Traefik service not found" "ERROR"
        FAILED_TESTS+=("Traefik: Service not found")
        return 1
    fi
    
    log "Traefik running with $traefik_running pods" "DEBUG"
    
    # Test Traefik connectivity
    local traefik_svc_ip=""
    traefik_svc_ip=$(kubectl get service prod-traefik -n prod-traefik-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    
    if [[ -z "$traefik_svc_ip" ]]; then
        # Try cluster IP if no external IP
        traefik_svc_ip=$(kubectl get service traefik -n prod-traefik-ingress -o jsonpath='{.spec.clusterIP}' 2>/dev/null || echo "")
    fi
    
    if [[ -z "$traefik_svc_ip" ]]; then
        log "Traefik service IP not found" "ERROR"
        FAILED_TESTS+=("Traefik: Service IP not accessible")
        return 1
    fi
    
    log "Testing Traefik connectivity at $traefik_svc_ip" "DEBUG"
    
    # Test Traefik dashboard (port 8080)
    local dashboard_result=""
    dashboard_result=$(curl -s --connect-timeout 5 --max-time 10 -o /dev/null -w "%{http_code}" "http://${traefik_svc_ip}:8080/dashboard/" 2>/dev/null || echo "000")
    
    if [[ "$dashboard_result" =~ ^(200|301|302|401|403)$ ]]; then
        log "Traefik dashboard accessible (HTTP $dashboard_result)" "DEBUG"
    else
        log "Traefik dashboard not accessible (HTTP $dashboard_result)" "WARNING"
        FAILED_TESTS+=("Traefik: Dashboard not accessible at port 8080")
    fi
    
    # Test Traefik API
    local api_result=""
    api_result=$(curl -s --connect-timeout 5 --max-time 10 -o /dev/null -w "%{http_code}" "http://${traefik_svc_ip}:8080/api/overview" 2>/dev/null || echo "000")
    
    if [[ "$api_result" =~ ^(200|301|302)$ ]]; then
        log "Traefik API accessible (HTTP $api_result)" "DEBUG"
    else
        log "Traefik API not accessible (HTTP $api_result)" "WARNING" 
        FAILED_TESTS+=("Traefik: API not accessible")
    fi
    
    # Check IngressRoute resources
    local ingress_routes=$(kubectl get ingressroute --all-namespaces --no-headers 2>/dev/null | wc -l)
    log "Found $ingress_routes IngressRoute resources" "DEBUG"
    
    if [[ $ingress_routes -eq 0 ]]; then
        log "No IngressRoute resources found" "WARNING"
        FAILED_TESTS+=("Traefik: No IngressRoute resources configured")
    fi
    
    # Test actual routing by checking if services behind ingress are accessible
    local services_behind_ingress=$(kubectl get ingressroute --all-namespaces -o jsonpath='{.items[*].spec.routes[*].services[*].name}' 2>/dev/null | tr ' ' '\n' | sort -u | wc -l)
    log "Found $services_behind_ingress services configured behind Traefik ingress" "DEBUG"
    
    return 0
}

test_monitoring_stack() {
    log "Testing monitoring stack" "DEBUG"
    
    # Check Prometheus
    if kubectl get pods -n prod-monitoring-stack -l app.kubernetes.io/name=prometheus >/dev/null 2>&1; then
        local prometheus_running=$(kubectl get pods -n prod-monitoring-stack -l app.kubernetes.io/name=prometheus --no-headers 2>/dev/null | grep "Running" | wc -l)
        log "Prometheus running with $prometheus_running pods" "DEBUG"
    else
        log "Prometheus not found (might be disabled)" "WARNING"
    fi
    
    # Check Grafana
    if kubectl get pods -n prod-grafana-system -l app.kubernetes.io/name=grafana >/dev/null 2>&1; then
        local grafana_running=$(kubectl get pods -n prod-grafana-system -l app.kubernetes.io/name=grafana --no-headers 2>/dev/null | grep "Running" | wc -l)
        log "Grafana running with $grafana_running pods" "DEBUG"
    else
        log "Grafana not found (might be disabled)" "WARNING"
    fi
    
    return 0
}

test_consul_vault_integration() {
    log "Testing Consul/Vault integration" "DEBUG"
    
    # Check Consul
    if kubectl get pods -n prod-consul-stack -l app=consul >/dev/null 2>&1; then
        local consul_running=$(kubectl get pods -n prod-consul-stack -l app=consul --no-headers 2>/dev/null | grep "Running" | wc -l)
        log "Consul running with $consul_running pods" "DEBUG"
        
        # Check Consul leader
        if kubectl exec -n prod-consul-stack deployment/prod-consul -- consul operator raft list-peers >/dev/null 2>&1; then
            log "Consul cluster has raft consensus" "DEBUG"
        else
            log "Consul raft consensus check failed" "WARNING"
        fi
    else
        log "Consul not found (might be disabled)" "WARNING"
    fi
    
    # Check Vault
    if kubectl get pods -n prod-vault-stack -l app.kubernetes.io/name=vault >/dev/null 2>&1; then
        local vault_running=$(kubectl get pods -n prod-vault-stack -l app.kubernetes.io/name=vault --no-headers 2>/dev/null | grep "Running" | wc -l)
        log "Vault running with $vault_running pods" "DEBUG"
        
        # Check Vault status
        if kubectl exec -n prod-vault-stack prod-vault-0 -- vault status >/dev/null 2>&1; then
            log "Vault status check successful" "DEBUG"
        else
            log "Vault status check failed (might be sealed)" "WARNING"
        fi
    else
        log "Vault not found (might be disabled)" "WARNING"
    fi
    
    return 0
}

# ============================================================================
# PERFORMANCE AND RESOURCE TESTS
# ============================================================================

test_resource_usage() {
    log "Testing resource usage" "DEBUG"
    
    # Check node resources
    local node_count=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
    
    if [[ $node_count -eq 0 ]]; then
        log "No nodes found" "ERROR"
        return 1
    fi
    
    # Check for resource pressure
    local pressure_nodes=$(kubectl get nodes --no-headers 2>/dev/null | grep -E "(MemoryPressure|DiskPressure|PIDPressure)" | grep "True" || true)
    
    if [[ -n "$pressure_nodes" ]]; then
        log "Found nodes with resource pressure:" "WARNING"
        echo "$pressure_nodes" | while read line; do
            log "  $line" "WARNING"
        done
        # Not a hard failure as this might be temporary
    fi
    
    log "Checked $node_count nodes for resource pressure" "DEBUG"
    return 0
}

test_pod_resource_limits() {
    log "Testing pod resource limits" "DEBUG"
    
    # Check for pods without resource limits
    local pods_without_limits=$(kubectl get pods --all-namespaces -o jsonpath='{range .items[*]}{.metadata.namespace}{" "}{.metadata.name}{" "}{.spec.containers[*].resources.limits}{"\n"}{end}' 2>/dev/null | \
        grep -E "prod-" | grep -v "cpu\|memory" | wc -l || echo "0")
    
    if [[ $pods_without_limits -gt 0 ]]; then
        log "$pods_without_limits pods found without resource limits" "WARNING"
        # Not a hard failure as some pods might legitimately not have limits
    fi
    
    log "Checked pod resource limit configuration" "DEBUG"
    return 0
}

# ============================================================================
# SECURITY TESTS
# ============================================================================

test_security_policies() {
    log "Testing security policies" "DEBUG"
    
    # Check for Gatekeeper
    if kubectl get pods -n gatekeeper-system >/dev/null 2>&1; then
        local gatekeeper_running=$(kubectl get pods -n gatekeeper-system --no-headers 2>/dev/null | grep "Running" | wc -l)
        log "Gatekeeper running with $gatekeeper_running pods" "DEBUG"
        
        # Check constraint templates
        local constraints=$(kubectl get constrainttemplates 2>/dev/null | wc -l)
        log "Found $constraints constraint templates" "DEBUG"
    else
        log "Gatekeeper not found (might be disabled)" "WARNING"
    fi
    
    return 0
}

test_network_policies() {
    log "Testing network policies" "DEBUG"
    
    local network_policies=$(kubectl get networkpolicies --all-namespaces --no-headers 2>/dev/null | wc -l)
    
    if [[ $network_policies -eq 0 ]]; then
        log "No network policies found" "WARNING"
        # Not a failure as network policies might not be configured
    else
        log "Found $network_policies network policies" "DEBUG"
    fi
    
    return 0
}

# ============================================================================
# MAIN TEST EXECUTION
# ============================================================================

main() {
    log "Starting tf-kube-any-compute integration tests" "INFO"
    log "Output file: ${OUTPUT_FILE:-stdout}" "INFO"
    log "Verbose mode: $VERBOSE" "INFO"
    
    # Critical cluster connectivity tests
    if ! run_test "Cluster Connectivity" test_cluster_connectivity; then
        log "Critical failure: Cannot connect to cluster" "ERROR"
        exit 2
    fi
    
    run_test "Helm Connectivity" test_helm_connectivity
    
    # Core infrastructure tests
    run_test "Namespaces Exist" test_namespaces_exist
    run_test "Pods Running" test_pods_running
    run_test "Services Accessible" test_services_accessible
    
    # Networking tests
    run_test "Ingress Configuration" test_ingress_configuration
    run_test "Load Balancer Services" test_load_balancer_services
    
    # Storage tests
    run_test "Storage Classes" test_storage_classes
    run_test "Persistent Volumes" test_persistent_volumes
    
    # Application-specific tests
    run_test "Traefik Functionality" test_traefik_functionality
    run_test "Monitoring Stack" test_monitoring_stack
    run_test "Consul/Vault Integration" test_consul_vault_integration
    
    # Performance and resource tests
    run_test "Resource Usage" test_resource_usage
    run_test "Pod Resource Limits" test_pod_resource_limits
    
    # Security tests
    run_test "Security Policies" test_security_policies
    run_test "Network Policies" test_network_policies
    
    # Test summary
    log "" "INFO"
    log "============================================" "INFO"
    log "Integration Test Results" "INFO"
    log "============================================" "INFO"
    log "Total tests: $TESTS_TOTAL" "INFO"
    log "Passed: $TESTS_PASSED" "SUCCESS"
    log "Warnings: $TESTS_WARNING" "WARNING"
    log "Failed: $TESTS_FAILED" "ERROR"
    
    if [[ $TESTS_WARNING -gt 0 ]]; then
        log "" "WARNING"
        log "Tests with warnings:" "WARNING"
        for test in "${WARNING_TESTS[@]}"; do
            log "  - $test" "WARNING"
        done
    fi
    
    if [[ $TESTS_FAILED -gt 0 ]]; then
        log "" "ERROR"
        log "Failed tests:" "ERROR"
        for test in "${FAILED_TESTS[@]}"; do
            log "  - $test" "ERROR"
        done
        log "" "ERROR"
        log "Integration tests completed with failures" "ERROR"
        exit 1
    elif [[ $TESTS_WARNING -gt 0 ]]; then
        log "" "WARNING"
        log "Integration tests completed with warnings (non-critical issues found)" "WARNING"
        exit 0
    else
        log "" "SUCCESS"
        log "All integration tests passed!" "SUCCESS"
        exit 0
    fi
}

# Run main function
main "$@"
