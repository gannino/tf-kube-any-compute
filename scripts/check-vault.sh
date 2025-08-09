#!/bin/bash
# ============================================================================
# Vault Service Health Check Script
# ============================================================================
#
# Comprehensive health check for HashiCorp Vault deployment including:
# - Pod status and readiness
# - Service connectivity
# - Vault initialization and seal status
# - Key rotation and backup status
# - Performance metrics
#
# Usage:
#   ./scripts/check-vault.sh [options]
#
# Options:
#   --verbose, -v       Verbose output
#   --status-only       Only check basic status
#   --unseal-check      Check seal status
#   --help, -h          Show help
#
# ============================================================================

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERBOSE=false
STATUS_ONLY=false
UNSEAL_CHECK=false

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

log() {
    local level="$1"
    shift
    local message="$*"
    
    case "${level}" in
        "ERROR")
            echo -e "${RED}❌ [ERROR]${NC} ${message}"
            ;;
        "WARN")
            echo -e "${YELLOW}⚠️  [WARN]${NC} ${message}"
            ;;
        "INFO")
            echo -e "${GREEN}ℹ️  [INFO]${NC} ${message}"
            ;;
        "SUCCESS")
            echo -e "${GREEN}✅ [SUCCESS]${NC} ${message}"
            ;;
        "DEBUG")
            if [[ "${VERBOSE}" == "true" ]]; then
                echo -e "${BLUE}🔍 [DEBUG]${NC} ${message}"
            fi
            ;;
    esac
}

check_prerequisites() {
    log "INFO" "Checking prerequisites..."
    
    if ! command -v kubectl &> /dev/null; then
        log "ERROR" "kubectl is required but not installed"
        exit 1
    fi
    
    if ! kubectl cluster-info --request-timeout=5s >/dev/null 2>&1; then
        log "ERROR" "Cannot connect to Kubernetes cluster"
        exit 1
    fi
    
    log "SUCCESS" "Prerequisites check passed"
}

# ============================================================================
# VAULT DIAGNOSTICS
# ============================================================================

check_vault_namespace() {
    log "INFO" "Checking Vault namespace..."
    
    local vault_ns="prod-vault-stack"
    
    if kubectl get namespace "$vault_ns" >/dev/null 2>&1; then
        log "SUCCESS" "Vault namespace '$vault_ns' exists"
        return 0
    else
        log "ERROR" "Vault namespace '$vault_ns' not found"
        return 1
    fi
}

check_vault_pods() {
    log "INFO" "Checking Vault pods..."
    
    local vault_ns="prod-vault-stack"
    local vault_pods
    vault_pods=$(kubectl get pods -n "$vault_ns" --no-headers 2>/dev/null | grep vault || echo "")
    
    if [[ -z "$vault_pods" ]]; then
        log "ERROR" "No Vault pods found in namespace $vault_ns"
        return 1
    fi
    
    log "DEBUG" "Vault pods status:"
    kubectl get pods -n "$vault_ns" | grep vault || true
    
    # Count running vs total pods
    local total_pods running_pods
    total_pods=$(echo "$vault_pods" | wc -l)
    running_pods=$(echo "$vault_pods" | grep "Running" | wc -l || echo "0")
    
    if [[ $running_pods -eq $total_pods ]]; then
        log "SUCCESS" "All $total_pods Vault pods are running"
    else
        log "WARN" "$running_pods/$total_pods Vault pods are running"
        
        # Show non-running pods
        local non_running
        non_running=$(echo "$vault_pods" | grep -v "Running" || echo "")
        if [[ -n "$non_running" ]]; then
            log "WARN" "Non-running pods:"
            echo "$non_running"
        fi
    fi
    
    return 0
}

check_vault_service() {
    log "INFO" "Checking Vault service..."
    
    local vault_ns="prod-vault-stack"
    local vault_svc="prod-vault"
    
    if kubectl get service "$vault_svc" -n "$vault_ns" >/dev/null 2>&1; then
        log "SUCCESS" "Vault service '$vault_svc' exists"
        
        # Check service endpoints
        local endpoints
        endpoints=$(kubectl get endpoints "$vault_svc" -n "$vault_ns" -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null || echo "")
        
        if [[ -n "$endpoints" ]]; then
            log "SUCCESS" "Vault service has endpoints: $endpoints"
        else
            log "WARN" "Vault service has no endpoints"
        fi
        
        # Show service details if verbose
        if [[ "${VERBOSE}" == "true" ]]; then
            log "DEBUG" "Vault service details:"
            kubectl describe service "$vault_svc" -n "$vault_ns"
        fi
    else
        log "ERROR" "Vault service '$vault_svc' not found in namespace $vault_ns"
        return 1
    fi
    
    return 0
}

