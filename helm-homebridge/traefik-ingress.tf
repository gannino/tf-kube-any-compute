# Traefik IngressRoute for Homebridge
resource "kubernetes_manifest" "ingress_route" {
  count = local.ingress_enabled ? 1 : 0

  manifest = {
    apiVersion = "traefik.containo.us/v1alpha1"
    kind       = "IngressRoute"
    metadata = {
      name      = "${var.name}-ingress"
      namespace = kubernetes_namespace.this.metadata[0].name
      labels    = local.common_labels
    }
    spec = {
      entryPoints = ["websecure"]
      routes = [
        {
          match = "Host(`${local.ingress_host}`)"
          kind  = "Rule"
          services = [
            {
              name = data.kubernetes_service.this.metadata[0].name
              port = data.kubernetes_service.this.spec[0].port[0].port
            }
          ]
        }
      ]
      tls = {
        certResolver = var.traefik_cert_resolver
      }
    }
  }

  depends_on = [
    helm_release.this,
    data.kubernetes_service.this
  ]
}

# Data source to get the service information
data "kubernetes_service" "this" {
  metadata {
    name      = var.name
    namespace = kubernetes_namespace.this.metadata[0].name
  }

  depends_on = [helm_release.this]
}
