resource "kubernetes_namespace" "this" {
  metadata {
    name        = local.module_config.namespace
    labels      = local.common_labels
    annotations = local.common_labels
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

      echo "Cleaning up Longhorn resources..."

      # Delete Longhorn custom resources
      for resource in volumes engines replicas nodes engineimages instancemanagers sharemanagers backingimages; do
        kubectl get $resource.longhorn.io -n ${self.triggers.namespace} -o name 2>/dev/null | xargs -r kubectl patch -n ${self.triggers.namespace} -p '{"metadata":{"finalizers":[]}}' --type=merge || true
        kubectl delete $resource.longhorn.io -n ${self.triggers.namespace} --all --ignore-not-found=true --timeout=60s 2>/dev/null || true
      done

      # Delete CSI driver
      kubectl delete csidriver driver.longhorn.io --ignore-not-found=true --timeout=30s 2>/dev/null || true

      # Delete storage classes
      kubectl get storageclass -o name 2>/dev/null | grep longhorn | xargs -r kubectl delete --ignore-not-found=true --timeout=30s 2>/dev/null || true

      echo "✓ Longhorn resources cleaned up."
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

      echo "Starting force Longhorn namespace cleanup for ${self.triggers.namespace}..."

      # Force delete all workload resources
      kubectl delete deployment,daemonset,statefulset -n ${self.triggers.namespace} --all --force --grace-period=0 --timeout=60s 2>/dev/null || true
      kubectl delete pods -n ${self.triggers.namespace} --all --force --grace-period=0 --timeout=30s 2>/dev/null || true

      # Delete PVCs/PVs with Longhorn provisioner
      kubectl delete pvc -n ${self.triggers.namespace} --all --force --grace-period=0 --timeout=60s 2>/dev/null || true
      for pv in $(kubectl get pv -o name 2>/dev/null | grep longhorn); do
        kubectl patch $pv -p '{"metadata":{"finalizers":null}}' --type=merge 2>/dev/null || true
        kubectl delete $pv --force --grace-period=0 --timeout=30s 2>/dev/null || true
      done

      # Delete all Longhorn custom resources with finalizer removal
      for resource in volumes engines replicas nodes engineimages instancemanagers sharemanagers backingimages; do
        kubectl get $resource.longhorn.io -n ${self.triggers.namespace} -o name 2>/dev/null | xargs -r kubectl patch -n ${self.triggers.namespace} -p '{"metadata":{"finalizers":[]}}' --type=merge || true
        kubectl delete $resource.longhorn.io -n ${self.triggers.namespace} --all --ignore-not-found=true --force --grace-period=0 --timeout=60s 2>/dev/null || true
      done

      # Delete CSI driver
      kubectl delete csidriver driver.longhorn.io --ignore-not-found=true --timeout=30s 2>/dev/null || true

      # Delete storage classes
      kubectl get storageclass -o name 2>/dev/null | grep longhorn | xargs -r kubectl delete --ignore-not-found=true --timeout=30s 2>/dev/null || true

      # Delete CRDs
      kubectl get crd -o name 2>/dev/null | grep longhorn.io | xargs -r kubectl delete --ignore-not-found=true --timeout=60s 2>/dev/null || true

      # Delete webhooks
      kubectl delete mutatingwebhookconfiguration,validatingwebhookconfiguration -l app.kubernetes.io/name=longhorn --ignore-not-found=true --timeout=30s 2>/dev/null || true

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
    templatefile("${path.module}/values.yaml.tpl", local.template_values)
  ]

  disable_webhooks = local.helm_config.disable_webhooks
  skip_crds        = local.helm_config.skip_crds
  replace          = local.helm_config.replace
  force_update     = local.helm_config.force_update
  cleanup_on_fail  = local.helm_config.cleanup_on_fail
  timeout          = local.helm_config.timeout
  wait             = local.helm_config.wait
  wait_for_jobs    = local.helm_config.wait_for_jobs

  # Prevent uninstall issues
  disable_openapi_validation = true
  atomic                     = false

  # Lifecycle configuration to handle stuck deletions
  lifecycle {
    # Note: metadata is provider-controlled and doesn't need ignore_changes
  }

  depends_on = [
    kubernetes_namespace.this,
    null_resource.cleanup,
    null_resource.force_namespace_cleanup
  ]
}
