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
    traefik_uid             = var.traefik_uid
    traefik_gid             = var.traefik_gid
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

  # ACME initialization script for Longhorn storage
  # This script runs in a Kubernetes Job before Traefik starts to ensure
  # ACME files exist with correct permissions (600) and ownership (UID:GID)
  # This prevents Traefik from skipping the hurricane resolver due to permission errors
  acme_init_script = <<-EOT
    set -e

    echo "=== ACME File Initializer for Longhorn CSI ==="
    echo "Storage class: ${local.module_config.storage_class}"
    echo "Namespace: ${kubernetes_namespace.this.metadata[0].name}"
    echo "PVC: ${local.module_config.name}-certs"
    echo "Target ownership: ${var.traefik_uid}:${var.traefik_gid} (Traefik user)"
    echo "Target permissions: 600 (rw-------)"

    # Ensure directory exists
    echo "Creating ACME directory..."
    mkdir -p /certs

    # Create acme-hurricane.json with correct ownership and permissions
    if [ ! -f /certs/acme-hurricane.json ]; then
      echo "Creating acme-hurricane.json with correct ownership (${var.traefik_uid}:${var.traefik_gid}) and permissions (600)..."
      echo '{"hurricane":{}}' > /certs/acme-hurricane.json
      chown ${var.traefik_uid}:${var.traefik_gid} /certs/acme-hurricane.json
      chmod 600 /certs/acme-hurricane.json
    fi

    # Create acme.json with correct ownership and permissions
    if [ ! -f /certs/acme.json ]; then
      echo "Creating acme.json with correct ownership (${var.traefik_uid}:${var.traefik_gid}) and permissions (600)..."
      echo '{}' > /certs/acme.json
      chown ${var.traefik_uid}:${var.traefik_gid} /certs/acme.json
      chmod 600 /certs/acme.json
    fi

    # Ensure all JSON files have correct ownership and permissions
    echo "Fixing ownership and permissions for all ACME files..."
    for file in /certs/acme-hurricane.json /certs/acme.json; do
      if [ -f "$file" ]; then
        chown ${var.traefik_uid}:${var.traefik_gid} "$file"
        chmod 600 "$file"
      fi
    done

    echo "Verifying ACME files..."
    ls -la /certs/

    echo "=== ACME files initialized successfully ==="
  EOT
}
