#!/bin/bash

# 🚀 Helm Repository Setup Script for tf-kube-any-compute
# This script automatically adds and updates all Helm repositories used by the project

set -eo pipefail  # Exit on error, pipe failures

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TIMEOUT=${HELM_TIMEOUT:-300}
VERBOSE=${VERBOSE:-false}

# Helm repositories used in this project
# Extracted from Terraform module variable defaults
declare -A HELM_REPOSITORIES=(
    ["prometheus-community"]="https://prometheus-community.github.io/helm-charts"
    ["grafana"]="https://grafana.github.io/helm-charts"
    ["traefik"]="https://helm.traefik.io/traefik"
    ["metallb"]="https://metallb.github.io/metallb"
    ["gatekeeper"]="https://open-policy-agent.github.io/gatekeeper/charts"
    ["nfs-subdir-external-provisioner"]="https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/"
    ["node-feature-discovery"]="https://kubernetes-sigs.github.io/node-feature-discovery/charts"
    ["hashicorp"]="https://helm.releases.hashicorp.com"
    ["portainer"]="https://portainer.github.io/k8s/"
    ["containeroo"]="https://charts.containeroo.ch"
)

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to print verbose output
print_verbose() {
    if [ "$VERBOSE" = "true" ]; then
        print_status "$BLUE" "🔍 VERBOSE: $1"
    fi
}

# Function to check if helm is installed
check_helm_installed() {
    print_status "$BLUE" "🔍 Checking Helm installation..."

    if ! command -v helm &> /dev/null; then
        print_status "$RED" "❌ Helm is not installed or not in PATH"
        print_status "$YELLOW" "💡 Please install Helm: https://helm.sh/docs/intro/install/"
        exit 1
    fi

    local helm_version
    helm_version=$(helm version --short --client 2>/dev/null || echo "unknown")
    print_status "$GREEN" "✅ Helm found: $helm_version"
}

# Function to check network connectivity
check_network_connectivity() {
    print_status "$BLUE" "🌐 Checking network connectivity..."

    # Test basic connectivity
    if ! ping -c 1 -W 5 8.8.8.8 &>/dev/null; then
        print_status "$YELLOW" "⚠️  Warning: No internet connectivity detected"
        print_status "$YELLOW" "   This may cause repository additions to fail"
        return 1
    fi

    print_status "$GREEN" "✅ Network connectivity confirmed"
    return 0
}

# Function to add a single repository
add_repository() {
    local repo_name=$1
    local repo_url=$2
    local description=$3
    local retry_count=0
    local max_retries=3

    print_status "$BLUE" "📦 Adding repository: $repo_name"
    print_verbose "   URL: $repo_url"
    print_verbose "   Description: $description"

    while [ $retry_count -lt $max_retries ]; do
        if helm repo list 2>/dev/null | grep -q "^$repo_name"; then
            print_verbose "   Repository already exists, updating..."
            if helm repo update "$repo_name" --timeout="${TIMEOUT}s" &>/dev/null; then
                print_status "$GREEN" "   ✅ Repository updated: $repo_name"
                return 0
            else
                print_status "$YELLOW" "   ⚠️  Failed to update repository: $repo_name (attempt $((retry_count + 1)))"
            fi
        else
            print_verbose "   Adding new repository..."
            if helm repo add "$repo_name" "$repo_url" --timeout="${TIMEOUT}s" &>/dev/null; then
                print_status "$GREEN" "   ✅ Repository added: $repo_name"
                return 0
            else
                print_status "$YELLOW" "   ⚠️  Failed to add repository: $repo_name (attempt $((retry_count + 1)))"
            fi
        fi

        retry_count=$((retry_count + 1))
        if [ $retry_count -lt $max_retries ]; then
            print_verbose "   Retrying in 2 seconds..."
            sleep 2
        fi
    done

    print_status "$RED" "   ❌ Failed to add/update repository after $max_retries attempts: $repo_name"
    return 1
}

# Function to verify repository accessibility
verify_repository() {
    local repo_name=$1
    local expected_charts=$2

    print_verbose "Verifying repository: $repo_name"

    # Try to search for expected charts
    IFS=',' read -ra CHARTS <<< "$expected_charts"
    for chart in "${CHARTS[@]}"; do
        if helm search repo "$repo_name/$chart" --max-col-width=0 2>/dev/null | grep -q "$repo_name/$chart"; then
            print_verbose "   ✅ Chart found: $repo_name/$chart"
        else
            print_status "$YELLOW" "   ⚠️  Chart not found: $repo_name/$chart"
            return 1
        fi
    done

    return 0
}

# Function to update all repositories
update_all_repositories() {
    print_status "$BLUE" "🔄 Updating all Helm repositories..."

    if helm repo update --timeout="${TIMEOUT}s"; then
        print_status "$GREEN" "✅ All repositories updated successfully"
    else
        print_status "$YELLOW" "⚠️  Some repositories failed to update"
        return 1
    fi
}

