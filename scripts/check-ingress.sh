#!/bin/bash
# ============================================================================
# Ingress Health Check Script
# ============================================================================
#
# Comprehensive health check for ingress configuration including:
# - Traefik ingress controller status
# - Ingress resource validation
# - SSL/TLS certificate status
# - Connectivity testing for all ingress endpoints
# - Load balancer configuration
#
# Usage:
#   ./scripts/check-ingress.sh [options]
#
# Options:
#   --verbose, -v       Verbose output
#   --test-ssl          Test SSL certificates
#   --connectivity      Test actual connectivity
#   --help, -h          Show help
#
# ============================================================================

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERBOSE=false
TEST_SSL=false
TEST_CONNECTIVITY=true

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
# TRAEFIK INGRESS CONTROLLER CHECKS
# ============================================================================

check_traefik_controller() {
    log "INFO" "Checking Traefik ingress controller..."

    local traefik_ns="prod-traefik-ingress"

    # Check namespace
    if ! kubectl get namespace "$traefik_ns" >/dev/null 2>&1; then
        log "ERROR" "Traefik namespace '$traefik_ns' not found"
        return 1
    fi

    # Check Traefik pods
    local traefik_pods
    traefik_pods=$(kubectl get pods -n "$traefik_ns" --no-headers 2>/dev/null | grep traefik || echo "")

    if [[ -z "$traefik_pods" ]]; then
        log "ERROR" "No Traefik pods found in namespace $traefik_ns"
        return 1
    fi

    local running_pods
    running_pods=$(echo "$traefik_pods" | grep "Running" | wc -l || echo "0")
    local total_pods
    total_pods=$(echo "$traefik_pods" | wc -l)

    if [[ $running_pods -eq $total_pods ]]; then
        log "SUCCESS" "All $total_pods Traefik pods are running"
    else
        log "WARN" "$running_pods/$total_pods Traefik pods are running"

        if [[ "${VERBOSE}" == "true" ]]; then
            log "DEBUG" "Traefik pod status:"
            kubectl get pods -n "$traefik_ns" | grep traefik || true
        fi
    fi

    # Check Traefik service
    local traefik_svc="prod-traefik"
    if kubectl get service "$traefik_svc" -n "$traefik_ns" >/dev/null 2>&1; then
        log "SUCCESS" "Traefik service '$traefik_svc' exists"

        # Get service details
        local svc_type external_ip
        svc_type=$(kubectl get service "$traefik_svc" -n "$traefik_ns" -o jsonpath='{.spec.type}' 2>/dev/null || echo "unknown")
        external_ip=$(kubectl get service "$traefik_svc" -n "$traefik_ns" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")

        log "INFO" "Traefik service type: $svc_type"
        if [[ "$svc_type" == "LoadBalancer" ]]; then
            if [[ "$external_ip" != "pending" && -n "$external_ip" ]]; then
                log "SUCCESS" "LoadBalancer external IP: $external_ip"
            else
                log "WARN" "LoadBalancer external IP is pending"
            fi
        fi

        if [[ "${VERBOSE}" == "true" ]]; then
            log "DEBUG" "Traefik service details:"
            kubectl describe service "$traefik_svc" -n "$traefik_ns"
        fi
    else
        log "ERROR" "Traefik service '$traefik_svc' not found"
        return 1
    fi

    return 0
}

# ============================================================================
# INGRESS RESOURCE CHECKS
# ============================================================================

check_ingress_resources() {
    log "INFO" "Checking ingress resources..."

    local ingresses
    ingresses=$(kubectl get ingress --all-namespaces --no-headers 2>/dev/null || echo "")

    if [[ -z "$ingresses" ]]; then
        log "WARN" "No ingress resources found in cluster"
        return 1
    fi

    local ingress_count
    ingress_count=$(echo "$ingresses" | wc -l)
    log "SUCCESS" "Found $ingress_count ingress resources"

    if [[ "${VERBOSE}" == "true" ]]; then
        log "DEBUG" "Ingress resources:"
        kubectl get ingress --all-namespaces
    fi

    # Check each ingress
    local total_ingresses=0
    local healthy_ingresses=0

    while IFS= read -r line; do
        local namespace ingress_name ingress_class hosts address ports
        namespace=$(echo "$line" | awk '{print $1}')
        ingress_name=$(echo "$line" | awk '{print $2}')
        ingress_class=$(echo "$line" | awk '{print $3}')
        hosts=$(echo "$line" | awk '{print $4}')
        address=$(echo "$line" | awk '{print $5}')
        ports=$(echo "$line" | awk '{print $6}')

        total_ingresses=$((total_ingresses + 1))

        log "INFO" "Checking ingress: $namespace/$ingress_name"

        # Check ingress class
        if [[ "$ingress_class" == "traefik" ]]; then
            log "SUCCESS" "  ✅ Using Traefik ingress class"
        else
            log "WARN" "  ⚠️  Using '$ingress_class' ingress class (not Traefik)"
        fi

        # Check host configuration
        if [[ -n "$hosts" && "$hosts" != "<none>" ]]; then
            log "SUCCESS" "  ✅ Host configured: $hosts"
        else
            log "WARN" "  ⚠️  No host configured"
        fi

        # Check address
        if [[ -n "$address" && "$address" != "<none>" ]]; then
            log "SUCCESS" "  ✅ Address assigned: $address"
            healthy_ingresses=$((healthy_ingresses + 1))
        else
            log "WARN" "  ⚠️  No address assigned"
        fi

        # Check ports
        if [[ "$ports" == *"443"* ]]; then
            log "SUCCESS" "  ✅ HTTPS configured"
        else
            log "INFO" "  ℹ️  Only HTTP configured"
        fi

        echo ""

    done <<< "$ingresses"

    log "INFO" "Ingress health summary: $healthy_ingresses/$total_ingresses ingresses have addresses"

    return 0
}

# ============================================================================
# CONNECTIVITY TESTS
# ============================================================================

test_ingress_connectivity() {
    if [[ "$TEST_CONNECTIVITY" != "true" ]]; then
        log "INFO" "Skipping connectivity tests (use --connectivity to enable)"
        return 0
    fi

    log "INFO" "Testing ingress connectivity..."

    local ingresses
    ingresses=$(kubectl get ingress --all-namespaces --no-headers 2>/dev/null || echo "")

    if [[ -z "$ingresses" ]]; then
        log "WARN" "No ingress resources to test"
        return 1
    fi

    local total_tests=0
    local successful_tests=0

    while IFS= read -r line; do
        local namespace ingress_name hosts
        namespace=$(echo "$line" | awk '{print $1}')
        ingress_name=$(echo "$line" | awk '{print $2}')
        hosts=$(echo "$line" | awk '{print $4}')

        if [[ -n "$hosts" && "$hosts" != "<none>" ]]; then
            # Split hosts by comma if multiple
            IFS=',' read -ra HOST_ARRAY <<< "$hosts"

            for host in "${HOST_ARRAY[@]}"; do
                host=$(echo "$host" | xargs)  # Trim whitespace

                if [[ -n "$host" ]]; then
                    total_tests=$((total_tests + 1))
                    log "INFO" "Testing connectivity to: $host"

                    local connection_successful=false

                    # Test HTTPS first, then HTTP
                    for protocol in https http; do
                        local test_url="${protocol}://${host}"
                        local http_code

                        log "DEBUG" "Testing: $test_url"

                        if [[ "$protocol" == "https" ]]; then
                            http_code=$(curl -k -s --connect-timeout 5 --max-time 10 -o /dev/null -w "%{http_code}" "$test_url" 2>/dev/null || echo "000")
                        else
                            http_code=$(curl -s --connect-timeout 5 --max-time 10 -o /dev/null -w "%{http_code}" "$test_url" 2>/dev/null || echo "000")
                        fi

                        # Consider various success codes
                        if [[ "$http_code" =~ ^(200|301|302|307)$ ]]; then
                            log "SUCCESS" "  ✅ $test_url responding (HTTP $http_code)"
                            connection_successful=true
                            successful_tests=$((successful_tests + 1))
                            break
                        elif [[ "$http_code" =~ ^(401|403)$ ]]; then
                            log "SUCCESS" "  ✅ $test_url service available, requires authentication (HTTP $http_code)"
                            connection_successful=true
                            successful_tests=$((successful_tests + 1))
                            break
                        else
                            log "DEBUG" "  ❌ $test_url not responding (HTTP $http_code)"
                        fi
                    done

                    if [[ "$connection_successful" != "true" ]]; then
                        log "WARN" "  ⚠️  $host not responding on HTTP or HTTPS"
                    fi
                fi
            done
        fi
    done <<< "$ingresses"

    echo ""
    log "INFO" "Connectivity test summary: $successful_tests/$total_tests hosts responding"

    if [[ $successful_tests -eq $total_tests && $total_tests -gt 0 ]]; then
        log "SUCCESS" "All ingress endpoints are accessible!"
    elif [[ $successful_tests -gt 0 ]]; then
        log "WARN" "Some ingress endpoints are not accessible"
    else
        log "ERROR" "No ingress endpoints are accessible"
    fi

    return 0
}

# ============================================================================
# SSL/TLS CERTIFICATE CHECKS
# ============================================================================

check_ssl_certificates() {
    if [[ "$TEST_SSL" != "true" ]]; then
        log "INFO" "Skipping SSL certificate checks (use --test-ssl to enable)"
        return 0
    fi

    log "INFO" "Checking SSL certificates..."

    # Look for TLS secrets
    local tls_secrets
    tls_secrets=$(kubectl get secrets --all-namespaces --field-selector type=kubernetes.io/tls --no-headers 2>/dev/null || echo "")

    if [[ -z "$tls_secrets" ]]; then
        log "WARN" "No TLS secrets found in cluster"
        return 0
    fi

    local secret_count
    secret_count=$(echo "$tls_secrets" | wc -l)
    log "SUCCESS" "Found $secret_count TLS secrets"

    if [[ "${VERBOSE}" == "true" ]]; then
        log "DEBUG" "TLS secrets:"
        kubectl get secrets --all-namespaces --field-selector type=kubernetes.io/tls
    fi

    # Check certificate expiration for HTTPS ingresses
    local ingresses
    ingresses=$(kubectl get ingress --all-namespaces --no-headers 2>/dev/null | grep "443" || echo "")

    if [[ -n "$ingresses" ]]; then
        log "INFO" "Checking certificate expiration for HTTPS ingresses..."

        while IFS= read -r line; do
            local hosts
            hosts=$(echo "$line" | awk '{print $4}')

            if [[ -n "$hosts" && "$hosts" != "<none>" ]]; then
                IFS=',' read -ra HOST_ARRAY <<< "$hosts"

                for host in "${HOST_ARRAY[@]}"; do
                    host=$(echo "$host" | xargs)

                    if [[ -n "$host" ]]; then
                        log "DEBUG" "Checking certificate for: $host"

                        # Check certificate expiration
                        local cert_info
                        if cert_info=$(echo | timeout 10 openssl s_client -servername "$host" -connect "$host:443" 2>/dev/null | openssl x509 -noout -dates 2>/dev/null); then
                            local expiry_date
                            expiry_date=$(echo "$cert_info" | grep "notAfter" | cut -d= -f2)

                            if [[ -n "$expiry_date" ]]; then
                                log "SUCCESS" "  ✅ Certificate for $host expires: $expiry_date"

                                # Check if certificate expires soon (30 days)
                                local expiry_epoch current_epoch days_until_expiry
                                expiry_epoch=$(date -d "$expiry_date" +%s 2>/dev/null || echo "0")
                                current_epoch=$(date +%s)
                                days_until_expiry=$(( (expiry_epoch - current_epoch) / 86400 ))

                                if [[ $days_until_expiry -lt 30 && $days_until_expiry -gt 0 ]]; then
                                    log "WARN" "  ⚠️  Certificate expires in $days_until_expiry days"
                                elif [[ $days_until_expiry -le 0 ]]; then
                                    log "ERROR" "  ❌ Certificate has expired"
                                fi
                            fi
                        else
                            log "WARN" "  ⚠️  Unable to retrieve certificate for $host"
                        fi
                    fi
                done
            fi
        done <<< "$ingresses"
    fi

    return 0
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

print_usage() {
    cat << EOF
Ingress Health Check Script

Usage: $0 [options]

Options:
    --verbose, -v       Verbose output
    --test-ssl          Test SSL certificates and expiration
    --connectivity      Test actual connectivity (default: enabled)
    --help, -h          Show this help

Examples:
    $0                  # Basic ingress health check
    $0 --verbose        # Detailed ingress health check
    $0 --test-ssl       # Include SSL certificate checks
    $0 --verbose --test-ssl --connectivity  # Full ingress diagnostics

EOF
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --verbose|-v)
                VERBOSE=true
                shift
                ;;
            --test-ssl)
                TEST_SSL=true
                shift
                ;;
            --connectivity)
                TEST_CONNECTIVITY=true
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

    echo "🌐 Ingress Health Check"
    echo "======================="
    echo "Timestamp: $(date)"
    echo ""

    check_prerequisites

    # Core ingress checks
    check_traefik_controller
    echo ""

    check_ingress_resources
    echo ""

    test_ingress_connectivity
    echo ""

    check_ssl_certificates
    echo ""

    log "SUCCESS" "Ingress health check completed"

    if [[ "$TEST_SSL" != "true" ]]; then
        echo ""
        log "INFO" "💡 Tip: Use --test-ssl to check SSL certificate status"
    fi
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
