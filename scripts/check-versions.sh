#!/bin/bash
# ============================================================================
# Version Check Script for tf-kube-any-compute
# ============================================================================
# This script checks current versions of all deployed services and compares
# them with the latest available versions.
#
# Usage:
#   ./scripts/check-versions.sh [--check-terraform] [--update-check]
#
# Options:
#   --check-terraform  Check chart versions in terraform.tfvars vs latest
#   --update-check     Check for updates from upstream repositories (requires cluster)
# ============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

CHECK_TERRAFORM=false
UPDATE_CHECK=false
if [[ "$1" == "--check-terraform" ]]; then
  CHECK_TERRAFORM=true
fi
if [[ "$1" == "--update-check" ]] || [[ "$2" == "--update-check" ]]; then
  UPDATE_CHECK=true
fi

echo "=== 🔍 Service Version Check ==="
echo ""

# Add Helm repos if update check is enabled
if [ "$UPDATE_CHECK" = true ]; then
  echo "📥 Adding Helm repositories..."

  # Add standard Helm repos
  helm repo add traefik https://traefik.github.io/charts >/dev/null 2>&1 || true
  helm repo add metallb https://metallb.github.io/metallb >/dev/null 2>&1 || true
  helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null 2>&1 || true
  helm repo add grafana https://grafana.github.io/helm-charts >/dev/null 2>&1 || true
  helm repo add hashicorp https://helm.releases.hashicorp.com >/dev/null 2>&1 || true
  helm repo add portainer https://portainer.github.io/k8s/ >/dev/null 2>&1 || true
  helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/ >/dev/null 2>&1 || true
  helm repo add local-path-provisioner https://charts.containeroo.ch >/dev/null 2>&1 || true
  helm repo add node-feature-discovery https://kubernetes-sigs.github.io/node-feature-discovery/charts >/dev/null 2>&1 || true
  helm repo add schwarzit https://schwarzit.github.io/helm-charts >/dev/null 2>&1 || true

  helm repo update >/dev/null 2>&1
  echo "✅ Helm repositories updated"
  echo ""
fi

# ============================================================================
# Check Terraform.tfvars Chart Versions
# ============================================================================
if [ "$CHECK_TERRAFORM" = true ]; then
  echo "📋 Chart Versions in terraform.tfvars / locals.tf:"
  echo ""

  # Function to get latest version from artifacthub API
  get_latest_artifacthub() {
    local package_name=$1
    local repo_name=$2
    curl -s "https://artifacthub.io/api/v1/packages/helm/${repo_name}/${package_name}" | jq -r '.version' 2>/dev/null || echo "unknown"
  }

  # Function to get latest version from GitHub API (releases)
  get_latest_github_tags() {
    local repo=$1
    curl -s "https://api.github.com/repos/${repo}/releases/latest" | jq -r '.tag_name' 2>/dev/null || echo "unknown"
  }

  # Array of services: name current_version check_function check_args
  services=(
    "Authelia|0.10.49|get_latest_artifacthub|authelia|authelia"
    "Grafana|10.5.15|get_latest_artifacthub|grafana|grafana"
    "Kube State Metrics|7.2.0|get_latest_artifacthub|kube-state-metrics|prometheus-community"
    "Loki|2.33.3|get_latest_artifacthub|loki|grafana"
    "Portainer|2.19.0|get_latest_artifacthub|portainer|portainer"
    "Promtail|0.18.3|get_latest_artifacthub|promtail|grafana"
    "Node-RED|0.35.0|get_latest_artifacthub|node-red-chart|selfhostedpro"
    "Headlamp|0.40.0|get_latest_github_tags|headlamp-k8s|headlamp-k8s"
    "KubeVirt|v1.1.1|get_latest_github_tags|kubevirt|kubevirt"
    "Redis|18.1.4|get_latest_artifacthub|redis|bitnami"
    "NFS CSI|4.0.18|get_latest_artifacthub|nfs-subdir-external-provisioner|kubernetes-sigs-nfs-subdir-external-provisioner"
    "Node Feature Discovery|0.18.3|get_latest_artifacthub|node-feature-discovery|kubernetes-sigs"
    "Longhorn|1.11.0|get_latest_github_tags|longhorn|longhorn"
    "Rook-Ceph|v1.19.2|get_latest_github_tags|rook|rook"
    "Prometheus Stack|82.4.0|get_latest_artifacthub|kube-prometheus-stack|prometheus-community"
    "Traefik|6.46.0|get_latest_artifacthub|traefik|traefik"
    "Vault|6.4.1|get_latest_artifacthub|vault|hashicorp"
    "Consul|6.17.1|get_latest_artifacthub|consul|hashicorp"
    "MetalLB|0.15.3|get_latest_artifacthub|metallb|metallb"
  )

  for service in "${services[@]}"; do
    IFS='|' read -r name current func_name arg1 arg2 <<< "$service"

    echo -e "  ${CYAN}${name}${NC}"
    echo "    Current:  $current"

    if [ "$func_name" = "get_latest_artifacthub" ]; then
      latest=$(get_latest_artifacthub "$arg1" "$arg2")
    else
      latest=$(get_latest_github_tags "$arg1")
    fi

    echo "    Latest:   $latest"

    # Normalize versions for comparison (remove 'v' prefix)
    current_normalized=$(echo "$current" | sed 's/^v//')
    latest_normalized=$(echo "$latest" | sed 's/^v//')

    if [ "$latest_normalized" != "unknown" ]; then
      # Simple version comparison
      if [ "$current_normalized" != "$latest_normalized" ]; then
        echo -e "    ${YELLOW}⬆️ UPDATE AVAILABLE${NC}"
      else
        echo -e "    ${GREEN}✅ UP TO DATE${NC}"
      fi
    else
      echo -e "    ${YELLOW}⚠️  Could not determine latest version${NC}"
    fi
    echo ""
  done
