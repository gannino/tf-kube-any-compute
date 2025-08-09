resource "kubernetes_limit_range" "namespace_limits" {
  metadata {
    name      = "resource-limits"
    namespace = kubernetes_namespace.this.metadata[0].name
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
    }
    #TODO: think how to improve limits
    # limit {
    #   type = "Pod"

    #   max = {
    #     cpu    = var.cpu_limit
    #     memory = var.memory_limit
    #   }

    #   min = {
    #     cpu    = var.cpu_request
    #     memory = var.memory_request
    #   }
    # }
  }
}
