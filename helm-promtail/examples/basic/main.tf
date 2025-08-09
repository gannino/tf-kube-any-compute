# Basic Promtail Example

module "promtail" {
  source = "../../"

  namespace     = "monitoring"
  chart_version = "6.16.6"
  loki_url      = "http://loki.monitoring.svc.cluster.local:3100"

  # Basic resource configuration
  resource_limits = {
    requests = {
      cpu    = "100m"
      memory = "128Mi"
    }
    limits = {
      cpu    = "200m"
      memory = "256Mi"
    }
  }

  # Enable monitoring
  service_monitor_enabled = true

  # Basic logging level
  log_level = "info"
}
