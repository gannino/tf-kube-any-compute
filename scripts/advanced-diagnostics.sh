#!/bin/bash
# ============================================================================
# Advanced Diagnostics Script for tf-kube-any-compute
# ============================================================================
#
# Enhanced diagnostic capabilities including:
# - Performance analysis and bottleneck detection
# - Security posture assessment
# - Resource optimization recommendations
# - Automated issue resolution suggestions
# - Cross-service dependency analysis
# - Capacity planning insights
#
# Usage:
#   ./scripts/advanced-diagnostics.sh [options]
#
# Options:
#   --performance, -p    Performance analysis mode
#   --security, -s       Security assessment mode
#   --optimization, -o   Resource optimization analysis
#   --dependencies, -d   Service dependency analysis
#   --capacity, -c       Capacity planning analysis
#   --recommendations    Generate improvement recommendations
#   --json              Output in JSON format
#   --export FILE       Export results to file
#   --help, -h          Show help
#
# ============================================================================

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Mode flags
PERFORMANCE_MODE=false
SECURITY_MODE=false
OPTIMIZATION_MODE=false
DEPENDENCIES_MODE=false
CAPACITY_MODE=false
RECOMMENDATIONS_MODE=false
JSON_OUTPUT=false
EXPORT_FILE=""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

log() {
    local level="$1"
    shift
    local message="$*"

    if [[ "$JSON_OUTPUT" == "true" ]]; then
        return  # Skip logging in JSON mode
    fi

    case "${level}" in
        "ERROR")
            echo -e "${RED}❌ [ERROR]${NC} ${message}" >&2
            ;;
        "WARN")
            echo -e "${YELLOW}⚠️  [WARN]${NC} ${message}"
            ;;
        "INFO")
            echo -e "${BLUE}ℹ️  [INFO]${NC} ${message}"
            ;;
        "SUCCESS")
            echo -e "${GREEN}✅ [SUCCESS]${NC} ${message}"
            ;;
        "PERF")
            echo -e "${PURPLE}📊 [PERF]${NC} ${message}"
            ;;
        "SEC")
            echo -e "${RED}🔒 [SEC]${NC} ${message}"
            ;;
        "OPT")
            echo -e "${CYAN}⚡ [OPT]${NC} ${message}"
            ;;
    esac
}

# JSON output functions
json_start() {
    if [[ "$JSON_OUTPUT" == "true" ]]; then
        echo "{"
        echo "  \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\","
        echo "  \"cluster\": \"$(kubectl config current-context 2>/dev/null || echo 'unknown')\","
        echo "  \"analysis\": {"
    fi
}

json_section() {
    local section="$1"
    if [[ "$JSON_OUTPUT" == "true" ]]; then
        echo "    \"$section\": {"
    else
        log "INFO" "🔍 $section Analysis"
        echo "----------------------------------------"
    fi
}

json_end_section() {
    if [[ "$JSON_OUTPUT" == "true" ]]; then
        echo "    },"
    fi
}

json_end() {
    if [[ "$JSON_OUTPUT" == "true" ]]; then
        echo "  }"
        echo "}"
    fi
}

