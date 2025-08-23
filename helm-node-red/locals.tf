# ============================================================================
# HELM-NODE-RED MODULE LOCALS - COMPUTED CONFIGURATION
# ============================================================================

locals {
  # Module configuration
  module_config = {
    name                    = var.name
    namespace               = var.namespace
    chart_name              = var.chart_name
    chart_repo              = var.chart_repo
    chart_version           = var.chart_version
    deployment_wait_timeout = var.deployment_wait_timeout
  }

  # Helm configuration
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

  # Common labels
  common_labels = {
    "app.kubernetes.io/name"       = "node-red"
    "app.kubernetes.io/instance"   = var.name
    "app.kubernetes.io/component"  = "automation"
    "app.kubernetes.io/part-of"    = "homelab-automation"
    "app.kubernetes.io/managed-by" = "terraform"
  }

  # Template values for Helm chart
  template_values = {
    # Basic configuration
    name      = var.name
    namespace = var.namespace

    # Image and architecture
    cpu_arch = var.cpu_arch

    # Node selector for architecture
    node_selector = var.disable_arch_scheduling ? {} : {
      "kubernetes.io/arch" = var.cpu_arch
    }

    # Resource configuration
    cpu_limit      = var.cpu_limit
    memory_limit   = var.memory_limit
    cpu_request    = var.cpu_request
    memory_request = var.memory_request

    # Storage configuration
    enable_persistence   = var.enable_persistence
    storage_class        = var.storage_class
    persistent_disk_size = var.persistent_disk_size

    # Ingress configuration
    enable_ingress        = var.enable_ingress
    domain_name           = var.domain_name
    traefik_cert_resolver = var.traefik_cert_resolver
    ingress_host          = "node-red${var.domain_name}"

    # Service configuration
    service_port = 1880
    service_type = "ClusterIP"

    # Security context
    security_context = {
      runAsNonRoot = false # Node-RED needs root for some operations
      runAsUser    = 1000
      runAsGroup   = 1000
      fsGroup      = 1000
    }

    # Environment variables
    environment_variables = {
      TZ = "UTC"
    }

    # Palette packages
    palette_packages = var.palette_packages
  }
}
