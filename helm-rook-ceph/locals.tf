# ============================================================================
# 5-LEVEL OVERRIDE HIERARCHY
# ============================================================================
# Priority order (later overrides earlier):
#   1. System defaults (hardcoded below as fallbacks)
#   2. Service defaults (variable defaults in variables.tf)
#   3. User variables (passed from root module)
#   4. Service overrides (var.service_overrides - fine-grained control)
#   5. Auto-detection (runtime cluster analysis below)
#
# Pattern: coalesce(try(override, null), variable, fallback)

locals {
  # ==========================================================================
  # SYSTEM DEFAULTS (Level 1 - Hardcoded fallbacks)
  # ==========================================================================
  system_defaults = {
    # Chart versions by architecture
    chart_version_amd64 = "v1.17.5"
    chart_version_arm64 = "v1.17.5" # Unified version - ARM64 support improved

    # Ceph image versions (must match Rook version compatibility)
    ceph_image_default = "v18.2.4"

    # Resource defaults
    cpu_limit      = "500m"
    memory_limit   = "512Mi"
    cpu_request    = "250m"
    memory_request = "256Mi"

    # CSI defaults
    csi_provisioner_replicas         = 1
    csi_rbd_provisioner_cpu_limit    = "200m"
    csi_rbd_provisioner_memory_limit = "256Mi"
    csi_rbd_plugin_cpu_limit         = "200m"
    csi_rbd_plugin_memory_limit      = "512Mi"

    # Kubelet paths by distribution
    kubelet_path_standard = "/var/lib/kubelet"
    kubelet_path_microk8s = "/var/snap/microk8s/common/var/lib/kubelet"
    kubelet_path_k3s      = "/var/lib/rancher/k3s/agent"

    # Helm defaults
    helm_timeout = 600

    # Cleanup defaults
    cleanup_timeout = "5m"
  }

  # ==========================================================================
  # COMPUTED CONFIGURATION (Levels 2-5 Merged)
  # ==========================================================================

  # Basic configuration with override hierarchy
  name = coalesce(
    try(var.service_overrides.name, null),
    var.name,
    "rook-ceph"
  )

  namespace = coalesce(
    try(var.service_overrides.namespace, null),
    var.namespace,
    "rook-ceph"
  )

  # Chart version with architecture-aware auto-detection
  chart_version = coalesce(
    try(var.service_overrides.chart_version, null),
    var.chart_version != "" ? var.chart_version : null,
    var.cpu_arch == "arm64" ? local.system_defaults.chart_version_arm64 : local.system_defaults.chart_version_amd64
  )

  # Ceph image version with override support
  ceph_image_version = coalesce(
    try(var.service_overrides.ceph_image_version, null),
    var.ceph_image_version != "v18.2.4" ? var.ceph_image_version : null, # Allow explicit override
    local.system_defaults.ceph_image_default
  )

  # Resource configuration with override hierarchy
  cpu_limit = coalesce(
    try(var.service_overrides.cpu_limit, null),
    var.cpu_limit,
    local.system_defaults.cpu_limit
  )

  memory_limit = coalesce(
    try(var.service_overrides.memory_limit, null),
    var.memory_limit,
    local.system_defaults.memory_limit
  )

  cpu_request = coalesce(
    try(var.service_overrides.cpu_request, null),
    var.cpu_request,
    local.system_defaults.cpu_request
  )

  memory_request = coalesce(
    try(var.service_overrides.memory_request, null),
    var.memory_request,
    local.system_defaults.memory_request
  )

  # Feature toggles with override hierarchy
  enable_ceph_cluster = coalesce(
    try(var.service_overrides.enable_ceph_cluster, null),
    var.enable_ceph_cluster,
    true
  )

  enable_dashboard = coalesce(
    try(var.service_overrides.enable_dashboard, null),
    var.enable_dashboard,
    true
  )

  enable_ingress = coalesce(
    try(var.service_overrides.enable_ingress, null),
    var.enable_ingress,
    true
  )

  dashboard_ssl = coalesce(
    try(var.service_overrides.dashboard_ssl, null),
    var.dashboard_ssl,
    false
  )

  limit_range_enabled = coalesce(
    try(var.service_overrides.limit_range_enabled, null),
    var.limit_range_enabled,
    true
  )

  # Ceph configuration with override hierarchy
  monitor_count = coalesce(
    try(var.service_overrides.monitor_count, null),
    var.monitor_count,
    3
  )

  # OSD storage configuration with override hierarchy
  osd_per_node = coalesce(
    try(var.service_overrides.osd_per_node, null),
    var.osd_per_node,
    1
  )

  osd_data_size = coalesce(
    try(var.service_overrides.osd_data_size, null),
    var.osd_data_size,
    "10Gi"
  )

  storage_class_name = coalesce(
    try(var.service_overrides.storage_class_name, null),
    var.storage_class_name,
    "hostpath"
  )

  # CSI kubelet path with distribution-aware auto-detection
  csi_kubelet_dir_path = coalesce(
    try(var.service_overrides.csi_kubelet_dir_path, null),
    var.csi_kubelet_dir_path != "" ? var.csi_kubelet_dir_path : null,
    local.detected_kubelet_path
  )

  # CSI configuration with nested override support
  csi_provisioner_replicas = coalesce(
    try(var.service_overrides.csi.provisioner_replicas, null),
    var.rook_csi_provisioner_replicas,
    local.system_defaults.csi_provisioner_replicas
  )

  csi_rbd_provisioner_cpu_limit = coalesce(
    try(var.service_overrides.csi.rbd_provisioner_cpu_limit, null),
    var.rook_csi_rbd_provisioner_cpu_limit,
    local.system_defaults.csi_rbd_provisioner_cpu_limit
  )

  csi_rbd_provisioner_memory_limit = coalesce(
    try(var.service_overrides.csi.rbd_provisioner_memory_limit, null),
    var.rook_csi_rbd_provisioner_memory_limit,
    local.system_defaults.csi_rbd_provisioner_memory_limit
  )

  csi_rbd_plugin_cpu_limit = coalesce(
    try(var.service_overrides.csi.rbd_plugin_cpu_limit, null),
    var.rook_csi_rbd_plugin_cpu_limit,
    local.system_defaults.csi_rbd_plugin_cpu_limit
  )

  csi_rbd_plugin_memory_limit = coalesce(
    try(var.service_overrides.csi.rbd_plugin_memory_limit, null),
    var.rook_csi_rbd_plugin_memory_limit,
    local.system_defaults.csi_rbd_plugin_memory_limit
  )

  # Ingress configuration with override hierarchy
  domain_name = coalesce(
    try(var.service_overrides.domain_name, null),
    var.domain_name,
    "local"
  )

  traefik_cert_resolver = coalesce(
    try(var.service_overrides.traefik_cert_resolver, null),
    var.traefik_cert_resolver,
    "default"
  )

  # Helm configuration with override hierarchy
  helm_timeout = coalesce(
    try(var.service_overrides.helm_timeout, null),
    var.helm_timeout,
    local.system_defaults.helm_timeout
  )

  # Cleanup configuration with override hierarchy
  cleanup_stale_data_on_deploy = coalesce(
    try(var.service_overrides.cleanup_stale_data_on_deploy, null),
    var.cleanup_stale_data_on_deploy,
    true # Default: clean stale data to prevent keyring mismatch
  )

  force_namespace_cleanup = coalesce(
    try(var.service_overrides.force_namespace_cleanup, null),
    var.force_namespace_cleanup,
    false
  )

  cleanup_timeout = coalesce(
    try(var.service_overrides.cleanup_timeout, null),
    var.cleanup_timeout,
    local.system_defaults.cleanup_timeout
  )

  # ==========================================================================
  # AUTO-DETECTION (Level 5 - Runtime cluster analysis)
  # ==========================================================================

  # Detect kubelet path based on kubernetes distribution
  # This is a best-effort detection; override with csi_kubelet_dir_path if needed
  detected_kubelet_path = local.system_defaults.kubelet_path_standard

  # ==========================================================================
  # MODULE CONFIGURATION (Legacy compatibility)
  # ==========================================================================

  module_config = {
    name          = local.name
    namespace     = local.namespace
    chart_name    = var.chart_name
    chart_repo    = var.chart_repo
    chart_version = local.chart_version
    component     = "storage-orchestrator"
  }

  helm_config = {
    disable_webhooks = var.helm_disable_webhooks
    skip_crds        = var.helm_skip_crds
    replace          = var.helm_replace
    force_update     = var.helm_force_update
    cleanup_on_fail  = var.helm_cleanup_on_fail
    timeout          = local.helm_timeout
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
      cpu    = local.cpu_request
      memory = local.memory_request
    }
    limits = {
      cpu    = local.cpu_limit
      memory = local.memory_limit
    }
  }

  limit_range_config = {
    enabled              = local.limit_range_enabled
    container_max_cpu    = var.limit_range_container_max_cpu != null ? var.limit_range_container_max_cpu : local.cpu_limit
    container_max_memory = var.limit_range_container_max_memory != null ? var.limit_range_container_max_memory : local.memory_limit
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
    csi_provisioner_replicas         = local.csi_provisioner_replicas
    csi_rbd_provisioner_cpu_limit    = local.csi_rbd_provisioner_cpu_limit
    csi_rbd_provisioner_memory_limit = local.csi_rbd_provisioner_memory_limit
    csi_rbd_plugin_cpu_limit         = local.csi_rbd_plugin_cpu_limit
    csi_rbd_plugin_memory_limit      = local.csi_rbd_plugin_memory_limit
    csi_kubelet_dir_path             = local.csi_kubelet_dir_path
    dashboard_ssl                    = local.dashboard_ssl
  }

  # Ingress configuration
  ingress_config = {
    host         = "rook-ceph.${local.domain_name}"
    service_name = "rook-ceph-mgr-dashboard"
    service_port = 8443
    path         = "/"

    # TLS configuration based on cert resolver type
    tls_annotations = local.traefik_cert_resolver == "wildcard" ? {
      "traefik.ingress.kubernetes.io/router.tls.domains.0.main" = local.domain_name
      "traefik.ingress.kubernetes.io/router.tls.domains.0.sans" = "*.${local.domain_name}"
      } : {
      "traefik.ingress.kubernetes.io/router.tls.domains.0.main" = "rook-ceph.${local.domain_name}"
    }

    # Base annotations for ingress
    base_annotations = {
      "traefik.ingress.kubernetes.io/router.entrypoints"      = "websecure"
      "traefik.ingress.kubernetes.io/router.tls"              = "true"
      "traefik.ingress.kubernetes.io/router.tls.certresolver" = local.traefik_cert_resolver
    }
  }
}
