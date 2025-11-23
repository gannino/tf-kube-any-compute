# ============================================================================
# HELM-OPENHAB MODULE - VENDOR-NEUTRAL HOME AUTOMATION PLATFORM
# ============================================================================

# Create openHAB namespace
resource "kubernetes_namespace" "this" {
  metadata {
    labels = local.common_labels
    name   = local.module_config.namespace
  }
}

# Note: Using native Kubernetes deployment instead of Helm due to unavailable chart repository
