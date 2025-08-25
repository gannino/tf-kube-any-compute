# ============================================================================
# TRAEFIK INGRESS ROUTE FOR OPENHAB
# ============================================================================

resource "kubernetes_manifest" "ingress_route" {
  count = var.enable_ingress ? 1 : 0

  manifest = {
    apiVersion = "traefik.containo.us/v1alpha1"
    kind       = "IngressRoute"
    metadata = {
      name      = "${local.module_config.name}-ingress"
      namespace = kubernetes_namespace.this.metadata[0].name
      labels    = local.common_labels
    }
    spec = {
      entryPoints = ["websecure"]
      routes = [
        {
          match = "Host(`${local.ingress_config.host}`)"
          kind  = "Rule"
          services = [
            {
              name = local.ingress_config.service_name
              port = local.ingress_config.service_port
            }
          ]
        }
      ]
      tls = {
        certResolver = local.module_config.traefik_cert_resolver
      }
    }
  }

  depends_on = [helm_release.this]
}

# Optional Karaf console ingress (for debugging)
resource "kubernetes_manifest" "karaf_ingress_route" {
  count = var.enable_ingress && var.enable_karaf_console ? 1 : 0

  manifest = {
    apiVersion = "traefik.containo.us/v1alpha1"
    kind       = "IngressRoute"
    metadata = {
      name      = "${local.module_config.name}-karaf-ingress"
      namespace = kubernetes_namespace.this.metadata[0].name
      labels    = local.common_labels
    }
    spec = {
      entryPoints = ["websecure"]
      routes = [
        {
          match = "Host(`openhab-karaf.${local.module_config.domain_name}`)"
          kind  = "Rule"
          services = [
            {
              name = local.ingress_config.service_name
              port = 8101
            }
          ]
        }
      ]
      tls = {
        certResolver = local.module_config.traefik_cert_resolver
      }
    }
  }

  depends_on = [helm_release.this]
}
