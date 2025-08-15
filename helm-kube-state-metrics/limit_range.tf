# Limit Range for kube-state-metrics namespace
resource "kubernetes_limit_range" "this" {
  metadata {
    name      = "${local.module_config.name}-limit-range"
    namespace = kubernetes_namespace.this.metadata[0].name
    labels    = local.common_labels
  }

  spec {
    limit {
      type = "Container"
      default = {
        cpu    = local.module_config.cpu_limit
        memory = local.module_config.memory_limit
      }
      default_request = {
        cpu    = local.module_config.cpu_request
        memory = local.module_config.memory_request
      }
      max = {
        cpu    = "500m"
        memory = "512Mi"
      }
      min = {
        cpu    = "10m"
        memory = "32Mi"
      }
    }

    limit {
      type = "PersistentVolumeClaim"
      max = {
        storage = "10Gi"
      }
      min = {
        storage = "1Gi"
      }
    }
  }
}