# Check prerequisites
check_prerequisites() {
    local missing_tools=()
    local tools=("kubectl" "helm" "jq" "curl")

    for tool in "${tools[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing_tools+=("$tool")
        fi
    done

    if [ ${#missing_tools[@]} -ne 0 ]; then
        log "ERROR" "Missing required tools: ${missing_tools[*]}"
        exit 1
    fi

    if ! kubectl cluster-info --request-timeout=5s >/dev/null 2>&1; then
        log "ERROR" "Cannot connect to Kubernetes cluster"
        exit 1
    fi
}

# ============================================================================
# PERFORMANCE ANALYSIS
# ============================================================================

analyze_performance() {
    json_section "performance"

    log "PERF" "Analyzing cluster performance..."

    # Node resource utilization
    if kubectl top nodes >/dev/null 2>&1; then
        log "PERF" "Node Resource Utilization:"

        kubectl top nodes --no-headers 2>/dev/null | while read -r line; do
            local node cpu_percent cpu_cores memory_percent memory_gb
            read -r node cpu_percent cpu_cores memory_percent memory_gb <<< "$line"

            # Extract numeric values
            local cpu_num=$(echo "$cpu_percent" | sed 's/%//')
            local mem_num=$(echo "$memory_percent" | sed 's/%//')

            if [[ $cpu_num -gt 80 ]]; then
                log "WARN" "High CPU usage on $node: $cpu_percent"
            elif [[ $cpu_num -gt 60 ]]; then
                log "INFO" "Moderate CPU usage on $node: $cpu_percent"
            fi

            if [[ $mem_num -gt 80 ]]; then
                log "WARN" "High memory usage on $node: $memory_percent"
            elif [[ $mem_num -gt 60 ]]; then
                log "INFO" "Moderate memory usage on $node: $memory_percent"
            fi
        done
    else
        log "WARN" "Metrics server not available - cannot analyze resource usage"
    fi

    # Pod resource requests vs limits
    log "PERF" "Analyzing pod resource configuration..."

    local total_pods=0
    local pods_without_limits=0
    local pods_without_requests=0

    kubectl get pods --all-namespaces -o json 2>/dev/null | jq -r '
        .items[] |
        select(.metadata.namespace | test("^(prod|dev|qa|fat)-")) |
        {
            namespace: .metadata.namespace,
            name: .metadata.name,
            containers: [.spec.containers[] | {
                name: .name,
                requests: .resources.requests // {},
                limits: .resources.limits // {}
            }]
        }
    ' | while IFS= read -r pod_data; do
        ((total_pods++))

        local has_limits has_requests
        has_limits=$(echo "$pod_data" | jq -r '.containers[] | select(.limits | length > 0) | .name' | wc -l)
        has_requests=$(echo "$pod_data" | jq -r '.containers[] | select(.requests | length > 0) | .name' | wc -l)

        if [[ $has_limits -eq 0 ]]; then
            ((pods_without_limits++))
        fi

        if [[ $has_requests -eq 0 ]]; then
            ((pods_without_requests++))
        fi
    done

    if [[ $pods_without_limits -gt 0 ]]; then
        log "WARN" "$pods_without_limits/$total_pods pods missing resource limits"
    fi

    if [[ $pods_without_requests -gt 0 ]]; then
        log "WARN" "$pods_without_requests/$total_pods pods missing resource requests"
    fi

    # Service response time analysis
    log "PERF" "Testing service response times..."

    local services=("traefik" "grafana" "prometheus" "consul" "vault")
    for service in "${services[@]}"; do
        local namespace
        namespace=$(kubectl get services --all-namespaces --no-headers 2>/dev/null | grep "$service" | head -1 | awk '{print $1}' || echo "")

        if [[ -n "$namespace" ]]; then
            local service_ip
            service_ip=$(kubectl get service "$service" -n "$namespace" -o jsonpath='{.spec.clusterIP}' 2>/dev/null || echo "")

            if [[ -n "$service_ip" && "$service_ip" != "None" ]]; then
                local response_time
                response_time=$(kubectl run curl-test --image=curlimages/curl --rm -i --restart=Never --timeout=10s -- \
                    curl -s -o /dev/null -w "%{time_total}" "http://$service_ip" 2>/dev/null || echo "timeout")

                if [[ "$response_time" != "timeout" ]]; then
                    local time_ms=$(echo "$response_time * 1000" | bc 2>/dev/null || echo "0")
                    if (( $(echo "$time_ms > 1000" | bc -l) )); then
                        log "WARN" "$service response time: ${time_ms}ms (slow)"
                    else
                        log "SUCCESS" "$service response time: ${time_ms}ms"
                    fi
                else
                    log "WARN" "$service: Connection timeout"
                fi
            fi
        fi
    done

    json_end_section
}

# ============================================================================
# SECURITY ASSESSMENT
# ============================================================================

analyze_security() {
    json_section "security"

    log "SEC" "Analyzing security posture..."

    # Check for privileged containers
    log "SEC" "Checking for privileged containers..."

    local privileged_pods
    privileged_pods=$(kubectl get pods --all-namespaces -o json 2>/dev/null | \
        jq -r '.items[] | select(.spec.containers[]?.securityContext.privileged == true) | "\(.metadata.namespace)/\(.metadata.name)"' || echo "")

    if [[ -n "$privileged_pods" ]]; then
        log "WARN" "Found privileged containers:"
        echo "$privileged_pods" | while read -r pod; do
            log "WARN" "  $pod"
        done
    else
        log "SUCCESS" "No privileged containers found"
    fi

    # Check for containers running as root
    log "SEC" "Checking for containers running as root..."

    local root_containers
    root_containers=$(kubectl get pods --all-namespaces -o json 2>/dev/null | \
        jq -r '.items[] | select(.spec.containers[]?.securityContext.runAsUser == 0 or (.spec.containers[]?.securityContext.runAsUser | not)) | "\(.metadata.namespace)/\(.metadata.name)"' || echo "")

    if [[ -n "$root_containers" ]]; then
        log "WARN" "Found containers potentially running as root:"
        echo "$root_containers" | head -5 | while read -r pod; do
            log "WARN" "  $pod"
        done
        local count=$(echo "$root_containers" | wc -l)
        if [[ $count -gt 5 ]]; then
            log "WARN" "  ... and $((count - 5)) more"
        fi
    else
        log "SUCCESS" "All containers have non-root user specified"
    fi

    # Check for network policies
    log "SEC" "Checking network policies..."

    local netpol_count
    netpol_count=$(kubectl get networkpolicies --all-namespaces --no-headers 2>/dev/null | wc -l)

    if [[ $netpol_count -eq 0 ]]; then
        log "WARN" "No network policies found - consider implementing network segmentation"
    else
        log "SUCCESS" "Found $netpol_count network policies"
    fi

    # Check for Pod Security Standards
    log "SEC" "Checking Pod Security Standards..."

    local pss_namespaces
    pss_namespaces=$(kubectl get namespaces -o json 2>/dev/null | \
        jq -r '.items[] | select(.metadata.labels["pod-security.kubernetes.io/enforce"]) | .metadata.name' || echo "")

    if [[ -n "$pss_namespaces" ]]; then
        log "SUCCESS" "Pod Security Standards enabled in namespaces:"
        echo "$pss_namespaces" | while read -r ns; do
            local level
            level=$(kubectl get namespace "$ns" -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}' 2>/dev/null || echo "unknown")
            log "SUCCESS" "  $ns: $level"
        done
    else
        log "WARN" "No Pod Security Standards configured"
    fi

    # Check for secrets in environment variables
    log "SEC" "Checking for secrets in environment variables..."

    local env_secrets
    env_secrets=$(kubectl get pods --all-namespaces -o json 2>/dev/null | \
        jq -r '.items[] | .spec.containers[]? | .env[]? | select(.name | test("(?i)(password|secret|key|token)")) | "\(.name)"' | sort -u || echo "")

    if [[ -n "$env_secrets" ]]; then
        log "WARN" "Found potential secrets in environment variables:"
        echo "$env_secrets" | while read -r env_var; do
            log "WARN" "  $env_var"
        done
        log "INFO" "Consider using Kubernetes secrets or external secret management"
    else
        log "SUCCESS" "No obvious secrets found in environment variables"
    fi

    json_end_section
}

# ============================================================================
# RESOURCE OPTIMIZATION
# ============================================================================

analyze_optimization() {
    json_section "optimization"

    log "OPT" "Analyzing resource optimization opportunities..."

    # Identify over-provisioned resources
    if kubectl top pods --all-namespaces >/dev/null 2>&1; then
        log "OPT" "Analyzing resource utilization vs requests..."

        kubectl top pods --all-namespaces --no-headers 2>/dev/null | while read -r line; do
            local namespace pod cpu_usage memory_usage
            read -r namespace pod cpu_usage memory_usage <<< "$line"

            # Get resource requests
            local cpu_request memory_request
            cpu_request=$(kubectl get pod "$pod" -n "$namespace" -o jsonpath='{.spec.containers[0].resources.requests.cpu}' 2>/dev/null || echo "")
            memory_request=$(kubectl get pod "$pod" -n "$namespace" -o jsonpath='{.spec.containers[0].resources.requests.memory}' 2>/dev/null || echo "")

            if [[ -n "$cpu_request" && -n "$memory_request" ]]; then
                # Convert to comparable units (simplified)
                local cpu_usage_num=$(echo "$cpu_usage" | sed 's/m//')
                local cpu_request_num=$(echo "$cpu_request" | sed 's/m//')

                if [[ "$cpu_request_num" =~ ^[0-9]+$ && "$cpu_usage_num" =~ ^[0-9]+$ ]]; then
                    if [[ $cpu_usage_num -lt $((cpu_request_num / 4)) ]]; then
                        log "OPT" "Over-provisioned CPU: $namespace/$pod (using $cpu_usage, requested $cpu_request)"
                    fi
                fi
            fi
        done
    fi

    # Check for unused PVCs
    log "OPT" "Checking for unused persistent volumes..."

    kubectl get pvc --all-namespaces -o json 2>/dev/null | jq -r '
        .items[] |
        select(.status.phase == "Bound") |
        {
            namespace: .metadata.namespace,
            name: .metadata.name,
            volume: .spec.volumeName,
            size: .spec.resources.requests.storage
        }
    ' | while IFS= read -r pvc_data; do
        local namespace name volume
        namespace=$(echo "$pvc_data" | jq -r '.namespace')
        name=$(echo "$pvc_data" | jq -r '.name')
        volume=$(echo "$pvc_data" | jq -r '.volume')

        # Check if PVC is actually used by any pod
        local using_pods
        using_pods=$(kubectl get pods -n "$namespace" -o json 2>/dev/null | \
            jq -r --arg pvc "$name" '.items[] | select(.spec.volumes[]?.persistentVolumeClaim.claimName == $pvc) | .metadata.name' || echo "")

        if [[ -z "$using_pods" ]]; then
            log "OPT" "Unused PVC: $namespace/$name"
        fi
    done

    # Check for duplicate services
    log "OPT" "Checking for service optimization opportunities..."

    local service_ports
    service_ports=$(kubectl get services --all-namespaces -o json 2>/dev/null | \
        jq -r '.items[] | "\(.metadata.namespace) \(.metadata.name) \(.spec.ports[0].port // "none")"' | sort -k3 -n)

    echo "$service_ports" | awk '{print $3}' | sort | uniq -d | while read -r port; do
        if [[ "$port" != "none" && "$port" != "443" && "$port" != "80" ]]; then
            log "OPT" "Multiple services using port $port:"
            echo "$service_ports" | grep " $port$" | while read -r ns name p; do
                log "OPT" "  $ns/$name"
            done
        fi
    done

    json_end_section
}

# ============================================================================
# DEPENDENCY ANALYSIS
# ============================================================================

analyze_dependencies() {
    json_section "dependencies"

    log "INFO" "Analyzing service dependencies..."

    # Map service dependencies based on common patterns
    declare -A service_deps=(
        ["traefik"]="metallb"
        ["grafana"]="prometheus"
        ["promtail"]="loki"
        ["vault"]="consul"
    )

    # Check if dependencies are met
    for service in "${!service_deps[@]}"; do
        local dependency="${service_deps[$service]}"

        local service_ns dependency_ns
        service_ns=$(kubectl get services --all-namespaces --no-headers 2>/dev/null | grep "$service" | head -1 | awk '{print $1}' || echo "")
        dependency_ns=$(kubectl get services --all-namespaces --no-headers 2>/dev/null | grep "$dependency" | head -1 | awk '{print $1}' || echo "")

        if [[ -n "$service_ns" && -z "$dependency_ns" ]]; then
            log "WARN" "$service is deployed but dependency $dependency is missing"
        elif [[ -n "$service_ns" && -n "$dependency_ns" ]]; then
            log "SUCCESS" "$service -> $dependency dependency satisfied"
        fi
    done

    # Check for circular dependencies or conflicts
    log "INFO" "Checking for service conflicts..."

    # Check for multiple ingress controllers
    local ingress_controllers=0
    local controllers=("traefik" "nginx" "istio")

    for controller in "${controllers[@]}"; do
        if kubectl get services --all-namespaces --no-headers 2>/dev/null | grep -q "$controller"; then
            ((ingress_controllers++))
            log "INFO" "Found ingress controller: $controller"
        fi
    done

    if [[ $ingress_controllers -gt 1 ]]; then
        log "WARN" "Multiple ingress controllers detected - may cause conflicts"
    fi

    # Check for storage class conflicts
    local default_storage_classes
    default_storage_classes=$(kubectl get storageclass -o json 2>/dev/null | \
        jq -r '.items[] | select(.metadata.annotations["storageclass.kubernetes.io/is-default-class"] == "true") | .metadata.name' | wc -l)

    if [[ $default_storage_classes -gt 1 ]]; then
        log "WARN" "Multiple default storage classes detected"
        kubectl get storageclass -o json 2>/dev/null | \
            jq -r '.items[] | select(.metadata.annotations["storageclass.kubernetes.io/is-default-class"] == "true") | .metadata.name' | \
            while read -r sc; do
                log "WARN" "  Default storage class: $sc"
            done
    fi

    json_end_section
}

# ============================================================================
# CAPACITY PLANNING
# ============================================================================

analyze_capacity() {
    json_section "capacity"

    log "INFO" "Analyzing capacity and growth trends..."

    # Node capacity analysis
    log "INFO" "Node capacity analysis:"

    kubectl get nodes -o json 2>/dev/null | jq -r '
        .items[] | {
            name: .metadata.name,
            cpu_capacity: .status.capacity.cpu,
            memory_capacity: .status.capacity.memory,
            cpu_allocatable: .status.allocatable.cpu,
            memory_allocatable: .status.allocatable.memory,
            architecture: .status.nodeInfo.architecture
        }
    ' | while IFS= read -r node_data; do
        local name arch cpu_cap mem_cap
        name=$(echo "$node_data" | jq -r '.name')
        arch=$(echo "$node_data" | jq -r '.architecture')
        cpu_cap=$(echo "$node_data" | jq -r '.cpu_capacity')
        mem_cap=$(echo "$node_data" | jq -r '.memory_capacity')

        log "INFO" "Node $name ($arch): ${cpu_cap} CPU, ${mem_cap} memory"
    done

    # Storage growth analysis
    log "INFO" "Storage utilization analysis:"

    local total_storage_requested=0
    kubectl get pvc --all-namespaces -o json 2>/dev/null | jq -r '
        .items[] | {
            namespace: .metadata.namespace,
            name: .metadata.name,
            size: .spec.resources.requests.storage,
            status: .status.phase
        }
    ' | while IFS= read -r pvc_data; do
        local namespace name size status
        namespace=$(echo "$pvc_data" | jq -r '.namespace')
        name=$(echo "$pvc_data" | jq -r '.name')
        size=$(echo "$pvc_data" | jq -r '.size')
        status=$(echo "$pvc_data" | jq -r '.status')

        if [[ "$status" == "Bound" ]]; then
            log "INFO" "PVC $namespace/$name: $size ($status)"

            # Convert size to bytes for calculation (simplified)
            local size_num=$(echo "$size" | sed 's/[^0-9]//g')
            if [[ -n "$size_num" ]]; then
                total_storage_requested=$((total_storage_requested + size_num))
            fi
        fi
    done

    log "INFO" "Total storage requested: ${total_storage_requested}Gi (approximate)"

    # Pod density analysis
    local total_pods node_count
    total_pods=$(kubectl get pods --all-namespaces --no-headers 2>/dev/null | wc -l)
    node_count=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)

    if [[ $node_count -gt 0 ]]; then
        local pods_per_node=$((total_pods / node_count))
        log "INFO" "Pod density: $pods_per_node pods per node average"

        if [[ $pods_per_node -gt 100 ]]; then
            log "WARN" "High pod density - consider adding nodes"
        elif [[ $pods_per_node -lt 10 ]]; then
            log "INFO" "Low pod density - cluster has room for growth"
        fi
    fi

    json_end_section
}

# ============================================================================
# RECOMMENDATIONS ENGINE
# ============================================================================

generate_recommendations() {
    json_section "recommendations"

    log "INFO" "Generating optimization recommendations..."

    local recommendations=()

    # Performance recommendations
    if ! kubectl top nodes >/dev/null 2>&1; then
        recommendations+=("Install metrics-server for resource monitoring")
    fi

    # Security recommendations
    local netpol_count
    netpol_count=$(kubectl get networkpolicies --all-namespaces --no-headers 2>/dev/null | wc -l)
    if [[ $netpol_count -eq 0 ]]; then
        recommendations+=("Implement network policies for security segmentation")
    fi

    # Resource recommendations
    local pods_without_limits
    pods_without_limits=$(kubectl get pods --all-namespaces -o json 2>/dev/null | \
        jq -r '.items[] | select(.spec.containers[].resources.limits | not) | .metadata.name' | wc -l)

    if [[ $pods_without_limits -gt 0 ]]; then
        recommendations+=("Set resource limits on $pods_without_limits pods")
    fi

    # Storage recommendations
    local default_sc_count
    default_sc_count=$(kubectl get storageclass -o json 2>/dev/null | \
        jq -r '.items[] | select(.metadata.annotations["storageclass.kubernetes.io/is-default-class"] == "true")' | wc -l)

    if [[ $default_sc_count -eq 0 ]]; then
        recommendations+=("Configure a default storage class")
    elif [[ $default_sc_count -gt 1 ]]; then
        recommendations+=("Remove duplicate default storage classes")
    fi

    # Architecture recommendations
    local mixed_arch
    mixed_arch=$(kubectl get nodes -o jsonpath='{.items[*].status.nodeInfo.architecture}' 2>/dev/null | tr ' ' '\n' | sort -u | wc -l)

    if [[ $mixed_arch -gt 1 ]]; then
        recommendations+=("Enable auto_mixed_cluster_mode for mixed architecture support")
    fi

    # Output recommendations
    if [[ ${#recommendations[@]} -gt 0 ]]; then
        log "INFO" "Recommendations:"
        for rec in "${recommendations[@]}"; do
            log "INFO" "  • $rec"
        done
    else
        log "SUCCESS" "No immediate recommendations - cluster is well configured!"
    fi

    json_end_section
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

show_help() {
    cat << EOF
Advanced Diagnostics for tf-kube-any-compute

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -p, --performance    Performance analysis mode
    -s, --security       Security assessment mode
    -o, --optimization   Resource optimization analysis
    -d, --dependencies   Service dependency analysis
    -c, --capacity       Capacity planning analysis
    -r, --recommendations Generate improvement recommendations
    --json              Output in JSON format
    --export FILE       Export results to file
    -h, --help          Show this help

EXAMPLES:
    $0 --performance --security
    $0 --all --json --export results.json
    $0 --recommendations

DESCRIPTION:
    Advanced diagnostic tool that provides deep insights into cluster
    performance, security posture, resource optimization opportunities,
    and capacity planning recommendations.

EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -p|--performance)
                PERFORMANCE_MODE=true
                shift
                ;;
            -s|--security)
                SECURITY_MODE=true
                shift
                ;;
            -o|--optimization)
                OPTIMIZATION_MODE=true
                shift
                ;;
            -d|--dependencies)
                DEPENDENCIES_MODE=true
                shift
                ;;
            -c|--capacity)
                CAPACITY_MODE=true
                shift
                ;;
            -r|--recommendations)
                RECOMMENDATIONS_MODE=true
                shift
                ;;
            --all)
                PERFORMANCE_MODE=true
                SECURITY_MODE=true
                OPTIMIZATION_MODE=true
                DEPENDENCIES_MODE=true
                CAPACITY_MODE=true
                RECOMMENDATIONS_MODE=true
                shift
                ;;
            --json)
                JSON_OUTPUT=true
                shift
                ;;
            --export)
                EXPORT_FILE="$2"
                shift 2
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # If no specific mode selected, run all
    if [[ "$PERFORMANCE_MODE" == "false" && "$SECURITY_MODE" == "false" && \
          "$OPTIMIZATION_MODE" == "false" && "$DEPENDENCIES_MODE" == "false" && \
          "$CAPACITY_MODE" == "false" && "$RECOMMENDATIONS_MODE" == "false" ]]; then
        PERFORMANCE_MODE=true
        SECURITY_MODE=true
        OPTIMIZATION_MODE=true
        DEPENDENCIES_MODE=true
        CAPACITY_MODE=true
        RECOMMENDATIONS_MODE=true
    fi
}

