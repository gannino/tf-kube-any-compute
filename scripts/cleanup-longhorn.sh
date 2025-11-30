#!/bin/bash
set -e

NAMESPACE="prod-longhorn-system"

echo "🧹 Comprehensive Longhorn Cleanup Script"
echo "========================================"

# 1. Check if namespace exists
if ! kubectl get namespace $NAMESPACE &>/dev/null; then
  echo "✅ Namespace $NAMESPACE does not exist. Nothing to clean up."
  exit 0
fi

echo "📊 Current Longhorn resources:"
kubectl get all -n $NAMESPACE 2>/dev/null || true

# 2. Delete all Longhorn workloads first
echo "
🛑 Stopping Longhorn workloads..."
kubectl delete deployment,daemonset,statefulset -n $NAMESPACE --all --force --grace-period=0 2>/dev/null || true

# 3. Delete all pods
echo "🗑️ Deleting all pods..."
kubectl delete pods -n $NAMESPACE --all --force --grace-period=0 2>/dev/null || true

# 4. Remove finalizers from all Longhorn custom resources
echo "
🔧 Removing finalizers from Longhorn custom resources..."
for resource in volumes engines replicas nodes engineimages instancemanagers sharemanagers backingimages backingimagemanagers backingimagedata backups backupvolumes backuptargets recurringjobs orphans snapshots supportbundles systembackups systemrestores volumeattachments; do
  echo "  - Processing $resource..."
  kubectl get $resource.longhorn.io -n $NAMESPACE -o name 2>/dev/null | while read res; do
    kubectl patch -n $NAMESPACE $res -p '{"metadata":{"finalizers":[]}}' --type=merge 2>/dev/null || true
  done
done

# 5. Delete all Longhorn custom resources
echo "
🗑️ Deleting Longhorn custom resources..."
for resource in volumes engines replicas nodes engineimages instancemanagers sharemanagers backingimages backingimagemanagers backingimagedata backups backupvolumes backuptargets recurringjobs orphans snapshots supportbundles systembackups systemrestores volumeattachments; do
  kubectl delete $resource.longhorn.io -n $NAMESPACE --all --ignore-not-found=true 2>/dev/null || true
done

# 6. Delete PVCs
echo "
📦 Deleting PVCs..."
kubectl delete pvc -n $NAMESPACE --all --force --grace-period=0 2>/dev/null || true

# 7. Delete PVs with longhorn provisioner
echo "💾 Deleting Longhorn PVs..."
kubectl get pv -o json | jq -r '.items[] | select(.spec.storageClassName | contains("longhorn")) | .metadata.name' 2>/dev/null | while read pv; do
  kubectl patch pv $pv -p '{"metadata":{"finalizers":[]}}' --type=merge 2>/dev/null || true
  kubectl delete pv $pv --force --grace-period=0 2>/dev/null || true
done

# 8. Delete storage classes
echo "
📁 Removing Longhorn storage classes..."
kubectl get storageclass -o name | grep longhorn | xargs -r kubectl delete --ignore-not-found=true 2>/dev/null || true

# 9. Delete CSI drivers
echo "🔌 Removing CSI drivers..."
kubectl delete csidriver driver.longhorn.io --ignore-not-found=true 2>/dev/null || true

# 10. Remove finalizers from CRDs
echo "
🔧 Removing finalizers from Longhorn CRDs..."
kubectl get crd -o name | grep longhorn | while read crd; do
  kubectl patch $crd -p '{"metadata":{"finalizers":[]}}' --type=merge 2>/dev/null || true
done

# 11. Delete all Longhorn CRDs
echo "📋 Removing Longhorn CRDs..."
kubectl get crd -o name | grep longhorn | xargs -r kubectl delete --ignore-not-found=true 2>/dev/null || true

# 12. Delete webhooks
echo "🪝 Removing webhooks..."
kubectl delete validatingwebhookconfiguration longhorn-webhook-validator --ignore-not-found=true 2>/dev/null || true
kubectl delete mutatingwebhookconfiguration longhorn-webhook-mutator --ignore-not-found=true 2>/dev/null || true

# 13. Delete services
echo "🌐 Removing services..."
kubectl delete svc -n $NAMESPACE --all --force --grace-period=0 2>/dev/null || true

# 14. Delete configmaps and secrets
echo "🔐 Removing configmaps and secrets..."
kubectl delete configmap,secret -n $NAMESPACE --all --force --grace-period=0 2>/dev/null || true

# 15. Remove finalizers from namespace
echo "
🔧 Removing finalizers from namespace..."
kubectl patch namespace $NAMESPACE -p '{"metadata":{"finalizers":[]}}' --type=merge 2>/dev/null || true

# 16. Force delete namespace
echo "🗑️ Force deleting namespace..."
kubectl delete namespace $NAMESPACE --force --grace-period=0 2>/dev/null || true

# 17. Final verification
echo "
🔍 Verifying cleanup..."
sleep 2
if kubectl get namespace $NAMESPACE &>/dev/null; then
  echo "⚠️  Namespace still exists. Manual intervention may be required."
  echo "Run: kubectl get namespace $NAMESPACE -o json | jq '.spec.finalizers = []' | kubectl replace --raw /api/v1/namespaces/$NAMESPACE/finalize -f -"
else
  echo "✅ Namespace successfully deleted!"
fi

if kubectl get crd | grep -q longhorn; then
  echo "⚠️  Some Longhorn CRDs still exist:"
  kubectl get crd | grep longhorn
else
  echo "✅ All Longhorn CRDs removed!"
fi

echo "
✅ Longhorn cleanup completed!"
