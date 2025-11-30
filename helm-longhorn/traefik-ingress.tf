data "kubernetes_service" "this" {
  count = var.enable_ingress && var.enable_dashboard ? 1 : 0
  metadata {
    name      = local.ingress_config.service_name
    namespace = kubernetes_namespace.this.metadata[0].name
  }
  depends_on = [helm_release.this]
}

resource "kubernetes_manifest" "dashboard_ingress" {
  count = var.enable_ingress && var.enable_dashboard ? 1 : 0

  manifest = {
    apiVersion = "networking.k8s.io/v1"
    kind       = "Ingress"
    metadata = {
      name        = "${local.module_config.name}-ingress"
      namespace   = kubernetes_namespace.this.metadata[0].name
      annotations = merge(local.ingress_config.base_annotations, local.ingress_config.tls_annotations)
    }
    spec = {
      ingressClassName = var.traefik_ingress_config != null ? var.traefik_ingress_config.class_name : "traefik"
      rules = [{
        host = local.ingress_config.host
        http = {
          paths = [{
            path     = local.ingress_config.path
            pathType = "Prefix"
            backend = {
              service = {
                name = data.kubernetes_service.this[0].metadata[0].name
                port = {
                  number = local.ingress_config.service_port
                }
              }
            }
          }]
        }
      }]
    }
  }

  depends_on = [helm_release.this]
}
