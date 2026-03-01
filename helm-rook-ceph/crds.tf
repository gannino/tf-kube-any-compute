# ============================================================================
# ROOK-CEPH CRD AND CLEANUP MANAGEMENT
# ============================================================================
# CRDs are managed by Helm during installation for proper lifecycle management.
# Primary cleanup logic is in main.tf (null_resource.helm_cleanup).
# This file contains only:
#   1. CRD deployment tracking
#   2. Opt-in force cleanup for stuck namespaces

# Reference the namespace to ensure it exists
data "kubernetes_namespace" "this" {
  metadata {
    name = var.namespace
  }
  depends_on = [kubernetes_namespace.this]
}

# Placeholder resource to track CRD deployment state
resource "null_resource" "crds_deployed" {
  depends_on = [helm_release.this]

  triggers = {
    chart_version = var.chart_version
  }

  provisioner "local-exec" {
    command = <<EOT
      echo "Rook-Ceph CRDs deployed by Helm release"
      kubectl get crd | grep -E "(ceph.rook.io|objectbucket.io)" || echo "No CRDs found"
    EOT
  }
}

# ============================================================================
# FORCE CLEANUP - Opt-in for stuck namespaces
# ============================================================================
# Only enable this when namespace is stuck in Terminating phase.
# Primary cleanup is in main.tf (null_resource.helm_cleanup).

resource "null_resource" "force_namespace_cleanup" {
  count = var.force_namespace_cleanup ? 1 : 0

  triggers = {
    namespace       = var.namespace
    cleanup_timeout = var.cleanup_timeout
    kubeconfig_path = local.kubeconfig_path
  }

  # Ensure this runs after the main cleanup in main.tf
  depends_on = [null_resource.helm_cleanup]

  provisioner "local-exec" {
    when    = destroy
    command = <<EOT
      if [ -n "${self.triggers.kubeconfig_path}" ]; then
        export KUBECONFIG="${self.triggers.kubeconfig_path}"
      fi

      NAMESPACE="${self.triggers.namespace}"
      echo "========================================"
      echo "ROOK-CEPH FORCE CLEANUP"
      echo "Namespace: $NAMESPACE"
      echo "========================================"

      # Force delete all workload resources
      kubectl delete deployment,daemonset,statefulset -n "$NAMESPACE" --all --force --grace-period=0 --timeout=60s 2>/dev/null || true
      kubectl delete pods -n "$NAMESPACE" --all --force --grace-period=0 --timeout=30s 2>/dev/null || true

      # Delete all Rook-Ceph custom resources with finalizer removal
      kubectl get crd -o name 2>/dev/null | grep -E "(ceph.rook.io|objectbucket.io|csi.ceph.io)" | while read crd; do
        resource_name=$(echo "$crd" | sed 's/.*\///')
        crd_scope=$(kubectl get "$crd" -o jsonpath='{.spec.scope}' 2>/dev/null || echo "Namespaced")
        if [[ "$crd_scope" != "Namespaced" ]]; then
          continue
        fi
        kubectl get "$resource_name" -n "$NAMESPACE" -o name 2>/dev/null | xargs -r kubectl patch -n "$NAMESPACE" -p '{"metadata":{"finalizers":[]}}' --type=merge 2>/dev/null || true
        kubectl delete "$resource_name" -n "$NAMESPACE" --all --ignore-not-found=true --force --grace-period=0 --timeout=60s 2>/dev/null || true
      done

      # Delete CSI drivers
      kubectl delete csidriver -l operator=rook --ignore-not-found=true --timeout=30s 2>/dev/null || true

      # Delete storage classes
      kubectl get storageclass -o name 2>/dev/null | grep -E "(ceph.rook|rook-)" | xargs -r kubectl delete --ignore-not-found=true --timeout=30s 2>/dev/null || true

      # Delete CRDs
      kubectl get crd -o name 2>/dev/null | grep -E "(ceph.rook.io|objectbucket.io)" | xargs -r kubectl delete --ignore-not-found=true --timeout=60s 2>/dev/null || true

      # Delete webhooks
      kubectl delete validatingwebhookconfiguration -l app=rook-ceph-operator --ignore-not-found=true --timeout=30s 2>/dev/null || true

      # Force remove namespace finalizers if stuck
      if kubectl get namespace "$NAMESPACE" 2>/dev/null | grep -q Terminating; then
        echo "Namespace stuck in Terminating, removing finalizers..."
        kubectl get namespace "$NAMESPACE" -o json 2>/dev/null | \
          jq 'del(.spec.finalizers)' | \
          kubectl replace --raw "/api/v1/namespaces/$NAMESPACE/finalize" -f - 2>/dev/null || true
      fi

      echo "✓ Force cleanup completed for namespace $NAMESPACE"
      echo "========================================"
    EOT
  }
}
