# ServiceMonitor for Traefik metrics
resource "kubectl_manifest" "traefik_servicemonitor" {
  count = var.enable_servicemonitor ? 1 : 0

  yaml_body = yamlencode({
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
  })

  depends_on = [
    helm_release.this
  ]
}
