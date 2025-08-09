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
        cpu    = local.resource_config.limits.cpu
        memory = local.resource_config.limits.memory
      }

      default_request = {
        cpu    = local.resource_config.requests.cpu
        memory = local.resource_config.requests.memory
      }

      max = {
        cpu    = local.limit_range_config.container_max_cpu
        memory = local.limit_range_config.container_max_memory
      }
    }

    # PVC limits for storage security
    limit {
      type = "PersistentVolumeClaim"

      max = {
        storage = local.limit_range_config.pvc_max_storage
      }

      min = {
        storage = local.limit_range_config.pvc_min_storage
      }
    }
  }
}
