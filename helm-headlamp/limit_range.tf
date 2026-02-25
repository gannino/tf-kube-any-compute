resource "kubernetes_limit_range_v1" "this" {
  metadata {
    name      = "${var.name}-resource-limits"
    namespace = kubernetes_namespace.this.metadata[0].name
    labels = merge(local.common_labels, {
      "app.kubernetes.io/component" = "resource-limits"
    })
  }
  spec {
    limit {
      type = "Container"

      default = {
        cpu    = var.cpu_limit
        memory = var.memory_limit
      }

      default_request = {
        cpu    = var.cpu_request
        memory = var.memory_request
      }
    }
  }
}