fi

# ============================================================================
# Helm-based Services (Cluster Check)
# ============================================================================
echo "📦 Helm-based Services:"
echo ""

HELM_SERVICES=(
  "prod-traefik-system:traefik:traefik/traefik"
  "prod-metallb-system:metallb:metallb/metallb"
  "prod-prometheus-system:kube-prometheus-stack:prometheus-community/kube-prometheus-stack"
  "prod-grafana-system:grafana:grafana/grafana"
  "prod-consul-system:consul:hashicorp/consul"
  "prod-vault-system:vault:hashicorp/vault"
  "prod-portainer-system:portainer:portainer/portainer"
  "prod-nfs-csi-system:nfs-subdir-external-provisioner:nfs-subdir-external-provisioner/nfs-subdir-external-provisioner"
  "prod-host-path-csi-system:prod-host-path-csi:local-path-provisioner/local-path-provisioner"
  "prod-node-feature-discovery-system:node-feature-discovery:node-feature-discovery/node-feature-discovery"
  "prod-kube-state-metrics-system:kube-state-metrics:prometheus-community/kube-state-metrics"
  "prod-loki-system:loki:grafana/loki"
  "prod-promtail-system:promtail:grafana/promtail"
  "prod-node-red-system:prod-node-red:schwarzit/node-red"
)

for service in "${HELM_SERVICES[@]}"; do
  IFS=':' read -r namespace chart_prefix repo <<< "$service"

  # Get current version
  releases=$(helm list -n "$namespace" -o json 2>/dev/null || echo "[]")
  if [ "$releases" != "[]" ] && [ ! -z "$releases" ]; then
    current_chart=$(echo "$releases" | jq -r '.[0].chart // empty')
    # Extract chart name and version properly
    chart_name=$(echo "$current_chart" | rev | cut -d- -f2- | rev)
    current_version=$(echo "$current_chart" | rev | cut -d- -f1 | rev)
    app_version=$(echo "$releases" | jq -r '.[0].app_version // empty')
    status=$(echo "$releases" | jq -r '.[0].status // empty')

    if [ ! -z "$current_chart" ]; then
      echo -e "  ${BLUE}${chart_name}${NC}"
      echo "    Chart Version: $current_version"
      echo "    App Version:   $app_version"
      echo "    Status:        $status"

      if [ "$UPDATE_CHECK" = true ]; then
        # Check for latest version - search by chart name and filter results
        search_results=$(helm search repo "$repo" --versions 2>/dev/null || echo "")
        if [ ! -z "$search_results" ]; then
          # Try exact match first, then fallback to any match
          latest=$(echo "$search_results" | grep -E "^$repo[[:space:]]" | head -1 | awk '{print $2}')
          if [ -z "$latest" ]; then
            latest=$(echo "$search_results" | grep -v "NAME" | head -1 | awk '{print $2}')
          fi

          if [ ! -z "$latest" ] && [[ "$latest" =~ ^[0-9] ]]; then
            if [ "$latest" != "$current_version" ]; then
              echo -e "    ${YELLOW}Latest:        $latest ⬆️  UPDATE AVAILABLE${NC}"
            else
              echo -e "    ${GREEN}Latest:        $latest ✅ UP TO DATE${NC}"
            fi
          fi
        fi
      fi
      echo ""
    fi
  fi
