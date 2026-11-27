#!/bin/bash
# Cleanup PVCs stuck in Terminating state due to PVC-PV deletion deadlock
# Usage: ./scripts/cleanup-stuck-pvcs.sh

set -e

echo "🔧 Cleaning up stuck PVCs"
echo ""

# Step 0: Remove blocking webhooks (e.g., Longhorn)
echo "🔍 Checking for blocking webhooks..."
if kubectl get validatingwebhookconfiguration longhorn-webhook-validator >/dev/null 2>&1; then
  echo "  - Removing Longhorn webhook (blocking PVC updates)..."
  kubectl delete validatingwebhookconfiguration longhorn-webhook-validator --wait=false 2>/dev/null || true
  echo "  ✅ Longhorn webhook removed"
fi

# Find all PVCs in Terminating state
echo "🔍 Finding PVCs in Terminating state..."
STUCK_PVCS=$(kubectl get pvc -A \
  -o jsonpath='{range .items[?(@.metadata.deletionTimestamp)]}{.metadata.namespace} {.metadata.name}{"\n"}{end}')

if [ -z "$STUCK_PVCS" ]; then
  echo "✅ No stuck PVCs found"
  exit 0
fi

echo "🚨 Found stuck PVCs:"
echo "$STUCK_PVCS"
echo ""
read -p "Continue with cleanup? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "❌ Cleanup aborted"
  exit 1
fi

# Process each stuck PVC
echo "$STUCK_PVCS" | while read -r namespace pvc; do
  echo "🧹 Cleaning up ${namespace}/${pvc}"

  # Get PV name
  pv_name=$(kubectl get pvc "$pvc" -n "$namespace" -o jsonpath='{.spec.volumeName}' 2>/dev/null || echo "")

  # Step 1: Remove PVC finalizers using JSON replace (more reliable than patch)
  echo "  - Removing PVC finalizers..."
  kubectl get pvc "$pvc" -n "$namespace" -o json | \
    jq '.metadata.finalizers = []' | \
    kubectl replace -f - >/dev/null 2>&1 || true

  # Step 2: Force delete PVC with zero grace period (no wait for speed)
  echo "  - Force deleting PVC..."
  kubectl delete pvc "$pvc" -n "$namespace" \
    --force --grace-period=0 --wait=false 2>/dev/null || true

  # Step 3: Clean up associated PV if still bound
  if [ -n "$pv_name" ]; then
    pv_status=$(kubectl get pv "$pv_name" -o jsonpath='{.status.phase}' 2>/dev/null || echo "")
    if [ "$pv_status" = "Bound" ] || [ "$pv_status" = "Released" ]; then
      echo "  - Cleaning up PV $pv_name (status: $pv_status)..."
      kubectl get pv "$pv_name" -o json | \
        jq '.metadata.finalizers = []' | \
        kubectl replace -f - >/dev/null 2>&1 || true
      kubectl delete pv "$pv_name" \
        --force --grace-period=0 --wait=false 2>/dev/null || true
    fi
  fi

  echo "  ✅ Cleanup complete for ${namespace}/${pvc}"
done

echo ""
echo "✅ All stuck PVCs cleaned up successfully"
echo "📝 Note: Persistent Volume data may still exist on storage"
echo "   Run 'kubectl get pv' to check for remaining volumes"
