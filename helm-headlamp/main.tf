resource "kubernetes_namespace" "this" {
  metadata {
    annotations = merge(local.common_labels, {
      name = var.namespace
    })
    labels = local.common_labels
    name   = var.namespace
  }

  lifecycle {
    create_before_destroy = true
  }

  timeouts {
    delete = var.cleanup_timeout
  }
}

# Headlamp values template using standardized template values
locals {
  headlamp_values = templatefile("${path.module}/templates/headlamp-values.yaml.tpl", local.template_values)
}

# Install helm release Headlamp
resource "helm_release" "this" {
  name       = var.name
  chart      = local.helm_config.chart
  repository = local.helm_config.repository
  version    = local.helm_config.version
  namespace  = kubernetes_namespace.this.metadata[0].name

  values = [
    local.headlamp_values
  ]

  # Helm deployment configuration using locals
  disable_webhooks = var.helm_disable_webhooks
  skip_crds        = var.helm_skip_crds
  replace          = var.helm_replace
  force_update     = var.helm_force_update
  cleanup_on_fail  = var.helm_cleanup_on_fail
  timeout          = var.helm_timeout
  wait             = var.helm_wait
  wait_for_jobs    = var.helm_wait_for_jobs

  depends_on = [
    kubernetes_namespace.this
  ]
}

# Force cleanup resource for stuck namespaces (handles KubeVirt subresources)
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
      # Set KUBECONFIG from trigger
      export KUBECONFIG="$${KUBECONFIG_PATH}"

      # Wait for namespace to enter terminating state
      echo "Waiting for namespace to enter terminating phase..."
      timeout 300 bash -c "until kubectl get namespace $$NAMESPACE -o jsonpath='{.status.phase}' | grep -q 'Terminating'; do sleep 2; done"

      # Handle KubeVirt stale subresources
      echo "Checking for KubeVirt stale subresources..."
      kubectl api-resources --api-group=subresources.kubevirt.io 2>/dev/null && {
        echo "Cleaning up stale KubeVirt subresources..."
        kubectl delete apiservice v1alpha3.subresources.kubevirt.io --ignore-not-found=true || true
        kubectl delete apiservice v1.subresources.kubevirt.io --ignore-not-found=true || true
      }

      # Force remove namespace finalizers
      echo "Force removing namespace finalizers..."
      kubectl get namespace $$NAMESPACE -o json | \
        jq 'del(.spec.finalizers)' | \
        kubectl replace --raw "/api/v1/namespaces/$$NAMESPACE/finalize" -f - --timeout=$$CLEANUP_TIMEOUT

      # Verify namespace is deleted
      echo "Verifying namespace deletion..."
      timeout 300 bash -c "until ! kubectl get namespace $$NAMESPACE 2>/dev/null; do sleep 2; done"
      echo "Namespace $$NAMESPACE successfully cleaned up."
    EOT

    environment = {
      KUBECONFIG_PATH = self.triggers.kubeconfig_path
      NAMESPACE       = self.triggers.namespace
      CLEANUP_TIMEOUT = self.triggers.cleanup_timeout
    }
  }

  depends_on = [
    helm_release.this
  ]
}