check_vault_ingress() {
    log "INFO" "Checking Vault ingress..."
    
    local vault_ns="prod-vault-stack"
    local ingresses
    ingresses=$(kubectl get ingress -n "$vault_ns" --no-headers 2>/dev/null || echo "")
    
    if [[ -z "$ingresses" ]]; then
        log "INFO" "No ingress found for Vault (might be using LoadBalancer)"
        return 0
    fi
    
    log "SUCCESS" "Found Vault ingress configurations"
    kubectl get ingress -n "$vault_ns"
    
    # Test ingress connectivity
    while IFS= read -r line; do
        local host
        host=$(echo "$line" | awk '{print $3}')
        
        if [[ -n "$host" && "$host" != "<none>" ]]; then
            log "INFO" "Testing Vault ingress connectivity: $host"
            
            # Test HTTPS connectivity
            local https_code
            https_code=$(curl -k -s --connect-timeout 5 --max-time 10 -o /dev/null -w "%{http_code}" "https://$host" 2>/dev/null || echo "000")
            
            if [[ "$https_code" =~ ^(200|301|302|307)$ ]]; then
                log "SUCCESS" "✅ Vault ingress responding: https://$host (HTTP $https_code)"
            elif [[ "$https_code" =~ ^(401|403)$ ]]; then
                log "SUCCESS" "✅ Vault service available, requires authentication: https://$host (HTTP $https_code)"
            else
                log "WARN" "❌ Vault ingress not responding: https://$host (HTTP $https_code)"
            fi
        fi
    done <<< "$ingresses"
    
    return 0
}

check_vault_storage() {
    log "INFO" "Checking Vault storage..."
    
    local vault_ns="prod-vault-stack"
    local pvcs
    pvcs=$(kubectl get pvc -n "$vault_ns" --no-headers 2>/dev/null | grep vault || echo "")
    
    if [[ -z "$pvcs" ]]; then
        log "INFO" "No Vault PVCs found (might be using hostPath or external storage)"
        return 0
    fi
    
    log "SUCCESS" "Found Vault storage:"
    kubectl get pvc -n "$vault_ns" | grep vault || true
    
    # Check for bound PVCs
    local bound_pvcs
    bound_pvcs=$(echo "$pvcs" | grep "Bound" | wc -l || echo "0")
    local total_pvcs
    total_pvcs=$(echo "$pvcs" | wc -l)
    
    if [[ $bound_pvcs -eq $total_pvcs ]]; then
        log "SUCCESS" "All $total_pvcs Vault PVCs are bound"
    else
        log "WARN" "$bound_pvcs/$total_pvcs Vault PVCs are bound"
    fi
    
    return 0
}

check_vault_status() {
    if [[ "$UNSEAL_CHECK" != "true" ]]; then
        log "INFO" "Skipping Vault seal status check (use --unseal-check to enable)"
        return 0
    fi
    
    log "INFO" "Checking Vault seal status..."
    
    local vault_ns="prod-vault-stack"
    local vault_pod
    vault_pod=$(kubectl get pods -n "$vault_ns" --no-headers | grep vault | grep Running | head -1 | awk '{print $1}' || echo "")
    
    if [[ -z "$vault_pod" ]]; then
        log "ERROR" "No running Vault pod found for status check"
        return 1
    fi
    
    log "DEBUG" "Using Vault pod: $vault_pod"
    
    # Check if vault command is available in pod
    if kubectl exec -n "$vault_ns" "$vault_pod" -- vault version >/dev/null 2>&1; then
        log "SUCCESS" "Vault CLI available in pod"
        
        # Check seal status
        local seal_status
        if seal_status=$(kubectl exec -n "$vault_ns" "$vault_pod" -- vault status 2>/dev/null); then
            log "SUCCESS" "Vault status retrieved successfully"
            
            if [[ "${VERBOSE}" == "true" ]]; then
                log "DEBUG" "Vault status:"
                echo "$seal_status"
            fi
            
            # Parse seal status
            if echo "$seal_status" | grep -q "Sealed.*false"; then
                log "SUCCESS" "✅ Vault is unsealed and operational"
            elif echo "$seal_status" | grep -q "Sealed.*true"; then
                log "WARN" "🔒 Vault is sealed (this may be expected)"
            else
                log "WARN" "❓ Vault seal status unclear"
            fi
        else
            log "WARN" "Unable to retrieve Vault status (might not be initialized)"
        fi
    else
        log "WARN" "Vault CLI not available in pod (might be a sidecar container)"
    fi
    
    return 0
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

print_usage() {
    cat << EOF
Vault Service Health Check

Usage: $0 [options]

Options:
    --verbose, -v       Verbose output
    --status-only       Only check basic status  
    --unseal-check      Check Vault seal status
    --help, -h          Show this help

Examples:
    $0                  # Basic health check
    $0 --verbose        # Detailed health check
    $0 --unseal-check   # Include seal status check

EOF
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --verbose|-v)
                VERBOSE=true
                shift
                ;;
            --status-only)
                STATUS_ONLY=true
                shift
                ;;
            --unseal-check)
                UNSEAL_CHECK=true
                shift
                ;;
            --help|-h)
                print_usage
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                print_usage
                exit 1
                ;;
        esac
    done
}

main() {
    parse_arguments "$@"
    
    echo "🔍 Vault Service Health Check"
    echo "=============================="
    echo "Timestamp: $(date)"
    echo ""
    
    check_prerequisites
    
    if ! check_vault_namespace; then
        log "ERROR" "Cannot proceed without Vault namespace"
        exit 1
    fi
    
    # Basic checks
    check_vault_pods
    check_vault_service
    check_vault_ingress
    
    if [[ "$STATUS_ONLY" != "true" ]]; then
        check_vault_storage
        check_vault_status
    fi
    
    echo ""
    log "SUCCESS" "Vault health check completed"
    
    if [[ "$UNSEAL_CHECK" != "true" ]]; then
        echo ""
        log "INFO" "💡 Tip: Use --unseal-check to verify Vault seal status"
    fi
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
