# ServiceMonitor for Consul metrics
resource "kubernetes_manifest" "consul_servicemonitor" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "${var.name}-metrics"
      namespace = var.namespace
      labels = merge(local.common_labels, {
        "app.kubernetes.io/name"      = "consul"
        "app.kubernetes.io/component" = "metrics"
      })
    }
    spec = {
      selector = {
        matchLabels = {
          app       = "consul"
          component = "server"
        }
      }
      endpoints = [
        {
          port = "http"
          path = "/v1/agent/metrics"
          params = {
            format = ["prometheus"]
          }
          interval = "30s"
        }
      ]
    }
  }

  depends_on = [
    helm_release.this
  ]
}
