# ServiceMonitor for Traefik metrics
resource "kubernetes_manifest" "traefik_servicemonitor" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "${var.name}-metrics"
      namespace = var.namespace
      labels = merge(local.common_labels, {
        "app.kubernetes.io/name"      = "traefik"
        "app.kubernetes.io/component" = "metrics"
      })
    }
    spec = {
      selector = {
        matchLabels = {
          "app.kubernetes.io/name"     = "traefik"
          "app.kubernetes.io/instance" = var.name
        }
      }
      endpoints = [
        {
          port     = "metrics"
          path     = "/metrics"
          interval = "30s"
        }
      ]
    }
  }

  depends_on = [
    helm_release.this
  ]
}
