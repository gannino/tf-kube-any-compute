data "kubernetes_service" "this" {
  metadata {
    name      = local.ingress_config.service_name
    namespace = kubernetes_namespace.this.metadata[0].name
  }
  depends_on = [helm_release.this]
}

resource "kubernetes_ingress_v1" "this" {
  count = local.ingress_config.enabled ? 1 : 0

  metadata {
    name        = local.ingress_config.name
    namespace   = kubernetes_namespace.this.metadata[0].name
    labels      = local.common_labels
    annotations = local.ingress_config.annotations
  }

  spec {
    ingress_class_name = local.ingress_config.class_name

    rule {
      host = local.ingress_config.host
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = data.kubernetes_service.this.metadata[0].name
              port {
                number = local.ingress_config.service_port
              }
            }
          }
        }
      }
    }
  }

  depends_on = [data.kubernetes_service.this]
}
