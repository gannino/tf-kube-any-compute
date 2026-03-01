#!/bin/bash
set -euo pipefail

echo "🔧 Cleaning up stuck Longhorn resources..."
echo ""

# Remove finalizers from Longhorn CRDs
echo "🔗 Removing finalizers from Longhorn CRDs..."
kubectl get crd -o name 2>/dev/null | grep longhorn.io | while read crd; do
  kubectl patch "$crd" -p '{"metadata":{"finalizers":[]}}' --type=merge 2>/dev/null || true
done
echo "  ✓ CRD finalizers removed"
echo ""

# Remove finalizers from Longhorn namespace
echo "🔗 Removing finalizers from Longhorn namespace..."
for ns in prod-longhorn-system longhorn-system; do
  kubectl patch ns "$ns" -p '{"metadata":{"finalizers":[]}}' --type=merge 2>/dev/null || true
done
echo "  ✓ Namespace finalizers removed"
echo ""

# Delete stuck Longhorn resources
echo "🗑️  Deleting stuck Longhorn resources..."
kubectl delete crd $(kubectl get crd -o name 2>/dev/null | grep longhorn.io | sed 's|customresourcedefinitions.apiextensions.k8s.io/||' | tr '\n' ' ') --ignore-not-found=true 2>/dev/null || true
echo "  ✓ CRDs deleted"
echo ""

# Delete storage classes
echo "🗑️  Deleting Longhorn storage classes..."
for sc in $(kubectl get storageclass -o name 2>/dev/null | grep longhorn || true); do
  echo "  - Removing finalizers from $sc..."
  kubectl patch "$sc" -p '{"metadata":{"finalizers":[]}}' --type=merge 2>/dev/null || true
  kubectl delete "$sc" --ignore-not-found=true --timeout=30s 2>/dev/null || true
done
echo "  ✓ Storage classes deleted (including finalizers)"
echo ""

# Delete CSI driver
echo "🗑️  Deleting Longhorn CSI driver..."
kubectl delete csidriver driver.longhorn.io --ignore-not-found=true --timeout=30s 2>/dev/null || true
echo "  ✓ CSI driver deleted"
echo ""

# Delete namespaces
echo "🗑️  Deleting Longhorn namespaces..."
for ns in prod-longhorn-system longhorn-system; do
  kubectl delete ns "$ns" --ignore-not-found=true 2>/dev/null || true
done
echo "  ✓ Namespaces deleted"
echo ""

echo "✅ Longhorn cleanup complete!"
echo ""
echo "Next steps:"
echo "  1. Run: terraform destroy -target=module.longhorn"
echo "  2. Run: terraform apply"
