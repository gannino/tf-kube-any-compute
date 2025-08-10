#!/bin/bash
# shellcheck disable=SC2086,SC2162,SC2236  # Variable expansion, read without -r, use -n instead of ! -z
# Quick cleanup without full reset

echo "🧹 Quick cleanup of stuck resources..."

# Clean Terraform state locks
echo "🔓 Cleaning Terraform locks..."
terraform force-unlock -force $(terraform show -json 2>/dev/null | jq -r '.values.root_module.resources[] | select(.type == "terraform_data") | .values.id' 2>/dev/null) 2>/dev/null || true

# Remove stuck Helm releases
echo "📦 Removing stuck Helm releases..."
helm list -A | grep -E "(failed|pending)" | awk '{print $1 " -n " $2}' | while read release; do
    if [ ! -z "$release" ]; then
        echo "Removing stuck release: $release"
        helm uninstall $release --no-hooks || true
    fi
done

# Fix namespace conflicts
echo "🗂️ Fixing namespace conflicts..."
kubectl get namespaces -o name | grep -E "(premon|monitoring)" | xargs -r kubectl patch -p '{"metadata":{"finalizers":[]}}' --type=merge 2>/dev/null || true
kubectl get namespaces -o name | grep -E "(premon|monitoring)" | xargs -r kubectl delete --force --grace-period=0 2>/dev/null || true

# Clean up conflicting Prometheus services
echo "📊 Cleaning up Prometheus conflicts..."
kubectl get services -A | grep prometheus-operator | awk '{print $2 " -n " $1}' | while read svc; do
    if [ ! -z "$svc" ]; then
        echo "Removing conflicting service: $svc"
        kubectl delete service $svc --force --grace-period=0 2>/dev/null || true
    fi
done

# Remove stuck PVCs
echo "💾 Removing stuck PVCs..."
kubectl get pvc -A | grep -E "(Terminating|Pending)" | awk '{print $2 " -n " $1}' | while read pvc; do
    if [ ! -z "$pvc" ]; then
        echo "Force deleting PVC: $pvc"
        kubectl patch pvc $pvc --type merge -p '{"metadata":{"finalizers":[]}}' || true
        kubectl delete pvc $pvc --force --grace-period=0 || true
    fi
done

# Clean up webhooks
echo "🪝 Cleaning up webhooks..."
kubectl get mutatingwebhookconfigurations | grep -E "(prometheus|grafana|traefik|consul|vault|portainer)" | awk '{print $1}' | while read webhook; do
    if [ ! -z "$webhook" ]; then
        echo "Removing webhook: $webhook"
        kubectl delete mutatingwebhookconfigurations "$webhook" --force --grace-period=0 2>/dev/null || true
    fi
done

kubectl get validatingwebhookconfigurations | grep -E "(prometheus|grafana|traefik|consul|vault|portainer)" | awk '{print $1}' | while read webhook; do
    if [ ! -z "$webhook" ]; then
        echo "Removing webhook: $webhook"
        kubectl delete validatingwebhookconfigurations "$webhook" --force --grace-period=0 2>/dev/null || true
    fi
done

# Clean up orphaned CRDs
echo "🔧 Cleaning up orphaned CRDs..."
kubectl get crd | grep -E "(prometheus|grafana|traefik|consul|vault|portainer)" | awk '{print $1}' | while read crd; do
    if [ ! -z "$crd" ]; then
        echo "Removing CRD: $crd"
        kubectl delete crd "$crd" --force --grace-period=0 2>/dev/null || true
    fi
done

echo "✅ Quick cleanup completed!"
