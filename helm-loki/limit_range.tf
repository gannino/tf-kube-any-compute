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
  }
}