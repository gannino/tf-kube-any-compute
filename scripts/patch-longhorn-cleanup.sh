#!/bin/bash
set -euo pipefail

echo "🔧 Patching Longhorn leftover resources..."
echo ""

# Remove finalizers from CRDs
echo "🔗 Removing finalizers from Longhorn CRDs..."
kubectl get crd -o name | grep longhorn.io | while read crd; do
  kubectl patch "$crd" -p '{"metadata":{"finalizers":[]}}' --type=merge 2>/dev/null || true
done
echo "  ✓ CRD finalizers removed"
echo ""

# Remove finalizers from namespace
echo "🔗 Removing finalizers from prod-longhorn-system namespace..."
kubectl patch ns prod-longhorn-system -p '{"metadata":{"finalizers":[]}}' --type=merge 2>/dev/null || true
echo "  ✓ Namespace finalizers removed"
echo ""

# Delete CRDs
echo "🗑️  Deleting Longhorn CRDs..."
kubectl delete crd $(kubectl get crd -o name | grep longhorn.io | sed 's|customresourcedefinitions.apiextensions.k8s.io/||' | tr '\n' ' ') --ignore-not-found=true 2>/dev/null || true
echo "  ✓ CRDs deleted"
echo ""

# Delete storage classes
echo "🗑️  Deleting Longhorn storage classes..."
kubectl delete sc longhorn longhorn-static --ignore-not-found=true 2>/dev/null || true
echo "  ✓ Storage classes deleted"
echo ""

# Delete namespace
echo "🗑️  Deleting prod-longhorn-system namespace..."
kubectl delete ns prod-longhorn-system --ignore-not-found=true 2>/dev/null || true
echo "  ✓ Namespace deleted"
echo ""

echo "✅ Longhorn cleanup patching complete!"
echo ""
echo "Verifying cleanup..."
./scripts/check-longhorn-cleanup.sh
