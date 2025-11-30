# Rate Limiting Middleware - only create when CRDs are available
resource "kubectl_manifest" "rate_limit" {
  count = var.rate_limit.enabled && var.enable_middleware_resources ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "traefik.io/v1alpha1"
    kind       = "Middleware"
    metadata = {
      name      = "${var.name_prefix}-rate-limit"
      namespace = var.namespace
      labels    = var.labels
    }
    spec = {
      rateLimit = {
        average = var.rate_limit.average
        burst   = var.rate_limit.burst
      }
    }
  })
}

# IP Whitelist Middleware - only create when CRDs are available
resource "kubectl_manifest" "ip_whitelist" {
  count = var.ip_whitelist.enabled && var.enable_middleware_resources ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "traefik.io/v1alpha1"
    kind       = "Middleware"
    metadata = {
      name      = "${var.name_prefix}-ip-whitelist"
      namespace = var.namespace
      labels    = var.labels
    }
    spec = {
      ipAllowList = {
        sourceRange = var.ip_whitelist.source_ranges
      }
    }
  })
}
