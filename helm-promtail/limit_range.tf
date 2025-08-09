resource "kubernetes_limit_range" "namespace_limits" {
  count = local.limit_range_config.enabled ? 1 : 0

  metadata {
    name      = "resource-limits"
    namespace = kubernetes_namespace.this.metadata[0].name
    labels    = local.common_labels
  }

  spec {
    limit {
      type = "Container"
      default = {
        cpu    = local.limit_range_config.container_defaults.cpu
        memory = local.limit_range_config.container_defaults.memory
      }
      default_request = {
        cpu    = local.limit_range_config.container_requests.cpu
        memory = local.limit_range_config.container_requests.memory
      }
      max = {
        cpu    = local.limit_range_config.container_limits.cpu
        memory = local.limit_range_config.container_limits.memory
      }
    }

    limit {
      type = "PersistentVolumeClaim"
      max = {
        storage = local.limit_range_config.pvc_limits.max_storage
      }
      min = {
        storage = local.limit_range_config.pvc_limits.min_storage
      }
    }
  }

  depends_on = [kubernetes_namespace.this]
}
