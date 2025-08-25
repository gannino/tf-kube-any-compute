locals {
  # Architecture-based node selector
  node_selector = var.disable_arch_scheduling ? {} : {
    "kubernetes.io/arch" = var.cpu_arch
  }

  # Common labels
  common_labels = {
    "app.kubernetes.io/name"       = var.name
    "app.kubernetes.io/instance"   = var.name
    "app.kubernetes.io/component"  = "homebridge"
    "app.kubernetes.io/managed-by" = "terraform"
  }

  # Ingress configuration
  ingress_enabled = var.enable_ingress
  ingress_host    = "homebridge${var.domain_name}"

  # Plugin list as JSON string for Helm values
  plugins_json = jsonencode(var.plugins)
}