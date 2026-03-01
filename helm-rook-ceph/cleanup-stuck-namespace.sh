#!/bin/bash
# ============================================================================
# ROOK-CEPH EMERGENCY CLEANUP SCRIPT
# ============================================================================
#
# PURPOSE: Manual emergency cleanup when Terraform destroy gets stuck.
#
# WHEN TO USE:
#   - Namespace stuck in "Terminating" phase after terraform destroy
#   - Finalizers not being removed by Terraform provisioners
#   - Resources left behind after failed Terraform operations
#
# PREREQUISITES:
#   - jq installed (for JSON processing)
#   - kubectl configured with cluster admin access
#   - Run from the helm-rook-ceph module directory
#
# USAGE:
#   ./cleanup-stuck-namespace.sh [workspace_prefix] [namespace]
#
# EXAMPLES:
#   ./cleanup-stuck-namespace.sh prod rook-ceph      # Cleans prod-rook-ceph-system
#   ./cleanup-stuck-namespace.sh sit rook-ceph       # Cleans sit-rook-ceph-system
#   ./cleanup-stuck-namespace.sh "" rook-ceph        # Cleans rook-ceph (no prefix)
#
# WARNING: This script is destructive. It will remove ALL Rook-Ceph resources
# in the specified namespace, including data.
# ============================================================================

set -e

# Configuration
WORKSPACE_PREFIX="${1:-}"
NAMESPACE="${2:-rook-ceph}"
CI_MODE="${CI_MODE:-false}"

# Workspace-aware kubeconfig detection (matches main provider.tf logic)
if [ "$CI_MODE" = "true" ]; then
  KUBECONFIG="${KUBECONFIG:-}"
elif [ -n "$WORKSPACE_PREFIX" ]; then
  KUBECONFIG="$HOME/.kube/${WORKSPACE_PREFIX}-config"
else
  KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"
fi
export KUBECONFIG

# Calculate full namespace name
if [ -n "$WORKSPACE_PREFIX" ] && [ "$WORKSPACE_PREFIX" != "prod" ]; then
  FULL_NAMESPACE="${WORKSPACE_PREFIX}-${NAMESPACE}"
else
  FULL_NAMESPACE="$NAMESPACE"
fi

echo "========================================"
echo "ROOK-CEPH EMERGENCY CLEANUP"
echo "========================================"
echo "Workspace prefix: ${WORKSPACE_PREFIX:-none}"
echo "Namespace:        ${FULL_NAMESPACE}"
echo "Kubeconfig:       ${KUBECONFIG}"
echo ""
echo "⚠️  WARNING: This will DELETE ALL Rook-Ceph data!"
echo "Press Ctrl+C to abort, or wait 5 seconds..."
sleep 5
echo ""

# Verify namespace exists
if ! kubectl get namespace "${FULL_NAMESPACE}" 2>/dev/null; then
  echo "✓ Namespace ${FULL_NAMESPACE} does not exist. Nothing to clean up."
  exit 0
fi

# Check namespace status
NAMESPACE_STATUS=$(kubectl get namespace "${FULL_NAMESPACE}" -o jsonpath='{.status.phase}' 2>/dev/null || echo "Unknown")
echo "Namespace status: ${NAMESPACE_STATUS}"

# STEP 1: Delete webhooks FIRST
echo ""
echo "[1/7] Deleting admission webhooks..."
kubectl delete mutatingwebhookconfiguration,validatingwebhookconfiguration -l app.kubernetes.io/name=rook-ceph --ignore-not-found=true --timeout=30s 2>/dev/null || true
kubectl delete validatingwebhookconfiguration -l app=rook-ceph-operator --ignore-not-found=true --timeout=30s 2>/dev/null || true
echo "✓ Webhooks deleted"

# STEP 2: Discover and delete all Ceph custom resources
echo ""
echo "[2/7] Discovering and deleting Ceph custom resources..."
kubectl get crd -o name 2>/dev/null | grep -E "(ceph.rook.io|objectbucket.io|csi.ceph.io)" | while read -r crd; do
  resource_type=$(echo "$crd" | sed 's/.*\///')
  echo "  - Processing ${resource_type}..."

  crd_scope=$(kubectl get "$crd" -o jsonpath='{.spec.scope}' 2>/dev/null || echo "Namespaced")
  if [[ "$crd_scope" != "Namespaced" ]]; then
    echo "    (cluster-scoped, skipping)"
    continue
  fi

  kubectl get "${resource_type}" -n "${FULL_NAMESPACE}" -o name 2>/dev/null | while read -r res; do
    echo "    - Removing finalizers from ${res}"
    kubectl patch -n "${FULL_NAMESPACE}" "${res}" -p '{"metadata":{"finalizers":[]}}' --type=merge 2>/dev/null || true
  done
  kubectl delete "${resource_type}" -n "${FULL_NAMESPACE}" --all --ignore-not-found=true --timeout=60s 2>/dev/null || true
