# ============================================================================
# TRAEFIK INGRESS FOR HOMEBRIDGE
# ============================================================================

resource "kubernetes_ingress_v1" "this" {
  count = var.enable_ingress ? 1 : 0

  metadata {
    name        = "${var.name}-ingress"
    namespace   = kubernetes_namespace.this.metadata[0].name
    annotations = merge(local.ingress_config.base_annotations, local.ingress_config.tls_annotations)
  }

  spec {
    ingress_class_name = "traefik"
    tls {
      hosts = [local.ingress_config.host]
    }
    rule {
      host = local.ingress_config.host
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.this.metadata[0].name
              port {
                number = local.ingress_config.service_port
              }
            }
          }
        }
      }
    }
  }
  depends_on = [kubernetes_service.this]
}
