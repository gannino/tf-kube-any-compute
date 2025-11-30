# ============================================================================
# KUBERNETES INGRESS FOR N8N WITH TRAEFIK ANNOTATIONS
# ============================================================================

resource "kubernetes_ingress_v1" "this" {
  count = var.enable_ingress ? 1 : 0

  metadata {
    name      = "${var.name}-ingress"
    namespace = kubernetes_namespace.this.metadata[0].name
    labels    = local.common_labels
    annotations = merge(
      var.traefik_ingress_config != null ? var.traefik_ingress_config.annotations : {
        "traefik.ingress.kubernetes.io/router.tls"         = "true"
        "traefik.ingress.kubernetes.io/router.entrypoints" = "websecure"
      },
      {
        "traefik.ingress.kubernetes.io/router.tls.certresolver" = var.traefik_ingress_config != null ? var.traefik_ingress_config.cert_resolver : var.traefik_cert_resolver
      }
    )
  }

  spec {
    ingress_class_name = var.traefik_ingress_config != null ? var.traefik_ingress_config.class_name : "traefik"

    tls {
      hosts = [local.n8n_host]
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
