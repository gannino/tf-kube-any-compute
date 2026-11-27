#!/bin/bash
# Ensure the primary storage class can actually provision and bind a PVC.
# Runs before the full `make apply` as a bootstrap gate: the recurring
# 112226-112324 failure mode was PVC-dependent charts (consul, grafana,
# portainer) timing out because Longhorn's CSI stack was degraded while
# PVC-free charts deployed fine. A 1Gi test PVC catches that in seconds.
#
# Storage class resolution order:
#   1. $STORAGE_CLASS env override
#   2. `terraform output primary_storage_class` (available after bootstrap)
#   3. the cluster's default StorageClass
set -euo pipefail

SC="${STORAGE_CLASS:-}"
NAMESPACE="default"
PVC="storage-bind-check"

if [ -z "$SC" ]; then
    SC=$(terraform output -raw primary_storage_class 2>/dev/null || true)
fi
if [ -z "$SC" ]; then
    SC=$(kubectl get sc -o jsonpath='{.items[?(@.metadata.annotations.storageclass\.kubernetes\.io/is-default-class=="true")].metadata.name}' 2>/dev/null || true)
fi
if [ -z "$SC" ]; then
    echo "❌ Could not determine the primary storage class (set STORAGE_CLASS=<name> to override)"
    exit 1
fi

echo "Testing PVC provisioning on storage class: $SC"

# Idempotent start: remove any leftover test PVC
kubectl -n "$NAMESPACE" delete pvc "$PVC" --ignore-not-found=true >/dev/null 2>&1 || true

kubectl apply -f - >/dev/null <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: $PVC
  namespace: $NAMESPACE
spec:
  accessModes: ["ReadWriteOnce"]
  storageClassName: "$SC"
  resources:
    requests:
      storage: 1Gi
EOF

if kubectl -n "$NAMESPACE" wait --for=jsonpath='{.status.phase}'=Bound "pvc/$PVC" --timeout=180s >/dev/null 2>&1; then
    echo "✅ Storage class '$SC' provisions successfully"
    kubectl -n "$NAMESPACE" delete pvc "$PVC" --ignore-not-found=true >/dev/null 2>&1 || true
    exit 0
fi

echo "❌ PVC did not bind on storage class '$SC' within 180s - refusing to apply"
echo "   Current PVC state:"
kubectl -n "$NAMESPACE" get pvc "$PVC" -o wide 2>/dev/null || true
echo "   StorageClasses:"
kubectl get sc 2>/dev/null | head -5 || true
echo "   If this cluster uses Longhorn, check its CSI stack:"
echo "     kubectl -n longhorn-system get pods"
echo "     kubectl -n longhorn-system get nodes.longhorn.io"
kubectl -n "$NAMESPACE" delete pvc "$PVC" --ignore-not-found=true >/dev/null 2>&1 || true
exit 1