done
echo "✓ Ceph custom resources deleted"

# STEP 3: Delete PVCs and PVs
echo ""
echo "[3/7] Deleting PVCs and PVs..."
kubectl delete pvc -n "${FULL_NAMESPACE}" --all --ignore-not-found=true --timeout=60s 2>/dev/null || true
for pv in $(kubectl get pv -o name 2>/dev/null | grep -E 'ceph|rbd' || true); do
  echo "  - Removing finalizers from ${pv}"
  kubectl patch "${pv}" -p '{"metadata":{"finalizers":null}}' --type=merge 2>/dev/null || true
  kubectl delete "${pv}" --ignore-not-found=true --timeout=30s 2>/dev/null || true
done
echo "✓ PVCs and PVs deleted"

# STEP 4: Delete workloads
echo ""
echo "[4/7] Deleting workloads..."
kubectl delete deployment,daemonset,statefulset -n "${FULL_NAMESPACE}" --all --force --grace-period=0 --ignore-not-found=true --timeout=60s 2>/dev/null || true
kubectl delete pods -n "${FULL_NAMESPACE}" --all --force --grace-period=0 --ignore-not-found=true --timeout=60s 2>/dev/null || true
echo "✓ Workloads deleted"

# STEP 5: Delete CSI drivers
echo ""
echo "[5/7] Deleting CSI drivers..."
kubectl delete csidriver -l operator=rook --ignore-not-found=true --timeout=30s 2>/dev/null || true
kubectl delete csidriver rbd.csi.ceph.com cephfs.csi.ceph.com --ignore-not-found=true --timeout=30s 2>/dev/null || true
echo "✓ CSI drivers deleted"

# STEP 6: Delete storage classes
echo ""
echo "[6/7] Deleting Ceph storage classes..."
for sc in $(kubectl get storageclass -o name 2>/dev/null | grep -E "(ceph.rook|rook-)" || true); do
  kubectl patch "${sc}" -p '{"metadata":{"finalizers":[]}}' --type=merge 2>/dev/null || true
  kubectl delete "${sc}" --ignore-not-found=true --timeout=30s 2>/dev/null || true
done
echo "✓ Storage classes deleted"

# STEP 7: Remove disaster-protection finalizers from ConfigMaps and Secrets
echo ""
echo "[7/7] Removing disaster-protection finalizers..."
for resource in $(kubectl get configmap,secret -n "${FULL_NAMESPACE}" -o name 2>/dev/null); do
  if kubectl get "$resource" -n "${FULL_NAMESPACE}" -o jsonpath='{.metadata.finalizers}' 2>/dev/null | grep -q "disaster-protection"; then
    echo "  - Removing finalizer from ${resource}"
    kubectl patch "$resource" -n "${FULL_NAMESPACE}" -p '{"metadata":{"finalizers":[]}}' --type=merge 2>/dev/null || true
  fi
done
echo "✓ Disaster-protection finalizers removed"

# Force remove namespace finalizers if stuck
echo ""
if kubectl get namespace "${FULL_NAMESPACE}" 2>/dev/null | grep -q Terminating; then
  echo "Namespace stuck in Terminating, removing finalizers..."
  kubectl get namespace "${FULL_NAMESPACE}" -o json | \
    jq 'del(.spec.finalizers)' | \
    kubectl replace --raw "/api/v1/namespaces/${FULL_NAMESPACE}/finalize" -f - 2>/dev/null || true
fi

# Wait for namespace deletion
echo ""
echo "Waiting for namespace deletion (timeout: 180s)..."
timeout 180 bash -c "while kubectl get namespace ${FULL_NAMESPACE} 2>/dev/null; do sleep 2; done" 2>/dev/null || true

# Final check
echo ""
echo "========================================"
if kubectl get namespace "${FULL_NAMESPACE}" 2>/dev/null; then
  echo "⚠ WARNING: Namespace ${FULL_NAMESPACE} still exists"
  echo "Status: $(kubectl get namespace "${FULL_NAMESPACE}" -o jsonpath='{.status.phase}')"
  echo ""
  echo "Manual intervention may be required:"
  echo "  kubectl edit namespace ${FULL_NAMESPACE}"
  echo "  # Remove all finalizers from the spec"
else
  echo "✓ Namespace ${FULL_NAMESPACE} cleanup completed successfully."
fi
echo "========================================"
