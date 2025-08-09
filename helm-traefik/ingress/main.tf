# Middleware Secret for Basic Auth
resource "random_password" "password" {
  count   = var.traefik_dashboard_password == "" ? 1 : 0
  length  = 12
  special = false
}

locals {
  dashboard_password = var.traefik_dashboard_password != "" ? var.traefik_dashboard_password : random_password.password[0].result
}

resource "kubernetes_secret" "traefik_dashboard_auth" {
  metadata {
    name      = "traefik-dashboard-auth"
    namespace = var.namespace
  }

  data = {
    users = "admin:${bcrypt(local.dashboard_password, 6)}"
  }

  type = "Opaque"
}

output "traefik_dashboard_password" {
  value     = local.dashboard_password
  sensitive = true
}

# Traefik Basic Auth Middleware (uses the secret above)
resource "kubernetes_manifest" "traefik_dashboard_auth_middleware" {
  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "Middleware"
    metadata = {
      name      = "admin-basic-auth"
      namespace = var.namespace
    }
    spec = {
      basicAuth = {
        secret = kubernetes_secret.traefik_dashboard_auth.metadata[0].name
      }
    }
  }
}

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
          middlewares = [{
            name      = kubernetes_manifest.traefik_dashboard_auth_middleware.manifest.metadata.name
            namespace = var.namespace
          }]
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
