#!/bin/bash
# Ensure CoreDNS is running with minimum replicas
# This prevents DNS resolution failures that break cluster services

set -euo pipefail

NAMESPACE="kube-system"
DEPLOYMENT="coredns"
MIN_REPLICAS=2

echo "Checking CoreDNS deployment..."

# Get current replica count
CURRENT_REPLICAS=$(kubectl get deployment $DEPLOYMENT -n $NAMESPACE -o jsonpath='{.spec.replicas}')
READY_REPLICAS=$(kubectl get deployment $DEPLOYMENT -n $NAMESPACE -o jsonpath='{.status.readyReplicas}' || echo "0")

echo "Current replicas: $CURRENT_REPLICAS, Ready replicas: $READY_REPLICAS"

# Scale up if needed
if [ "$CURRENT_REPLICAS" -lt "$MIN_REPLICAS" ]; then
    echo "Scaling CoreDNS from $CURRENT_REPLICAS to $MIN_REPLICAS replicas..."
    kubectl scale deployment $DEPLOYMENT --replicas=$MIN_REPLICAS -n $NAMESPACE

    # Wait for pods to be ready
    echo "Waiting for CoreDNS pods to be ready..."
    kubectl rollout status deployment/$DEPLOYMENT -n $NAMESPACE --timeout=60s

    echo "CoreDNS scaled successfully"
elif [ "${READY_REPLICAS:-0}" -lt "$MIN_REPLICAS" ]; then
    echo "CoreDNS has $CURRENT_REPLICAS replicas but only $READY_REPLICAS are ready. Waiting..."
    kubectl rollout status deployment/$DEPLOYMENT -n $NAMESPACE --timeout=60s
else
    echo "CoreDNS is healthy with $READY_REPLICAS/$CURRENT_REPLICAS replicas ready"
fi

# Test DNS resolution
echo "Testing DNS resolution..."
if kubectl run test-dns-check --image=busybox --rm --restart=Never -- nslookup kubernetes.default.svc.cluster.local >/dev/null 2>&1; then
    echo "✅ DNS resolution is working"
else
    echo "❌ DNS resolution failed"
    exit 1
fi