done

# ============================================================================
# Native Kubernetes Deployments
# ============================================================================
echo "🐳 Native Kubernetes Deployments:"
echo ""

# Home Assistant
echo -e "  ${BLUE}Home Assistant${NC}"
image=$(kubectl get deployment -n prod-home-assistant-system prod-home-assistant -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || echo "Not deployed")
if [ "$image" != "Not deployed" ]; then
  echo "    Image: $image"
  if [[ "$image" == *":latest"* ]]; then
    echo -e "    ${YELLOW}⚠️  Using 'latest' tag - consider pinning to specific version${NC}"
  fi
else
  echo "    Status: Not deployed"
fi
echo ""

# openHAB
echo -e "  ${BLUE}openHAB${NC}"
image=$(kubectl get deployment -n prod-openhab-system prod-openhab -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || echo "Not deployed")
if [ "$image" != "Not deployed" ]; then
  echo "    Image: $image"
  version=$(echo "$image" | cut -d: -f2)
  echo "    Version: $version"
else
  echo "    Status: Not deployed"
fi
echo ""

# Homebridge
echo -e "  ${BLUE}Homebridge${NC}"
image=$(kubectl get deployment -n prod-homebridge-system prod-homebridge -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || echo "Not deployed")
if [ "$image" != "Not deployed" ]; then
  echo "    Image: $image"
  if [[ "$image" == *":latest"* ]]; then
    echo -e "    ${YELLOW}⚠️  Using 'latest' tag - consider pinning to specific version${NC}"
  fi
else
  echo "    Status: Not deployed"
fi
echo ""

# Node-RED
echo -e "  ${BLUE}Node-RED${NC}"
image=$(kubectl get deployment -n prod-node-red-system prod-node-red -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || echo "Not deployed")
if [ "$image" != "Not deployed" ]; then
  echo "    Image: $image"
  if [[ "$image" == *":latest"* ]]; then
    echo -e "    ${YELLOW}⚠️  Using 'latest' tag - consider pinning to specific version${NC}"
  fi
else
  echo "    Status: Not deployed"
fi
echo ""

# n8n
echo -e "  ${BLUE}n8n${NC}"
image=$(kubectl get deployment -n prod-n8n-system prod-n8n -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || echo "Not deployed")
if [ "$image" != "Not deployed" ]; then
  echo "    Image: $image"
  if [[ "$image" == *":latest"* ]]; then
    echo -e "    ${YELLOW}⚠️  Using 'latest' tag - consider pinning to specific version${NC}"
  fi
else
  echo "    Status: Not deployed"
fi
echo ""

# ============================================================================
# Summary
# ============================================================================
echo "=== 📊 Summary ==="
echo ""

# Count services using 'latest' tag
latest_count=$(kubectl get deployments -A -o json 2>/dev/null | jq '[.items[].spec.template.spec.containers[].image | select(contains(":latest"))] | length')
echo "Services using 'latest' tag: $latest_count"

if [ "$latest_count" -gt 0 ]; then
  echo -e "${YELLOW}⚠️  Consider pinning versions for production stability${NC}"
fi

echo ""
echo "=== ✅ Version check complete ==="

if [ "$CHECK_TERRAFORM" = false ] && [ "$UPDATE_CHECK" = false ]; then
  echo ""
  echo "💡 Tips:"
  echo "   --check-terraform  Check chart versions in terraform.tfvars vs latest"
  echo "   --update-check     Check deployed services vs latest (requires cluster)"
fi
