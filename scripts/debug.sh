#!/bin/bash
# ============================================================================
# Debug Script for tf-kube-any-compute Infrastructure
# ============================================================================
#
# This script provides comprehensive diagnostics for deployed infrastructure
# including cluster health, service status, networking, and common issues.
#
# Usage:
#   ./scripts/debug.sh [options]
#
# Options:
#   --quick, -q         Quick health check only
#   --full, -f          Full diagnostic report
#   --service SERVICE   Focus on specific service
#   --network, -n       Network diagnostics only
#   --storage, -s       Storage diagnostics only
#   --output FILE       Save output to file
#   --verbose, -v       Verbose output
#   --help, -h          Show this help
#
# Examples:
#   ./scripts/debug.sh --quick
#   ./scripts/debug.sh --service vault
#   ./scripts/debug.sh --network --output network-debug.log
#
# ============================================================================
#   -h, --help          Show this help message
#   -v, --verbose       Enable verbose output
#   -s, --summary-only  Show only summary information
#   -o, --output FILE   Save output to file
#
# ============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
VERBOSE=false
SUMMARY_ONLY=false
QUICK_MODE=false
FULL_MODE=false
NETWORK_ONLY=false
STORAGE_ONLY=false
SPECIFIC_SERVICE=""
OUTPUT_FILE=""

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -s|--summary-only)
                SUMMARY_ONLY=true
                shift
                ;;
            -q|--quick)
                QUICK_MODE=true
                shift
                ;;
            -f|--full)
                FULL_MODE=true
                shift
                ;;
            -n|--network)
                NETWORK_ONLY=true
                shift
                ;;
            --storage)
                STORAGE_ONLY=true
                shift
                ;;
            --service)
                SPECIFIC_SERVICE="$2"
                shift 2
                ;;
            -o|--output)
                OUTPUT_FILE="$2"
                shift 2
                ;;
            *)
                echo -e "${RED}Unknown option: $1${NC}"
                show_help
                exit 1
                ;;
        esac
    done
}

# Show help message
show_help() {
    cat << EOF
tf-kube-any-compute Cluster Diagnostics

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -h, --help          Show this help message
    -v, --verbose       Enable verbose output
    -s, --summary-only  Show only summary information
    -o, --output FILE   Save output to file

EXAMPLES:
    $0                  # Run full diagnostics
    $0 -s               # Quick summary only
    $0 -v -o debug.log  # Verbose output saved to file

DESCRIPTION:
    This script performs comprehensive diagnostics of your Kubernetes
    infrastructure deployed via tf-kube-any-compute. It checks:
    
    • Cluster connectivity and health
    • Architecture detection and mixed cluster support
    • Service deployment status
    • Storage configuration and PVC health
    • Ingress and networking functionality
    • Resource utilization and limits
    
    The script is safe to run and performs only read-only operations.

EOF
}

# Logging functions
log() {
    local message="$1"
    if [[ -n "$OUTPUT_FILE" ]]; then
        echo "$message" | tee -a "$OUTPUT_FILE"
    else
        echo "$message"
    fi
}

log_section() {
    local title="$1"
    local separator="$(printf '=%.0s' {1..60})"
    log ""
    log -e "${BLUE}$separator${NC}"
    log -e "${BLUE}$title${NC}"
    log -e "${BLUE}$separator${NC}"
}

log_subsection() {
    local title="$1"
    log ""
    log -e "${CYAN}📋 $title${NC}"
    log "----------------------------------------"
}

log_success() {
    log -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    log -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    log -e "${RED}❌ $1${NC}"
}

log_info() {
    log -e "${PURPLE}ℹ️  $1${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check required tools
check_prerequisites() {
    log_section "📋 Prerequisites Check"
    
    local missing_tools=()
    local tools=("kubectl" "terraform" "helm" "jq")
    
    for tool in "${tools[@]}"; do
        if command_exists "$tool"; then
            local version
            case $tool in
                kubectl) version=$(kubectl version --client --short 2>/dev/null | head -1 || echo "Unknown") ;;
                terraform) version=$(terraform version | head -1 || echo "Unknown") ;;
                helm) version=$(helm version --short 2>/dev/null || echo "Unknown") ;;
                jq) version=$(jq --version 2>/dev/null || echo "Unknown") ;;
            esac
            log_success "$tool: $version"
        else
            log_error "$tool: Not found"
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        log_info "Please install missing tools and try again"
        exit 1
    fi
    
    log_success "All required tools are available"
}

