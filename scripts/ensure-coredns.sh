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
# Verbose + retries: transient failures right after a CoreDNS scale-up
# (image pull not finished, pod scheduling delay) must not abort the apply
# with no diagnostic output. -i attaches so nslookup output is visible
# even without a TTY.
echo "Testing DNS resolution..."
ATTEMPTS=3
for i in $(seq 1 $ATTEMPTS); do
    echo "Attempt $i/$ATTEMPTS..."
    if kubectl run test-dns-check-"$i" --image=busybox -i --rm --restart=Never -- nslookup kubernetes.default.svc.cluster.local; then
        echo "✅ DNS resolution is working"
        exit 0
    fi
    echo "❌ Attempt $i failed (output above)"
    if [ "$i" -lt "$ATTEMPTS" ]; then
        echo "Retrying in 10s..."
        sleep 10
    fi
done

echo "❌ DNS resolution failed after $ATTEMPTS attempts"
echo "   Check CoreDNS logs: kubectl -n kube-system logs deploy/coredns --tail=30"
exit 1
