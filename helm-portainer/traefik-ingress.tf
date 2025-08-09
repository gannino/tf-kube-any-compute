resource "kubernetes_manifest" "portainer_ingress" {
  count = var.enable_portainer_ingress_route ? 1 : 0

  manifest = {
    apiVersion = "networking.k8s.io/v1"
    kind       = "Ingress"
    metadata = {
      name        = "${local.module_config.name}-ingress"
      namespace   = kubernetes_namespace.this.metadata[0].name
      annotations = merge(local.ingress_config.base_annotations, local.ingress_config.tls_annotations)
    }
    spec = {
      ingressClassName = "traefik"
      rules = [{
        host = local.ingress_config.host
        http = {
          paths = [{
            path     = local.ingress_config.path
            pathType = "Prefix"
            backend = {
              service = {
                name = data.kubernetes_service.this.metadata[0].name
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