# Detect cluster information
detect_cluster_info() {
    log_section "🏗️ Cluster Information"
    
    # Check cluster connectivity
    if ! kubectl cluster-info >/dev/null 2>&1; then
        log_error "Cannot connect to Kubernetes cluster"
        log_info "Please check your kubeconfig and cluster connectivity"
        return 1
    fi
    
    log_success "Cluster connectivity: OK"
    
    # Kubernetes version
    log_subsection "Kubernetes Version"
    local k8s_server_version
    k8s_server_version=$(kubectl version --short 2>/dev/null | grep Server || echo "Server version unavailable")
    log "$k8s_server_version"
    
    # Node information
    log_subsection "Cluster Nodes"
    if kubectl get nodes >/dev/null 2>&1; then
        local node_count
        node_count=$(kubectl get nodes --no-headers | wc -l)
        log "Total nodes: $node_count"
        
        # Node architecture distribution
        log ""
        log "Node Architecture Distribution:"
        kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.nodeInfo.architecture}{"\t"}{.metadata.labels.node-role\.kubernetes\.io/control-plane}{"\t"}{.metadata.labels.node-role\.kubernetes\.io/master}{"\n"}{end}' 2>/dev/null | \
        while IFS=$'\t' read -r name arch control_plane master; do
            local role="worker"
            if [[ "$control_plane" == "" ]] || [[ "$master" == "" ]]; then
                role="control-plane"
            fi
            printf "  %-20s %-10s %-15s\n" "$name" "$arch" "$role"
        done
        
        # Architecture summary
        log ""
        log "Architecture Summary:"
        kubectl get nodes -o jsonpath='{range .items[*]}{.status.nodeInfo.architecture}{"\n"}{end}' 2>/dev/null | \
        sort | uniq -c | while read -r count arch; do
            log "  $arch: $count node(s)"
        done
        
        # Detect mixed cluster
        local unique_archs
        unique_archs=$(kubectl get nodes -o jsonpath='{range .items[*]}{.status.nodeInfo.architecture}{"\n"}{end}' 2>/dev/null | sort -u | wc -l)
        if [[ $unique_archs -gt 1 ]]; then
            log_warning "Mixed architecture cluster detected"
            log_info "Ensure auto_mixed_cluster_mode is enabled in terraform.tfvars"
        else
            log_success "Single architecture cluster"
        fi
    else
        log_error "Cannot retrieve node information"
    fi
}

# Check Terraform state
check_terraform_state() {
    log_section "🏗️ Terraform State"
    
    cd "$PROJECT_DIR" || exit 1
    
    if [[ ! -f "terraform.tfstate" ]]; then
        log_warning "No terraform.tfstate found in $PROJECT_DIR"
        log_info "Infrastructure may not be deployed yet"
        return 0
    fi
    
    log_success "Terraform state file exists"
    
    # Check if terraform state is accessible
    if ! terraform show >/dev/null 2>&1; then
        log_error "Cannot read Terraform state"
        log_info "Try running: terraform init"
        return 1
    fi
    
    # Count resources
    local resource_count
    resource_count=$(terraform show -json 2>/dev/null | jq '.values.root_module.resources | length' 2>/dev/null || echo "0")
    log "Resources in state: $resource_count"
    
    if [[ $VERBOSE == true ]]; then
        log_subsection "Resource Summary"
        terraform show -json 2>/dev/null | jq -r '.values.root_module.resources[] | .type + "." + .name' 2>/dev/null | sort | uniq -c | while read -r count type; do
            printf "  %-30s %s\n" "$type" "$count"
        done
    fi
    
    # Check for terraform outputs
    log_subsection "Terraform Outputs"
    if terraform output >/dev/null 2>&1; then
        if [[ $VERBOSE == true ]]; then
            terraform output 2>/dev/null || log_info "No outputs available"
        else
            local output_count
            output_count=$(terraform output -json 2>/dev/null | jq 'keys | length' 2>/dev/null || echo "0")
            log "Available outputs: $output_count"
        fi
    else
        log_warning "No Terraform outputs available"
    fi
}

