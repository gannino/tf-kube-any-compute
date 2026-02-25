#!/bin/bash
set -e

# Workspace-aware kubeconfig detection (matches main provider.tf logic)
WORKSPACE_PREFIX="${1:-prod}"
NAMESPACE="${2:-rook-ceph}"

if [ "$CI_MODE" = "true" ]; then
  KUBECONFIG="${KUBECONFIG:-}"
elif [ -n "$WORKSPACE_PREFIX" ]; then
  KUBECONFIG="$HOME/.kube/${WORKSPACE_PREFIX}-config"
else
  KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"
fi

export KUBECONFIG

FULL_NAMESPACE="${WORKSPACE_PREFIX}-${NAMESPACE}"
if [ "${WORKSPACE_PREFIX}" = "prod" ]; then
  FULL_NAMESPACE="${NAMESPACE}"
fi

echo "Cleaning up stuck Rook-Ceph namespace: ${FULL_NAMESPACE}..."
echo "Using kubeconfig: ${KUBECONFIG}"

# Check if namespace exists
if ! kubectl get namespace "${FULL_NAMESPACE}" 2>/dev/null; then
  echo "Namespace ${FULL_NAMESPACE} does not exist. Nothing to clean up."
  exit 0
fi

# Check namespace status
NAMESPACE_STATUS=$(kubectl get namespace "${FULL_NAMESPACE}" -o jsonpath='{.status.phase}')
echo "Namespace status: ${NAMESPACE_STATUS}"

# Delete CephCluster resource with finalizer removal (triggers OSD/MON cleanup)
echo "Deleting CephCluster..."
for cluster in $(kubectl get cephcluster.ceph.rook.io -n "${FULL_NAMESPACE}" -o name 2>/dev/null || true); do
  kubectl patch -n "${FULL_NAMESPACE}" "${cluster}" -p '{"metadata":{"finalizers":[]}}' --type=merge || true
  kubectl delete -n "${FULL_NAMESPACE}" "${cluster}" --ignore-not-found=true --timeout=120s || true
done

# Delete all Ceph custom resources with finalizer removal
echo "Deleting Ceph custom resources..."
for resource in cephblockpool cephfilesystem cephobjectstore cephnfs cephobjectrealm cephobjectzone cephobjectzonegroup cephbucket; do
  echo "Processing ${resource}..."
  kubectl get "${resource}.ceph.rook.io" -n "${FULL_NAMESPACE}" -o name 2>/dev/null | while read -r res; do
    kubectl patch -n "${FULL_NAMESPACE}" "${res}" -p '{"metadata":{"finalizers":[]}}' --type=merge || true
  done
  kubectl delete "${resource}.ceph.rook.io" -n "${FULL_NAMESPACE}" --all --ignore-not-found=true --timeout=60s || true
done

# Delete PVCs/PVs with Rook provisioner
echo "Deleting PVCs and PVs..."
kubectl delete pvc -n "${FULL_NAMESPACE}" --all --ignore-not-found=true --timeout=60s || true
for pv in $(kubectl get pv -o name 2>/dev/null | grep -E 'ceph|rbd' || true); do
  kubectl patch "${pv}" -p '{"metadata":{"finalizers":null}}' --type=merge || true
  kubectl delete "${pv}" --ignore-not-found=true --timeout=30s || true
done

# Delete CSI drivers
echo "Deleting CSI drivers..."
kubectl delete csidriver rbd.csi.ceph.com --ignore-not-found=true --timeout=30s || true
kubectl delete csidriver cephfs.csi.ceph.com --ignore-not-found=true --timeout=30s || true

# Delete storage classes
echo "Deleting storage classes..."
kubectl get storageclass -o name 2>/dev/null | grep -E 'ceph|rbd' | xargs -r kubectl delete --ignore-not-found=true --timeout=30s || true

# Delete CRDs
echo "Deleting CRDs..."
kubectl get crd -o name 2>/dev/null | grep ceph.rook.io | xargs -r kubectl delete --ignore-not-found=true --timeout=60s || true

# Delete webhooks
echo "Deleting webhooks..."
kubectl delete mutatingwebhookconfiguration,validatingwebhookconfiguration -l app.kubernetes.io/name=rook-ceph --ignore-not-found=true --timeout=30s || true

# Force remove namespace finalizers if stuck
if kubectl get namespace "${FULL_NAMESPACE}" 2>/dev/null | grep -q Terminating; then
  echo "Namespace stuck in Terminating, removing finalizers..."
  kubectl get namespace "${FULL_NAMESPACE}" -o json | \
    jq 'del(.spec.finalizers)' | \
    kubectl replace --raw "/api/v1/namespaces/${FULL_NAMESPACE}/finalize" -f - || true
fi

# Wait for namespace deletion
echo "Waiting for namespace deletion..."
timeout 180 bash -c "while kubectl get namespace ${FULL_NAMESPACE} 2>/dev/null; do sleep 2; done" || true

# Final check
if kubectl get namespace "${FULL_NAMESPACE}" 2>/dev/null; then
  echo "⚠ Warning: Namespace ${FULL_NAMESPACE} still exists after cleanup"
  kubectl get namespace "${FULL_NAMESPACE}" -o jsonpath='{.status.phase}'
else
  echo "✓ Namespace ${FULL_NAMESPACE} cleanup completed successfully."
fi
