data "kubernetes_service" "prometheus" {
  metadata {
    name      = local.service_names.prometheus
    namespace = kubernetes_namespace.this.metadata[0].name
  }
  depends_on = [helm_release.this]
}

resource "kubernetes_ingress_v1" "prometheus" {
  count = var.enable_prometheus_ingress ? 1 : 0

  metadata {
    name      = "${local.module_config.name}-prometheus-ingress"
    namespace = kubernetes_namespace.this.metadata[0].name
    annotations = merge(local.ingress_config.base_annotations, local.ingress_config.tls_annotations,
      length(var.traefik_security_middlewares) > 0 ? {
        "traefik.ingress.kubernetes.io/router.middlewares" = join(",", [for mw in var.traefik_security_middlewares : "${var.traefik_middleware_namespace}-${mw}@kubernetescrd"])
      } : {},
      local.module_config.traefik_cert_resolver != "default" ? {
        "traefik.ingress.kubernetes.io/router.tls.domains.0.main" = local.module_config.domain_name
        "traefik.ingress.kubernetes.io/router.tls.domains.0.sans" = "*.${local.module_config.domain_name}"
      } : {}
    )
  }

  spec {
    ingress_class_name = local.ingress_config.ingress_class

    rule {
      host = local.ingress_config.prometheus_host
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = data.kubernetes_service.prometheus.metadata[0].name
              port {
                number = local.ports.prometheus
              }
            }
          }
        }
      }
    }
  }

  depends_on = [data.kubernetes_service.prometheus]
}
