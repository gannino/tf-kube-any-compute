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

  # Effective CPU architecture (empty string if scheduling disabled)
  effective_cpu_arch = var.disable_arch_scheduling ? "" : var.cpu_arch

  # Auto-enable emulation for ARM64
  effective_emulation = var.enable_emulation || var.cpu_arch == "arm64"

  # Template values
  template_values = {
    namespace             = var.namespace
    enable_emulation      = local.effective_emulation
    enable_servicemonitor = var.enable_servicemonitor
    cpu_arch              = local.effective_cpu_arch
  }
}
