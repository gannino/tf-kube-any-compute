# ServiceMonitor for Authelia metrics
resource "kubectl_manifest" "authelia_servicemonitor" {
  count = var.enable_servicemonitor ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "${var.name}-metrics"
      namespace = var.servicemonitor_namespace
      labels = merge(local.common_labels, {
        "app.kubernetes.io/name"      = "authelia"
        "app.kubernetes.io/component" = "metrics"
      })
    }
    spec = {
      selector = {
        matchLabels = {
          "app.kubernetes.io/name" = "authelia"
        }
      }
      endpoints = [
        {
          port          = "http"
          path          = "/metrics"
          interval      = "30s"
          scrapeTimeout = "10s"
        }
      ]
    }
  })

  depends_on = [
    helm_release.this
  ]
}
