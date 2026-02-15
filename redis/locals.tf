# ============================================================================
# Redis Module - Local Values
# ============================================================================

locals {
  # Module configuration
  module_config = {
    namespace = var.namespace
    name      = var.name
  }

  # Common labels for all resources
  common_labels = {
    "app.kubernetes.io/managed-by" = "terraform"
    "app.kubernetes.io/part-of"    = "k8s-infrastructure"
    "app.kubernetes.io/name"       = "redis"
    "app.kubernetes.io/component"  = "caching"
  }

  # Resource configuration
  resources_config = {
    limits = {
      cpu    = var.cpu_limit
      memory = var.memory_limit
    }
    requests = {
      cpu    = var.cpu_request
      memory = var.memory_request
    }
  }
}
