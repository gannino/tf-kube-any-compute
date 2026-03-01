# ============================================================================
# LONGHORN CRD CLEANUP - Runs during destroy
# ============================================================================
# CRDs are created by Helm during installation for proper ownership labels.
# This module only handles cleanup during destroy operations.

# Reference the namespace to ensure it exists
data "kubernetes_namespace" "this" {
  metadata {
    name = var.namespace
  }
  depends_on = [kubernetes_namespace.this]
}

# Placeholder resource to track CRD deployment state
# This ensures we have a dependency chain for cleanup
resource "null_resource" "crds_deployed" {
  depends_on = [helm_release.this]

  triggers = {
    chart_version = var.chart_version
  }

  provisioner "local-exec" {
    command = <<EOT
      echo "Longhorn CRDs deployed by Helm release"
      kubectl get crd | grep longhorn.io || echo "No CRDs found"
    EOT
  }
}

# ============================================================================
# CRD CLEANUP RESOURCE (OPTIONAL - RUNS ONLY WITH force_namespace_cleanup)
# ============================================================================
# WARNING: CRD deletion will remove ALL Longhorn custom resources cluster-wide.
# Only enable when you want to completely remove Longhorn from the cluster.

# Cleanup CRDs when force_namespace_cleanup is enabled
resource "null_resource" "cleanup_crds" {
  count      = var.force_namespace_cleanup ? 1 : 0
  depends_on = [null_resource.force_namespace_cleanup]

  triggers = {
    chart_version = var.chart_version
    kubeconfig    = local.kubeconfig_path
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<EOT
      if [ -n "${self.triggers.kubeconfig}" ]; then
        export KUBECONFIG="${self.triggers.kubeconfig}"
      fi

      echo "Cleaning up Longhorn CRDs..."

      # Remove finalizers from any remaining Longhorn custom resources
      # SAFETY: Skip "nodes" as it could match cluster nodes
      for resource in volumes engines replicas engineimages instancemanagers sharemanagers backingimages backups backuptargets; do
        kubectl get $resource.longhorn.io --all-namespaces -o json 2>/dev/null | \
          jq -r '.items[] | "\.metadata.namespace \.metadata.name"' | \
          xargs -I {} kubectl patch {} --type=merge -p '{"metadata":{"finalizers":[]}}' 2>/dev/null || true
      done

      # Delete all Longhorn CRDs
      kubectl get crd -o name 2>/dev/null | grep longhorn.io | \
        xargs -r kubectl delete --ignore-not-found=true --timeout=60s

      echo "✓ CRDs cleaned up."
    EOT
  }

  lifecycle {
    ignore_changes = [triggers]
  }
}
