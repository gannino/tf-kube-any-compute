# ============================================================================
# NATIVE TERRAFORM N8N MODULE LOCALS - COMPUTED CONFIGURATION
# ============================================================================

locals {
  # Module configuration
  module_config = {
    name      = var.name
    namespace = var.namespace
  }

  # Common labels
  common_labels = {
    "app.kubernetes.io/name"       = "n8n"
    "app.kubernetes.io/instance"   = var.name
    "app.kubernetes.io/component"  = "workflow-automation"
    "app.kubernetes.io/part-of"    = "homelab-automation"
    "app.kubernetes.io/managed-by" = "terraform"
  }

  # n8n configuration
  n8n_version = "latest"
  n8n_host    = "n8n.${var.domain_name}"
}
