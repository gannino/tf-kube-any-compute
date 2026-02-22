# Traefik Ingress for Authelia using standard Kubernetes Ingress
resource "kubernetes_ingress_v1" "this" {
  metadata {
    name      = "${var.name}-ingress"
    namespace = kubernetes_namespace.this.metadata[0].name
    labels = merge(local.common_labels, {
      "ingress.kubernetes.io/class" = var.traefik_ingress_config != null ? var.traefik_ingress_config.class_name : "traefik"
    })
    annotations = merge(
      local.ingress_config.base_annotations,
      local.ingress_config.tls_annotations,
      {
        "traefik.ingress.kubernetes.io/router.entrypoints"      = "websecure"
        "traefik.ingress.kubernetes.io/router.tls"              = "true"
        "traefik.ingress.kubernetes.io/router.tls.certresolver" = var.traefik_cert_resolver
      }
    )
  }

  spec {
    ingress_class_name = var.traefik_ingress_config != null ? var.traefik_ingress_config.class_name : "traefik"

    tls {
      hosts = ["authelia.${var.domain_name}"]
    }

    rule {
      host = "authelia.${var.domain_name}"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = var.name
              port {
                number = 9091
              }
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.this]
}