main() {
    parse_args "$@"

    # Setup output redirection if needed
    if [[ -n "$EXPORT_FILE" ]]; then
        exec > >(tee "$EXPORT_FILE")
    fi

    check_prerequisites

    if [[ "$JSON_OUTPUT" != "true" ]]; then
        echo "🔍 Advanced Diagnostics for tf-kube-any-compute"
        echo "=============================================="
        echo "Timestamp: $(date)"
        echo "Cluster: $(kubectl config current-context 2>/dev/null || echo 'unknown')"
        echo ""
    fi

    json_start

    if [[ "$PERFORMANCE_MODE" == "true" ]]; then
        analyze_performance
    fi

    if [[ "$SECURITY_MODE" == "true" ]]; then
        analyze_security
    fi

    if [[ "$OPTIMIZATION_MODE" == "true" ]]; then
        analyze_optimization
    fi

    if [[ "$DEPENDENCIES_MODE" == "true" ]]; then
        analyze_dependencies
    fi

    if [[ "$CAPACITY_MODE" == "true" ]]; then
        analyze_capacity
    fi

    if [[ "$RECOMMENDATIONS_MODE" == "true" ]]; then
        generate_recommendations
    fi

    json_end

    if [[ "$JSON_OUTPUT" != "true" ]]; then
        echo ""
        log "SUCCESS" "Advanced diagnostics completed!"
        if [[ -n "$EXPORT_FILE" ]]; then
            log "INFO" "Results exported to: $EXPORT_FILE"
        fi
    fi
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