# Check Helm deployments
check_helm_deployments() {
    log_section "📦 Helm Deployments"
    
    if ! command_exists helm; then
        log_warning "Helm not available, skipping Helm deployment check"
        return 0
    fi
    
    # List all releases
    log_subsection "All Helm Releases"
    if helm list --all-namespaces >/dev/null 2>&1; then
        local release_count
        release_count=$(helm list --all-namespaces -q | wc -l)
        log "Total Helm releases: $release_count"
        
        if [[ $release_count -gt 0 ]]; then
            helm list --all-namespaces -o table 2>/dev/null
        fi
    else
        log_info "No Helm releases found"
    fi
    
    # Check for failed releases
    log_subsection "Release Health Check"
    local failed_releases
    failed_releases=$(helm list --all-namespaces -f "failed" -q 2>/dev/null || true)
    if [[ -n "$failed_releases" ]]; then
        log_error "Failed releases found:"
        echo "$failed_releases" | while read -r release; do
            log_error "  $release"
        done
        log_info "Check release status with: helm status <release-name> -n <namespace>"
    else
        log_success "No failed Helm releases"
    fi
    
    # Check for pending releases
    local pending_releases
    pending_releases=$(helm list --all-namespaces -f "pending" -q 2>/dev/null || true)
    if [[ -n "$pending_releases" ]]; then
        log_warning "Pending releases found:"
        echo "$pending_releases" | while read -r release; do
            log_warning "  $release"
        done
    fi
}

# Check pod status across key namespaces
check_pod_status() {
    log_section "🚀 Pod Status"
    
    local namespaces=(
        ".*-traefik-ingress"
        ".*-metallb-ingress"
        ".*-monitoring-stack"
        ".*-grafana-system"
        ".*-consul-stack"
        ".*-vault-stack"
        ".*-portainer-system"
        ".*-gatekeeper-system"
        ".*-nfs-csi-system"
        ".*-host-path-csi-system"
        ".*-node-feature-discovery-system"
        ".*-loki-system"
        ".*-promtail-system"
    )
    
    # Get all namespaces matching our patterns
    local found_namespaces=()
    for pattern in "${namespaces[@]}"; do
        while IFS= read -r ns; do
            if [[ "$ns" =~ $pattern ]]; then
                found_namespaces+=("$ns")
            fi
        done < <(kubectl get namespaces -o name 2>/dev/null | sed 's/namespace\///')
    done
    
    # Remove duplicates and sort (compatible with all shells)
    local unique_namespaces
    unique_namespaces=($(printf '%s\n' "${found_namespaces[@]}" | sort -u))
    
    if [[ ${#unique_namespaces[@]} -eq 0 ]]; then
        log_info "No tf-kube-any-compute namespaces found"
        return 0
    fi
    
    for ns in "${unique_namespaces[@]}"; do
        if kubectl get namespace "$ns" >/dev/null 2>&1; then
            log_subsection "Namespace: $ns"
            
            local pod_count
            pod_count=$(kubectl get pods -n "$ns" --no-headers 2>/dev/null | wc -l)
            
            if [[ $pod_count -eq 0 ]]; then
                log_info "No pods found in namespace $ns"
                continue
            fi
            
            kubectl get pods -n "$ns" --no-headers 2>/dev/null | while read -r line; do
                local pod_name status ready restarts age
                read -r pod_name ready status restarts age <<< "$line"
                
                case $status in
                    "Running"|"Completed")
                        if [[ "$ready" == *"/"* ]]; then
                            local ready_count total_count
                            IFS='/' read -r ready_count total_count <<< "$ready"
                            if [[ "$ready_count" == "$total_count" ]]; then
                                log_success "$pod_name ($status, $ready)"
                            else
                                log_warning "$pod_name ($status, $ready) - Not all containers ready"
                            fi
                        else
                            log_success "$pod_name ($status)"
                        fi
                        ;;
                    "Pending"|"ContainerCreating"|"PodInitializing")
                        log_warning "$pod_name ($status) - Starting up"
                        ;;
                    "CrashLoopBackOff"|"Error"|"Failed"|"ImagePullBackOff"|"ErrImagePull")
                        log_error "$pod_name ($status) - Needs attention"
                        if [[ $VERBOSE == true ]]; then
                            log_info "Check logs with: kubectl logs $pod_name -n $ns"
                        fi
                        ;;
                    *)
                        log_warning "$pod_name ($status) - Unknown status"
                        ;;
                esac
            done
        fi
    done
}

