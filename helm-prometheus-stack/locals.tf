locals {
  # Module configuration using standardized computed values pattern
  module_config = {
    name      = var.name
    namespace = var.namespace
    component = "monitoring-stack"

    # Resource limits configuration
    cpu_limit      = var.cpu_limit
    memory_limit   = var.memory_limit
    cpu_request    = var.cpu_request
    memory_request = var.memory_request

    # Prometheus configuration
    prometheus_storage_size  = var.prometheus_storage_size
    prometheus_storage_class = var.prometheus_storage_class

    # Alertmanager configuration
    alertmanager_storage_size  = var.alertmanager_storage_size
    alertmanager_storage_class = var.alertmanager_storage_class

    # Networking configuration
    domain_name                 = var.domain_name
    traefik_cert_resolver       = var.traefik_cert_resolver
    enable_prometheus_ingress   = var.enable_prometheus_ingress
    enable_alertmanager_ingress = var.enable_alertmanager_ingress

    # Deployment configuration
    cpu_arch             = var.cpu_arch
    enable_node_selector = var.enable_node_selector
    prometheus_url       = var.prometheus_url
  }

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

  # Template values for Helm chart configuration
  template_values = {
    cpu_arch                   = local.module_config.cpu_arch
    prometheus_size            = local.module_config.prometheus_storage_size
    prometheus_storage_class   = local.module_config.prometheus_storage_class
    alertmanager_size          = local.module_config.alertmanager_storage_size
    alertmanager_storage_class = local.module_config.alertmanager_storage_class
    domain_name                = local.module_config.domain_name
    traefik_cert_resolver      = local.module_config.traefik_cert_resolver
    name                       = local.module_config.name
    namespace                  = local.module_config.namespace
    enable_node_selector       = local.module_config.enable_node_selector
  }

  # Service names for ingress configuration
  service_names = {
    prometheus   = "${local.module_config.name}-kube-pr-prometheus"
    alertmanager = "${local.module_config.name}-kube-pr-alertmanager"
  }

  # Ingress configuration
  ingress_config = {
    prometheus_host   = "prometheus.${local.module_config.domain_name}"
    alertmanager_host = "alertmanager.${local.module_config.domain_name}"
    ingress_class     = "traefik"

    # TLS configuration based on cert resolver type
    # Use wildcard certificates for DNS challenge resolvers (non-default)
    tls_annotations = var.traefik_cert_resolver != "default" ? {
      "traefik.ingress.kubernetes.io/router.tls.domains.0.main" = local.module_config.domain_name
      "traefik.ingress.kubernetes.io/router.tls.domains.0.sans" = "*.${local.module_config.domain_name}"
    } : {}

    # Base annotations for all ingress resources
    base_annotations = {
      "traefik.ingress.kubernetes.io/router.entrypoints"      = "websecure"
      "traefik.ingress.kubernetes.io/router.tls"              = "true"
      "traefik.ingress.kubernetes.io/router.tls.certresolver" = local.module_config.traefik_cert_resolver
    }
  }

  # Port configuration for services
  ports = {
    prometheus   = 9090
    alertmanager = 9093
  }

  # Authentication configuration
  monitoring_password = var.monitoring_admin_password != "" ? var.monitoring_admin_password : random_password.monitoring_password[0].result
}
