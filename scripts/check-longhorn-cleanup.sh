#!/bin/bash
set -euo pipefail

echo "🔍 Checking for Longhorn leftover resources..."
echo ""

# Check namespaces
echo "📦 Longhorn Namespaces:"
kubectl get ns | grep -i longhorn || echo "  ✓ No longhorn namespaces found"
echo ""

# Check Longhorn CRDs
echo "📋 Longhorn CRDs:"
kubectl get crd | grep -i longhorn || echo "  ✓ No longhorn CRDs found"
echo ""

# Check storage classes
echo "💾 Storage Classes:"
kubectl get sc | grep -i longhorn || echo "  ✓ No longhorn storage classes found"
echo ""

# Check PVs
echo "📁 Persistent Volumes (Longhorn):"
kubectl get pv | grep -i longhorn || echo "  ✓ No longhorn PVs found"
echo ""

# Check PVCs across all namespaces
echo "📂 Persistent Volume Claims (Longhorn):"
kubectl get pvc -A | grep -i longhorn || echo "  ✓ No longhorn PVCs found"
echo ""

# Check for Longhorn resources in all namespaces
echo "🔎 Longhorn Resources (all namespaces):"
for resource in volumeattachments volumes replicas engines nodes instancemanagers backingimages backuptargets; do
  count=$(kubectl get $resource -A 2>/dev/null | wc -l)
  if [ $count -gt 1 ]; then
    echo "  ⚠️  Found $resource:"
    kubectl get $resource -A 2>/dev/null | tail -n +2 | head -5
  fi
done
echo ""

# Check for Longhorn finalizers
echo "🔗 Checking for Longhorn finalizers on PVs:"
kubectl get pv -o json | jq '.items[] | select(.metadata.finalizers[]? | contains("longhorn")) | .metadata.name' 2>/dev/null || echo "  ✓ No longhorn finalizers found"
echo ""

# Check for stuck resources
echo "⏳ Checking for stuck/terminating resources:"
kubectl get all -A --field-selector=status.phase=Terminating 2>/dev/null | grep -i longhorn || echo "  ✓ No stuck longhorn resources"
echo ""

echo "✅ Longhorn cleanup inspection complete!"
