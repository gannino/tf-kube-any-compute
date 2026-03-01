#!/bin/bash
set -e

# Workspace-aware kubeconfig detection (matches main provider.tf logic)
WORKSPACE_PREFIX="${1:-prod}"
NAMESPACE="${2:-longhorn-system}"

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

echo "========================================"
echo "Cleaning up stuck Longhorn namespace: ${FULL_NAMESPACE}..."
echo "Using kubeconfig: ${KUBECONFIG}"
echo "========================================"

# Check if namespace exists
if ! kubectl get namespace "${FULL_NAMESPACE}" 2>/dev/null; then
  echo "Namespace ${FULL_NAMESPACE} does not exist. Nothing to clean up."
  exit 0
fi

# Check namespace status
NAMESPACE_STATUS=$(kubectl get namespace "${FULL_NAMESPACE}" -o jsonpath='{.status.phase}')
echo "Namespace status: ${NAMESPACE_STATUS}"

# STEP 1: Delete webhooks FIRST (critical - they block deletion with finalizers)
echo "[1/8] Deleting admission webhooks..."
kubectl delete mutatingwebhookconfiguration longhorn-webhook-mutator --ignore-not-found=true --timeout=30s || true
kubectl delete validatingwebhookconfiguration longhorn-webhook-validator --ignore-not-found=true --timeout=30s || true
echo "  ✓ Webhooks deleted"

# STEP 2: Discover and delete all Longhorn custom resources dynamically
echo "[2/8] Discovering and deleting Longhorn custom resources..."
kubectl get crd -o name 2>/dev/null | grep longhorn.io | while read -r crd; do
  # Extract full resource name with group (e.g., volumes.longhorn.io)
  resource_name=$(echo "$crd" | sed 's/.*\///')

  # SAFETY CHECK #1: Verify CRD is namespaced (not cluster-scoped)
  crd_scope=$(kubectl get "$crd" -o jsonpath='{.spec.scope}' 2>/dev/null || echo "Namespaced")
  if [[ "$crd_scope" != "Namespaced" ]]; then
    echo "  - Skipping ${resource_name} (cluster-scoped CRD, handled by CRD deletion)"
    continue
  fi

  # SPECIAL HANDLING: nodes.longhorn.io shares name with core nodes
  # Must handle carefully: remove finalizers ONLY in target namespace
  if [[ "$resource_name" =~ ^nodes\.longhorn\.io$ ]]; then
    echo "  - Processing ${resource_name} (namespace-scoped only)..."
    kubectl get "${resource_name}" -n "${FULL_NAMESPACE}" -o name 2>/dev/null | while read -r res; do
      echo "    - Removing finalizers from ${res}"
      kubectl patch -n "${FULL_NAMESPACE}" "${res}" -p '{"metadata":{"finalizers":[]}}' --type=merge || true
      kubectl delete "${resource_name}" -n "${FULL_NAMESPACE}" --all --ignore-not-found=true --timeout=60s || true
    done
    continue
  fi

  echo "  - Processing ${resource_name}..."
  # Use fully qualified name to ensure we only get Longhorn resources
  kubectl get "${resource_name}" -n "${FULL_NAMESPACE}" -o name 2>/dev/null | while read -r res; do
    kubectl patch -n "${FULL_NAMESPACE}" "${res}" -p '{"metadata":{"finalizers":[]}}' --type=merge || true
  done
  kubectl delete "${resource_name}" -n "${FULL_NAMESPACE}" --all --ignore-not-found=true --timeout=60s || true
done

# STEP 3: Delete PVCs/PVs
echo "[3/8] Deleting PVCs and PVs..."
kubectl delete pvc -n "${FULL_NAMESPACE}" --all --ignore-not-found=true --timeout=60s || true
for pv in $(kubectl get pv -o name 2>/dev/null | grep longhorn || true); do
  kubectl patch "${pv}" -p '{"metadata":{"finalizers":null}}' --type=merge || true
  kubectl delete "${pv}" --ignore-not-found=true --timeout=30s || true
done

# STEP 4: Delete CSI driver
echo "[4/8] Deleting CSI driver..."
kubectl delete csidriver driver.longhorn.io --ignore-not-found=true --timeout=30s || true

# STEP 5: Delete storage classes
echo "[5/8] Deleting Longhorn storage classes..."
for sc in $(kubectl get storageclass -o name 2>/dev/null | grep longhorn || true); do
  echo "  - Removing finalizers from ${sc}..."
  kubectl patch "${sc}" -p '{"metadata":{"finalizers":[]}}' --type=merge 2>/dev/null || true
  kubectl delete "${sc}" --ignore-not-found=true --timeout=30s || true
done

# STEP 6: Delete custom resource instances BEFORE deleting CRDs (critical ordering)
# CRD deletion will try to delete instances, and instances with finalizers will block CRD deletion
echo "[6/8] Deleting Longhorn custom resource instances..."
kubectl get crd -o name 2>/dev/null | grep longhorn.io | while read -r crd; do
  resource_name=$(echo "$crd" | sed 's/.*\///')
  crd_scope=$(kubectl get "$crd" -o jsonpath='{.spec.scope}' 2>/dev/null || echo "Namespaced")
  if [[ "$crd_scope" != "Namespaced" ]]; then
    continue
  fi
  kubectl get "${resource_name}" -n "${FULL_NAMESPACE}" -o name 2>/dev/null | while read -r res; do
    kubectl delete "${resource_name}" -n "${FULL_NAMESPACE}" --all --ignore-not-found=true --timeout=30s || true
  done
done

# STEP 7: Delete CRDs (now that instances are gone)
echo "[7/8] Deleting CRDs..."
kubectl get crd -o name 2>/dev/null | grep longhorn.io | xargs -r kubectl delete --ignore-not-found=true --timeout=60s || true

# Force remove namespace finalizers if stuck
if kubectl get namespace "${FULL_NAMESPACE}" 2>/dev/null | grep -q Terminating; then
  echo "Namespace stuck in Terminating, removing finalizers..."
  kubectl get namespace "${FULL_NAMESPACE}" -o json | \
    jq 'del(.spec.finalizers)' | \
    kubectl replace --raw "/api/v1/namespaces/${FULL_NAMESPACE}/finalize" -f - || true
fi

# Wait for namespace deletion
echo "Waiting for namespace deletion..."
timeout 120 bash -c "while kubectl get namespace ${FULL_NAMESPACE} 2>/dev/null; do sleep 2; done" || true

# Final check
echo "========================================"
if kubectl get namespace "${FULL_NAMESPACE}" 2>/dev/null; then
  echo "⚠ Warning: Namespace ${FULL_NAMESPACE} still exists after cleanup"
  kubectl get namespace "${FULL_NAMESPACE}" -o jsonpath='{.status.phase}'
else
  echo "✓ Namespace ${FULL_NAMESPACE} cleanup completed successfully."
fi
echo "========================================"
