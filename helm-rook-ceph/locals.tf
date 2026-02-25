locals {
  module_config = {
    name          = var.name
    namespace     = var.namespace
    chart_name    = var.chart_name
    chart_repo    = var.chart_repo
    chart_version = var.chart_version
    component     = "storage-orchestrator"
  }

  helm_config = {
    disable_webhooks = var.helm_disable_webhooks
    skip_crds        = var.helm_skip_crds
    replace          = var.helm_replace
    force_update     = var.helm_force_update
    cleanup_on_fail  = var.helm_cleanup_on_fail
    timeout          = var.helm_timeout
    wait             = var.helm_wait
    wait_for_jobs    = var.helm_wait_for_jobs
  }

  common_labels = {
    "app.kubernetes.io/name"       = local.module_config.name
    "app.kubernetes.io/component"  = local.module_config.component
    "app.kubernetes.io/part-of"    = "infrastructure"
    "app.kubernetes.io/managed-by" = "terraform"
  }

  resource_config = {
    requests = {
      cpu    = var.cpu_request
      memory = var.memory_request
    }
    limits = {
      cpu    = var.cpu_limit
      memory = var.memory_limit
    }
  }

  limit_range_config = {
    enabled              = var.limit_range_enabled
    container_max_cpu    = var.limit_range_container_max_cpu != null ? var.limit_range_container_max_cpu : var.cpu_limit
    container_max_memory = var.limit_range_container_max_memory != null ? var.limit_range_container_max_memory : var.memory_limit
    pvc_max_storage      = var.limit_range_pvc_max_storage
    pvc_min_storage      = var.limit_range_pvc_min_storage
  }

  # Kubeconfig path detection (matches main provider.tf logic)
  kubeconfig_path = var.ci_mode ? null : (
    var.kubeconfig_path != "" ? var.kubeconfig_path : (
      var.workspace_prefix != "" ? "${pathexpand("~")}/.kube/${var.workspace_prefix}-config" : "${pathexpand("~")}/.kube/config"
    )
  )

  template_values = {
    cpu_arch                         = var.cpu_arch
    disable_arch_scheduling          = var.disable_arch_scheduling
    cpu_limit                        = local.resource_config.limits.cpu
    memory_limit                     = local.resource_config.limits.memory
    cpu_request                      = local.resource_config.requests.cpu
    memory_request                   = local.resource_config.requests.memory
    csi_provisioner_replicas         = var.rook_csi_provisioner_replicas
    csi_rbd_provisioner_cpu_limit    = var.rook_csi_rbd_provisioner_cpu_limit
    csi_rbd_provisioner_memory_limit = var.rook_csi_rbd_provisioner_memory_limit
    csi_rbd_plugin_cpu_limit         = var.rook_csi_rbd_plugin_cpu_limit
    csi_rbd_plugin_memory_limit      = var.rook_csi_rbd_plugin_memory_limit
  }

  # Ingress configuration
  ingress_config = {
    host         = "rook-ceph.${var.domain_name}"
    service_name = "rook-ceph-mgr-dashboard"
    service_port = 7000
    path         = "/"

    # TLS configuration based on cert resolver type
    tls_annotations = var.traefik_cert_resolver == "wildcard" ? {
      "traefik.ingress.kubernetes.io/router.tls.domains.0.main" = var.domain_name
      "traefik.ingress.kubernetes.io/router.tls.domains.0.sans" = "*.${var.domain_name}"
      } : {
      "traefik.ingress.kubernetes.io/router.tls.domains.0.main" = "rook-ceph.${var.domain_name}"
    }

    # Base annotations for ingress
    base_annotations = {
      "traefik.ingress.kubernetes.io/router.entrypoints"      = "websecure"
      "traefik.ingress.kubernetes.io/router.tls"              = "true"
      "traefik.ingress.kubernetes.io/router.tls.certresolver" = var.traefik_cert_resolver
    }
  }
}