# Check storage configuration
check_storage() {
    log_section "💾 Storage Configuration"
    
    # Storage classes
    log_subsection "Storage Classes"
    if kubectl get storageclass >/dev/null 2>&1; then
        kubectl get storageclass -o custom-columns="NAME:.metadata.name,PROVISIONER:.provisioner,DEFAULT:.metadata.annotations.storageclass\.kubernetes\.io/is-default-class" --no-headers 2>/dev/null | while read -r line; do
            local name provisioner default
            read -r name provisioner default <<< "$line"
            
            if [[ "$default" == "true" ]]; then
                log_success "$name (default) - $provisioner"
            else
                log_info "$name - $provisioner"
            fi
        done
    else
        log_warning "No storage classes found"
    fi
    
    # PVC status
    log_subsection "Persistent Volume Claims"
    local pvc_count
    pvc_count=$(kubectl get pvc --all-namespaces --no-headers 2>/dev/null | wc -l)
    
    if [[ $pvc_count -eq 0 ]]; then
        log_info "No PVCs found"
    else
        log "Total PVCs: $pvc_count"
        log ""
        kubectl get pvc --all-namespaces --no-headers 2>/dev/null | while read -r line; do
            local ns name status volume capacity access_modes storage_class age
            read -r ns name status volume capacity access_modes storage_class age <<< "$line"
            
            case $status in
                "Bound")
                    log_success "$ns/$name ($status) - $capacity on $storage_class"
                    ;;
                "Pending")
                    log_warning "$ns/$name ($status) - Waiting for volume"
                    ;;
                "Lost"|"Failed")
                    log_error "$ns/$name ($status) - Volume issue"
                    ;;
                *)
                    log_warning "$ns/$name ($status) - Unknown status"
                    ;;
            esac
        done
    fi
}

# Check ingress and networking
check_networking() {
    log_section "🌐 Networking & Ingress"
    
    # Check for Traefik IngressRoutes
    log_subsection "Traefik Configuration"
    if kubectl get crd ingressroutes.traefik.containo.us >/dev/null 2>&1; then
        log_success "Traefik CRDs installed"
        
        local ingressroute_count
        ingressroute_count=$(kubectl get ingressroutes --all-namespaces --no-headers 2>/dev/null | wc -l)
        log "IngressRoutes: $ingressroute_count"
        
        if [[ $VERBOSE == true && $ingressroute_count -gt 0 ]]; then
            kubectl get ingressroutes --all-namespaces -o custom-columns="NAMESPACE:.metadata.namespace,NAME:.metadata.name,HOSTS:.spec.routes[*].match" --no-headers 2>/dev/null
        fi
    else
        log_warning "Traefik CRDs not found - Traefik may not be deployed"
    fi
    
    # Check services with LoadBalancer type
    log_subsection "LoadBalancer Services"
    local lb_services
    lb_services=$(kubectl get services --all-namespaces --field-selector spec.type=LoadBalancer --no-headers 2>/dev/null | wc -l)
    
    if [[ $lb_services -gt 0 ]]; then
        log "LoadBalancer services: $lb_services"
        kubectl get services --all-namespaces --field-selector spec.type=LoadBalancer -o custom-columns="NAMESPACE:.metadata.namespace,NAME:.metadata.name,EXTERNAL-IP:.status.loadBalancer.ingress[0].ip" --no-headers 2>/dev/null | while read -r line; do
            local ns name external_ip
            read -r ns name external_ip <<< "$line"
            
            if [[ "$external_ip" == "<none>" || -z "$external_ip" ]]; then
                log_warning "$ns/$name - No external IP assigned"
            else
                log_success "$ns/$name - $external_ip"
            fi
        done
    else
        log_info "No LoadBalancer services found"
    fi
}

