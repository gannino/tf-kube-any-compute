data "kubernetes_service" "alertmanager" {
  metadata {
    name      = local.service_names.alertmanager
    namespace = kubernetes_namespace.this.metadata[0].name
  }
  depends_on = [helm_release.this]
}

resource "kubernetes_ingress_v1" "alertmanager" {
  count = var.enable_alertmanager_ingress ? 1 : 0
  
  metadata {
    name      = "${local.module_config.name}-alertmanager-ingress"
    namespace = kubernetes_namespace.this.metadata[0].name
    annotations = merge(local.ingress_config.base_annotations, local.ingress_config.tls_annotations,
      var.enable_monitoring_auth ? {
        "traefik.ingress.kubernetes.io/router.middlewares" = "${kubernetes_namespace.this.metadata[0].name}-monitoring-basic-auth@kubernetescrd"
      } : {},
      local.module_config.traefik_cert_resolver != "wildcard" ? {
        "traefik.ingress.kubernetes.io/router.tls.domains.0.main" = local.ingress_config.alertmanager_host
      } : {}
    )
  }

  spec {
    ingress_class_name = local.ingress_config.ingress_class

    rule {
      host = local.ingress_config.alertmanager_host
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = data.kubernetes_service.alertmanager.metadata[0].name
              port {
                number = local.ports.alertmanager
              }
            }
          }
        }
      }
    }
  }

  depends_on = [data.kubernetes_service.alertmanager]
}