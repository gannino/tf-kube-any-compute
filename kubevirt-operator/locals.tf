locals {
  # Module configuration
  module_config = {
    namespace     = var.namespace
    name          = var.name
    chart_version = var.chart_version
  }

  # Common labels
  common_labels = {
    "app.kubernetes.io/name"       = "kubevirt"
    "app.kubernetes.io/instance"   = var.name
    "app.kubernetes.io/managed-by" = "terraform"
  }

  # Auto-enable emulation for ARM64
  effective_emulation = var.enable_emulation || var.cpu_arch == "arm64"

  # Kubeconfig path detection (matches main provider.tf logic)
  kubeconfig_path = var.ci_mode ? null : (
    var.kubeconfig_path != "" ? var.kubeconfig_path : (
      var.workspace_prefix != "" ? "${pathexpand("~")}/.kube/${var.workspace_prefix}-config" : "${pathexpand("~")}/.kube/config"
    )
  )
}
