locals {
  # Module configuration using standardized computed values pattern
  module_config = {
    name      = var.name
    namespace = var.namespace
    component = "home-automation"

    # Chart configuration
    chart_name    = var.chart_name
    chart_repo    = var.chart_repo
    chart_version = var.chart_version

    # Resource limits configuration
    cpu_limit      = var.cpu_limit
    memory_limit   = var.memory_limit
    cpu_request    = var.cpu_request
    memory_request = var.memory_request

    # Storage configuration
    persistent_disk_size = var.persistent_disk_size
    addons_disk_size     = var.addons_disk_size
    conf_disk_size       = var.conf_disk_size
    storage_class        = var.storage_class
    enable_persistence   = var.enable_persistence

    # Feature configuration
    enable_privileged    = var.enable_privileged
    enable_host_network  = var.enable_host_network
    enable_karaf_console = var.enable_karaf_console

    # Network configuration
    domain_name           = var.domain_name
    traefik_cert_resolver = var.traefik_cert_resolver
    enable_ingress        = var.enable_ingress

    # Architecture configuration
    cpu_arch                = var.cpu_arch
    disable_arch_scheduling = var.disable_arch_scheduling
  }

  # Architecture-based node selector
  node_selector = var.disable_arch_scheduling ? {} : {
    "kubernetes.io/arch" = var.cpu_arch
  }

  # Common labels following app.kubernetes.io standard
  common_labels = {
    "app.kubernetes.io/name"       = local.module_config.name
    "app.kubernetes.io/component"  = local.module_config.component
    "app.kubernetes.io/part-of"    = "home-automation"
    "app.kubernetes.io/managed-by" = "terraform"
  }

  # Determine access mode based on storage class
  access_mode = contains(["hostpath", "local"], lower(var.storage_class)) ? ["ReadWriteOnce"] : ["ReadWriteMany"]

  # PVC configurations for openHAB's multiple volumes
  pvc_configs = {
    data = {
      name            = "${local.module_config.name}-data"
      storage_class   = local.module_config.storage_class
      persistent_size = local.module_config.persistent_disk_size
      access_modes    = local.access_mode
      mount_path      = "/openhab/userdata"
    }
    addons = {
      name            = "${local.module_config.name}-addons"
      storage_class   = local.module_config.storage_class
      persistent_size = local.module_config.addons_disk_size
      access_modes    = local.access_mode
      mount_path      = "/openhab/addons"
    }
    conf = {
      name            = "${local.module_config.name}-conf"
      storage_class   = local.module_config.storage_class
      persistent_size = local.module_config.conf_disk_size
      access_modes    = local.access_mode
      mount_path      = "/openhab/conf"
    }
  }

  # Common PVC labels
  pvc_labels = merge(local.common_labels, {
    "app.kubernetes.io/instance" = local.module_config.name
  })

  # Ingress configuration
  ingress_config = {
    host         = "openhab.${local.module_config.domain_name}"
    service_name = local.module_config.name
    service_port = 8080
    path         = "/"

    # TLS configuration based on cert resolver type
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
