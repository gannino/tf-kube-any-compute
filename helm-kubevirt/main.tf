# ============================================================================
# HELM-KUBEVIRT MODULE - VIRTUAL MACHINE MANAGEMENT
# ============================================================================

# Create KubeVirt namespace
resource "kubernetes_namespace" "this" {
  metadata {
    name   = local.module_config.namespace
    labels = local.common_labels
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
# Note: Using kubectl_manifest instead of kubernetes_manifest to handle webhook deletion issues
# kubectl can bypass validating webhooks during deletion, preventing deadlock scenarios
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
