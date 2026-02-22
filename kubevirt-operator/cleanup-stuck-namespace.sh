#!/bin/bash
set -e

export KUBECONFIG="${HOME}/.kube/prod-config"

echo "Cleaning up stuck KubeVirt namespace..."

# Delete stale API services
kubectl delete apiservice v1.subresources.kubevirt.io --ignore-not-found=true --timeout=30s || true
kubectl delete apiservice v1alpha3.subresources.kubevirt.io --ignore-not-found=true --timeout=30s || true

# Check if namespace still exists
if kubectl get namespace prod-kubevirt-system 2>/dev/null; then
  echo "Namespace still exists, checking status..."
  kubectl get namespace prod-kubevirt-system -o jsonpath='{.status.phase}'
  echo ""

  # If stuck in Terminating, force remove finalizers
  if kubectl get namespace prod-kubevirt-system -o jsonpath='{.status.phase}' | grep -q Terminating; then
    echo "Removing finalizers from stuck namespace..."
    kubectl get namespace prod-kubevirt-system -o json | \
      jq 'del(.spec.finalizers)' | \
      kubectl replace --raw "/api/v1/namespaces/prod-kubevirt-system/finalize" -f - || true
  fi
else
  echo "Namespace already deleted."
fi

echo "✓ Cleanup completed."
