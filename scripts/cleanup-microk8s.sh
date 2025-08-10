#!/bin/bash
# MicroK8s Cluster Cleanup Script

set -e

echo "🧹 Starting MicroK8s cluster cleanup..."

# Remove all Helm releases
echo "📦 Removing Helm releases..."
helm list -A -o json | jq -r '.[] | "\(.name) -n \(.namespace)"' | while read release; do
    if [ ! -z "$release" ]; then
        echo "Removing Helm release: $release"
        helm uninstall $release || true
    fi
done

# Delete all custom namespaces (keep system ones)
echo "🗂️ Cleaning up namespaces..."
kubectl get namespaces -o json | jq -r '.items[] | select(.metadata.name | test("^(prod-|dev-|qa-|build-)")) | .metadata.name' | while read ns; do
    if [ ! -z "$ns" ]; then
        echo "Deleting namespace: $ns"
        kubectl delete namespace "$ns" --force --grace-period=0 || true
    fi
done

# Clean up conflicting services across all namespaces
echo "📊 Cleaning up conflicting services..."
kubectl get services -A | grep -E "(prometheus-operator|grafana|traefik|consul|vault|portainer)" | awk '{print $2 " -n " $1}' | while read svc; do
    if [ ! -z "$svc" ]; then
        echo "Removing service: $svc"
        kubectl delete service $svc --force --grace-period=0 || true
    fi
done

# Remove PVCs
echo "💾 Cleaning up PVCs..."
kubectl delete pvc --all -A || true

# Remove custom storage classes
echo "🗄️ Removing custom storage classes..."
kubectl delete storageclass nfs-csi nfs-csi-safe nfs-csi-fast hostpath 2>/dev/null || true

# Remove webhooks
echo "🪝 Cleaning up webhooks..."
kubectl get mutatingwebhookconfigurations -o name | grep -E "(traefik|prometheus|grafana|consul|vault|portainer|gatekeeper)" | xargs kubectl delete || true
kubectl get validatingwebhookconfigurations -o name | grep -E "(traefik|prometheus|grafana|consul|vault|portainer|gatekeeper)" | xargs kubectl delete || true

# Remove CRDs
echo "🔧 Cleaning up CRDs..."
kubectl get crd -o name | grep -E "(traefik|prometheus|grafana|consul|vault|portainer|gatekeeper)" | xargs kubectl delete || true

# Force remove stuck resources
echo "🔨 Force cleaning stuck resources..."
kubectl get pods -A | grep -E "(Terminating|Error|CrashLoopBackOff)" | awk '{print $2 " -n " $1}' | while read pod; do
    if [ ! -z "$pod" ]; then
        echo "Force deleting pod: $pod"
        kubectl delete pod $pod --force --grace-period=0 || true
    fi
done

# Reset MicroK8s (nuclear option)
echo "☢️ Resetting MicroK8s..."
sudo microk8s reset --destroy-storage || true

# Restart MicroK8s
echo "🔄 Restarting MicroK8s..."
sudo microk8s stop
sudo microk8s start

# Wait for MicroK8s to be ready
echo "⏳ Waiting for MicroK8s to be ready..."
microk8s status --wait-ready

# Re-enable basic addons
echo "🔌 Re-enabling basic addons..."
microk8s enable dns

echo "✅ MicroK8s cleanup completed!"
echo "🚀 You can now run 'terraform apply' again"