# Check resource utilization
check_resource_utilization() {
    if [[ $SUMMARY_ONLY == true ]]; then
        return 0
    fi
    
    log_section "📊 Resource Utilization"
    
    # Node resource usage (if metrics-server is available)
    if kubectl top nodes >/dev/null 2>&1; then
        log_subsection "Node Resource Usage"
        kubectl top nodes 2>/dev/null
    else
        log_info "Metrics server not available - cannot show resource usage"
    fi
    
    # Check for resource quotas
    log_subsection "Resource Quotas"
    local quota_count
    quota_count=$(kubectl get resourcequota --all-namespaces --no-headers 2>/dev/null | wc -l)
    
    if [[ $quota_count -gt 0 ]]; then
        log "Resource quotas found: $quota_count"
        if [[ $VERBOSE == true ]]; then
            kubectl get resourcequota --all-namespaces 2>/dev/null
        fi
    else
        log_info "No resource quotas configured"
    fi
}

# Service-specific diagnostics
check_specific_service() {
    local service_name="$1"
    log_section "🔍 SERVICE-SPECIFIC DIAGNOSTICS: $service_name"
    
    # Find namespace containing the service
    local namespace
    namespace=$(kubectl get services --all-namespaces --no-headers 2>/dev/null | grep "$service_name" | head -1 | awk '{print $1}' || echo "")
    
    if [[ -z "$namespace" ]]; then
        log_error "Service $service_name not found in any namespace"
        
        # Try to find similar service names
        log_info "Searching for similar services..."
        kubectl get services --all-namespaces --no-headers 2>/dev/null | grep -i "$service_name" || log_info "No similar services found"
        return 1
    fi
    
    log_success "Found $service_name in namespace: $namespace"
    
    # Service details
    log_subsection "Service Details"
    kubectl describe service "$service_name" -n "$namespace" 2>/dev/null || log_error "Failed to describe service"
    
    # Associated pods
    log_subsection "Associated Pods"
    local selector
    selector=$(kubectl get service "$service_name" -n "$namespace" -o jsonpath='{.spec.selector}' 2>/dev/null || echo "{}")
    
    if [[ "$selector" != "{}" ]]; then
        # Convert JSON selector to label selector format
        local label_selector=""
        if command -v jq >/dev/null 2>&1; then
            label_selector=$(echo "$selector" | jq -r 'to_entries[] | "\(.key)=\(.value)"' 2>/dev/null | tr '\n' ',' | sed 's/,$//')
        else
            # Fallback without jq
            label_selector=$(echo "$selector" | sed 's/[{}"]//g' | sed 's/:/=/g' | tr ',' ' ')
        fi
        
        if [[ -n "$label_selector" ]]; then
            kubectl get pods -n "$namespace" -l "$label_selector" 2>/dev/null || log_warning "Failed to get pods for service"
        fi
    else
        log_warning "Service has no selector - cannot find associated pods"
    fi
    
    # Service endpoints
    log_subsection "Service Endpoints"
    kubectl describe endpoints "$service_name" -n "$namespace" 2>/dev/null || log_warning "Failed to describe endpoints"
    
    # Ingress information if available
    log_subsection "Ingress Configuration"
    local ingresses
    ingresses=$(kubectl get ingress -n "$namespace" --no-headers 2>/dev/null | grep "$service_name" || echo "")
    
    if [[ -n "$ingresses" ]]; then
        log_success "Found ingress configurations:"
        echo "$ingresses"
    else
        log_info "No ingress found for service $service_name"
    fi
}

