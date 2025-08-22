# ============================================================================
# KUBERNETES INGRESS FOR NODE-RED WITH TRAEFIK ANNOTATIONS
# ============================================================================

resource "kubernetes_ingress_v1" "this" {
  count = var.enable_ingress ? 1 : 0

  metadata {
    name      = "${var.name}-ingress"
    namespace = kubernetes_namespace.this.metadata[0].name
    labels    = local.common_labels
    annotations = {
      "kubernetes.io/ingress.class"                           = "traefik"
      "traefik.ingress.kubernetes.io/router.tls"              = "true"
      "traefik.ingress.kubernetes.io/router.tls.certresolver" = var.traefik_cert_resolver
      "traefik.ingress.kubernetes.io/router.entrypoints"      = "websecure"
    }
  }

  spec {
    rule {
      host = "node-red.${var.domain_name}"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = data.kubernetes_service.this.metadata[0].name
              port {
                number = 1880
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    helm_release.this,
    data.kubernetes_service.this
  ]
}
