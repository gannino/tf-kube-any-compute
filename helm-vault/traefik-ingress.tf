resource "time_sleep" "wait_for_crd_registration" {
  # This sleep will only trigger after the Traefik Helm release is applied.
  # IMPORTANT: You must replace 'module.traefik.helm_release.this' with the
  # actual address of your Traefik helm_release resource.
  depends_on = [helm_release.this]

  create_duration = var.ingress_sleep_duration
}

# This data source is useful for discovering the service that selects the Vault pods.
data "kubernetes_service" "this" {
  metadata {
    name      = local.module_config.name
    namespace = kubernetes_namespace.this.metadata[0].name
  }
  depends_on = [helm_release.this]
}

# --------------------------------------------------------------------------
# SOLUTION: IngressRoute with Health Check Configuration
# This directly configures health checks on the service reference in the IngressRoute
# --------------------------------------------------------------------------
# This resource creates a Traefik IngressRoute for Vault with health check configuration.
# It is enabled only when Traefik ingress is selected via local.ingress_selector.
resource "kubernetes_manifest" "vault_ingress_route" {
  count = local.ingress_selector == "traefik" ? 1 : 0

  depends_on = [data.kubernetes_service.this, time_sleep.wait_for_crd_registration]

  manifest = local.ingress_config.traefik_ingress_route.manifest
}

# --------------------------------------------------------------------------
# OLD CODE (for reference - you can now delete this from your .tf file)
# --------------------------------------------------------------------------

# Kubernetes Ingress resource for Vault UI
resource "kubernetes_ingress_v1" "this" {
  count = local.ingress_selector == "k8s" ? 1 : 0

  metadata {
    name        = local.ingress_config.k8s_ingress.name
    namespace   = kubernetes_namespace.this.metadata[0].name
    annotations = local.ingress_config.k8s_ingress.annotations
    labels      = local.common_labels
  }

  spec {
    ingress_class_name = "traefik"

    rule {
      host = local.ingress_config.k8s_ingress.host
      http {
        path {
          path      = local.ingress_config.k8s_ingress.path
          path_type = local.ingress_config.k8s_ingress.path_type
          backend {
            service {
              name = data.kubernetes_service.this.metadata[0].name
              port {
                number = local.ingress_config.k8s_ingress.service_port
              }
            }
          }
        }
      }
    }
  }

  depends_on = [data.kubernetes_service.this]
}
