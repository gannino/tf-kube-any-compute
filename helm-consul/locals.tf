# locals.tf - Computed values for Consul module

locals {
  # Module configuration computed from variables and standardized patterns
  module_config = {
    name      = var.name
    namespace = var.namespace
    component = "service-mesh"

    # Helm chart configuration
    chart_name    = coalesce(var.service_overrides.helm_config.chart_name, var.chart_name)
    chart_repo    = coalesce(var.service_overrides.helm_config.chart_repo, var.chart_repo)
    chart_version = coalesce(var.service_overrides.helm_config.chart_version, var.chart_version)

    # Domain and networking
    domain_name    = var.domain_name
    enable_ingress = var.enable_ingress

    # Resource requirements
    cpu_limit      = var.cpu_limit
    memory_limit   = var.memory_limit
    cpu_request    = var.cpu_request
    memory_request = var.memory_request

    # Storage configuration
    storage_class        = var.storage_class
    persistent_disk_size = var.persistent_disk_size

    # Architecture and scheduling
    cpu_arch                = var.cpu_arch
    disable_arch_scheduling = var.disable_arch_scheduling

    # Consul-specific configuration
    consul_image_version     = var.consul_image_version
    consul_k8s_image_version = var.consul_k8s_image_version
    traefik_cert_resolver    = var.traefik_cert_resolver
  }

  # Helm configuration with service overrides for backward compatibility
  helm_config = {
    # Helm deployment options
    timeout          = coalesce(var.service_overrides.helm_config.timeout, var.helm_timeout)
    disable_webhooks = coalesce(var.service_overrides.helm_config.disable_webhooks, var.helm_disable_webhooks)
    skip_crds        = coalesce(var.service_overrides.helm_config.skip_crds, var.helm_skip_crds)
    replace          = coalesce(var.service_overrides.helm_config.replace, var.helm_replace)
    force_update     = coalesce(var.service_overrides.helm_config.force_update, var.helm_force_update)
    cleanup_on_fail  = coalesce(var.service_overrides.helm_config.cleanup_on_fail, var.helm_cleanup_on_fail)
    wait             = coalesce(var.service_overrides.helm_config.wait, var.helm_wait)
    wait_for_jobs    = coalesce(var.service_overrides.helm_config.wait_for_jobs, var.helm_wait_for_jobs)
  }

  # Common labels following Kubernetes recommended labels
  common_labels = merge({
    "app.kubernetes.io/name"       = local.module_config.name
    "app.kubernetes.io/component"  = local.module_config.component
    "app.kubernetes.io/part-of"    = "infrastructure"
    "app.kubernetes.io/managed-by" = "terraform"
  }, var.service_overrides.labels)

  # Consul-specific configuration
  consul_config = {
    # Encryption key configuration
    gossip_encryption_key_secret_name = "${local.module_config.namespace}-gossip-encryption-key"
    bootstrap_acl_token_secret_name   = "${local.module_config.name}-bootstrap-acl-token"

    # Service discovery
    server_service_name = "${local.module_config.name}-server"
    ui_service_name     = "${local.module_config.name}-ui"
  }

  # Ingress configuration for Consul UI
  ingress_config = {
    enabled      = true
    name         = "${local.module_config.name}-ingress"
    host         = "consul.${local.module_config.domain_name}"
    service_name = "${local.module_config.name}-ui"
    service_port = 80
    class_name   = "traefik"
    path_type    = "Prefix"
    path         = "/"

    # Traefik-specific annotations
    annotations = merge({
      "traefik.ingress.kubernetes.io/router.entrypoints"      = "websecure"
      "traefik.ingress.kubernetes.io/router.tls"              = "true"
      "traefik.ingress.kubernetes.io/router.tls.certresolver" = local.module_config.traefik_cert_resolver
      }, local.module_config.traefik_cert_resolver != "default" ? {
      "traefik.ingress.kubernetes.io/router.tls.domains.0.main" = local.module_config.domain_name
      "traefik.ingress.kubernetes.io/router.tls.domains.0.sans" = "*.${local.module_config.domain_name}"
      } : {}
    )
  }

  # Template values for Helm chart
  template_values = merge({
    # Core module configuration
    name        = local.module_config.name
    namespace   = local.module_config.namespace
    component   = local.module_config.component
    domain_name = local.module_config.domain_name

    # Resource requirements
    cpu_limit      = local.module_config.cpu_limit
    memory_limit   = local.module_config.memory_limit
    cpu_request    = local.module_config.cpu_request
    memory_request = local.module_config.memory_request

    # Storage configuration
    storage_class        = local.module_config.storage_class
    persistent_disk_size = local.module_config.persistent_disk_size

    # Architecture and scheduling
    cpu_arch                = local.module_config.cpu_arch
    disable_arch_scheduling = local.module_config.disable_arch_scheduling

    # Consul-specific configuration
    consul_image_version     = local.module_config.consul_image_version
    consul_k8s_image_version = local.module_config.consul_k8s_image_version
    traefik_cert_resolver    = local.module_config.traefik_cert_resolver

    # Encryption configuration
    gossip_encryption_key_secret_name = local.consul_config.gossip_encryption_key_secret_name
    bootstrap_acl_token_secret_name   = local.consul_config.bootstrap_acl_token_secret_name

    # Service discovery
    server_service_name = local.consul_config.server_service_name
    ui_service_name     = local.consul_config.ui_service_name

    # Ingress configuration
    enable_ingress = local.module_config.enable_ingress
    ingress_host   = local.ingress_config.host
  }, var.service_overrides.template_values)
}
