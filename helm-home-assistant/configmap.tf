# ConfigMap for Home Assistant HTTP configuration
resource "kubernetes_config_map" "http_config" {
  metadata {
    name      = "${var.name}-http-config"
    namespace = kubernetes_namespace.this.metadata[0].name
  }

  data = {
    "configuration.yaml" = yamlencode({
      http = {
        use_x_forwarded_for = var.use_x_forwarded_for
        trusted_proxies     = var.trusted_proxies
      }
    })
  }
}
