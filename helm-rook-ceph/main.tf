resource "kubernetes_namespace" "this" {
  metadata {
    annotations = local.common_labels
    labels      = local.common_labels
    name        = local.module_config.namespace
  }
}

# ============================================================================
# CLEANUP RESOURCES FOR STUCK NAMESPACES
# ============================================================================

# Basic cleanup provisioner to handle stuck deletions (always runs)
resource "null_resource" "cleanup" {
  triggers = {
    namespace       = local.module_config.namespace
    kubeconfig_path = local.kubeconfig_path
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<EOT
      if [ -n "${self.triggers.kubeconfig_path}" ]; then
        export KUBECONFIG="${self.triggers.kubeconfig_path}"
      fi

      echo "Cleaning up Rook-Ceph resources..."

      # Delete CephCluster resource (this triggers OSD/MON cleanup)
      kubectl delete cephcluster.ceph.rook.io -n ${self.triggers.namespace} --all --ignore-not-found=true --timeout=120s 2>/dev/null || true

      # Delete CephBlockPools, CephFilesystems, CephObjectStores
      kubectl delete cephblockpool.ceph.rook.io -n ${self.triggers.namespace} --all --ignore-not-found=true --timeout=60s 2>/dev/null || true
      kubectl delete cephfilesystem.ceph.rook.io -n ${self.triggers.namespace} --all --ignore-not-found=true --timeout=60s 2>/dev/null || true
      kubectl delete cephobjectstore.ceph.rook.io -n ${self.triggers.namespace} --all --ignore-not-found=true --timeout=60s 2>/dev/null || true

      # Delete CSI drivers
      kubectl delete csidriver rbd.csi.ceph.com --ignore-not-found=true --timeout=30s 2>/dev/null || true
      kubectl delete csidriver cephfs.csi.ceph.com --ignore-not-found=true --timeout=30s 2>/dev/null || true

      # Delete storage classes
      kubectl get storageclass -o name 2>/dev/null | grep -E 'ceph|rbd' | xargs -r kubectl delete --ignore-not-found=true --timeout=30s 2>/dev/null || true

      echo "✓ Rook-Ceph resources cleaned up."
    EOT
  }
}

# Force cleanup resource (opt-in via var.force_namespace_cleanup)
resource "null_resource" "force_namespace_cleanup" {
  count = var.force_namespace_cleanup ? 1 : 0

  triggers = {
    namespace       = var.namespace
    cleanup_timeout = var.cleanup_timeout
    kubeconfig_path = local.kubeconfig_path
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<EOT
      if [ -n "${self.triggers.kubeconfig_path}" ]; then
        export KUBECONFIG="${self.triggers.kubeconfig_path}"
      fi

      echo "Starting force Rook-Ceph namespace cleanup for ${self.triggers.namespace}..."

      # Force delete CephCluster with finalizer removal
      for cluster in $(kubectl get cephcluster.ceph.rook.io -n ${self.triggers.namespace} -o name 2>/dev/null); do
        kubectl patch -n ${self.triggers.namespace} $cluster -p '{"metadata":{"finalizers":[]}}' --type=merge 2>/dev/null || true
        kubectl delete -n ${self.triggers.namespace} $cluster --ignore-not-found=true --force --grace-period=0 --timeout=120s 2>/dev/null || true
      done

      # Delete all Ceph custom resources with finalizer removal
      for resource in cephblockpool cephfilesystem cephobjectstore cephnfs cephobjectrealm cephobjectzone cephobjectzonegroup cephbucket; do
        kubectl get $resource.ceph.rook.io -n ${self.triggers.namespace} -o name 2>/dev/null | xargs -r kubectl patch -n ${self.triggers.namespace} -p '{"metadata":{"finalizers":[]}}' --type=merge || true
        kubectl delete $resource.ceph.rook.io -n ${self.triggers.namespace} --all --ignore-not-found=true --force --grace-period=0 --timeout=60s 2>/dev/null || true
      done

      # Delete PVCs/PVs with Rook provisioner
      kubectl delete pvc -n ${self.triggers.namespace} --all --force --grace-period=0 --timeout=60s 2>/dev/null || true
      for pv in $(kubectl get pv -o name 2>/dev/null | grep -E 'ceph|rbd'); do
        kubectl patch $pv -p '{"metadata":{"finalizers":null}}' --type=merge 2>/dev/null || true
        kubectl delete $pv --force --grace-period=0 --timeout=30s 2>/dev/null || true
      done

      # Force delete all workload resources
      kubectl delete deployment,daemonset,statefulset -n ${self.triggers.namespace} --all --force --grace-period=0 --timeout=60s 2>/dev/null || true
      kubectl delete pods -n ${self.triggers.namespace} --all --force --grace-period=0 --timeout=30s 2>/dev/null || true

      # Delete CSI drivers
      kubectl delete csidriver rbd.csi.ceph.com --ignore-not-found=true --timeout=30s 2>/dev/null || true
      kubectl delete csidriver cephfs.csi.ceph.com --ignore-not-found=true --timeout=30s 2>/dev/null || true

      # Delete storage classes
      kubectl get storageclass -o name 2>/dev/null | grep -E 'ceph|rbd' | xargs -r kubectl delete --ignore-not-found=true --timeout=30s 2>/dev/null || true

      # Delete CRDs
      kubectl get crd -o name 2>/dev/null | grep ceph.rook.io | xargs -r kubectl delete --ignore-not-found=true --timeout=60s 2>/dev/null || true

      # Delete webhooks
      kubectl delete mutatingwebhookconfiguration,validatingwebhookconfiguration -l app.kubernetes.io/name=rook-ceph --ignore-not-found=true --timeout=30s 2>/dev/null || true

      # Force remove namespace finalizers if stuck
      if kubectl get namespace ${self.triggers.namespace} 2>/dev/null | grep -q Terminating; then
        echo "Namespace stuck in Terminating, removing finalizers..."
        kubectl get namespace ${self.triggers.namespace} -o json 2>/dev/null | \
          jq 'del(.spec.finalizers)' | \
          kubectl replace --raw "/api/v1/namespaces/${self.triggers.namespace}/finalize" -f - 2>/dev/null || true
      fi

      echo "✓ Namespace ${self.triggers.namespace} force cleanup completed."
    EOT
  }

  depends_on = [null_resource.cleanup]
}

resource "helm_release" "this" {
  name       = local.module_config.name
  chart      = local.module_config.chart_name
  repository = local.module_config.chart_repo
  version    = local.module_config.chart_version
  namespace  = kubernetes_namespace.this.metadata[0].name

  create_namespace = false
  values = [
    templatefile("${path.module}/templates/rook-ceph-values.yaml.tpl", local.template_values)
  ]

  disable_webhooks = local.helm_config.disable_webhooks
  skip_crds        = local.helm_config.skip_crds
  replace          = local.helm_config.replace
  force_update     = local.helm_config.force_update
  cleanup_on_fail  = local.helm_config.cleanup_on_fail
  timeout          = local.helm_config.timeout
  wait             = local.helm_config.wait
  wait_for_jobs    = local.helm_config.wait_for_jobs

  depends_on = [
    kubernetes_namespace.this,
    kubernetes_limit_range.namespace_limits,
    null_resource.cleanup,
    null_resource.force_namespace_cleanup
  ]
}
