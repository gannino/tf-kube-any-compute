#!/bin/bash
# ============================================================================
# Version Check Script for tf-kube-any-compute
# ============================================================================
# This script checks current versions of all deployed services and compares
# them with the latest available versions.
#
# Usage:
#   ./scripts/check-versions.sh [--update-check]
#
# Options:
#   --update-check    Check for updates from upstream repositories
# ============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

UPDATE_CHECK=false
if [[ "$1" == "--update-check" ]]; then
  UPDATE_CHECK=true
fi

echo "=== 🔍 Service Version Check ==="
echo ""

# Add Helm repos if update check is enabled
if [ "$UPDATE_CHECK" = true ]; then
  echo "📥 Adding Helm repositories..."
  helm repo add traefik https://traefik.github.io/charts >/dev/null 2>&1 || true
  helm repo add metallb https://metallb.github.io/metallb >/dev/null 2>&1 || true
  helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null 2>&1 || true
  helm repo add grafana https://grafana.github.io/helm-charts >/dev/null 2>&1 || true
  helm repo add hashicorp https://helm.releases.hashicorp.com >/dev/null 2>&1 || true
  helm repo add portainer https://portainer.github.io/k8s/ >/dev/null 2>&1 || true
  helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/ >/dev/null 2>&1 || true
  helm repo add local-path-provisioner https://rancher.github.io/local-path-provisioner >/dev/null 2>&1 || true
  helm repo add node-feature-discovery https://kubernetes-sigs.github.io/node-feature-discovery/charts >/dev/null 2>&1 || true
  helm repo add k8s-at-home https://k8s-at-home.com/charts/ >/dev/null 2>&1 || true
  helm repo update >/dev/null 2>&1
  echo "✅ Helm repositories updated"
  echo ""
fi

# ============================================================================
# Helm-based Services
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
  "prod-host-path-csi-system:local-path-provisioner:local-path-provisioner/local-path-provisioner"
  "prod-node-feature-discovery-system:node-feature-discovery:node-feature-discovery/node-feature-discovery"
  "prod-kube-state-metrics-system:kube-state-metrics:prometheus-community/kube-state-metrics"
  "prod-loki-system:loki:grafana/loki"
  "prod-promtail-system:promtail:grafana/promtail"
  "prod-node-red-system:node-red:k8s-at-home/node-red"
)

for service in "${HELM_SERVICES[@]}"; do
  IFS=':' read -r namespace chart_prefix repo <<< "$service"

  # Get current version
  releases=$(helm list -n "$namespace" -o json 2>/dev/null || echo "[]")
  if [ "$releases" != "[]" ] && [ ! -z "$releases" ]; then
    current_chart=$(echo "$releases" | jq -r '.[0].chart // empty')
    current_version=$(echo "$releases" | jq -r '.[0].chart // empty' | sed "s/${chart_prefix}-//")
    app_version=$(echo "$releases" | jq -r '.[0].app_version // empty')
    status=$(echo "$releases" | jq -r '.[0].status // empty')

    if [ ! -z "$current_chart" ]; then
      echo -e "  ${BLUE}${chart_prefix}${NC}"
      echo "    Chart Version: $current_version"
      echo "    App Version:   $app_version"
      echo "    Status:        $status"

      if [ "$UPDATE_CHECK" = true ]; then
        # Check for latest version
        latest=$(helm search repo "$repo" 2>/dev/null | grep -v "NAME" | head -1 | awk '{print $2}' || echo "N/A")
        if [ "$latest" != "N/A" ] && [ ! -z "$latest" ]; then
          if [ "$latest" != "$current_version" ]; then
            echo -e "    ${YELLOW}Latest:        $latest ⬆️  UPDATE AVAILABLE${NC}"
          else
            echo -e "    ${GREEN}Latest:        $latest ✅ UP TO DATE${NC}"
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

if [ "$UPDATE_CHECK" = false ]; then
  echo ""
  echo "💡 Tip: Run with --update-check to compare with latest available versions"
  echo "   (requires helm repos to be configured)"
fi
