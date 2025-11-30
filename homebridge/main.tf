# Create namespace
resource "kubernetes_namespace" "this" {
  metadata {
    name   = var.namespace
    labels = local.common_labels
  }
}

# Note: Using native Kubernetes deployment instead of Helm due to unavailable chart repository
