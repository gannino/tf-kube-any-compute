data "kubernetes_service" "gateway" {
  count = local.module_config.enable_ingress ? 1 : 0
  metadata {
    name      = "${local.module_config.name}-gateway"
    namespace = kubernetes_namespace.this.metadata[0].name
  }
  depends_on = [helm_release.this]
}

resource "kubernetes_ingress_v1" "this" {
  count = local.module_config.enable_ingress ? 1 : 0
  metadata {
    name      = "${local.module_config.name}-ingress"
    namespace = kubernetes_namespace.this.metadata[0].name
    annotations = merge({
      "kubernetes.io/ingress.class"                           = "traefik"
      "traefik.ingress.kubernetes.io/router.entrypoints"      = "websecure"
      "traefik.ingress.kubernetes.io/router.tls"              = "true"
      "traefik.ingress.kubernetes.io/router.tls.certresolver" = local.module_config.traefik_cert_resolver
      }, local.module_config.traefik_cert_resolver == "wildcard" ? {
      "traefik.ingress.kubernetes.io/router.tls.domains.0.main" = local.module_config.domain_name
      "traefik.ingress.kubernetes.io/router.tls.domains.0.sans" = "*.${local.module_config.domain_name}"
      } : {
      "traefik.ingress.kubernetes.io/router.tls.domains.0.main" = "loki.${local.module_config.domain_name}"
    })
  }

  spec {
    ingress_class_name = "traefik"
    tls {
      hosts = ["loki.${local.module_config.domain_name}"]
    }
    rule {
      host = "loki.${local.module_config.domain_name}"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = data.kubernetes_service.gateway[0].metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
  depends_on = [helm_release.this]
}
