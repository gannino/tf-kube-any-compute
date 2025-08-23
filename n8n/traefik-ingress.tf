# ============================================================================
# KUBERNETES INGRESS FOR N8N WITH TRAEFIK ANNOTATIONS
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
    tls {
      hosts       = [local.n8n_host]
      secret_name = "${var.name}-tls"
    }

    rule {
      host = local.n8n_host
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.n8n.metadata[0].name
              port {
                number = 5678
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_service.n8n
  ]
}