# Function to list current repositories
list_repositories() {
    print_status "$BLUE" "📋 Current Helm repositories:"

    if helm repo list &>/dev/null; then
        helm repo list | while IFS= read -r line; do
            print_status "$NC" "   $line"
        done
    else
        print_status "$YELLOW" "   No repositories configured"
    fi
}

# Function to validate service charts
validate_service_charts() {
    print_status "$BLUE" "🧪 Validating service charts..."

    local validation_map=(
        "traefik|traefik"
        "prometheus-community|kube-prometheus-stack,prometheus"
        "grafana|grafana,loki"
        "hashicorp|vault,consul"
        "portainer|portainer"
        "metallb|metallb"
        "csi-driver-nfs|csi-driver-nfs"
        "gatekeeper|gatekeeper"
        "node-feature-discovery|node-feature-discovery"
    )

    local failed_validations=0

    for validation in "${validation_map[@]}"; do
        IFS='|' read -r repo_name expected_charts <<< "$validation"
        if ! verify_repository "$repo_name" "$expected_charts"; then
            failed_validations=$((failed_validations + 1))
        fi
    done

    if [ $failed_validations -eq 0 ]; then
        print_status "$GREEN" "✅ All service charts validated successfully"
    else
        print_status "$YELLOW" "⚠️  $failed_validations validation(s) failed"
    fi
}

# Function to clean up failed repositories
cleanup_failed_repositories() {
    print_status "$BLUE" "🧹 Cleaning up failed repositories..."

    local cleanup_count=0

    for repo_info in "${HELM_REPOSITORIES[@]}"; do
        IFS='|' read -r repo_name repo_url description <<< "$repo_info"

        # Check if repository exists but is not accessible
        if helm repo list 2>/dev/null | grep -q "^$repo_name"; then
            if ! helm search repo "$repo_name/" --max-col-width=0 &>/dev/null; then
                print_status "$YELLOW" "🗑️  Removing failed repository: $repo_name"
                helm repo remove "$repo_name" &>/dev/null || true
                cleanup_count=$((cleanup_count + 1))
            fi
        fi
    done

    if [ $cleanup_count -gt 0 ]; then
        print_status "$GREEN" "✅ Cleaned up $cleanup_count failed repositories"
    else
        print_status "$GREEN" "✅ No cleanup needed"
    fi
}

# Main execution function
main() {
    print_status "$GREEN" "🚀 tf-kube-any-compute Helm Repository Setup"
    print_status "$NC" "================================================"

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -t|--timeout)
                TIMEOUT="$2"
                shift 2
                ;;
            --cleanup)
                cleanup_failed_repositories
                exit 0
                ;;
            --list)
                list_repositories
                exit 0
                ;;
            --validate)
                validate_service_charts
                exit 0
                ;;
            -h|--help)
                echo "Usage: $0 [OPTIONS]"
                echo "Options:"
                echo "  -v, --verbose     Enable verbose output"
                echo "  -t, --timeout N   Set timeout in seconds (default: 300)"
                echo "  --cleanup         Clean up failed repositories"
                echo "  --list            List current repositories"
                echo "  --validate        Validate service charts"
                echo "  -h, --help        Show this help message"
                exit 0
                ;;
            *)
                print_status "$RED" "❌ Unknown option: $1"
                print_status "$YELLOW" "💡 Use --help for usage information"
                exit 1
                ;;
        esac
    done

    # Pre-flight checks
    check_helm_installed
    check_network_connectivity

    # Add repositories
    print_status "$BLUE" "📦 Adding Helm repositories..."
    local failed_repos=0
    local total_repos=${#HELM_REPOSITORIES[@]}

    for repo_info in "${HELM_REPOSITORIES[@]}"; do
        IFS='|' read -r repo_name repo_url description <<< "$repo_info"

        if ! add_repository "$repo_name" "$repo_url" "$description"; then
            failed_repos=$((failed_repos + 1))
        fi
    done

    # Update all repositories
    if ! update_all_repositories; then
        print_status "$YELLOW" "⚠️  Repository update had issues"
    fi

    # Final status
    print_status "$NC" "================================================"

    if [ $failed_repos -eq 0 ]; then
        print_status "$GREEN" "🎉 SUCCESS: All $total_repos repositories configured successfully!"
        print_status "$GREEN" "✅ Ready to run: terraform apply"
    else
        print_status "$YELLOW" "⚠️  PARTIAL SUCCESS: $((total_repos - failed_repos))/$total_repos repositories configured"
        print_status "$YELLOW" "💡 You may need to disable failed services in terraform.tfvars"
    fi

    # Validation
    if [ "$VERBOSE" = "true" ]; then
        validate_service_charts
        list_repositories
    fi

    print_status "$BLUE" "💡 Next steps:"
    print_status "$NC" "   1. Review any warnings above"
    print_status "$NC" "   2. Run: terraform init"
    print_status "$NC" "   3. Run: terraform plan"
    print_status "$NC" "   4. Run: terraform apply"
}

# Execute main function with all arguments
main "$@"
