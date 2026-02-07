# ============================================================================
# HELM-KUBEVIRT MODULE - VIRTUAL MACHINE MANAGEMENT
# ============================================================================

# Create KubeVirt namespace
resource "kubernetes_namespace" "this" {
  metadata {
    name   = local.module_config.namespace
    labels = local.common_labels
  }

  lifecycle {
    create_before_destroy = true
  }

  timeouts {
    delete = var.cleanup_timeout
  }
}

# Deploy PriorityClass
resource "kubectl_manifest" "kubevirt_priorityclass" {
  yaml_body = templatefile("${path.module}/templates/kubevirt-priorityclass.yaml.tpl", {})
}

# Deploy KubeVirt CRD
resource "kubectl_manifest" "kubevirt_crd" {
  yaml_body = templatefile("${path.module}/templates/kubevirt-crd.yaml.tpl", {})

  depends_on = [kubernetes_namespace.this, kubectl_manifest.kubevirt_priorityclass]
}

# Deploy KubeVirt RBAC
resource "kubectl_manifest" "kubevirt_rbac" {
  yaml_body = templatefile("${path.module}/templates/kubevirt-rbac.yaml.tpl", {
    namespace = kubernetes_namespace.this.metadata[0].name
  })

  depends_on = [kubectl_manifest.kubevirt_crd]
}

# Deploy KubeVirt Operator Deployment
resource "kubernetes_manifest" "kubevirt_operator" {
  manifest = yamldecode(templatefile("${path.module}/templates/kubevirt-operator.yaml.tpl", {
    namespace        = kubernetes_namespace.this.metadata[0].name
    kubevirt_version = var.chart_version
    cpu_arch         = local.effective_cpu_arch
    cpu_limit        = var.cpu_limit
    memory_limit     = var.memory_limit
    cpu_request      = var.cpu_request
    memory_request   = var.memory_request
  }))

  depends_on = [kubectl_manifest.kubevirt_rbac]
}

# Deploy KubeVirt CR
# Note: Using kubectl_manifest instead of kubernetes_manifest to handle webhook issues
# The CR includes bypass annotations to prevent webhook connection failures
resource "kubectl_manifest" "kubevirt_cr" {
  yaml_body = templatefile("${path.module}/templates/kubevirt-cr.yaml.tpl", local.template_values)

  depends_on = [kubernetes_manifest.kubevirt_operator]
}

# ServiceMonitor for Prometheus metrics
resource "kubectl_manifest" "kubevirt_servicemonitor" {
  count = var.enable_servicemonitor ? 1 : 0

  yaml_body = templatefile("${path.module}/templates/servicemonitor.yaml.tpl", {
    namespace = kubernetes_namespace.this.metadata[0].name
  })

  depends_on = [kubectl_manifest.kubevirt_cr]
}

# ============================================================================
# FORCE CLEANUP RESOURCE FOR STUCK NAMESPACES
# ============================================================================

# Force cleanup resource for stuck namespaces (handles KubeVirt resources)
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

      echo "Starting KubeVirt namespace cleanup for $$NAMESPACE..."

      # Delete all VirtualMachineInstances, VirtualMachines, and VirtualMachineInstanceReplicaSets
      echo "Cleaning up KubeVirt virtual machine resources..."
      kubectl delete vm --all -n $$NAMESPACE --ignore-not-found=true --timeout=30s 2>/dev/null || true
      kubectl delete vmi --all -n $$NAMESPACE --ignore-not-found=true --timeout=30s 2>/dev/null || true
      kubectl delete vmirs --all -n $$NAMESPACE --ignore-not-found=true --timeout=30s 2>/dev/null || true

      # Delete KubeVirt custom resources
      echo "Cleaning up KubeVirt custom resources..."
      kubectl delete kubevirt $$NAMESPACE -n $$NAMESPACE --ignore-not-found=true --timeout=60s 2>/dev/null || true

      # Wait for namespace to enter terminating state
      echo "Waiting for namespace to enter terminating phase..."
      timeout 300 bash -c "until kubectl get namespace $$NAMESPACE -o jsonpath='{.status.phase}' | grep -q 'Terminating'; do sleep 2; done" 2>/dev/null || true

      # Handle KubeVirt stale subresources
      echo "Cleaning up stale KubeVirt subresources..."
      kubectl delete apiservice v1alpha3.subresources.kubevirt.io --ignore-not-found=true --timeout=30s 2>/dev/null || true
      kubectl delete apiservice v1.subresources.kubevirt.io --ignore-not-found=true --timeout=30s 2>/dev/null || true

      # Delete KubeVirt CRDs
      echo "Cleaning up KubeVirt CRDs..."
      kubectl get crd -o json | jq '.items[] | select(.metadata.name | contains("kubevirt.io")) | .metadata.name' | xargs -I {} kubectl delete crd {} --ignore-not-found=true --timeout=30s 2>/dev/null || true

      # Force remove namespace finalizers
      echo "Force removing namespace finalizers..."
      kubectl get namespace $$NAMESPACE -o json 2>/dev/null | \
        jq 'del(.spec.finalizers)' | \
        kubectl replace --raw "/api/v1/namespaces/$$NAMESPACE/finalize" -f - --timeout=$$CLEANUP_TIMEOUT 2>/dev/null || true

      # Verify namespace is deleted
      echo "Verifying namespace deletion..."
      timeout 600 bash -c "until ! kubectl get namespace $$NAMESPACE 2>/dev/null; do sleep 5; done" 2>/dev/null || true

      if ! kubectl get namespace $$NAMESPACE 2>/dev/null; then
        echo "✓ Namespace $$NAMESPACE successfully cleaned up."
      else
        echo "⚠ Namespace $$NAMESPACE cleanup may have issues, but process completed."
      fi
    EOT

    environment = {
      KUBECONFIG_PATH = self.triggers.kubeconfig_path
      NAMESPACE       = self.triggers.namespace
      CLEANUP_TIMEOUT = self.triggers.cleanup_timeout
    }
  }

  depends_on = [
    kubectl_manifest.kubevirt_cr
  ]
}
