# locals.tf - Computed values for Vault module

locals {
  # Module configuration computed from variables and standardized patterns
  module_config = {
    name      = var.name
    namespace = var.namespace
    component = "secret-management"

    # Domain and networking
    domain_name = var.domain_name

    # Resource requirements
    cpu_limit      = var.cpu_limit
    memory_limit   = var.memory_limit
    cpu_request    = var.cpu_request
    memory_request = var.memory_request

    # Storage configuration
    storage_class = var.storage_class
    storage_size  = var.storage_size

    # Architecture and scheduling
    cpu_arch                = var.cpu_arch
    disable_arch_scheduling = var.disable_arch_scheduling

    # Vault-specific configuration
    consul_address          = var.consul_address
    consul_token            = var.consul_token
    vault_init_timeout      = var.vault_init_timeout
    vault_readiness_timeout = var.vault_readiness_timeout

    # Ingress configuration
    enable_ingress         = var.enable_ingress
    enable_traefik_ingress = var.enable_traefik_ingress
    traefik_cert_resolver  = var.traefik_cert_resolver
  }

  # Helm configuration with service overrides for backward compatibility
  helm_config = {
    chart_name    = coalesce(var.service_overrides.helm_config.chart_name, var.chart_name)
    chart_repo    = coalesce(var.service_overrides.helm_config.chart_repo, var.chart_repo)
    chart_version = coalesce(var.service_overrides.helm_config.chart_version, var.chart_version)

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

  # Ingress selector logic
  ingress_selector = local.module_config.enable_ingress && !local.module_config.enable_traefik_ingress ? "k8s" : (
    local.module_config.enable_traefik_ingress && local.module_config.enable_ingress ? "traefik" : "none"
  )

  # Template values for Helm chart
  template_values = merge({
    domain_name    = local.module_config.domain_name
    name           = local.module_config.name
    consul_address = local.module_config.consul_address
    consul_token   = local.module_config.consul_token
    cpu_limit      = local.module_config.cpu_limit
    memory_limit   = local.module_config.memory_limit
    cpu_request    = local.module_config.cpu_request
    memory_request = local.module_config.memory_request
  }, var.service_overrides.template_values)

  # Ingress configuration for both types
  ingress_config = {
    # Standard Kubernetes Ingress configuration
    k8s_ingress = {
      name         = "${local.module_config.name}-svclb-ui"
      host         = "vault.${local.module_config.domain_name}"
      service_port = 8200
      path_type    = "Prefix"
      path         = "/"

      # Traefik-specific annotations
      annotations = merge({
        "traefik.ingress.kubernetes.io/router.entrypoints"      = "websecure"
        "traefik.ingress.kubernetes.io/router.tls"              = "true"
        "traefik.ingress.kubernetes.io/router.tls.certresolver" = local.module_config.traefik_cert_resolver
        "traefik.ingress.kubernetes.io/router.pathmatcher"      = "PathPrefix"

        # Health check configuration for Vault
        "traefik.ingress.kubernetes.io/service.loadbalancer.healthcheck.path"     = "/v1/sys/health?standbyok=true&sealedcode=200&uninitcode=200"
        "traefik.ingress.kubernetes.io/service.loadbalancer.healthcheck.interval" = var.healthcheck_interval
        "traefik.ingress.kubernetes.io/service.loadbalancer.healthcheck.timeout"  = var.healthcheck_timeout
        "traefik.ingress.kubernetes.io/service.loadbalancer.healthcheck.scheme"   = "http"
        "traefik.ingress.kubernetes.io/service.loadbalancer.healthcheck.port"     = tostring(var.vault_port)
        "traefik.ingress.kubernetes.io/service.loadbalancer.healthcheck.status"   = "200"
        }, local.module_config.traefik_cert_resolver == "wildcard" ? {
        "traefik.ingress.kubernetes.io/router.tls.domains.0.main" = local.module_config.domain_name
        "traefik.ingress.kubernetes.io/router.tls.domains.0.sans" = "*.${local.module_config.domain_name}"
        } : {
        "traefik.ingress.kubernetes.io/router.tls.domains.0.main" = "vault.${local.module_config.domain_name}"
      })
    }

    # Traefik IngressRoute configuration
    traefik_ingress_route = {
      name = "${local.module_config.name}-ingressroute"
      host = "vault.${local.module_config.domain_name}"

      # Traefik manifest specification
      manifest = {
        apiVersion = "traefik.io/v1alpha1"
        kind       = "IngressRoute"
        metadata = {
          name      = "${local.module_config.name}-ingressroute"
          namespace = local.module_config.namespace
        }
        spec = {
          entryPoints = ["websecure"]
          routes = [{
            kind  = "Rule"
            match = "Host(`vault.${local.module_config.domain_name}`)"
            services = [{
              name = local.module_config.name
              port = 8200
              healthCheck = {
                path     = "/v1/sys/health?standbyok=true&sealedcode=200&uninitcode=200"
                interval = var.healthcheck_interval
                timeout  = var.healthcheck_timeout
                scheme   = "http"
                port     = 8200
                status   = 200
              }
            }]
          }]
          tls = {
            certResolver = local.module_config.traefik_cert_resolver
            domains = local.module_config.traefik_cert_resolver == "wildcard" ? [{
              main = local.module_config.domain_name
              sans = ["*.${local.module_config.domain_name}"]
              }] : [{
              main = "vault.${local.module_config.domain_name}"
              sans = []
            }]
          }
        }
      }
    }
  }
}
