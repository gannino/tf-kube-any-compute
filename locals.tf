locals {
  # ============================================================================
  # WORKSPACE AND DOMAIN CONFIGURATION
  # ============================================================================

  # Workspace mapping
  workspace = {
    "default" = "BUILD"
    "preprod" = "PREPROD"
    "prod"    = "PROD"
    "sit"     = "SIT"
    "qa"      = "QA"
    "uat"     = "UAT"
    "fat"     = "FAT"
    "dev"     = "DEV"
    "pentest" = "PENTEST"
  }

  # Computed workspace prefix for consistent naming
  workspace_prefix = lower(lookup(local.workspace, terraform.workspace, "default"))

  # Domain configuration - construct from base_domain and platform_name
  # Format: {workspace}.{platform}.{base_domain}
  # Example: prod.k3s.annino.cloud

  # Backward compatibility: use legacy domain_name if provided
  domain = var.domain_name != null ? (
    var.domain_name == ".local" ? (
      "${local.workspace_prefix}.${var.platform_name}.local"
      ) : (
      "${local.workspace_prefix}.${var.platform_name}${var.domain_name}"
    )
    ) : (
    # New format using base_domain and platform_name
    var.base_domain == "local" ? (
      "${local.workspace_prefix}.${var.platform_name}.local"
      ) : (
      "${local.workspace_prefix}.${var.platform_name}.${var.base_domain}"
    )
  )

  # ============================================================================
  # SERVICE ENABLEMENT WITH BACKWARD COMPATIBILITY
  # ============================================================================

  # Unified service configuration with backward compatibility
  services_enabled = {
    traefik                = coalesce(var.enable_traefik, var.services.traefik, true)
    metallb                = coalesce(var.enable_metallb, var.services.metallb, true)
    nfs_csi                = coalesce(var.enable_nfs_csi, var.services.nfs_csi, true)
    host_path              = coalesce(var.enable_host_path, var.services.host_path, true)
    prometheus             = coalesce(var.enable_prometheus, var.services.prometheus, true)
    prometheus_crds        = coalesce(var.enable_prometheus_crds, var.services.prometheus_crds, true)
    grafana                = coalesce(var.enable_grafana, var.services.grafana, true)
    loki                   = coalesce(var.enable_loki, var.services.loki, true)
    promtail               = coalesce(var.enable_promtail, var.services.promtail, true)
    consul                 = coalesce(var.enable_consul, var.services.consul, true)
    vault                  = coalesce(var.enable_vault, var.services.vault, true)
    gatekeeper             = coalesce(var.enable_gatekeeper, var.services.gatekeeper, false)
    portainer              = coalesce(var.enable_portainer, var.services.portainer, true)
    node_feature_discovery = coalesce(var.enable_node_feature_discovery, var.services.node_feature_discovery, true)
  }

  # ============================================================================
  # ARCHITECTURE DETECTION AND CLUSTER ANALYSIS
  # ============================================================================

  # Auto-detect CPU architecture - try different K8s distributions in order of preference
  k8s_masters_count        = length(data.kubernetes_nodes.k8s_masters.nodes)
  k8s_masters_legacy_count = length(data.kubernetes_nodes.k8s_masters_legacy.nodes)
  k3s_masters_count        = length(data.kubernetes_nodes.k3s_masters.nodes)
  microk8s_masters_count   = length(data.kubernetes_nodes.microk8s_masters.nodes)
  k8s_workers_count        = length(data.kubernetes_nodes.k8s_workers.nodes)
  k3s_workers_count        = length(data.kubernetes_nodes.k3s_workers.nodes)
  all_nodes_count          = length(data.kubernetes_nodes.all_nodes.nodes)

  # Select first available control plane node from any distribution
  detection_node = (
    local.k8s_masters_count > 0 ? data.kubernetes_nodes.k8s_masters.nodes[0] :
    local.k8s_masters_legacy_count > 0 ? data.kubernetes_nodes.k8s_masters_legacy.nodes[0] :
    local.k3s_masters_count > 0 ? data.kubernetes_nodes.k3s_masters.nodes[0] :
    local.microk8s_masters_count > 0 ? data.kubernetes_nodes.microk8s_masters.nodes[0] :
    local.all_nodes_count > 0 ? data.kubernetes_nodes.all_nodes.nodes[0] : null
  )

  # Analyze all nodes for mixed architecture detection
  all_node_archs   = local.all_nodes_count > 0 ? [for node in data.kubernetes_nodes.all_nodes.nodes : node.status[0].node_info[0].architecture] : []
  unique_archs     = toset(local.all_node_archs)
  is_mixed_cluster = length(local.unique_archs) > 1

  # Control plane architecture (primary)
  control_plane_arch = local.detection_node != null ? local.detection_node.status[0].node_info[0].architecture : ""

  # Mixed cluster strategy: use control plane arch, or most common arch, or amd64 default
  arch_counts      = { for arch in local.unique_archs : arch => length([for a in local.all_node_archs : a if a == arch]) }
  most_common_arch = length(local.arch_counts) > 0 ? keys(local.arch_counts)[index(values(local.arch_counts), max(values(local.arch_counts)...))] : "amd64"

  detected_arch = (
    var.cpu_arch != "" ? var.cpu_arch :                         # User override
    local.control_plane_arch != "" ? local.control_plane_arch : # Control plane arch
    local.most_common_arch                                      # Most common arch
  )

  cpu_arch = local.detected_arch

  # Worker node architectures for application services
  worker_node_archs = concat(
    local.k8s_workers_count > 0 ? [for node in data.kubernetes_nodes.k8s_workers.nodes : node.status[0].node_info[0].architecture] : [],
    local.k3s_workers_count > 0 ? [for node in data.kubernetes_nodes.k3s_workers.nodes : node.status[0].node_info[0].architecture] : []
  )
  worker_arch_counts      = length(local.worker_node_archs) > 0 ? { for arch in toset(local.worker_node_archs) : arch => length([for a in local.worker_node_archs : a if a == arch]) } : {}
  most_common_worker_arch = length(local.worker_arch_counts) > 0 ? keys(local.worker_arch_counts)[index(values(local.worker_arch_counts), max(values(local.worker_arch_counts)...))] : ""

  # ============================================================================
  # CLUSTER INFORMATION AND MIXED CLUSTER HANDLING
  # ============================================================================

  # Detected Kubernetes distribution for debugging
  k8s_distribution = (
    local.k8s_masters_count > 0 ? "kubernetes" :
    local.k8s_masters_legacy_count > 0 ? "kubernetes-legacy" :
    local.k3s_masters_count > 0 ? "k3s" :
    local.microk8s_masters_count > 0 ? "microk8s" : "unknown"
  )

  # Mixed cluster information
  cluster_architecture_info = {
    is_mixed                 = local.is_mixed_cluster
    architectures            = local.unique_archs
    control_plane_arch       = local.control_plane_arch
    most_common_arch         = local.most_common_arch
    most_common_worker_arch  = local.most_common_worker_arch
    selected_arch            = local.cpu_arch
    arch_distribution        = local.arch_counts
    worker_arch_distribution = local.worker_arch_counts
    k8s_distribution         = local.k8s_distribution
  }

  # Auto-configure for mixed clusters
  mixed_cluster_overrides = var.auto_mixed_cluster_mode && local.is_mixed_cluster ? {
    # Cluster-wide services should run on all nodes
    node_feature_discovery = true
    metallb                = true
    nfs_csi                = true
    # Application services can be architecture-specific
    traefik          = false
    prometheus_stack = false
    consul           = false
    vault            = false
    portainer        = false
  } : {}

  # Merge user config with auto-detected mixed cluster config
  final_disable_arch_scheduling = merge(var.disable_arch_scheduling, local.mixed_cluster_overrides)

  # ============================================================================
  # STORAGE CONFIGURATION WITH OVERRIDE HIERARCHY
  # ============================================================================

  # NFS configuration with backward compatibility
  nfs_server = coalesce(
    var.nfs_server_address != "192.168.1.100" ? var.nfs_server_address : null,
    var.nfs_server != "" ? var.nfs_server : null,
    "192.168.1.100"
  )

  nfs_path = coalesce(
    var.nfs_server_path != "/mnt/k8s-storage" ? var.nfs_server_path : null,
    var.nfs_path != "" ? var.nfs_path : null,
    "/mnt/k8s-storage"
  )

  # Storage class selection logic with NFS as primary, hostpath as fallback
  primary_storage_class = var.use_nfs_storage && local.services_enabled.nfs_csi ? "nfs-csi" : (
    var.use_hostpath_storage && local.services_enabled.host_path ? "hostpath" : "hostpath"
  )

  # Storage class mapping for different use cases
  storage_classes = {
    default   = local.primary_storage_class
    safe      = var.use_nfs_storage && local.services_enabled.nfs_csi ? "nfs-csi-safe" : "hostpath"
    fast      = var.use_nfs_storage && local.services_enabled.nfs_csi ? "nfs-csi-fast" : "hostpath"
    secondary = var.use_nfs_storage && local.services_enabled.nfs_csi ? "nfs-csi" : "hostpath"
    backup    = "hostpath" # Always use local storage for backups
    grafana   = "hostpath" # Default to hostpath for Grafana (can be overridden)
    local     = "hostpath" # Explicit local storage option
  }

  # Storage sizes based on environment constraints
  storage_sizes = var.enable_microk8s_mode ? {
    prometheus   = "4Gi"
    grafana      = "2Gi"
    alertmanager = "1Gi"
    consul       = "1Gi"
    vault        = "1Gi"
    traefik      = "128Mi"
    portainer    = "1Gi"
    } : {
    prometheus   = "8Gi"
    grafana      = "4Gi"
    alertmanager = "2Gi"
    consul       = "2Gi"
    vault        = "2Gi"
    traefik      = "256Mi"
    portainer    = "2Gi"
  }

  # ============================================================================
  # SERVICE CONFIGURATION WITH OVERRIDE HIERARCHY
  # ============================================================================

  # Service configuration with override hierarchy: service_override → global → defaults
  service_configs = {
    traefik = {
      cpu_arch                   = coalesce(try(var.service_overrides.traefik.cpu_arch, null), local.most_common_worker_arch, local.most_common_arch, "amd64")
      storage_class              = coalesce(try(var.service_overrides.traefik.storage_class, null), var.storage_class_override.traefik, local.storage_classes.default, "hostpath")
      helm_timeout               = coalesce(try(var.service_overrides.traefik.helm_timeout, null), var.default_helm_timeout)
      enable_dashboard           = coalesce(try(var.service_overrides.traefik.enable_dashboard, null), false)
      load_balancer_class        = coalesce(try(var.service_overrides.traefik.load_balancer_class, null), "metallb")
      enable_load_balancer_class = coalesce(try(var.service_overrides.traefik.enable_load_balancer_class, null), false)
    }
    prometheus = {
      cpu_arch                    = coalesce(try(var.service_overrides.prometheus.cpu_arch, null), local.most_common_worker_arch, local.most_common_arch, "amd64")
      storage_class               = coalesce(try(var.service_overrides.prometheus.storage_class, null), var.storage_class_override.prometheus, local.storage_classes.default, "hostpath")
      helm_timeout                = coalesce(try(var.service_overrides.prometheus.helm_timeout, null), var.default_helm_timeout)
      enable_ingress              = coalesce(try(var.service_overrides.prometheus.enable_ingress, null), var.enable_prometheus_ingress_route, true)
      enable_alertmanager_ingress = coalesce(try(var.service_overrides.prometheus.enable_alertmanager_ingress, null), true)
      monitoring_admin_password   = var.monitoring_admin_password
    }
    grafana = {
      cpu_arch           = coalesce(try(var.service_overrides.grafana.cpu_arch, null), local.most_common_worker_arch, local.most_common_arch, "amd64")
      storage_class      = coalesce(try(var.service_overrides.grafana.storage_class, null), var.storage_class_override.grafana, local.storage_classes.grafana, "hostpath")
      helm_timeout       = coalesce(try(var.service_overrides.grafana.helm_timeout, null), var.default_helm_timeout)
      enable_persistence = coalesce(try(var.service_overrides.grafana.enable_persistence, null), var.enable_grafana_persistence, true)
      node_name          = coalesce(try(var.service_overrides.grafana.node_name, null), var.grafana_node_name, "")
    }
    metallb = {
      address_pool                 = coalesce(try(var.service_overrides.metallb.address_pool, null), var.metallb_address_pool)
      load_balancer_class          = coalesce(try(var.service_overrides.metallb.load_balancer_class, null), "metallb")
      enable_load_balancer_class   = coalesce(try(var.service_overrides.metallb.enable_load_balancer_class, null), false)
      address_pool_name            = coalesce(try(var.service_overrides.metallb.address_pool_name, null), "default-pool")
      enable_prometheus_metrics    = coalesce(try(var.service_overrides.metallb.enable_prometheus_metrics, null), true)
      controller_replica_count     = coalesce(try(var.service_overrides.metallb.controller_replica_count, null), 1)
      speaker_replica_count        = coalesce(try(var.service_overrides.metallb.speaker_replica_count, null), 1)
      enable_bgp                   = coalesce(try(var.service_overrides.metallb.enable_bgp, null), false)
      enable_frr                   = coalesce(try(var.service_overrides.metallb.enable_frr, null), false)
      log_level                    = coalesce(try(var.service_overrides.metallb.log_level, null), "debug")
      service_monitor_enabled      = coalesce(try(var.service_overrides.metallb.service_monitor_enabled, null), false)
    }
    vault = {
      cpu_arch      = coalesce(try(var.service_overrides.vault.cpu_arch, null), local.most_common_worker_arch, local.most_common_arch, "amd64")
      storage_class = coalesce(try(var.service_overrides.vault.storage_class, null), var.storage_class_override.vault, local.storage_classes.default, "hostpath")
    }
    consul = {
      cpu_arch      = coalesce(try(var.service_overrides.consul.cpu_arch, null), local.most_common_worker_arch, local.most_common_arch, "amd64")
      storage_class = coalesce(try(var.service_overrides.consul.storage_class, null), var.storage_class_override.consul, local.storage_classes.default, "hostpath")
    }
    portainer = {
      cpu_arch      = coalesce(try(var.service_overrides.portainer.cpu_arch, null), local.most_common_worker_arch, local.most_common_arch, "amd64")
      storage_class = coalesce(try(var.service_overrides.portainer.storage_class, null), var.storage_class_override.portainer, local.storage_classes.default, "hostpath")
    }
    loki = {
      cpu_arch      = coalesce(try(var.service_overrides.loki.cpu_arch, null), local.most_common_worker_arch, local.most_common_arch, "amd64")
      storage_class = coalesce(try(var.service_overrides.loki.storage_class, null), var.storage_class_override.loki, local.storage_classes.default, "hostpath")
    }
  }

  # ============================================================================
  # LEGACY COMPATIBILITY MAPPINGS
  # ============================================================================

  # CPU architecture mapping for different services (backward compatibility)
  cpu_architectures = {
    # Application services - prefer worker arch, fallback to most common, then amd64
    traefik               = local.service_configs.traefik.cpu_arch
    portainer             = local.service_configs.portainer.cpu_arch
    prometheus_stack      = local.service_configs.prometheus.cpu_arch
    prometheus_stack_crds = local.service_configs.prometheus.cpu_arch
    grafana               = local.service_configs.grafana.cpu_arch
    consul                = local.service_configs.consul.cpu_arch
    vault                 = local.service_configs.vault.cpu_arch
    loki                  = local.service_configs.loki.cpu_arch
    promtail              = coalesce(var.cpu_arch_override.promtail, local.cpu_arch)
    gatekeeper            = coalesce(var.cpu_arch_override.gatekeeper, local.most_common_worker_arch, local.most_common_arch, "amd64")
    host_path             = coalesce(var.cpu_arch_override.host_path, local.most_common_worker_arch, local.most_common_arch, "amd64")

    # Cluster-wide services - use detected arch (control plane priority for cluster services)
    metallb                = coalesce(var.cpu_arch_override.metallb, local.cpu_arch)
    nfs_csi                = coalesce(var.cpu_arch_override.nfs_csi, local.cpu_arch)
    node_feature_discovery = coalesce(var.cpu_arch_override.node_feature_discovery, local.cpu_arch)
  }

  # Common labels for all resources
  common_labels = {
    "app.kubernetes.io/managed-by" = "terraform"
    "app.kubernetes.io/part-of"    = "k8s-infrastructure"
    "environment"                  = terraform.workspace
  }

  # Resource defaults based on environment
  resource_defaults = {
    cpu_limit      = var.enable_resource_limits ? var.default_cpu_limit : "1000m"
    memory_limit   = var.enable_resource_limits ? var.default_memory_limit : "1Gi"
    cpu_request    = var.enable_resource_limits ? "100m" : "250m"
    memory_request = var.enable_resource_limits ? "128Mi" : "256Mi"
  }

  # Cert resolver mapping for different services  
  cert_resolvers = {
    default      = var.traefik_cert_resolver
    traefik      = coalesce(var.cert_resolver_override.traefik, var.traefik_cert_resolver)
    prometheus   = coalesce(var.cert_resolver_override.prometheus, var.traefik_cert_resolver)
    grafana      = coalesce(var.cert_resolver_override.grafana, var.traefik_cert_resolver)
    alertmanager = coalesce(var.cert_resolver_override.alertmanager, var.traefik_cert_resolver)
    consul       = coalesce(var.cert_resolver_override.consul, var.traefik_cert_resolver)
    vault        = coalesce(var.cert_resolver_override.vault, var.traefik_cert_resolver)
    portainer    = coalesce(var.cert_resolver_override.portainer, var.traefik_cert_resolver)
  }

  # Let's Encrypt email with backward compatibility
  letsencrypt_email = coalesce(
    var.le_email != "" ? var.le_email : null,
    var.letsencrypt_email != "" && var.letsencrypt_email != "admin@example.com" ? var.letsencrypt_email : null,
    "admin@example.com"
  )

  # ============================================================================
  # HELM CONFIGURATION MAPPINGS
  # ============================================================================

  # Helm configuration with service overrides integration
  helm_configs = {
    traefik = {
      timeout          = coalesce(try(var.service_overrides.traefik.helm_timeout, null), var.default_helm_timeout)
      disable_webhooks = var.default_helm_disable_webhooks
      skip_crds        = var.default_helm_skip_crds
      replace          = var.default_helm_replace
      force_update     = var.default_helm_force_update
      cleanup_on_fail  = var.default_helm_cleanup_on_fail
      wait             = coalesce(try(var.service_overrides.traefik.helm_wait, null), var.default_helm_wait)
      wait_for_jobs    = coalesce(try(var.service_overrides.traefik.helm_wait_for_jobs, null), var.default_helm_wait_for_jobs)
    }
    metallb = {
      timeout          = coalesce(try(var.service_overrides.metallb.helm_timeout, null), var.default_helm_timeout)
      disable_webhooks = var.default_helm_disable_webhooks
      skip_crds        = var.default_helm_skip_crds
      replace          = var.default_helm_replace
      force_update     = var.default_helm_force_update
      cleanup_on_fail  = var.default_helm_cleanup_on_fail
      wait             = coalesce(try(var.service_overrides.metallb.helm_wait, null), var.default_helm_wait)
      wait_for_jobs    = coalesce(try(var.service_overrides.metallb.helm_wait_for_jobs, null), var.default_helm_wait_for_jobs)
    }
    nfs_csi = {
      timeout          = coalesce(try(var.service_overrides.nfs_csi.helm_timeout, null), var.default_helm_timeout)
      disable_webhooks = var.default_helm_disable_webhooks
      skip_crds        = var.default_helm_skip_crds
      replace          = var.default_helm_replace
      force_update     = var.default_helm_force_update
      cleanup_on_fail  = var.default_helm_cleanup_on_fail
      wait             = coalesce(try(var.service_overrides.nfs_csi.helm_wait, null), var.default_helm_wait)
      wait_for_jobs    = coalesce(try(var.service_overrides.nfs_csi.helm_wait_for_jobs, null), var.default_helm_wait_for_jobs)
    }
    host_path = {
      timeout          = coalesce(try(var.service_overrides.host_path.helm_timeout, null), var.default_helm_timeout)
      disable_webhooks = var.default_helm_disable_webhooks
      skip_crds        = var.default_helm_skip_crds
      replace          = var.default_helm_replace
      force_update     = var.default_helm_force_update
      cleanup_on_fail  = var.default_helm_cleanup_on_fail
      wait             = coalesce(try(var.service_overrides.host_path.helm_wait, null), var.default_helm_wait)
      wait_for_jobs    = coalesce(try(var.service_overrides.host_path.helm_wait_for_jobs, null), var.default_helm_wait_for_jobs)
    }
    gatekeeper = {
      timeout          = coalesce(try(var.service_overrides.gatekeeper.helm_timeout, null), var.default_helm_timeout)
      disable_webhooks = var.default_helm_disable_webhooks
      skip_crds        = var.default_helm_skip_crds
      replace          = var.default_helm_replace
      force_update     = var.default_helm_force_update
      cleanup_on_fail  = var.default_helm_cleanup_on_fail
      wait             = coalesce(try(var.service_overrides.gatekeeper.helm_wait, null), var.default_helm_wait)
      wait_for_jobs    = coalesce(try(var.service_overrides.gatekeeper.helm_wait_for_jobs, null), var.default_helm_wait_for_jobs)
    }
    node_feature_discovery = {
      timeout          = coalesce(try(var.service_overrides.node_feature_discovery.helm_timeout, null), var.default_helm_timeout)
      disable_webhooks = var.default_helm_disable_webhooks
      skip_crds        = var.default_helm_skip_crds
      replace          = var.default_helm_replace
      force_update     = var.default_helm_force_update
      cleanup_on_fail  = var.default_helm_cleanup_on_fail
      wait             = coalesce(try(var.service_overrides.node_feature_discovery.helm_wait, null), var.default_helm_wait)
      wait_for_jobs    = coalesce(try(var.service_overrides.node_feature_discovery.helm_wait_for_jobs, null), var.default_helm_wait_for_jobs)
    }
    portainer = {
      timeout          = coalesce(try(var.service_overrides.portainer.helm_timeout, null), var.default_helm_timeout)
      disable_webhooks = var.default_helm_disable_webhooks
      skip_crds        = var.default_helm_skip_crds
      replace          = var.default_helm_replace
      force_update     = var.default_helm_force_update
      cleanup_on_fail  = var.default_helm_cleanup_on_fail
      wait             = coalesce(try(var.service_overrides.portainer.helm_wait, null), var.default_helm_wait)
      wait_for_jobs    = coalesce(try(var.service_overrides.portainer.helm_wait_for_jobs, null), var.default_helm_wait_for_jobs)
    }
    prometheus_stack = {
      timeout          = coalesce(try(var.service_overrides.prometheus.helm_timeout, null), var.default_helm_timeout)
      disable_webhooks = var.default_helm_disable_webhooks
      skip_crds        = var.default_helm_skip_crds
      replace          = var.default_helm_replace
      force_update     = var.default_helm_force_update
      cleanup_on_fail  = var.default_helm_cleanup_on_fail
      wait             = coalesce(try(var.service_overrides.prometheus.helm_wait, null), var.default_helm_wait)
      wait_for_jobs    = coalesce(try(var.service_overrides.prometheus.helm_wait_for_jobs, null), var.default_helm_wait_for_jobs)
    }
    prometheus_stack_crds = {
      timeout          = coalesce(try(var.service_overrides.prometheus_crds.helm_timeout, null), var.default_helm_timeout)
      disable_webhooks = var.default_helm_disable_webhooks
      skip_crds        = var.default_helm_skip_crds
      replace          = var.default_helm_replace
      force_update     = var.default_helm_force_update
      cleanup_on_fail  = var.default_helm_cleanup_on_fail
      wait             = coalesce(try(var.service_overrides.prometheus_crds.helm_wait, null), var.default_helm_wait)
      wait_for_jobs    = coalesce(try(var.service_overrides.prometheus_crds.helm_wait_for_jobs, null), var.default_helm_wait_for_jobs)
    }
    grafana = {
      timeout          = coalesce(try(var.service_overrides.grafana.helm_timeout, null), var.default_helm_timeout)
      disable_webhooks = var.default_helm_disable_webhooks
      skip_crds        = var.default_helm_skip_crds
      replace          = var.default_helm_replace
      force_update     = var.default_helm_force_update
      cleanup_on_fail  = var.default_helm_cleanup_on_fail
      wait             = coalesce(try(var.service_overrides.grafana.helm_wait, null), var.default_helm_wait)
      wait_for_jobs    = coalesce(try(var.service_overrides.grafana.helm_wait_for_jobs, null), var.default_helm_wait_for_jobs)
    }
    loki = {
      timeout          = coalesce(try(var.service_overrides.loki.helm_timeout, null), var.default_helm_timeout)
      disable_webhooks = var.default_helm_disable_webhooks
      skip_crds        = var.default_helm_skip_crds
      replace          = var.default_helm_replace
      force_update     = var.default_helm_force_update
      cleanup_on_fail  = var.default_helm_cleanup_on_fail
      wait             = coalesce(try(var.service_overrides.loki.helm_wait, null), var.default_helm_wait)
      wait_for_jobs    = coalesce(try(var.service_overrides.loki.helm_wait_for_jobs, null), var.default_helm_wait_for_jobs)
    }
    promtail = {
      timeout          = coalesce(try(var.service_overrides.promtail.helm_timeout, null), var.default_helm_timeout)
      disable_webhooks = var.default_helm_disable_webhooks
      skip_crds        = var.default_helm_skip_crds
      replace          = var.default_helm_replace
      force_update     = var.default_helm_force_update
      cleanup_on_fail  = var.default_helm_cleanup_on_fail
      wait             = coalesce(try(var.service_overrides.promtail.helm_wait, null), var.default_helm_wait)
      wait_for_jobs    = coalesce(try(var.service_overrides.promtail.helm_wait_for_jobs, null), var.default_helm_wait_for_jobs)
    }
    consul = {
      timeout          = coalesce(try(var.service_overrides.consul.helm_timeout, null), var.default_helm_timeout)
      disable_webhooks = var.default_helm_disable_webhooks
      skip_crds        = var.default_helm_skip_crds
      replace          = var.default_helm_replace
      force_update     = var.default_helm_force_update
      cleanup_on_fail  = var.default_helm_cleanup_on_fail
      wait             = coalesce(try(var.service_overrides.consul.helm_wait, null), var.default_helm_wait)
      wait_for_jobs    = coalesce(try(var.service_overrides.consul.helm_wait_for_jobs, null), var.default_helm_wait_for_jobs)
    }
    vault = {
      timeout          = coalesce(try(var.service_overrides.vault.helm_timeout, null), var.default_helm_timeout)
      disable_webhooks = var.default_helm_disable_webhooks
      skip_crds        = var.default_helm_skip_crds
      replace          = var.default_helm_replace
      force_update     = var.default_helm_force_update
      cleanup_on_fail  = var.default_helm_cleanup_on_fail
      wait             = coalesce(try(var.service_overrides.vault.helm_wait, null), var.default_helm_wait)
      wait_for_jobs    = coalesce(try(var.service_overrides.vault.helm_wait_for_jobs, null), var.default_helm_wait_for_jobs)
    }
  }
}

# Query control plane nodes - try multiple label patterns for different K8s distributions
data "kubernetes_nodes" "k8s_masters" {
  metadata {
    labels = {
      "node-role.kubernetes.io/control-plane" = ""
    }
  }
}

data "kubernetes_nodes" "k8s_masters_legacy" {
  metadata {
    labels = {
      "node-role.kubernetes.io/master" = ""
    }
  }
}

data "kubernetes_nodes" "k3s_masters" {
  metadata {
    labels = {
      "node-role.kubernetes.io/control-plane" = "true"
    }
  }
}

data "kubernetes_nodes" "microk8s_masters" {
  metadata {
    labels = {
      "node.kubernetes.io/microk8s-controlplane" = "microk8s-controlplane"
    }
  }
}

# Query worker nodes specifically
data "kubernetes_nodes" "k8s_workers" {
  metadata {
    labels = {
      "node-role.kubernetes.io/worker" = ""
    }
  }
}

data "kubernetes_nodes" "k3s_workers" {
  metadata {
    labels = {
      "node-role.kubernetes.io/worker" = "true"
    }
  }
}

# Fallback to any node if no control plane nodes found
data "kubernetes_nodes" "all_nodes" {
  metadata {
    labels = {}
  }
}
