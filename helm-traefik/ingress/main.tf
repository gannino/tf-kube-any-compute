# BREAKING CHANGE: Legacy middleware system removed
# All authentication now handled by centralized middleware system

resource "kubernetes_manifest" "ingressroute_traefik_dashboard" {
  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "IngressRoute"
    metadata = {
      name      = "traefik-dashboard"
      namespace = var.namespace
      annotations = {
        "kubernetes.io/ingress.class" = "traefik"
      }
    }
    spec = {
      entryPoints = ["websecure"]
      routes = [
        {
          kind  = "Rule"
          match = "Host(`traefik.${var.domain_name}`)"
          # Use centralized middleware system only
          middlewares = [
            for middleware in var.dashboard_middleware : {
              name      = middleware
              namespace = var.namespace
            }
          ]
          services = [{
            kind = "TraefikService"
            name = "api@internal"
          }]
        }
      ]
      tls = {
        certResolver = var.traefik_cert_resolver
        domains = var.traefik_cert_resolver == "wildcard" ? [{
          main = var.domain_name
          sans = ["*.${var.domain_name}"]
          }] : [{
          main = "traefik.${var.domain_name}"
          sans = []
        }]
      }
    }
  }
}