# Generate comprehensive summary
generate_summary() {
    log_section "📊 Health Summary"
    
    local issues=0
    local warnings=0
    
    # Cluster connectivity
    if ! kubectl cluster-info >/dev/null 2>&1; then
        log_error "Cluster connectivity issues"
        ((issues++))
    else
        log_success "Cluster connectivity: OK"
    fi
    
    # Node health
    local not_ready_nodes
    not_ready_nodes=$(kubectl get nodes --no-headers 2>/dev/null | grep -v " Ready " | wc -l)
    if [[ $not_ready_nodes -gt 0 ]]; then
        log_warning "$not_ready_nodes node(s) not ready"
        ((warnings++))
    else
        log_success "All nodes ready"
    fi
    
    # Failed Helm releases
    if command_exists helm; then
        local failed_helm
        failed_helm=$(helm list --all-namespaces -f "failed" -q 2>/dev/null | wc -l)
        if [[ $failed_helm -gt 0 ]]; then
            log_error "$failed_helm failed Helm release(s)"
            ((issues++))
        else
            log_success "No failed Helm releases"
        fi
    fi
    
    # Unhealthy pods
    local unhealthy_pods
    unhealthy_pods=$(kubectl get pods --all-namespaces --field-selector=status.phase!=Running,status.phase!=Succeeded --no-headers 2>/dev/null | wc -l)
    if [[ $unhealthy_pods -gt 0 ]]; then
        log_warning "$unhealthy_pods pod(s) not in healthy state"
        ((warnings++))
    else
        log_success "All pods healthy"
    fi
    
    # PVC issues
    local pending_pvcs
    pending_pvcs=$(kubectl get pvc --all-namespaces --no-headers 2>/dev/null | grep -c "Pending" || echo "0")
    if [[ $pending_pvcs -gt 0 ]]; then
        log_warning "$pending_pvcs PVC(s) pending"
        ((warnings++))
    fi
    
    # Final summary
    log ""
    log "=================="
    log "FINAL ASSESSMENT"
    log "=================="
    
    if [[ $issues -eq 0 && $warnings -eq 0 ]]; then
        log_success "✨ Cluster is healthy and all services are running well!"
    elif [[ $issues -eq 0 ]]; then
        log_warning "⚡ Cluster is functional with $warnings minor warning(s)"
    else
        log_error "🚨 Found $issues critical issue(s) and $warnings warning(s)"
    fi
    
    log ""
    log_info "💡 Next steps:"
    echo "  • Review any issues or warnings above"
    echo "  • Check specific service logs: kubectl logs -n <namespace> <pod>"
    echo "  • Verify configuration: terraform plan"
    echo "  • Run tests: make test-all"
    echo "  • Check service URLs in terraform outputs"
    
    if [[ -n "$OUTPUT_FILE" ]]; then
        log_info "📁 Full diagnostics saved to: $OUTPUT_FILE"
    fi
}

# Main execution function
main() {
    parse_args "$@"
    
    # Setup output redirection if needed
    if [[ -n "$OUTPUT_FILE" ]]; then
        # Create output file and add header
        cat > "$OUTPUT_FILE" << EOF
tf-kube-any-compute Cluster Diagnostics Report
Generated: $(date)
Command: $0 $*
===============================================

EOF
    fi
    
    log_section "🔍 tf-kube-any-compute Cluster Diagnostics"
    log "Generated: $(date)"
    log "Command: $0 $*"
    
    # Execute diagnostic functions based on mode
    if [[ -n "$SPECIFIC_SERVICE" ]]; then
        # Service-specific diagnostics
        check_prerequisites
        check_specific_service "$SPECIFIC_SERVICE"
    elif [[ "$QUICK_MODE" == "true" ]]; then
        # Quick mode - basic health checks only
        check_prerequisites
        detect_cluster_info
        check_pod_status
        generate_summary
    elif [[ "$NETWORK_ONLY" == "true" ]]; then
        # Network diagnostics only
        check_prerequisites
        detect_cluster_info
        check_networking
    elif [[ "$STORAGE_ONLY" == "true" ]]; then
        # Storage diagnostics only
        check_prerequisites
        detect_cluster_info
        check_storage
    else
        # Standard or full mode
        check_prerequisites
        detect_cluster_info
        
        if [[ "$FULL_MODE" == "true" ]]; then
            check_terraform_state
        fi
        
        check_helm_deployments
        check_pod_status
        check_storage
        check_networking
        
        if [[ $SUMMARY_ONLY == false ]]; then
            check_resource_utilization
        fi
        
        generate_summary
    fi
    
    log ""
    log_info "🎯 Diagnostics complete!"
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
