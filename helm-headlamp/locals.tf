locals {
  # ============================================================================
  # HEADLAMP MODULE CONFIGURATION
  # ============================================================================

  # Module configuration using standardized computed values pattern
  module_config = {
    name      = var.name
    namespace = var.namespace
    component = "visualization"

    # Resource limits configuration
    cpu_limit      = var.cpu_limit
    memory_limit   = var.memory_limit
    cpu_request    = var.cpu_request
    memory_request = var.memory_request

    # Storage configuration
    enable_persistence = var.enable_persistence
    storage_class      = var.storage_class
    storage_size       = var.persistent_disk_size

    # Network configuration
    domain_name           = var.domain_name
    traefik_cert_resolver = var.traefik_cert_resolver

    # Node configuration
    cpu_arch = var.cpu_arch
  }

  # Common labels for all resources
  common_labels = {
    "app.kubernetes.io/managed-by" = "helm"
    "app.kubernetes.io/part-of"    = "k8s-infrastructure"
    "app.kubernetes.io/name"       = "headlamp"
  }

  # Plugin configuration - auto-enable KubeVirt plugin when KubeVirt is enabled
  enabled_plugins = var.kubevirt_enabled ? distinct(concat(var.enabled_plugins, ["kubevirt"])) : var.enabled_plugins

  # Helm configuration
  helm_config = {
    name       = local.module_config.name
    chart      = var.chart_name
    repository = var.chart_repo
    version    = var.chart_version
    namespace  = local.module_config.namespace

    # Helm deployment options
    timeout          = var.helm_timeout
    disable_webhooks = var.helm_disable_webhooks
    skip_crds        = var.helm_skip_crds
    replace          = var.helm_replace
    force_update     = var.helm_force_update
    cleanup_on_fail  = var.helm_cleanup_on_fail
    wait             = var.helm_wait
    wait_for_jobs    = var.helm_wait_for_jobs
  }

  # Storage configuration
  storage_config = var.enable_persistence ? {
    enabled       = true
    storage_class = var.storage_class
    size          = var.persistent_disk_size
    } : {
    enabled       = false
    storage_class = ""
    size          = ""
  }

  # Resource configuration
  resources_config = {
    limits = {
      cpu    = var.cpu_limit
      memory = var.memory_limit
    }
    requests = {
      cpu    = var.cpu_request
      memory = var.memory_request
    }
  }

  # Ingress configuration
  ingress_enabled = var.enable_headlamp_ingress && var.traefik_ingress_config != null

  # Ingress config for traefik-ingress.tf
  ingress_config = {
    host         = "headlamp.${local.module_config.domain_name}"
    service_name = local.module_config.name
    service_port = 80

    # TLS configuration based on cert resolver type
    tls_annotations = var.traefik_cert_resolver == "wildcard" ? {
      "traefik.ingress.kubernetes.io/router.tls.domains.0.main" = local.module_config.domain_name
      "traefik.ingress.kubernetes.io/router.tls.domains.0.sans" = "*.${local.module_config.domain_name}"
      } : {
      "traefik.ingress.kubernetes.io/router.tls.domains.0.main" = "headlamp.${local.module_config.domain_name}"
    }

    # Base annotations for ingress
    base_annotations = {
      "traefik.ingress.kubernetes.io/router.entrypoints"      = "websecure"
      "traefik.ingress.kubernetes.io/router.tls"              = "true"
      "traefik.ingress.kubernetes.io/router.tls.certresolver" = local.module_config.traefik_cert_resolver
      "traefik.ingress.kubernetes.io/router.middlewares"      = length(var.traefik_middleware) > 0 ? join(",", var.traefik_middleware) : ""
    }
  }

  # Template values for Helm chart
  template_values = {
    # Basic configuration
    NAMESPACE     = var.namespace
    NAME          = var.name
    NODE_SELECTOR = var.disable_arch_scheduling ? "" : var.cpu_arch
    COMMON_LABELS = yamlencode(local.common_labels)

    # Storage configuration
    PERSISTENCE_ENABLED       = local.storage_config.enabled
    PERSISTENCE_STORAGE_CLASS = local.storage_config.storage_class
    PERSISTENCE_SIZE          = local.storage_config.size

    # Resource limits
    CPU_LIMIT      = local.resources_config.limits.cpu
    MEMORY_LIMIT   = local.resources_config.limits.memory
    CPU_REQUEST    = local.resources_config.requests.cpu
    MEMORY_REQUEST = local.resources_config.requests.memory

    # Plugin configuration
    PLUGINS_ENABLED = local.enabled_plugins

    # OIDC authentication configuration
    OIDC_ENABLED              = try(var.oidc_config.enabled, false)
    OIDC_CLIENT_ID            = try(var.oidc_config.enabled, false) ? try(var.oidc_config.client_id, "") : ""
    OIDC_CLIENT_SECRET        = try(var.oidc_config.enabled, false) ? try(var.oidc_config.client_secret, "") : ""
    OIDC_ISSUER_URL           = try(var.oidc_config.enabled, false) ? try(var.oidc_config.issuer_url, "") : ""
    OIDC_SCOPES               = try(var.oidc_config.enabled, false) ? try(var.oidc_config.scopes, "profile,email") : ""
    OIDC_USE_ACCESS_TOKEN     = try(var.oidc_config.enabled, false) ? tostring(try(var.oidc_config.use_access_token, false)) : "false"
    OIDC_VALIDATOR_CLIENT_ID  = try(var.oidc_config.enabled, false) ? try(var.oidc_config.validator_client_id, "") : ""
    OIDC_VALIDATOR_ISSUER_URL = try(var.oidc_config.enabled, false) ? try(var.oidc_config.validator_issuer_url, "") : ""
  }
}
