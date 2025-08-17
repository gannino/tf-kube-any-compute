locals {
  # Module configuration using standardized computed values pattern
  module_config = {
    name      = var.name
    namespace = var.namespace
    component = "container-management"

    # Resource limits configuration
    cpu_limit      = var.cpu_limit
    memory_limit   = var.memory_limit
    cpu_request    = var.cpu_request
    memory_request = var.memory_request

    # Storage configuration
    persistent_disk_size = var.persistent_disk_size
    storage_class        = var.storage_class

    # Authentication configuration
    admin_password = var.portainer_admin_password

    # Network configuration
    domain_name                    = var.domain_name
    traefik_cert_resolver          = var.traefik_cert_resolver
    enable_portainer_ingress       = var.enable_portainer_ingress
    enable_portainer_ingress_route = var.enable_portainer_ingress_route

    # Architecture configuration
    cpu_arch                = var.cpu_arch
    disable_arch_scheduling = var.disable_arch_scheduling
  }

  # Computed admin password - use provided password or generate one
  admin_password = var.portainer_admin_password != null && var.portainer_admin_password != "" ? var.portainer_admin_password : try(random_password.portainer_admin[0].result, "")

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

  # Template values for Portainer Helm chart configuration
  template_values = {
    name                    = local.module_config.name
    cpu_limit               = local.module_config.cpu_limit
    memory_limit            = local.module_config.memory_limit
    cpu_request             = local.module_config.cpu_request
    memory_request          = local.module_config.memory_request
    cpu_arch                = local.module_config.cpu_arch
    disable_arch_scheduling = local.module_config.disable_arch_scheduling
    persistent_disk_size    = local.module_config.persistent_disk_size
    storage_class           = local.module_config.storage_class
    admin_password          = local.admin_password
  }

  # PVC configuration
  pvc_config = {
    name            = local.module_config.name
    storage_class   = local.module_config.storage_class
    persistent_size = local.module_config.persistent_disk_size
    access_modes    = ["ReadWriteOnce"]

    # Labels for PVC
    pvc_labels = merge(local.common_labels, {
      "app.kubernetes.io/instance" = local.module_config.name
    })
  }

  # Ingress configuration
  ingress_config = {
    host         = "portainer.${local.module_config.domain_name}"
    service_name = local.module_config.name
    service_port = 9000
    path         = "/"

    # TLS configuration based on cert resolver type
    # Use wildcard certificates for DNS challenge resolvers (non-default)
    tls_annotations = var.traefik_cert_resolver != "default" ? {
      "traefik.ingress.kubernetes.io/router.tls.domains.0.main" = local.module_config.domain_name
      "traefik.ingress.kubernetes.io/router.tls.domains.0.sans" = "*.${local.module_config.domain_name}"
    } : {}

    # Base annotations for ingress
    base_annotations = {
      "kubernetes.io/ingress.class"                           = "traefik"
      "traefik.ingress.kubernetes.io/router.entrypoints"      = "websecure"
      "traefik.ingress.kubernetes.io/router.pathmatcher"      = "PathPrefix"
      "traefik.ingress.kubernetes.io/router.tls"              = "true"
      "traefik.ingress.kubernetes.io/router.tls.certresolver" = local.module_config.traefik_cert_resolver
    }
  }
}
