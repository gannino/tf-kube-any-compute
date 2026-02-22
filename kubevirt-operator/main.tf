# ============================================================================
# KUBEVIRT MODULE - VIRTUAL MACHINE MANAGEMENT
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

# Fetch KubeVirt operator manifest
data "http" "kubevirt_operator" {
  url = "https://github.com/kubevirt/kubevirt/releases/download/${var.chart_version}/kubevirt-operator.yaml"
}

# Parse KubeVirt operator manifest
data "kubectl_file_documents" "kubevirt_operator" {
  content = data.http.kubevirt_operator.response_body
}

# Apply KubeVirt operator
resource "kubectl_manifest" "kubevirt_operator" {
  for_each = data.kubectl_file_documents.kubevirt_operator.manifests

  yaml_body = each.value

  depends_on = [kubernetes_namespace.this]
}

# Wait for operator to be ready
resource "null_resource" "wait_for_operator" {
  depends_on = [kubectl_manifest.kubevirt_operator]

  triggers = {
    namespace       = kubernetes_namespace.this.metadata[0].name
    kubeconfig_path = local.kubeconfig_path
  }

  provisioner "local-exec" {
    command = <<EOT
      export KUBECONFIG="${self.triggers.kubeconfig_path}"

      echo "Cleaning up old webhook configurations..."
      kubectl delete validatingwebhookconfiguration virt-operator-validator --ignore-not-found=true || true
      kubectl delete validatingwebhookconfiguration virt-api-validator --ignore-not-found=true || true
      kubectl delete mutatingwebhookconfiguration virt-api-mutator --ignore-not-found=true || true

      echo "Waiting for virt-operator deployment..."
      kubectl wait --for=condition=available --timeout=300s deployment/virt-operator -n ${self.triggers.namespace} || true
      sleep 10
    EOT
  }
}

# Fetch KubeVirt CR manifest
data "http" "kubevirt_cr" {
  url = "https://github.com/kubevirt/kubevirt/releases/download/${var.chart_version}/kubevirt-cr.yaml"
}

# Parse and customize KubeVirt CR
locals {
  kubevirt_cr_base = yamldecode(data.http.kubevirt_cr.response_body)

  kubevirt_cr_customized = merge(local.kubevirt_cr_base, {
    metadata = merge(local.kubevirt_cr_base.metadata, {
      namespace = kubernetes_namespace.this.metadata[0].name
    })
    spec = merge(local.kubevirt_cr_base.spec, {
      configuration = {
        developerConfiguration = {
          featureGates = local.effective_emulation ? ["HardwareVirtualization"] : []
        }
      }
    })
  })
}

# Apply KubeVirt CR
resource "kubectl_manifest" "kubevirt_cr" {
  yaml_body = yamlencode(local.kubevirt_cr_customized)

  depends_on = [null_resource.wait_for_operator]
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

# Cleanup API services before destroying namespace
resource "null_resource" "cleanup_apiservices" {
  triggers = {
    namespace       = kubernetes_namespace.this.metadata[0].name
    kubeconfig_path = local.kubeconfig_path
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<EOT
      export KUBECONFIG="${self.triggers.kubeconfig_path}"

      echo "Cleaning up KubeVirt API services..."
      kubectl delete apiservice v1.subresources.kubevirt.io --ignore-not-found=true --timeout=30s 2>/dev/null || true
      kubectl delete apiservice v1alpha3.subresources.kubevirt.io --ignore-not-found=true --timeout=30s 2>/dev/null || true

      echo "✓ API services cleaned up."
    EOT
  }

  depends_on = [kubectl_manifest.kubevirt_cr]
}

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
      export KUBECONFIG="${self.triggers.kubeconfig_path}"

      echo "Starting KubeVirt namespace cleanup for ${self.triggers.namespace}..."

      # Delete VMs and VMIs
      kubectl delete vm --all -n ${self.triggers.namespace} --ignore-not-found=true --timeout=30s 2>/dev/null || true
      kubectl delete vmi --all -n ${self.triggers.namespace} --ignore-not-found=true --timeout=30s 2>/dev/null || true
      kubectl delete vmirs --all -n ${self.triggers.namespace} --ignore-not-found=true --timeout=30s 2>/dev/null || true

      # Delete KubeVirt CR
      kubectl delete kubevirt kubevirt -n ${self.triggers.namespace} --ignore-not-found=true --timeout=60s 2>/dev/null || true

      # Delete API services
      kubectl delete apiservice v1alpha3.subresources.kubevirt.io --ignore-not-found=true --timeout=30s 2>/dev/null || true
      kubectl delete apiservice v1.subresources.kubevirt.io --ignore-not-found=true --timeout=30s 2>/dev/null || true

      # Delete CRDs
      kubectl get crd -o name 2>/dev/null | grep kubevirt.io | xargs -r kubectl delete --ignore-not-found=true --timeout=30s 2>/dev/null || true

      # Force remove namespace finalizers if stuck
      if kubectl get namespace ${self.triggers.namespace} 2>/dev/null | grep -q Terminating; then
        echo "Namespace stuck in Terminating, removing finalizers..."
        kubectl get namespace ${self.triggers.namespace} -o json 2>/dev/null | \
          jq 'del(.spec.finalizers)' | \
          kubectl replace --raw "/api/v1/namespaces/${self.triggers.namespace}/finalize" -f - 2>/dev/null || true
      fi

      echo "✓ Namespace ${self.triggers.namespace} cleanup completed."
    EOT
  }

  depends_on = [null_resource.cleanup_apiservices]
}
