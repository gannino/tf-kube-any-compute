locals {
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
    storage_size       = var.storage_size

    # Authentication configuration
    admin_user = var.grafana_admin_user

    # Network configuration
    domain_name           = var.domain_name
    traefik_cert_resolver = var.traefik_cert_resolver

    # Datasource URLs
    prometheus_url       = var.prometheus_url
    prometheus_namespace = var.prometheus_namespace
    alertmanager_url     = var.alertmanager_url
    loki_url             = var.loki_url

    # Node configuration
    cpu_arch          = var.cpu_arch
    grafana_node_name = var.grafana_node_name
  }

  # Computed admin password - use provided password or generate one
  admin_password = var.grafana_admin_password != null && var.grafana_admin_password != "" ? var.grafana_admin_password : try(random_password.password[0].result, "")

  # Helm configuration using standardized pattern
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

  # Common labels following app.kubernetes.io standard
  common_labels = {
    "app.kubernetes.io/name"       = local.module_config.name
    "app.kubernetes.io/component"  = local.module_config.component
    "app.kubernetes.io/part-of"    = "infrastructure"
    "app.kubernetes.io/managed-by" = "terraform"
  }

  # Template values for Grafana Helm chart configuration
  template_values = {
    GRAFANA_SERVICE_ACCOUNT = local.module_config.name
    GRAFANA_ADMIN_USER      = local.module_config.admin_user
    GRAFANA_ADMIN_PASSWORD  = local.admin_password
    PROMETHEUS_URL          = local.module_config.prometheus_url
    PROMETHEUS_NAMESPACE    = local.module_config.prometheus_namespace
    CPU_LIMIT               = local.module_config.cpu_limit
    MEMORY_LIMIT            = local.module_config.memory_limit
    CPU_REQUEST             = local.module_config.cpu_request
    MEMORY_REQUEST          = local.module_config.memory_request
    ENABLE_PERSISTENCE      = local.module_config.enable_persistence
    STORAGE_CLASS           = local.module_config.storage_class
    STORAGE_SIZE            = local.module_config.storage_size
    DOMAIN_NAME             = local.module_config.domain_name
    CPU_ARCH                = local.module_config.cpu_arch
    GRAFANA_NODE_NAME       = local.module_config.grafana_node_name != null ? local.module_config.grafana_node_name : ""
    ALERTMANAGER_URL        = local.module_config.alertmanager_url
    LOKI_URL                = local.module_config.loki_url
  }

  # Ingress configuration
  ingress_config = {
    host         = "grafana.${local.module_config.domain_name}"
    service_name = local.module_config.name
    service_port = 80

    # TLS configuration based on cert resolver type
    tls_annotations = var.traefik_cert_resolver == "wildcard" ? {
      "traefik.ingress.kubernetes.io/router.tls.domains.0.main" = local.module_config.domain_name
      "traefik.ingress.kubernetes.io/router.tls.domains.0.sans" = "*.${local.module_config.domain_name}"
      } : {
      "traefik.ingress.kubernetes.io/router.tls.domains.0.main" = "grafana.${local.module_config.domain_name}"
    }

    # Base annotations for ingress
    base_annotations = {
      "kubernetes.io/ingress.class"                           = "traefik"
      "traefik.ingress.kubernetes.io/router.entrypoints"      = "websecure"
      "traefik.ingress.kubernetes.io/router.tls"              = "true"
      "traefik.ingress.kubernetes.io/router.tls.certresolver" = local.module_config.traefik_cert_resolver
    }
  }
}
