# ============================================================================
# HELM-TRAEFIK MODULE - STANDARDIZED CONFIGURATION PATTERNS
# ============================================================================
# This module follows the standardized patterns for Task 3:
# - locals for computed values
# - variables for inputs with validation
# - clear conditions for service enablement
# ============================================================================

locals {
  # ============================================================================
  # COMPUTED VALUES - All derived/computed values use locals
  # ============================================================================

  # Generate random token for Hurricane Electric (backward compatibility)
  hurricane_token = random_password.hurricane_token.result

  # Module configuration with defaults and overrides
  module_config = {
    # Core settings
    namespace     = var.namespace
    name          = var.name
    chart_name    = var.chart_name
    chart_repo    = var.chart_repo
    chart_version = var.chart_version

    # Domain configuration
    domain_name = var.domain_name

    # Storage configuration
    storage_class = var.storage_class
    storage_size  = var.persistent_disk_size

    # Feature flags
    enable_ingress = var.enable_ingress

    # Architecture and node selection
    cpu_arch = var.cpu_arch

    # Resource limits
    cpu_limit      = var.cpu_limit
    memory_limit   = var.memory_limit
    cpu_request    = var.cpu_request
    memory_request = var.memory_request

    # Port configuration
    http_port      = var.http_port
    https_port     = var.https_port
    dashboard_port = var.dashboard_port
    metrics_port   = var.metrics_port

    # Timeout configuration
    deployment_wait_timeout = var.deployment_wait_timeout
  }

  # Helm configuration with validation
  helm_config = {
    timeout          = var.helm_timeout
    disable_webhooks = var.helm_disable_webhooks
    skip_crds        = var.helm_skip_crds
    replace          = var.helm_replace
    force_update     = var.helm_force_update
    cleanup_on_fail  = var.helm_cleanup_on_fail
    wait             = var.helm_wait
    wait_for_jobs    = var.helm_wait_for_jobs
  }

  # Computed labels
  common_labels = {
    "app.kubernetes.io/name"       = local.module_config.name
    "app.kubernetes.io/component"  = "ingress-controller"
    "app.kubernetes.io/managed-by" = "terraform"
    "app.kubernetes.io/part-of"    = "infrastructure"
  }

  # DNS provider configuration with backward compatibility
  dns_config = {
    primary_provider     = try(var.dns_providers.primary.name, "hurricane")
    primary_config       = try(var.dns_providers.primary.config, {})
    additional_providers = try(var.dns_providers.additional, [])
    challenge_config     = var.dns_challenge_config

    # Hurricane Electric tokens with proper priority: configured > legacy > auto-generated
    hurricane_tokens = (
      try(var.dns_providers.primary.config.HE_TOKENS, "") != "" ? var.dns_providers.primary.config.HE_TOKENS :
      var.hurricane_tokens != "" ? var.hurricane_tokens :
      "${var.domain_name}:${random_password.hurricane_token.result}"
    )
  }

  # Certificate resolver configuration - create resolver with DNS provider name
  computed_cert_resolvers = merge(
    {
      # Default HTTP challenge resolver
      default = merge(try(var.cert_resolvers.default, { challenge_type = "http" }), {
        dns_provider = coalesce(try(var.cert_resolvers.default.dns_provider, null), try(var.dns_providers.primary.name, "hurricane"))
      })

      # DNS provider-named resolver for DNS challenges
      (local.dns_config.primary_provider) = {
        challenge_type = "dns"
        dns_provider   = local.dns_config.primary_provider
      }
    },
    # Custom resolvers
    {
      for name, resolver in try(var.cert_resolvers.custom, {}) : name => merge(resolver, {
        dns_provider = coalesce(resolver.dns_provider, try(var.dns_providers.primary.name, "hurricane"))
      })
    }
  )

  # Template values for Helm chart
  template_values = {
    # Template variables used in traefik-values.yaml.tpl
    le_email                = var.le_email
    ingress_gateway_name    = local.module_config.name
    cpu_arch                = local.module_config.cpu_arch
    disable_arch_scheduling = var.disable_arch_scheduling
    cpu_limit               = local.module_config.cpu_limit
    memory_limit            = local.module_config.memory_limit
    cpu_request             = local.module_config.cpu_request
    memory_request          = local.module_config.memory_request
    storage_class           = local.module_config.storage_class
    persistent_disk_size    = local.module_config.storage_size
    consul_url              = var.consul_url
    traefik_cert_resolver   = var.traefik_cert_resolver

    # Port configuration
    http_port      = local.module_config.http_port
    https_port     = local.module_config.https_port
    dashboard_port = local.module_config.dashboard_port
    metrics_port   = local.module_config.metrics_port

    # DNS provider configuration
    dns_config     = local.dns_config
    cert_resolvers = local.computed_cert_resolvers

    # Tracing configuration
    enable_tracing  = try(var.enable_tracing, false)
    tracing_backend = try(var.tracing_backend, "loki")
    loki_endpoint   = try(var.loki_endpoint, "")
    jaeger_endpoint = try(var.jaeger_endpoint, "")
  }
}
