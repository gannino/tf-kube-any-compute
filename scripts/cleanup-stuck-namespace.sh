#!/bin/bash
# Generic stuck-namespace cleanup helper.
#
# Clears finalizers on any remaining resources in a namespace and finalizes
# the namespace itself via the raw /finalize API. Use when a namespace is
# stuck in `Terminating` because the namespace controller can't process a
# finalizer (common on clusters with many registered CRDs, e.g. Rook Ceph).
#
# Idempotent: safe to run anytime. Exits clean if the namespace is already
# gone or not stuck.
#
# Usage: cleanup-stuck-namespace.sh <namespace> [workspace-prefix]
#   namespace        required, e.g. prod-metrics-server-system
#   workspace-prefix optional, used to locate ~/.kube/<prefix>-config
#
# Env overrides:
#   KUBECONFIG        if set, used as-is
#   CI_MODE=true      skips workspace-prefix kubeconfig lookup
#   WORKSPACE_PREFIX  fallback if not passed as $2

set -uo pipefail

NAMESPACE="${1:?Usage: $0 <namespace> [workspace-prefix]}"
WORKSPACE_PREFIX="${2:-${WORKSPACE_PREFIX:-}}"

# --- Kubeconfig detection (mirrors root provider.tf logic) ---
if [ -z "${KUBECONFIG:-}" ]; then
  if [ "${CI_MODE:-}" = "true" ]; then
    : # rely on whatever KUBECONFIG the CI env provides
  elif [ -n "$WORKSPACE_PREFIX" ]; then
    export KUBECONFIG="$HOME/.kube/${WORKSPACE_PREFIX}-config"
  else
    export KUBECONFIG="$HOME/.kube/config"
  fi
fi

echo "========================================"
echo "Cleanup stuck namespace: ${NAMESPACE}"
echo "Using kubeconfig: ${KUBECONFIG:-<default>}"
echo "========================================"

# --- Exit clean if namespace doesn't exist ---
if ! kubectl get ns "$NAMESPACE" >/dev/null 2>&1; then
  echo "✓ Namespace ${NAMESPACE} does not exist. Nothing to clean up."
  exit 0
fi

STATUS="$(kubectl get ns "$NAMESPACE" -o jsonpath='{.status.phase}' 2>/dev/null || echo Unknown)"
DELETING="$(kubectl get ns "$NAMESPACE" -o jsonpath='{.metadata.deletionTimestamp}' 2>/dev/null || echo '')"
echo "Namespace status: ${STATUS}"
[ -n "$DELETING" ] && echo "Deletion timestamp: ${DELETING}"

# --- Step 1: enumerate every namespaced resource type and clear finalizers ---
# `kubectl get all` misses CRD instances, secrets, serviceaccounts, etc.
# This scan covers everything registered with the API.
echo "[1/2] Patching finalizers on any remaining resources..."
kubectl api-resources --verbs=list --namespaced -o name 2>/dev/null | while read -r rtype; do
  # `kubectl -n ... get` returns non-zero if the resource type errors; tolerate that
  resources="$(kubectl -n "$NAMESPACE" get "$rtype" -o name 2>/dev/null || true)"
  [ -z "$resources" ] && continue
  echo "  - ${rtype}:"
  echo "$resources" | while read -r res; do
    [ -z "$res" ] && continue
    echo "      patching ${res}"
    kubectl -n "$NAMESPACE" patch "$res" -p '{"metadata":{"finalizers":[]}}' --type=merge >/dev/null 2>&1 || true
  done
done
echo "  ✓ Finalizer scan complete"

# --- Step 2: finalize the namespace via raw API if it's deleting/stuck ---
if [ "$STATUS" = "Terminating" ] || [ -n "$DELETING" ]; then
  echo "[2/2] Namespace is Terminating — removing finalizers via raw /finalize API..."
  if ! kubectl get ns "$NAMESPACE" -o json 2>/dev/null \
        | jq 'del(.spec.finalizers)' \
        | kubectl replace --raw "/api/v1/namespaces/${NAMESPACE}/finalize" -f - >/dev/null 2>&1; then
    echo "  ⚠ raw finalize call failed — may need manual intervention"
    echo "    kubectl get ns ${NAMESPACE} -o json | jq 'del(.spec.finalizers)' \\"
    echo "      | kubectl replace --raw /api/v1/namespaces/${NAMESPACE}/finalize -f -"
  else
    echo "  ✓ finalize submitted"
  fi
else
  echo "[2/2] Namespace is ${STATUS} (not stuck) — skipping finalize."
fi

# --- Wait briefly for the namespace to actually disappear ---
echo "Waiting for namespace deletion (up to 60s)..."
if ! timeout 60 bash -c "while kubectl get ns '${NAMESPACE}' >/dev/null 2>&1; do sleep 2; done" 2>/dev/null; then
  echo "  (timed out waiting — namespace may still be clearing)"
fi

# --- Final report ---
echo "========================================"
if kubectl get ns "$NAMESPACE" >/dev/null 2>&1; then
  FINAL="$(kubectl get ns "$NAMESPACE" -o jsonpath='{.status.phase}' 2>/dev/null || echo Unknown)"
  echo "⚠ Namespace ${NAMESPACE} still exists (phase=${FINAL})"
  echo "  If still stuck, inspect remaining finalizers:"
  echo "    kubectl get ns ${NAMESPACE} -o jsonpath='{.spec.finalizers}'"
else
  echo "✓ Namespace ${NAMESPACE} is gone."
fi
echo "========================================"
