locals {
  # ============================================================================
  # CI/CD ENVIRONMENT DETECTION
  # ============================================================================

  # Detect CI environment
  ci_mode = can(regex("^(true|1)$", coalesce(try(env("CI"), ""), try(env("GITHUB_ACTIONS"), ""), try(env("GITLAB_CI"), ""), try(env("JENKINS_URL"), ""), try(env("BUILDKITE"), ""), ""))) || can(regex("runner", try(env("HOME"), "")))

  # Disable Kubernetes node queries in CI mode to prevent connection errors
  enable_k8s_node_queries = !local.ci_mode

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
    redis                  = coalesce(var.services.redis, false)
    authelia               = coalesce(var.services.authelia, false)
    consul                 = coalesce(var.enable_consul, var.services.consul, true)
    gatekeeper             = coalesce(var.enable_gatekeeper, var.services.gatekeeper, false)
    grafana                = coalesce(var.enable_grafana, var.services.grafana, true)
    headlamp               = coalesce(var.services.headlamp, false)
    home_assistant         = coalesce(var.services.home_assistant, false)
    homebridge             = coalesce(var.services.homebridge, false)
    host_path              = coalesce(var.enable_host_path, var.services.host_path, true)
    kube_state_metrics     = coalesce(var.enable_kube_state_metrics, var.services.kube_state_metrics, true)
    kubevirt               = coalesce(var.services.kubevirt, false)
    loki                   = coalesce(var.enable_loki, var.services.loki, true)
    longhorn               = coalesce(var.services.longhorn, false)
    metallb                = coalesce(var.enable_metallb, var.services.metallb, true)
    metrics_server         = coalesce(var.services.metrics_server, true)
    n8n                    = coalesce(var.services.n8n, false)
    nfs_csi                = coalesce(var.enable_nfs_csi, var.services.nfs_csi, true)
    node_feature_discovery = coalesce(var.enable_node_feature_discovery, var.services.node_feature_discovery, true)
    node_red               = coalesce(var.services.node_red, false)
    openhab                = coalesce(var.services.openhab, false)
    portainer              = coalesce(var.enable_portainer, var.services.portainer, true)
    prometheus             = coalesce(var.enable_prometheus, var.services.prometheus, true)
    prometheus_crds        = coalesce(var.enable_prometheus_crds, var.services.prometheus_crds, true)
    promtail               = coalesce(var.enable_promtail, var.services.promtail, true)
    rook_ceph              = coalesce(var.services.rook_ceph, false)
    traefik                = coalesce(var.enable_traefik, var.services.traefik, true)
    vault                  = coalesce(var.enable_vault, var.services.vault, true)
  }

  # ============================================================================
  # ARCHITECTURE DETECTION AND CLUSTER ANALYSIS
  # ============================================================================

  # Auto-detect CPU architecture - try different K8s distributions in order of preference
  # Skip node queries in CI mode to prevent connection errors
  k8s_masters_count        = local.enable_k8s_node_queries ? length(data.kubernetes_nodes.k8s_masters[0].nodes) : 0
  k8s_masters_legacy_count = local.enable_k8s_node_queries ? length(data.kubernetes_nodes.k8s_masters_legacy[0].nodes) : 0
  k3s_masters_count        = local.enable_k8s_node_queries ? length(data.kubernetes_nodes.k3s_masters[0].nodes) : 0
  microk8s_masters_count   = local.enable_k8s_node_queries ? length(data.kubernetes_nodes.microk8s_masters[0].nodes) : 0
  k8s_workers_count        = local.enable_k8s_node_queries ? length(data.kubernetes_nodes.k8s_workers[0].nodes) : 0
  k3s_workers_count        = local.enable_k8s_node_queries ? length(data.kubernetes_nodes.k3s_workers[0].nodes) : 0
  all_nodes_count          = local.enable_k8s_node_queries ? length(data.kubernetes_nodes.all_nodes[0].nodes) : 0

  # Select first available control plane node from any distribution
  detection_node = local.enable_k8s_node_queries ? (
    local.k8s_masters_count > 0 ? data.kubernetes_nodes.k8s_masters[0].nodes[0] :
    local.k8s_masters_legacy_count > 0 ? data.kubernetes_nodes.k8s_masters_legacy[0].nodes[0] :
    local.k3s_masters_count > 0 ? data.kubernetes_nodes.k3s_masters[0].nodes[0] :
    local.microk8s_masters_count > 0 ? data.kubernetes_nodes.microk8s_masters[0].nodes[0] :
    local.all_nodes_count > 0 ? data.kubernetes_nodes.all_nodes[0].nodes[0] : null
  ) : null

  # Analyze all nodes for mixed architecture detection
  all_node_archs   = local.enable_k8s_node_queries && local.all_nodes_count > 0 ? [for node in data.kubernetes_nodes.all_nodes[0].nodes : node.status[0].node_info[0].architecture] : []
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
    local.most_common_arch != "" ? local.most_common_arch :     # Most common arch
    "amd64"                                                     # CI mode fallback
  )

  cpu_arch = local.detected_arch

  # Worker node architectures for application services
  worker_node_archs = local.enable_k8s_node_queries ? concat(
    local.k8s_workers_count > 0 ? [for node in data.kubernetes_nodes.k8s_workers[0].nodes : node.status[0].node_info[0].architecture] : [],
    local.k3s_workers_count > 0 ? [for node in data.kubernetes_nodes.k3s_workers[0].nodes : node.status[0].node_info[0].architecture] : []
  ) : []
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
    traefik            = false
    prometheus_stack   = false
    consul             = false
    vault              = false
    portainer          = false
    kube_state_metrics = false
    metrics_server     = false
    headlamp           = false
  } : {}

  # Merge user config with auto-detected mixed cluster config
  final_disable_arch_scheduling = merge(var.disable_arch_scheduling, local.mixed_cluster_overrides)

  # ============================================================================
  # STORAGE CONFIGURATION WITH OVERRIDE HIERARCHY
  # ============================================================================

  # System defaults with override hierarchy
  defaults = merge({
    nfs_server_address      = "192.168.1.100"
    nfs_server_path         = "/mnt/k8s-storage"
    metallb_address_pool    = "192.168.1.200-192.168.1.210"
    cpu_limit_default       = "200m"
    memory_limit_default    = "256Mi"
    cpu_request_default     = "100m"
    memory_request_default  = "128Mi"
    cpu_limit_high          = "1000m"
    memory_limit_high       = "1Gi"
    cpu_request_high        = "500m"
    memory_request_high     = "1Gi"
    cpu_limit_light         = "100m"
    memory_limit_light      = "64Mi"
    cpu_request_light       = "25m"
    memory_request_light    = "32Mi"
    storage_size_small      = "1Gi"
    storage_size_medium     = "2Gi"
    storage_size_large      = "4Gi"
    storage_size_xlarge     = "8Gi"
    microk8s_cpu_limit      = "200m"
    microk8s_memory_limit   = "256Mi"
    microk8s_storage_small  = "1Gi"
    microk8s_storage_medium = "2Gi"
    microk8s_storage_large  = "4Gi"
    helm_timeout_short      = 180
    helm_timeout_medium     = 300
    helm_timeout_long       = 600
    helm_timeout_xllong     = 900
    ldap_port_default       = 389
    rate_limit_average      = 100
    rate_limit_burst        = 200
    ha_replicas_default     = 2
    ha_replicas_high        = 3
    node_red_palette_packages = [
      "node-red-contrib-home-assistant-websocket",
      "node-red-dashboard",
      "node-red-contrib-influxdb",
      "node-red-contrib-mqtt-broker",
      "node-red-node-pi-gpio",
      "node-red-contrib-modbus"
    ]
  }, var.system_defaults)

  # NFS configuration with backward compatibility
  nfs_server = coalesce(
    var.nfs_server_address != "" ? var.nfs_server_address : null,
    var.nfs_server != "" ? var.nfs_server : null,
    local.defaults.nfs_server_address
  )

  nfs_path = coalesce(
    var.nfs_server_path != "" ? var.nfs_server_path : null,
    var.nfs_path != "" ? var.nfs_path : null,
    local.defaults.nfs_server_path
  )

  # Storage class selection logic with NFS as primary, hostpath as fallback
  primary_storage_class = var.use_nfs_storage && local.services_enabled.nfs_csi ? "nfs-csi" : (
    var.use_hostpath_storage && local.services_enabled.host_path ? "hostpath" : "hostpath"
  )

  # Default NFS storage class type used across services
  default_nfs_storage_class_type = "reliable"

  # NFS storage class configurations with different mount options
  nfs_storage_class_configs = merge({
    default = {
      mount_options = [
        "hard",
        "retrans=5",
        "rsize=65536",
        "sync",
        "timeo=900",
        "vers=4.1",
        "wsize=65536"
      ]
      reclaim_policy = "Retain"
      access_modes   = ["ReadWriteMany"]
    }
    performance = {
      mount_options = [
        "hard",
        "retrans=3",
        "rsize=1048576",
        "async",
        "timeo=600",
        "vers=4.1",
        "wsize=1048576",
        "proto=tcp"
      ]
      reclaim_policy = "Retain"
      access_modes   = ["ReadWriteMany"]
    }
    reliable = {
      mount_options = [
        "hard",
        "retrans=10",
        "rsize=32768",
        "sync",
        "timeo=1200",
        "vers=4.1",
        "wsize=32768",
        "intr"
      ]
      reclaim_policy = "Retain"
      access_modes   = ["ReadWriteMany"]
    }
    low_latency = {
      mount_options = [
        "hard",
        "retrans=2",
        "rsize=65536",
        "async",
        "timeo=300",
        "vers=4.1",
        "wsize=65536",
        "proto=tcp",
        "noatime"
      ]
      reclaim_policy = "Delete"
      access_modes   = ["ReadWriteMany"]
    }
  }, var.nfs_storage_class_config)

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
    prometheus     = local.defaults.microk8s_storage_large
    grafana        = local.defaults.microk8s_storage_medium
    alertmanager   = local.defaults.microk8s_storage_small
    consul         = local.defaults.microk8s_storage_small
    vault          = local.defaults.microk8s_storage_small
    traefik        = "128Mi"
    portainer      = local.defaults.microk8s_storage_small
    loki           = "5Gi"
    node_red       = local.defaults.microk8s_storage_medium
    n8n            = "5Gi"
    home_assistant = "5Gi"
    openhab        = "8Gi"
    homebridge     = local.defaults.microk8s_storage_medium
    } : {
    prometheus     = local.defaults.storage_size_xlarge
    grafana        = local.defaults.storage_size_large
    alertmanager   = local.defaults.storage_size_medium
    consul         = local.defaults.storage_size_medium
    vault          = local.defaults.storage_size_medium
    traefik        = "256Mi"
    portainer      = local.defaults.storage_size_medium
    loki           = "10Gi"
    node_red       = local.defaults.storage_size_medium
    n8n            = "5Gi"
    home_assistant = "5Gi"
    openhab        = "8Gi"
    homebridge     = local.defaults.storage_size_medium
  }

  # ============================================================================
  # SERVICE CONFIGURATION WITH OVERRIDE HIERARCHY
  # ============================================================================

  # Service configuration with unified override hierarchy: service_override → legacy_override → global → defaults
  service_configs = {
    authelia = {
      cpu_arch               = coalesce(try(var.service_overrides.authelia.cpu_arch, null), try(var.cpu_arch_override.authelia, null), local.cpu_arch)
      chart_version          = coalesce(try(var.service_overrides.authelia.chart_version, null), "0.10.49")
      storage_class          = coalesce(try(var.service_overrides.authelia.storage_class, null), try(var.storage_class_override.authelia, null), local.storage_classes.default)
      storage_size           = coalesce(try(var.service_overrides.authelia.storage_size, null), "1Gi")
      nfs_storage_class_type = coalesce(try(var.service_overrides.authelia.nfs_storage_class_type, null), local.default_nfs_storage_class_type)
      nfs_config             = local.nfs_storage_class_configs[coalesce(try(var.service_overrides.authelia.nfs_storage_class_type, null), local.default_nfs_storage_class_type)]
      # cert_resolver handled separately in cert_resolvers local
      default_policy = coalesce(try(var.service_overrides.authelia.default_policy, null), "one_factor")
      ldap_enabled   = coalesce(try(var.service_overrides.authelia.ldap_enabled, null), false)
      oidc_enabled   = coalesce(try(var.service_overrides.authelia.oidc_enabled, null), false)
      # Default OIDC clients with headlamp pre-configured for auto-configuration
      oidc_clients = coalesce(try(var.service_overrides.authelia.oidc_clients, null), {
        headlamp = {
          client_id            = "headlamp"
          client_secret        = "headlamp-secret-change-me"
          redirect_uris        = ["https://headlamp.${local.domain}/oidc-callback"]
          authorization_policy = "two_factor"
          scopes               = ["openid", "profile", "email", "groups"]
        }
      })
      totp_enabled = coalesce(try(var.service_overrides.authelia.totp_enabled, null), true)
      duo_enabled  = coalesce(try(var.service_overrides.authelia.duo_enabled, null), false)
      # Auto-enable Redis when Redis module is deployed - use explicit override or derive from services.redis
      redis_enabled = coalesce(try(var.service_overrides.authelia.redis_enabled, null), local.services_enabled.redis)

      # Redis configuration: auto-discover from redis module when available
      # Note: Using hardcoded service name instead of module.redis[0].service_host to avoid circular dependency
      # Priority: 1) explicit redis_module_reference, 2) redis_address, 3) auto-discover from service name, 4) empty (no Redis)
      redis_address = local.services_enabled.redis ? coalesce(
        try(var.service_overrides.authelia.redis_module_reference, ""),
        try(var.service_overrides.authelia.redis_address, ""),
        "${local.workspace_prefix}-redis.${local.workspace_prefix}-redis-system.svc.cluster.local"
      ) : ""

      # Replica count: 2 when Redis is enabled (HA), 1 when using local storage
      # Check if Redis is enabled via variable override (for terraform.tfvars) or service_overrides
      replica_count = coalesce(
        try(var.service_overrides.authelia.replica_count, null),
        coalesce(try(var.service_overrides.authelia.redis_enabled, null), false) ? 2 : 1
      )
      # Resource limits with hierarchy
      cpu_limit      = coalesce(try(var.service_overrides.authelia.cpu_limit, null), var.enable_resource_limits ? "300m" : "500m")
      memory_limit   = coalesce(try(var.service_overrides.authelia.memory_limit, null), var.enable_resource_limits ? local.defaults.memory_limit_default : "512Mi")
      cpu_request    = coalesce(try(var.service_overrides.authelia.cpu_request, null), local.defaults.cpu_request_default)
      memory_request = coalesce(try(var.service_overrides.authelia.memory_request, null), local.defaults.memory_request_default)
    }
    consul = {
      cpu_arch               = coalesce(try(var.service_overrides.consul.cpu_arch, null), try(var.cpu_arch_override.consul, null), local.cpu_arch)
      storage_class          = coalesce(try(var.service_overrides.consul.storage_class, null), try(var.storage_class_override.consul, null), local.storage_classes.default)
      storage_size           = coalesce(try(var.service_overrides.consul.storage_size, null), local.storage_sizes.consul)
      nfs_storage_class_type = coalesce(try(var.service_overrides.consul.nfs_storage_class_type, null), local.default_nfs_storage_class_type)
      nfs_config             = local.nfs_storage_class_configs[coalesce(try(var.service_overrides.consul.nfs_storage_class_type, null), local.default_nfs_storage_class_type)]
      # cert_resolver handled separately in cert_resolvers local
      server_replicas          = coalesce(try(var.service_overrides.consul.server_replicas, null), local.defaults.ha_replicas_default)
      client_replicas          = coalesce(try(var.service_overrides.consul.client_replicas, null), 0)
      enable_pod_anti_affinity = coalesce(try(var.service_overrides.consul.enable_pod_anti_affinity, null), true)
      enable_servicemonitor    = coalesce(try(var.service_overrides.consul.enable_servicemonitor, null), local.services_enabled.prometheus_crds)
      # Resource limits with hierarchy
      cpu_limit      = coalesce(try(var.service_overrides.consul.cpu_limit, null), "500m")
      memory_limit   = coalesce(try(var.service_overrides.consul.memory_limit, null), "512Mi")
      cpu_request    = coalesce(try(var.service_overrides.consul.cpu_request, null), "250m")
      memory_request = coalesce(try(var.service_overrides.consul.memory_request, null), "256Mi")
    }
    grafana = {
      cpu_arch               = coalesce(try(var.service_overrides.grafana.cpu_arch, null), try(var.cpu_arch_override.grafana, null), local.cpu_arch)
      chart_version          = coalesce(try(var.service_overrides.grafana.chart_version, null), "9.3.1")
      storage_class          = coalesce(try(var.service_overrides.grafana.storage_class, null), try(var.storage_class_override.grafana, null), local.storage_classes.grafana)
      storage_size           = coalesce(try(var.service_overrides.grafana.storage_size, null), local.storage_sizes.grafana)
      nfs_storage_class_type = coalesce(try(var.service_overrides.grafana.nfs_storage_class_type, null), local.default_nfs_storage_class_type)
      nfs_config             = local.nfs_storage_class_configs[coalesce(try(var.service_overrides.grafana.nfs_storage_class_type, null), local.default_nfs_storage_class_type)]
      # cert_resolver handled separately in cert_resolvers local
      helm_timeout       = coalesce(try(var.service_overrides.grafana.helm_timeout, null), var.default_helm_timeout != 0 ? var.default_helm_timeout : local.defaults.helm_timeout_long)
      enable_persistence = coalesce(try(var.service_overrides.grafana.enable_persistence, null), var.enable_grafana_persistence, true)
      node_name          = try(var.service_overrides.grafana.node_name, var.grafana_node_name)
      admin_password     = try(var.service_overrides.grafana.admin_password, var.grafana_admin_password)
      # Resource limits with hierarchy
      cpu_limit      = coalesce(try(var.service_overrides.grafana.cpu_limit, null), var.enable_resource_limits ? "300m" : "500m")
      memory_limit   = coalesce(try(var.service_overrides.grafana.memory_limit, null), var.enable_resource_limits ? local.defaults.memory_limit_default : "512Mi")
      cpu_request    = coalesce(try(var.service_overrides.grafana.cpu_request, null), local.defaults.cpu_request_default)
      memory_request = coalesce(try(var.service_overrides.grafana.memory_request, null), local.defaults.memory_request_default)
    }
    kube_state_metrics = {
      cpu_arch      = coalesce(try(var.service_overrides.kube_state_metrics.cpu_arch, null), try(var.cpu_arch_override.kube_state_metrics, null), local.cpu_arch)
      chart_version = coalesce(try(var.service_overrides.kube_state_metrics.chart_version, null), "5.15.2")
      # Resource limits with hierarchy
      cpu_limit      = coalesce(try(var.service_overrides.kube_state_metrics.cpu_limit, null), var.enable_resource_limits ? local.defaults.cpu_limit_light : local.defaults.cpu_limit_default)
      memory_limit   = coalesce(try(var.service_overrides.kube_state_metrics.memory_limit, null), var.enable_resource_limits ? local.defaults.memory_request_default : local.defaults.memory_limit_default)
      cpu_request    = coalesce(try(var.service_overrides.kube_state_metrics.cpu_request, null), "50m")
      memory_request = coalesce(try(var.service_overrides.kube_state_metrics.memory_request, null), local.defaults.memory_request_light)
    }
    metrics_server = {
      cpu_arch = coalesce(try(var.service_overrides.metrics_server.cpu_arch, null), try(var.cpu_arch_override.metrics_server, null), local.cpu_arch)
      # Resource limits with hierarchy
      cpu_limit      = coalesce(try(var.service_overrides.metrics_server.cpu_limit, null), var.enable_resource_limits ? local.defaults.cpu_limit_light : local.defaults.cpu_limit_default)
      memory_limit   = coalesce(try(var.service_overrides.metrics_server.memory_limit, null), var.enable_resource_limits ? local.defaults.memory_limit_light : local.defaults.memory_limit_default)
      cpu_request    = coalesce(try(var.service_overrides.metrics_server.cpu_request, null), "50m")
      memory_request = coalesce(try(var.service_overrides.metrics_server.memory_request, null), local.defaults.memory_request_light)
    }
    loki = {
      cpu_arch               = coalesce(try(var.service_overrides.loki.cpu_arch, null), try(var.cpu_arch_override.loki, null), local.cpu_arch)
      chart_version          = coalesce(try(var.service_overrides.loki.chart_version, null), "6.16.0")
      storage_class          = coalesce(try(var.service_overrides.loki.storage_class, null), try(var.storage_class_override.loki, null), local.storage_classes.default)
      storage_size           = coalesce(try(var.service_overrides.loki.storage_size, null), local.storage_sizes.loki)
      nfs_storage_class_type = coalesce(try(var.service_overrides.loki.nfs_storage_class_type, null), local.default_nfs_storage_class_type)
      nfs_config             = local.nfs_storage_class_configs[coalesce(try(var.service_overrides.loki.nfs_storage_class_type, null), local.default_nfs_storage_class_type)]
      # Resource limits with hierarchy
      cpu_limit      = coalesce(try(var.service_overrides.loki.cpu_limit, null), var.enable_resource_limits ? local.defaults.cpu_limit_default : "500m")
      memory_limit   = coalesce(try(var.service_overrides.loki.memory_limit, null), var.enable_resource_limits ? local.defaults.memory_limit_default : "512Mi")
      cpu_request    = coalesce(try(var.service_overrides.loki.cpu_request, null), "50m")
      memory_request = coalesce(try(var.service_overrides.loki.memory_request, null), local.defaults.memory_request_light)
    }
    metallb = {
      address_pool = coalesce(try(var.service_overrides.metallb.address_pool, null), var.metallb_address_pool != "" ? var.metallb_address_pool : local.defaults.metallb_address_pool)
      cpu_arch     = coalesce(try(var.service_overrides.metallb.cpu_arch, null), try(var.cpu_arch_override.metallb, null), local.cpu_arch)
      # Resource limits with hierarchy
      cpu_limit      = coalesce(try(var.service_overrides.metallb.cpu_limit, null), var.enable_resource_limits ? (var.default_cpu_limit != "" ? var.default_cpu_limit : local.defaults.cpu_limit_default) : local.defaults.cpu_limit_light)
      memory_limit   = coalesce(try(var.service_overrides.metallb.memory_limit, null), var.enable_resource_limits ? (var.default_memory_limit != "" ? var.default_memory_limit : local.defaults.memory_limit_default) : local.defaults.memory_limit_light)
      cpu_request    = coalesce(try(var.service_overrides.metallb.cpu_request, null), local.defaults.cpu_request_light)
      memory_request = coalesce(try(var.service_overrides.metallb.memory_request, null), local.defaults.memory_request_light)
    }
    portainer = {
      cpu_arch               = coalesce(try(var.service_overrides.portainer.cpu_arch, null), try(var.cpu_arch_override.portainer, null), local.cpu_arch)
      chart_version          = coalesce(try(var.service_overrides.portainer.chart_version, null), "1.0.69")
      storage_class          = coalesce(try(var.service_overrides.portainer.storage_class, null), try(var.storage_class_override.portainer, null), local.storage_classes.default)
      storage_size           = coalesce(try(var.service_overrides.portainer.storage_size, null), local.storage_sizes.portainer)
      nfs_storage_class_type = coalesce(try(var.service_overrides.portainer.nfs_storage_class_type, null), local.default_nfs_storage_class_type)
      nfs_config             = local.nfs_storage_class_configs[coalesce(try(var.service_overrides.portainer.nfs_storage_class_type, null), local.default_nfs_storage_class_type)]
      # cert_resolver handled separately in cert_resolvers local
      admin_password = try(var.service_overrides.portainer.admin_password, var.portainer_admin_password)
      # Resource limits with hierarchy
      cpu_limit      = coalesce(try(var.service_overrides.portainer.cpu_limit, null), var.enable_resource_limits ? (var.default_cpu_limit != "" ? var.default_cpu_limit : local.defaults.cpu_limit_default) : "500m")
      memory_limit   = coalesce(try(var.service_overrides.portainer.memory_limit, null), var.enable_resource_limits ? (var.default_memory_limit != "" ? var.default_memory_limit : local.defaults.memory_limit_default) : "512Mi")
      cpu_request    = coalesce(try(var.service_overrides.portainer.cpu_request, null), local.defaults.cpu_request_default)
      memory_request = coalesce(try(var.service_overrides.portainer.memory_request, null), local.defaults.memory_request_default)
    }
    prometheus = {
      cpu_arch               = coalesce(try(var.service_overrides.prometheus.cpu_arch, null), try(var.cpu_arch_override.prometheus, null), local.cpu_arch)
      storage_class          = coalesce(try(var.service_overrides.prometheus.storage_class, null), try(var.storage_class_override.prometheus, null), local.storage_classes.default)
      storage_size           = coalesce(try(var.service_overrides.prometheus.storage_size, null), local.storage_sizes.prometheus)
      nfs_storage_class_type = coalesce(try(var.service_overrides.prometheus.nfs_storage_class_type, null), local.default_nfs_storage_class_type)
      nfs_config             = local.nfs_storage_class_configs[coalesce(try(var.service_overrides.prometheus.nfs_storage_class_type, null), local.default_nfs_storage_class_type)]
      # cert_resolver handled separately in cert_resolvers local
      helm_timeout                = coalesce(try(var.service_overrides.prometheus.helm_timeout, null), var.default_helm_timeout != 0 ? var.default_helm_timeout : local.defaults.helm_timeout_xllong)
      enable_ingress              = coalesce(try(var.service_overrides.prometheus.enable_ingress, null), var.enable_prometheus_ingress_route, true)
      enable_alertmanager_ingress = coalesce(try(var.service_overrides.prometheus.enable_alertmanager_ingress, null), true)
      monitoring_admin_password   = try(var.service_overrides.prometheus.monitoring_admin_password, var.monitoring_admin_password)
      # Alertmanager storage class with override hierarchy
      alertmanager_storage_class = coalesce(try(var.service_overrides.prometheus.alertmanager_storage_class, null), try(var.storage_class_override.alertmanager, null), "hostpath")
      # Resource limits with hierarchy
      cpu_limit      = coalesce(try(var.service_overrides.prometheus.cpu_limit, null), local.defaults.cpu_limit_high)
      memory_limit   = coalesce(try(var.service_overrides.prometheus.memory_limit, null), local.defaults.memory_limit_high)
      cpu_request    = coalesce(try(var.service_overrides.prometheus.cpu_request, null), local.defaults.cpu_request_high)
      memory_request = coalesce(try(var.service_overrides.prometheus.memory_request, null), local.defaults.memory_request_high)
    }
    promtail = {
      cpu_arch      = coalesce(try(var.service_overrides.promtail.cpu_arch, null), try(var.cpu_arch_override.promtail, null), local.cpu_arch)
      chart_version = coalesce(try(var.service_overrides.promtail.chart_version, null), "6.16.6")
      # Resource limits with hierarchy
      cpu_limit      = coalesce(try(var.service_overrides.promtail.cpu_limit, null), var.enable_resource_limits ? local.defaults.cpu_limit_light : local.defaults.cpu_limit_default)
      memory_limit   = coalesce(try(var.service_overrides.promtail.memory_limit, null), var.enable_resource_limits ? local.defaults.memory_request_default : local.defaults.memory_limit_default)
      cpu_request    = coalesce(try(var.service_overrides.promtail.cpu_request, null), "50m")
      memory_request = coalesce(try(var.service_overrides.promtail.memory_request, null), local.defaults.memory_request_light)
      # Limit range configuration with hierarchy
      container_default_cpu    = coalesce(try(var.service_overrides.promtail.container_default_cpu, null), local.defaults.cpu_limit_default)
      container_default_memory = coalesce(try(var.service_overrides.promtail.container_default_memory, null), local.defaults.memory_limit_default)
      container_request_cpu    = coalesce(try(var.service_overrides.promtail.container_request_cpu, null), "50m")
      container_request_memory = coalesce(try(var.service_overrides.promtail.container_request_memory, null), local.defaults.memory_request_light)
      container_max_cpu        = coalesce(try(var.service_overrides.promtail.container_max_cpu, null), "800m")
      container_max_memory     = coalesce(try(var.service_overrides.promtail.container_max_memory, null), local.defaults.memory_limit_high)
      pvc_max_storage          = coalesce(try(var.service_overrides.promtail.pvc_max_storage, null), "100Gi")
      pvc_min_storage          = coalesce(try(var.service_overrides.promtail.pvc_min_storage, null), local.defaults.storage_size_small)
    }
    traefik = {
      cpu_arch      = coalesce(try(var.service_overrides.traefik.cpu_arch, null), try(var.cpu_arch_override.traefik, null), local.cpu_arch)
      storage_class = coalesce(try(var.service_overrides.traefik.storage_class, null), try(var.storage_class_override.traefik, null), local.storage_classes.default)
      storage_size  = coalesce(try(var.service_overrides.traefik.storage_size, null), local.storage_sizes.traefik)
      # cert_resolver handled separately in cert_resolvers local
      helm_timeout          = coalesce(try(var.service_overrides.traefik.helm_timeout, null), var.default_helm_timeout != 0 ? var.default_helm_timeout : local.defaults.helm_timeout_long)
      enable_dashboard      = coalesce(try(var.service_overrides.traefik.enable_dashboard, null), false)
      enable_servicemonitor = coalesce(try(var.service_overrides.traefik.enable_servicemonitor, null), local.services_enabled.prometheus_crds)
      # Resource limits with hierarchy
      cpu_limit      = coalesce(try(var.service_overrides.traefik.cpu_limit, null), local.resource_defaults.cpu_limit)
      memory_limit   = coalesce(try(var.service_overrides.traefik.memory_limit, null), local.resource_defaults.memory_limit)
      cpu_request    = coalesce(try(var.service_overrides.traefik.cpu_request, null), local.resource_defaults.cpu_request)
      memory_request = coalesce(try(var.service_overrides.traefik.memory_request, null), local.resource_defaults.memory_request)
    }
    vault = {
      cpu_arch               = coalesce(try(var.service_overrides.vault.cpu_arch, null), try(var.cpu_arch_override.vault, null), local.cpu_arch)
      storage_class          = coalesce(try(var.service_overrides.vault.storage_class, null), try(var.storage_class_override.vault, null), local.storage_classes.default)
      storage_size           = coalesce(try(var.service_overrides.vault.storage_size, null), local.storage_sizes.vault)
      nfs_storage_class_type = coalesce(try(var.service_overrides.vault.nfs_storage_class_type, null), local.default_nfs_storage_class_type)
      nfs_config             = local.nfs_storage_class_configs[coalesce(try(var.service_overrides.vault.nfs_storage_class_type, null), local.default_nfs_storage_class_type)]
      # cert_resolver handled separately in cert_resolvers local
      ha_replicas = coalesce(try(var.service_overrides.vault.ha_replicas, null), local.defaults.ha_replicas_default)
      # Resource limits with hierarchy
      cpu_limit      = coalesce(try(var.service_overrides.vault.cpu_limit, null), "500m")
      memory_limit   = coalesce(try(var.service_overrides.vault.memory_limit, null), "512Mi")
      cpu_request    = coalesce(try(var.service_overrides.vault.cpu_request, null), "250m")
      memory_request = coalesce(try(var.service_overrides.vault.memory_request, null), "256Mi")
    }
    node_red = {
      cpu_arch               = coalesce(try(var.service_overrides.node_red.cpu_arch, null), try(var.cpu_arch_override.node_red, null), local.cpu_arch)
      chart_version          = coalesce(try(var.service_overrides.node_red.chart_version, null), "0.35.0")
      storage_class          = coalesce(try(var.service_overrides.node_red.storage_class, null), local.storage_classes.default)
      storage_size           = coalesce(try(var.service_overrides.node_red.persistent_disk_size, null), local.storage_sizes.node_red)
      nfs_storage_class_type = coalesce(try(var.service_overrides.node_red.nfs_storage_class_type, null), local.default_nfs_storage_class_type)
      nfs_config             = local.nfs_storage_class_configs[coalesce(try(var.service_overrides.node_red.nfs_storage_class_type, null), local.default_nfs_storage_class_type)]
      enable_persistence     = coalesce(try(var.service_overrides.node_red.enable_persistence, null), true)
      enable_ingress         = coalesce(try(var.service_overrides.node_red.enable_ingress, null), true)
      palette_packages       = coalesce(try(var.service_overrides.node_red.palette_packages, null), local.defaults.node_red_palette_packages)
      cpu_limit              = coalesce(try(var.service_overrides.node_red.cpu_limit, null), "500m")
      memory_limit           = coalesce(try(var.service_overrides.node_red.memory_limit, null), "512Mi")
      cpu_request            = coalesce(try(var.service_overrides.node_red.cpu_request, null), "250m")
      memory_request         = coalesce(try(var.service_overrides.node_red.memory_request, null), "256Mi")
    }
    n8n = {
      cpu_arch               = coalesce(try(var.service_overrides.n8n.cpu_arch, null), try(var.cpu_arch_override.n8n, null), local.cpu_arch)
      image_version          = coalesce(try(var.service_overrides.n8n.image_version, null), "latest")
      storage_class          = coalesce(try(var.service_overrides.n8n.storage_class, null), local.storage_classes.default)
      storage_size           = coalesce(try(var.service_overrides.n8n.persistent_disk_size, null), local.storage_sizes.n8n)
      nfs_storage_class_type = coalesce(try(var.service_overrides.n8n.nfs_storage_class_type, null), local.default_nfs_storage_class_type)
      nfs_config             = local.nfs_storage_class_configs[coalesce(try(var.service_overrides.n8n.nfs_storage_class_type, null), local.default_nfs_storage_class_type)]
      enable_persistence     = coalesce(try(var.service_overrides.n8n.enable_persistence, null), true)
      enable_database        = coalesce(try(var.service_overrides.n8n.enable_database, null), false)
      enable_ingress         = coalesce(try(var.service_overrides.n8n.enable_ingress, null), true)
      cpu_limit              = coalesce(try(var.service_overrides.n8n.cpu_limit, null), "1000m")
      memory_limit           = coalesce(try(var.service_overrides.n8n.memory_limit, null), "1Gi")
      cpu_request            = coalesce(try(var.service_overrides.n8n.cpu_request, null), "500m")
      memory_request         = coalesce(try(var.service_overrides.n8n.memory_request, null), "512Mi")
    }
    home_assistant = {
      cpu_arch               = coalesce(try(var.service_overrides.home_assistant.cpu_arch, null), try(var.cpu_arch_override.home_assistant, null), local.cpu_arch)
      image_version          = coalesce(try(var.service_overrides.home_assistant.image_version, null), "latest")
      storage_class          = coalesce(try(var.service_overrides.home_assistant.storage_class, null), local.storage_classes.default)
      storage_size           = coalesce(try(var.service_overrides.home_assistant.persistent_disk_size, null), local.storage_sizes.home_assistant)
      nfs_storage_class_type = coalesce(try(var.service_overrides.home_assistant.nfs_storage_class_type, null), local.default_nfs_storage_class_type)
      nfs_config             = local.nfs_storage_class_configs[coalesce(try(var.service_overrides.home_assistant.nfs_storage_class_type, null), local.default_nfs_storage_class_type)]
      enable_persistence     = coalesce(try(var.service_overrides.home_assistant.enable_persistence, null), true)
      enable_privileged      = coalesce(try(var.service_overrides.home_assistant.enable_privileged, null), false)
      enable_host_network    = coalesce(try(var.service_overrides.home_assistant.enable_host_network, null), true)
      enable_ingress         = coalesce(try(var.service_overrides.home_assistant.enable_ingress, null), true)
      nfs_fs_group           = coalesce(try(var.service_overrides.home_assistant.nfs_fs_group, null), var.nfs_fs_group)
      cpu_limit              = coalesce(try(var.service_overrides.home_assistant.cpu_limit, null), "1000m")
      memory_limit           = coalesce(try(var.service_overrides.home_assistant.memory_limit, null), "1Gi")
      cpu_request            = coalesce(try(var.service_overrides.home_assistant.cpu_request, null), "500m")
      memory_request         = coalesce(try(var.service_overrides.home_assistant.memory_request, null), "512Mi")
    }
    openhab = {
      cpu_arch                = coalesce(try(var.service_overrides.openhab.cpu_arch, null), try(var.cpu_arch_override.openhab, null), local.cpu_arch)
      image_version           = coalesce(try(var.service_overrides.openhab.image_version, null), "4.2.3")
      storage_class           = coalesce(try(var.service_overrides.openhab.storage_class, null), local.storage_classes.default)
      storage_size            = coalesce(try(var.service_overrides.openhab.persistent_disk_size, null), local.storage_sizes.openhab)
      nfs_storage_class_type  = coalesce(try(var.service_overrides.openhab.nfs_storage_class_type, null), local.default_nfs_storage_class_type)
      nfs_config              = local.nfs_storage_class_configs[coalesce(try(var.service_overrides.openhab.nfs_storage_class_type, null), local.default_nfs_storage_class_type)]
      addons_disk_size        = coalesce(try(var.service_overrides.openhab.addons_disk_size, null), "2Gi")
      conf_disk_size          = coalesce(try(var.service_overrides.openhab.conf_disk_size, null), "1Gi")
      enable_persistence      = coalesce(try(var.service_overrides.openhab.enable_persistence, null), true)
      enable_privileged       = coalesce(try(var.service_overrides.openhab.enable_privileged, null), false)
      enable_host_network     = coalesce(try(var.service_overrides.openhab.enable_host_network, null), true)
      enable_karaf_console    = coalesce(try(var.service_overrides.openhab.enable_karaf_console, null), false)
      enable_ingress          = coalesce(try(var.service_overrides.openhab.enable_ingress, null), true)
      deployment_wait_timeout = coalesce(try(var.service_overrides.openhab.deployment_wait_timeout, null), 300)
      nfs_fs_group            = coalesce(try(var.service_overrides.openhab.nfs_fs_group, null), var.nfs_fs_group)
      cpu_limit               = coalesce(try(var.service_overrides.openhab.cpu_limit, null), "2000m")
      memory_limit            = coalesce(try(var.service_overrides.openhab.memory_limit, null), "2Gi")
      cpu_request             = coalesce(try(var.service_overrides.openhab.cpu_request, null), "1000m")
      memory_request          = coalesce(try(var.service_overrides.openhab.memory_request, null), "1Gi")
    }
    homebridge = {
      cpu_arch               = coalesce(try(var.service_overrides.homebridge.cpu_arch, null), try(var.cpu_arch_override.homebridge, null), local.cpu_arch)
      image_version          = coalesce(try(var.service_overrides.homebridge.image_version, null), "latest")
      storage_class          = coalesce(try(var.service_overrides.homebridge.storage_class, null), local.storage_classes.default)
      storage_size           = coalesce(try(var.service_overrides.homebridge.persistent_disk_size, null), local.storage_sizes.homebridge)
      nfs_storage_class_type = coalesce(try(var.service_overrides.homebridge.nfs_storage_class_type, null), local.default_nfs_storage_class_type)
      nfs_config             = local.nfs_storage_class_configs[coalesce(try(var.service_overrides.homebridge.nfs_storage_class_type, null), local.default_nfs_storage_class_type)]
      enable_persistence     = coalesce(try(var.service_overrides.homebridge.enable_persistence, null), true)
      enable_host_network    = coalesce(try(var.service_overrides.homebridge.enable_host_network, null), true)
      enable_ingress         = coalesce(try(var.service_overrides.homebridge.enable_ingress, null), true)
      plugins                = coalesce(try(var.service_overrides.homebridge.plugins, null), ["homebridge-config-ui-x"])
      nfs_fs_group           = coalesce(try(var.service_overrides.homebridge.nfs_fs_group, null), var.nfs_fs_group)
      cpu_limit              = coalesce(try(var.service_overrides.homebridge.cpu_limit, null), "500m")
      memory_limit           = coalesce(try(var.service_overrides.homebridge.memory_limit, null), "512Mi")
      cpu_request            = coalesce(try(var.service_overrides.homebridge.cpu_request, null), "250m")
      memory_request         = coalesce(try(var.service_overrides.homebridge.memory_request, null), "256Mi")
    }
    headlamp = {
      cpu_arch               = coalesce(try(var.service_overrides.headlamp.cpu_arch, null), try(var.cpu_arch_override.headlamp, null), local.cpu_arch)
      chart_version          = coalesce(try(var.service_overrides.headlamp.chart_version, null), "0.40.0")
      storage_class          = coalesce(try(var.service_overrides.headlamp.storage_class, null), local.storage_classes.default)
      storage_size           = coalesce(try(var.service_overrides.headlamp.storage_size, null), "1Gi")
      nfs_storage_class_type = coalesce(try(var.service_overrides.headlamp.nfs_storage_class_type, null), local.default_nfs_storage_class_type)
      nfs_config             = local.nfs_storage_class_configs[coalesce(try(var.service_overrides.headlamp.nfs_storage_class_type, null), local.default_nfs_storage_class_type)]
      enable_persistence     = coalesce(try(var.service_overrides.headlamp.enable_persistence, null), true)
      enabled_plugins        = coalesce(try(var.service_overrides.headlamp.enabled_plugins, null), [])
      # OIDC authentication configuration with auto-configuration from Authelia
      # Priority: explicit override > auto-config from Authelia > default (empty)
      oidc_config = (
        # If user explicitly provides oidc_config override, use it
        try(var.service_overrides.headlamp.oidc_config, null) != null
        ? try(var.service_overrides.headlamp.oidc_config, {}) :
        # If Authelia is enabled with OIDC, auto-configure Headlamp
        local.services_enabled.authelia && coalesce(try(var.service_overrides.authelia.oidc_enabled, null), false)
        ? {
          enabled          = true
          issuer_url       = "https://authelia.${local.domain}"
          client_id        = "headlamp"
          client_secret    = try(var.service_overrides.authelia.oidc_clients.headlamp.client_secret, "change-me-in-production")
          scopes           = "openid,profile,email,groups,offline_access"
          use_access_token = false
        } :
        # Default to empty (no OIDC)
        {}
      )
      # Resource limits with hierarchy
      cpu_limit      = coalesce(try(var.service_overrides.headlamp.cpu_limit, null), "200m")
      memory_limit   = coalesce(try(var.service_overrides.headlamp.memory_limit, null), "256Mi")
      cpu_request    = coalesce(try(var.service_overrides.headlamp.cpu_request, null), "100m")
      memory_request = coalesce(try(var.service_overrides.headlamp.memory_request, null), "128Mi")
    }
    kubevirt = {
      # Architecture configuration
      cpu_arch      = coalesce(try(var.service_overrides.kubevirt.cpu_arch, null), try(var.cpu_arch_override.kubevirt, null), local.cpu_arch)
      chart_version = coalesce(try(var.service_overrides.kubevirt.chart_version, null), "v1.1.1")

      # Feature configuration
      enable_emulation      = coalesce(try(var.service_overrides.kubevirt.enable_emulation, null), local.cpu_arch == "arm64", true)
      enable_servicemonitor = coalesce(try(var.service_overrides.kubevirt.enable_servicemonitor, null), local.services_enabled.prometheus_crds)
      cdi_version           = try(var.service_overrides.kubevirt.cdi_version, "") #Disabled by default

      # Architecture-aware resource defaults
      cpu_limit      = coalesce(try(var.service_overrides.kubevirt.cpu_limit, null), local.cpu_arch == "arm64" ? "500m" : "1000m")
      memory_limit   = coalesce(try(var.service_overrides.kubevirt.memory_limit, null), local.cpu_arch == "arm64" ? "512Mi" : "1Gi")
      cpu_request    = coalesce(try(var.service_overrides.kubevirt.cpu_request, null), local.cpu_arch == "arm64" ? "250m" : "500m")
      memory_request = coalesce(try(var.service_overrides.kubevirt.memory_request, null), local.cpu_arch == "arm64" ? "256Mi" : "512Mi")

      # Cleanup and kubeconfig configuration
      force_namespace_cleanup = coalesce(try(var.service_overrides.kubevirt.force_namespace_cleanup, null), false)
      cleanup_timeout         = coalesce(try(var.service_overrides.kubevirt.cleanup_timeout, null), "15m")
      workspace_prefix        = local.workspace_prefix
      ci_mode                 = coalesce(try(var.service_overrides.kubevirt.ci_mode, null), false)
      kubeconfig_path         = try(var.service_overrides.kubevirt.kubeconfig_path, null) != null ? var.service_overrides.kubevirt.kubeconfig_path : ""
    }
    redis = {
      # Core configuration
      cpu_arch      = coalesce(try(var.service_overrides.redis.cpu_arch, null), try(var.cpu_arch_override.redis, null), local.cpu_arch)
      chart_version = coalesce(try(var.service_overrides.redis.chart_version, null), "18.1.4")

      # Storage configuration
      storage_class      = coalesce(try(var.service_overrides.redis.storage_class, null), local.storage_classes.default)
      storage_size       = coalesce(try(var.service_overrides.redis.storage_size, null), "8Gi")
      enable_persistence = coalesce(try(var.service_overrides.redis.enable_persistence, null), true)

      # Resource limits
      cpu_limit      = coalesce(try(var.service_overrides.redis.cpu_limit, null), "300m")
      memory_limit   = coalesce(try(var.service_overrides.redis.memory_limit, null), "512Mi")
      cpu_request    = coalesce(try(var.service_overrides.redis.cpu_request, null), "100m")
      memory_request = coalesce(try(var.service_overrides.redis.memory_request, null), "128Mi")
    }
    nfs_csi = {
      # Core configuration
      cpu_arch      = coalesce(try(var.service_overrides.nfs_csi.cpu_arch, null), try(var.cpu_arch_override.nfs_csi, null), local.cpu_arch)
      chart_version = coalesce(try(var.service_overrides.nfs_csi.chart_version, null), "4.0.17")

      # NFS server configuration
      nfs_server = coalesce(try(var.service_overrides.nfs_csi.nfs_server_address, null), local.nfs_server)
      nfs_path   = coalesce(try(var.service_overrides.nfs_csi.nfs_server_path, null), local.nfs_path)

      # Resource limits - light workload for CSI driver
      cpu_limit      = coalesce(try(var.service_overrides.nfs_csi.cpu_limit, null), local.defaults.cpu_limit_light)
      memory_limit   = coalesce(try(var.service_overrides.nfs_csi.memory_limit, null), local.defaults.memory_limit_light)
      cpu_request    = coalesce(try(var.service_overrides.nfs_csi.cpu_request, null), local.defaults.cpu_request_light)
      memory_request = coalesce(try(var.service_overrides.nfs_csi.memory_request, null), local.defaults.memory_request_light)
    }
    gatekeeper = {
      # Core configuration
      cpu_arch = coalesce(try(var.service_overrides.gatekeeper.cpu_arch, null), try(var.cpu_arch_override.gatekeeper, null), local.cpu_arch)

      # Security policy configuration
      enable_policies          = coalesce(try(var.service_overrides.gatekeeper.enable_policies, null), true)
      enable_security_policies = coalesce(try(var.service_overrides.gatekeeper.enable_security_policies, null), true)
      enable_resource_policies = coalesce(try(var.service_overrides.gatekeeper.enable_resource_policies, null), true)
      enable_hostpath_policy   = coalesce(try(var.service_overrides.gatekeeper.enable_hostpath_policy, null), true)
      hostpath_max_size        = coalesce(try(var.service_overrides.gatekeeper.hostpath_max_size, null), "10Gi")
      hostpath_storage_class   = coalesce(try(var.service_overrides.gatekeeper.hostpath_storage_class, null), "hostpath")

      # Resource limits
      cpu_limit      = coalesce(try(var.service_overrides.gatekeeper.cpu_limit, null), local.defaults.cpu_limit_default)
      memory_limit   = coalesce(try(var.service_overrides.gatekeeper.memory_limit, null), local.defaults.memory_limit_default)
      cpu_request    = coalesce(try(var.service_overrides.gatekeeper.cpu_request, null), local.defaults.cpu_request_default)
      memory_request = coalesce(try(var.service_overrides.gatekeeper.memory_request, null), local.defaults.memory_request_default)
    }
    node_feature_discovery = {
      # Core configuration
      cpu_arch      = coalesce(try(var.service_overrides.node_feature_discovery.cpu_arch, null), try(var.cpu_arch_override.node_feature_discovery, null), local.cpu_arch)
      chart_version = coalesce(try(var.service_overrides.node_feature_discovery.chart_version, null), "0.17.3")

      # Resource limits - light workload for discovery daemon
      cpu_limit      = coalesce(try(var.service_overrides.node_feature_discovery.cpu_limit, null), local.defaults.cpu_limit_light)
      memory_limit   = coalesce(try(var.service_overrides.node_feature_discovery.memory_limit, null), local.defaults.memory_limit_light)
      cpu_request    = coalesce(try(var.service_overrides.node_feature_discovery.cpu_request, null), local.defaults.cpu_request_light)
      memory_request = coalesce(try(var.service_overrides.node_feature_discovery.memory_request, null), local.defaults.memory_request_light)
    }
    host_path = {
      # Core configuration
      cpu_arch = coalesce(try(var.service_overrides.host_path.cpu_arch, null), try(var.cpu_arch_override.host_path, null), local.cpu_arch)
    }
    longhorn = {
      # Core configuration
      cpu_arch      = coalesce(try(var.service_overrides.longhorn.cpu_arch, null), try(var.cpu_arch_override.longhorn, null), local.cpu_arch)
      chart_version = coalesce(try(var.service_overrides.longhorn.chart_version, null), "1.7.2")

      # Storage configuration
      storage_class      = coalesce(try(var.service_overrides.longhorn.storage_class, null), local.storage_classes.default)
      storage_size       = coalesce(try(var.service_overrides.longhorn.storage_size, null), "20Gi")
      enable_persistence = coalesce(try(var.service_overrides.longhorn.enable_persistence, null), true)

      # Resource limits - storage-intensive workload
      cpu_limit      = coalesce(try(var.service_overrides.longhorn.cpu_limit, null), local.defaults.cpu_limit_high)
      memory_limit   = coalesce(try(var.service_overrides.longhorn.memory_limit, null), local.defaults.memory_limit_high)
      cpu_request    = coalesce(try(var.service_overrides.longhorn.cpu_request, null), local.defaults.cpu_request_default)
      memory_request = coalesce(try(var.service_overrides.longhorn.memory_request, null), local.defaults.memory_request_default)

      # Cleanup and kubeconfig configuration
      force_namespace_cleanup = coalesce(try(var.service_overrides.longhorn.force_namespace_cleanup, null), false)
      cleanup_timeout         = coalesce(try(var.service_overrides.longhorn.cleanup_timeout, null), "15m")
      workspace_prefix        = local.workspace_prefix
      ci_mode                 = coalesce(try(var.service_overrides.longhorn.ci_mode, null), false)
      kubeconfig_path         = try(var.service_overrides.longhorn.kubeconfig_path, null) != null ? var.service_overrides.longhorn.kubeconfig_path : ""
    }
    rook_ceph = {
      # Core configuration
      cpu_arch      = coalesce(try(var.service_overrides.rook_ceph.cpu_arch, null), try(var.cpu_arch_override.rook_ceph, null), local.cpu_arch)
      chart_version = coalesce(try(var.service_overrides.rook_ceph.chart_version, null), "v1.15.6")

      # Storage configuration - CSI resource configuration
      csi_rbd_storage_class    = coalesce(try(var.service_overrides.rook_ceph.csi_rbd_storage_class, null), "ceph-rbd")
      csi_cephfs_storage_class = coalesce(try(var.service_overrides.rook_ceph.csi_cephfs_storage_class, null), "ceph-cephfs")
      enable_cephfs            = coalesce(try(var.service_overrides.rook_ceph.enable_cephfs, null), false)
      enable_rbd               = coalesce(try(var.service_overrides.rook_ceph.enable_rbd, null), true)

      # Resource limits - storage-intensive workload
      cpu_limit      = coalesce(try(var.service_overrides.rook_ceph.cpu_limit, null), local.defaults.cpu_limit_high)
      memory_limit   = coalesce(try(var.service_overrides.rook_ceph.memory_limit, null), local.defaults.memory_limit_high)
      cpu_request    = coalesce(try(var.service_overrides.rook_ceph.cpu_request, null), local.defaults.cpu_request_default)
      memory_request = coalesce(try(var.service_overrides.rook_ceph.memory_request, null), local.defaults.memory_request_default)

      # Cleanup and kubeconfig configuration
      force_namespace_cleanup = coalesce(try(var.service_overrides.rook_ceph.force_namespace_cleanup, null), false)
      cleanup_timeout         = coalesce(try(var.service_overrides.rook_ceph.cleanup_timeout, null), "15m")
      workspace_prefix        = local.workspace_prefix
      ci_mode                 = coalesce(try(var.service_overrides.rook_ceph.ci_mode, null), false)
      kubeconfig_path         = try(var.service_overrides.rook_ceph.kubeconfig_path, null) != null ? var.service_overrides.rook_ceph.kubeconfig_path : ""
    }
  }

  # ============================================================================
  # LEGACY COMPATIBILITY MAPPINGS
  # ============================================================================

  # CPU architecture mapping using unified service configs
  cpu_architectures = {
    # Application services - all use service_configs now
    authelia               = local.service_configs.authelia.cpu_arch
    consul                 = local.service_configs.consul.cpu_arch
    gatekeeper             = local.service_configs.gatekeeper.cpu_arch
    grafana                = local.service_configs.grafana.cpu_arch
    headlamp               = local.service_configs.headlamp.cpu_arch
    host_path              = local.service_configs.host_path.cpu_arch
    kube_state_metrics     = local.service_configs.kube_state_metrics.cpu_arch
    kubevirt               = local.service_configs.kubevirt.cpu_arch
    loki                   = local.service_configs.loki.cpu_arch
    longhorn               = local.service_configs.longhorn.cpu_arch
    metallb                = local.service_configs.metallb.cpu_arch
    nfs_csi                = local.service_configs.nfs_csi.cpu_arch
    node_feature_discovery = local.service_configs.node_feature_discovery.cpu_arch
    portainer              = local.service_configs.portainer.cpu_arch
    prometheus             = local.service_configs.prometheus.cpu_arch
    prometheus_stack       = local.service_configs.prometheus.cpu_arch
    prometheus_stack_crds  = local.service_configs.prometheus.cpu_arch
    promtail               = local.service_configs.promtail.cpu_arch
    redis                  = local.service_configs.redis.cpu_arch
    rook_ceph              = local.service_configs.rook_ceph.cpu_arch
    traefik                = local.service_configs.traefik.cpu_arch
    vault                  = local.service_configs.vault.cpu_arch
  }

  # Chart versions for services - uses service_configs where available
  chart_versions = {
    longhorn               = local.service_configs.longhorn.chart_version
    nfs_csi                = local.service_configs.nfs_csi.chart_version
    node_feature_discovery = local.service_configs.node_feature_discovery.chart_version
    rook_ceph              = local.service_configs.rook_ceph.chart_version
    headlamp               = local.service_configs.headlamp.chart_version
  }

  # Common labels for all resources
  common_labels = {
    "app.kubernetes.io/managed-by" = "terraform"
    "app.kubernetes.io/part-of"    = "k8s-infrastructure"
    "environment"                  = terraform.workspace
  }

  # Resource defaults based on environment
  resource_defaults = {
    cpu_limit      = var.enable_resource_limits ? (var.default_cpu_limit != "" ? var.default_cpu_limit : local.defaults.cpu_limit_default) : local.defaults.cpu_limit_high
    memory_limit   = var.enable_resource_limits ? (var.default_memory_limit != "" ? var.default_memory_limit : local.defaults.memory_limit_default) : local.defaults.memory_limit_high
    cpu_request    = var.enable_resource_limits ? local.defaults.cpu_request_default : "250m"
    memory_request = var.enable_resource_limits ? local.defaults.memory_request_default : "256Mi"
  }

  # DNS provider name for certificate resolver (from configuration)
  dns_provider_name = try(var.service_overrides.traefik.dns_providers.primary.name, "hurricane")

  # Cert resolver mapping using override hierarchy
  cert_resolvers = {
    authelia       = coalesce(try(var.service_overrides.authelia.cert_resolver, null), try(var.cert_resolver_override.authelia, null), var.traefik_cert_resolver != "wildcard" ? var.traefik_cert_resolver : local.dns_provider_name)
    default        = coalesce(try(var.service_overrides.traefik.cert_resolver, null), try(var.cert_resolver_override.traefik, null), var.traefik_cert_resolver != "wildcard" ? var.traefik_cert_resolver : local.dns_provider_name)
    traefik        = coalesce(try(var.service_overrides.traefik.cert_resolver, null), try(var.cert_resolver_override.traefik, null), var.traefik_cert_resolver != "wildcard" ? var.traefik_cert_resolver : local.dns_provider_name)
    prometheus     = coalesce(try(var.service_overrides.prometheus.cert_resolver, null), try(var.cert_resolver_override.prometheus, null), var.traefik_cert_resolver != "wildcard" ? var.traefik_cert_resolver : local.dns_provider_name)
    grafana        = coalesce(try(var.service_overrides.grafana.cert_resolver, null), try(var.cert_resolver_override.grafana, null), var.traefik_cert_resolver != "wildcard" ? var.traefik_cert_resolver : local.dns_provider_name)
    alertmanager   = coalesce(try(var.service_overrides.prometheus.cert_resolver, null), try(var.cert_resolver_override.alertmanager, null), var.traefik_cert_resolver != "wildcard" ? var.traefik_cert_resolver : local.dns_provider_name)
    consul         = coalesce(try(var.service_overrides.consul.cert_resolver, null), try(var.cert_resolver_override.consul, null), var.traefik_cert_resolver != "wildcard" ? var.traefik_cert_resolver : local.dns_provider_name)
    vault          = coalesce(try(var.service_overrides.vault.cert_resolver, null), try(var.cert_resolver_override.vault, null), var.traefik_cert_resolver != "wildcard" ? var.traefik_cert_resolver : local.dns_provider_name)
    portainer      = coalesce(try(var.service_overrides.portainer.cert_resolver, null), try(var.cert_resolver_override.portainer, null), var.traefik_cert_resolver != "wildcard" ? var.traefik_cert_resolver : local.dns_provider_name)
    node_red       = coalesce(try(var.service_overrides.node_red.cert_resolver, null), var.traefik_cert_resolver != "wildcard" ? var.traefik_cert_resolver : local.dns_provider_name)
    n8n            = coalesce(try(var.service_overrides.n8n.cert_resolver, null), var.traefik_cert_resolver != "wildcard" ? var.traefik_cert_resolver : local.dns_provider_name)
    home_assistant = coalesce(try(var.service_overrides.home_assistant.cert_resolver, null), var.traefik_cert_resolver != "wildcard" ? var.traefik_cert_resolver : local.dns_provider_name)
    openhab        = coalesce(try(var.service_overrides.openhab.cert_resolver, null), var.traefik_cert_resolver != "wildcard" ? var.traefik_cert_resolver : local.dns_provider_name)
    homebridge     = coalesce(try(var.service_overrides.homebridge.cert_resolver, null), var.traefik_cert_resolver != "wildcard" ? var.traefik_cert_resolver : local.dns_provider_name)
    headlamp       = coalesce(try(var.service_overrides.headlamp.cert_resolver, null), var.traefik_cert_resolver != "wildcard" ? var.traefik_cert_resolver : local.dns_provider_name)
  }

  # Let's Encrypt email with backward compatibility
  letsencrypt_email = coalesce(
    var.le_email != "" ? var.le_email : null,
    var.letsencrypt_email != "" && var.letsencrypt_email != "admin@example.com" ? var.letsencrypt_email : null,
    "admin@example.com"
  )

  # ============================================================================
  # AUTHENTICATION CONFIGURATION WITH OVERRIDE HIERARCHY
  # ============================================================================

  # Middleware configuration with system defaults
  middleware_config = merge(
    {
      basic_auth = {
        enabled         = false
        secret_name     = ""
        realm           = "Authentication Required"
        static_password = ""
        username        = "admin"
      }
      ldap_auth = {
        enabled       = false
        log_level     = "INFO"
        url           = ""
        port          = local.defaults.ldap_port_default
        base_dn       = ""
        attribute     = "uid"
        bind_dn       = ""
        bind_password = ""
        search_filter = ""
      }
      rate_limit = {
        enabled = false
        average = local.defaults.rate_limit_average
        burst   = local.defaults.rate_limit_burst
      }
      ip_whitelist = {
        enabled       = false
        source_ranges = ["127.0.0.1/32"]
      }
      default_auth = {
        enabled       = false
        ldap_override = false
        basic_config = {
          secret_name     = ""
          realm           = "Authentication Required"
          static_password = ""
          username        = "admin"
        }
        ldap_config = {
          log_level     = "INFO"
          url           = ""
          port          = local.defaults.ldap_port_default
          base_dn       = ""
          attribute     = "uid"
          bind_dn       = ""
          bind_password = ""
          search_filter = ""
        }
      }
    },
    try(var.service_overrides.traefik.middleware_config, {})
  )

  # Authentication method selection logic
  auth_method_enabled = {
    ldap_auth    = local.middleware_config.ldap_auth.enabled
    basic_auth   = local.middleware_config.basic_auth.enabled
    default_auth = local.middleware_config.default_auth.enabled
  }

  # Preferred auth method (priority: default_auth > ldap_auth > basic_auth)
  preferred_auth_method = (
    local.auth_method_enabled.default_auth ? "default" :
    local.auth_method_enabled.ldap_auth ? "ldap" : "basic"
  )

  # Use static middleware names (independent of deployment status)
  traefik_basic_middleware   = local.traefik_middleware_names.basic_auth
  traefik_ldap_middleware    = local.traefik_middleware_names.ldap_auth
  traefik_default_middleware = local.traefik_middleware_names.default_auth

  # Preferred middleware name using Traefik outputs
  preferred_middleware = (
    local.preferred_auth_method == "default" ? local.traefik_default_middleware :
    local.preferred_auth_method == "ldap" ? local.traefik_ldap_middleware :
    local.traefik_basic_middleware
  )

  # Generate static middleware names based on configuration (independent of deployment)
  traefik_middleware_names = {
    basic_auth   = local.middleware_config.basic_auth.enabled ? "${local.workspace_prefix}-traefik-basic-auth" : null
    ldap_auth    = local.middleware_config.ldap_auth.enabled ? "${local.workspace_prefix}-traefik-ldap-auth" : null
    default_auth = local.middleware_config.default_auth.enabled ? "${local.workspace_prefix}-traefik-default-auth" : null
    rate_limit   = local.middleware_config.rate_limit.enabled ? "${local.workspace_prefix}-traefik-rate-limit" : null
    ip_whitelist = local.middleware_config.ip_whitelist.enabled ? "${local.workspace_prefix}-traefik-ip-whitelist" : null
  }

  # Services that need authentication (unprotected services)
  unprotected_services = ["traefik", "prometheus", "alertmanager"]

  # Services with built-in authentication
  protected_services = ["grafana", "portainer", "vault", "consul"]

  # Preferred auth middleware (priority: default_auth > ldap_auth > basic_auth)
  preferred_auth_middleware = (
    local.middleware_config.default_auth.enabled ? local.traefik_middleware_names.default_auth :
    local.middleware_config.ldap_auth.enabled ? local.traefik_middleware_names.ldap_auth :
    local.middleware_config.basic_auth.enabled ? local.traefik_middleware_names.basic_auth :
    null
  )

  # Build middleware lists for each service
  service_middlewares = {
    for service in concat(local.unprotected_services, local.protected_services) : service => (
      # Only apply middlewares if middleware system is enabled
      try(var.middleware_overrides.enabled, false) ? compact([
        # Auth middleware for unprotected services (when auth not disabled)
        (contains(local.unprotected_services, service) &&
          local.preferred_auth_middleware != null &&
        !try(var.middleware_overrides[service].disable_auth, false)) ? local.preferred_auth_middleware : null,

        # Rate limiting middleware (service setting > global setting > false)
        (coalesce(
          try(var.middleware_overrides[service].enable_rate_limit, null),
          try(var.middleware_overrides.all.enable_rate_limit, null),
          false
        ) && local.traefik_middleware_names.rate_limit != null) ? local.traefik_middleware_names.rate_limit : null,

        # IP whitelist middleware (service setting > global setting > false)
        (coalesce(
          try(var.middleware_overrides[service].enable_ip_whitelist, null),
          try(var.middleware_overrides.all.enable_ip_whitelist, null),
          false
        ) && local.traefik_middleware_names.ip_whitelist != null) ? local.traefik_middleware_names.ip_whitelist : null
      ]) : []
    )
  }

  # Add custom middlewares separately to avoid complexity
  service_middlewares_with_custom = {
    for service, middlewares in local.service_middlewares : service => concat(
      middlewares,
      try(var.middleware_overrides.enabled, false) ? try(var.middleware_overrides[service].custom_middlewares, []) : []
    )
  }

  # Legacy auth middleware mapping (for backward compatibility)
  auth_middlewares = {
    basic        = local.traefik_middleware_names.basic_auth
    ldap         = local.traefik_middleware_names.ldap_auth
    default      = local.traefik_middleware_names.default_auth
    traefik      = local.preferred_auth_middleware
    prometheus   = local.preferred_auth_middleware
    alertmanager = local.preferred_auth_middleware
    grafana      = null
    portainer    = null
    vault        = null
    consul       = null
  }

  # ============================================================================
  # HELM CONFIGURATION MAPPINGS
  # ============================================================================

  # Helm configuration with unified override hierarchy
  helm_configs = {
    traefik = {
      timeout          = local.service_configs.traefik.helm_timeout
      disable_webhooks = coalesce(try(var.service_overrides.traefik.helm_disable_webhooks, null), var.default_helm_disable_webhooks)
      skip_crds        = coalesce(try(var.service_overrides.traefik.helm_skip_crds, null), var.default_helm_skip_crds)
      replace          = coalesce(try(var.service_overrides.traefik.helm_replace, null), var.default_helm_replace)
      force_update     = coalesce(try(var.service_overrides.traefik.helm_force_update, null), var.default_helm_force_update)
      cleanup_on_fail  = coalesce(try(var.service_overrides.traefik.helm_cleanup_on_fail, null), var.default_helm_cleanup_on_fail)
      wait             = coalesce(try(var.service_overrides.traefik.helm_wait, null), var.default_helm_wait)
      wait_for_jobs    = coalesce(try(var.service_overrides.traefik.helm_wait_for_jobs, null), var.default_helm_wait_for_jobs)
    }
    metallb = {
      timeout          = coalesce(try(var.service_overrides.metallb.helm_timeout, null), var.default_helm_timeout != 0 ? var.default_helm_timeout : local.defaults.helm_timeout_medium)
      disable_webhooks = coalesce(try(var.service_overrides.metallb.helm_disable_webhooks, null), var.default_helm_disable_webhooks)
      skip_crds        = coalesce(try(var.service_overrides.metallb.helm_skip_crds, null), var.default_helm_skip_crds)
      replace          = coalesce(try(var.service_overrides.metallb.helm_replace, null), var.default_helm_replace)
      force_update     = coalesce(try(var.service_overrides.metallb.helm_force_update, null), var.default_helm_force_update)
      cleanup_on_fail  = coalesce(try(var.service_overrides.metallb.helm_cleanup_on_fail, null), var.default_helm_cleanup_on_fail)
      wait             = coalesce(try(var.service_overrides.metallb.helm_wait, null), var.default_helm_wait)
      wait_for_jobs    = coalesce(try(var.service_overrides.metallb.helm_wait_for_jobs, null), var.default_helm_wait_for_jobs)
    }
    nfs_csi = {
      timeout          = coalesce(try(var.service_overrides.nfs_csi.helm_timeout, null), var.default_helm_timeout != 0 ? var.default_helm_timeout : local.defaults.helm_timeout_medium)
      disable_webhooks = coalesce(try(var.service_overrides.nfs_csi.helm_disable_webhooks, null), var.default_helm_disable_webhooks)
      skip_crds        = coalesce(try(var.service_overrides.nfs_csi.helm_skip_crds, null), var.default_helm_skip_crds)
      replace          = coalesce(try(var.service_overrides.nfs_csi.helm_replace, null), var.default_helm_replace)
      force_update     = coalesce(try(var.service_overrides.nfs_csi.helm_force_update, null), var.default_helm_force_update)
      cleanup_on_fail  = coalesce(try(var.service_overrides.nfs_csi.helm_cleanup_on_fail, null), var.default_helm_cleanup_on_fail)
      wait             = coalesce(try(var.service_overrides.nfs_csi.helm_wait, null), var.default_helm_wait)
      wait_for_jobs    = coalesce(try(var.service_overrides.nfs_csi.helm_wait_for_jobs, null), var.default_helm_wait_for_jobs)
    }

    portainer = {
      timeout          = coalesce(try(var.service_overrides.portainer.helm_timeout, null), var.default_helm_timeout != 0 ? var.default_helm_timeout : local.defaults.helm_timeout_medium)
      disable_webhooks = coalesce(try(var.service_overrides.portainer.helm_disable_webhooks, null), var.default_helm_disable_webhooks)
      skip_crds        = coalesce(try(var.service_overrides.portainer.helm_skip_crds, null), var.default_helm_skip_crds)
      replace          = coalesce(try(var.service_overrides.portainer.helm_replace, null), var.default_helm_replace)
      force_update     = coalesce(try(var.service_overrides.portainer.helm_force_update, null), var.default_helm_force_update)
      cleanup_on_fail  = coalesce(try(var.service_overrides.portainer.helm_cleanup_on_fail, null), var.default_helm_cleanup_on_fail)
      wait             = coalesce(try(var.service_overrides.portainer.helm_wait, null), var.default_helm_wait)
      wait_for_jobs    = coalesce(try(var.service_overrides.portainer.helm_wait_for_jobs, null), var.default_helm_wait_for_jobs)
    }
    prometheus_stack = {
      timeout          = local.service_configs.prometheus.helm_timeout
      disable_webhooks = coalesce(try(var.service_overrides.prometheus.helm_disable_webhooks, null), var.default_helm_disable_webhooks)
      skip_crds        = coalesce(try(var.service_overrides.prometheus.helm_skip_crds, null), var.default_helm_skip_crds)
      replace          = coalesce(try(var.service_overrides.prometheus.helm_replace, null), var.default_helm_replace)
      force_update     = coalesce(try(var.service_overrides.prometheus.helm_force_update, null), var.default_helm_force_update)
      cleanup_on_fail  = coalesce(try(var.service_overrides.prometheus.helm_cleanup_on_fail, null), var.default_helm_cleanup_on_fail)
      wait             = coalesce(try(var.service_overrides.prometheus.helm_wait, null), var.default_helm_wait)
      wait_for_jobs    = coalesce(try(var.service_overrides.prometheus.helm_wait_for_jobs, null), var.default_helm_wait_for_jobs)
    }

    grafana = {
      timeout          = local.service_configs.grafana.helm_timeout
      disable_webhooks = coalesce(try(var.service_overrides.grafana.helm_disable_webhooks, null), var.default_helm_disable_webhooks)
      skip_crds        = coalesce(try(var.service_overrides.grafana.helm_skip_crds, null), var.default_helm_skip_crds)
      replace          = coalesce(try(var.service_overrides.grafana.helm_replace, null), var.default_helm_replace)
      force_update     = coalesce(try(var.service_overrides.grafana.helm_force_update, null), var.default_helm_force_update)
      cleanup_on_fail  = coalesce(try(var.service_overrides.grafana.helm_cleanup_on_fail, null), var.default_helm_cleanup_on_fail)
      wait             = coalesce(try(var.service_overrides.grafana.helm_wait, null), var.default_helm_wait)
      wait_for_jobs    = coalesce(try(var.service_overrides.grafana.helm_wait_for_jobs, null), var.default_helm_wait_for_jobs)
    }

    authelia = {
      timeout          = coalesce(try(var.service_overrides.authelia.helm_timeout, null), var.default_helm_timeout != 0 ? var.default_helm_timeout : local.defaults.helm_timeout_medium)
      disable_webhooks = coalesce(try(var.service_overrides.authelia.helm_disable_webhooks, null), var.default_helm_disable_webhooks)
      skip_crds        = coalesce(try(var.service_overrides.authelia.helm_skip_crds, null), var.default_helm_skip_crds)
      replace          = coalesce(try(var.service_overrides.authelia.helm_replace, null), var.default_helm_replace)
      force_update     = coalesce(try(var.service_overrides.authelia.helm_force_update, null), var.default_helm_force_update)
      cleanup_on_fail  = coalesce(try(var.service_overrides.authelia.helm_cleanup_on_fail, null), var.default_helm_cleanup_on_fail)
      wait             = coalesce(try(var.service_overrides.authelia.helm_wait, null), var.default_helm_wait)
      wait_for_jobs    = coalesce(try(var.service_overrides.authelia.helm_wait_for_jobs, null), var.default_helm_wait_for_jobs)
    }

    headlamp = {
      timeout          = coalesce(try(var.service_overrides.headlamp.helm_timeout, null), var.default_helm_timeout != 0 ? var.default_helm_timeout : local.defaults.helm_timeout_medium)
      disable_webhooks = coalesce(try(var.service_overrides.headlamp.helm_disable_webhooks, null), var.default_helm_disable_webhooks)
      skip_crds        = coalesce(try(var.service_overrides.headlamp.helm_skip_crds, null), var.default_helm_skip_crds)
      replace          = coalesce(try(var.service_overrides.headlamp.helm_replace, null), var.default_helm_replace)
      force_update     = coalesce(try(var.service_overrides.headlamp.helm_force_update, null), var.default_helm_force_update)
      cleanup_on_fail  = coalesce(try(var.service_overrides.headlamp.helm_cleanup_on_fail, null), var.default_helm_cleanup_on_fail)
      wait             = coalesce(try(var.service_overrides.headlamp.helm_wait, null), var.default_helm_wait)
      wait_for_jobs    = coalesce(try(var.service_overrides.headlamp.helm_wait_for_jobs, null), var.default_helm_wait_for_jobs)
    }

    consul = {
      timeout          = coalesce(try(var.service_overrides.consul.helm_timeout, null), var.default_helm_timeout != 0 ? var.default_helm_timeout : local.defaults.helm_timeout_long)
      disable_webhooks = coalesce(try(var.service_overrides.consul.helm_disable_webhooks, null), var.default_helm_disable_webhooks)
      skip_crds        = coalesce(try(var.service_overrides.consul.helm_skip_crds, null), var.default_helm_skip_crds)
      replace          = coalesce(try(var.service_overrides.consul.helm_replace, null), var.default_helm_replace)
      force_update     = coalesce(try(var.service_overrides.consul.helm_force_update, null), var.default_helm_force_update)
      cleanup_on_fail  = coalesce(try(var.service_overrides.consul.helm_cleanup_on_fail, null), var.default_helm_cleanup_on_fail)
      wait             = coalesce(try(var.service_overrides.consul.helm_wait, null), var.default_helm_wait)
      wait_for_jobs    = coalesce(try(var.service_overrides.consul.helm_wait_for_jobs, null), var.default_helm_wait_for_jobs)
    }
    vault = {
      timeout          = coalesce(try(var.service_overrides.vault.helm_timeout, null), var.default_helm_timeout != 0 ? var.default_helm_timeout : local.defaults.helm_timeout_long)
      disable_webhooks = coalesce(try(var.service_overrides.vault.helm_disable_webhooks, null), var.default_helm_disable_webhooks)
      skip_crds        = coalesce(try(var.service_overrides.vault.helm_skip_crds, null), var.default_helm_skip_crds)
      replace          = coalesce(try(var.service_overrides.vault.helm_replace, null), var.default_helm_replace)
      force_update     = coalesce(try(var.service_overrides.vault.helm_force_update, null), var.default_helm_force_update)
      cleanup_on_fail  = coalesce(try(var.service_overrides.vault.helm_cleanup_on_fail, null), var.default_helm_cleanup_on_fail)
      wait             = coalesce(try(var.service_overrides.vault.helm_wait, null), var.default_helm_wait)
      wait_for_jobs    = coalesce(try(var.service_overrides.vault.helm_wait_for_jobs, null), var.default_helm_wait_for_jobs)
    }
    host_path = {
      timeout          = coalesce(try(var.service_overrides.host_path.helm_timeout, null), var.default_helm_timeout != 0 ? var.default_helm_timeout : local.defaults.helm_timeout_short)
      disable_webhooks = coalesce(try(var.service_overrides.host_path.helm_disable_webhooks, null), var.default_helm_disable_webhooks)
      skip_crds        = coalesce(try(var.service_overrides.host_path.helm_skip_crds, null), var.default_helm_skip_crds)
      replace          = coalesce(try(var.service_overrides.host_path.helm_replace, null), var.default_helm_replace)
      force_update     = coalesce(try(var.service_overrides.host_path.helm_force_update, null), var.default_helm_force_update)
      cleanup_on_fail  = coalesce(try(var.service_overrides.host_path.helm_cleanup_on_fail, null), var.default_helm_cleanup_on_fail)
      wait             = coalesce(try(var.service_overrides.host_path.helm_wait, null), var.default_helm_wait)
      wait_for_jobs    = coalesce(try(var.service_overrides.host_path.helm_wait_for_jobs, null), var.default_helm_wait_for_jobs)
    }
    gatekeeper = {
      timeout          = coalesce(try(var.service_overrides.gatekeeper.helm_timeout, null), var.default_helm_timeout != 0 ? var.default_helm_timeout : local.defaults.helm_timeout_medium)
      disable_webhooks = coalesce(try(var.service_overrides.gatekeeper.helm_disable_webhooks, null), var.default_helm_disable_webhooks)
      skip_crds        = coalesce(try(var.service_overrides.gatekeeper.helm_skip_crds, null), var.default_helm_skip_crds)
      replace          = coalesce(try(var.service_overrides.gatekeeper.helm_replace, null), var.default_helm_replace)
      force_update     = coalesce(try(var.service_overrides.gatekeeper.helm_force_update, null), var.default_helm_force_update)
      cleanup_on_fail  = coalesce(try(var.service_overrides.gatekeeper.helm_cleanup_on_fail, null), var.default_helm_cleanup_on_fail)
      wait             = coalesce(try(var.service_overrides.gatekeeper.helm_wait, null), var.default_helm_wait)
      wait_for_jobs    = coalesce(try(var.service_overrides.gatekeeper.helm_wait_for_jobs, null), var.default_helm_wait_for_jobs)
    }
    node_feature_discovery = {
      timeout          = coalesce(try(var.service_overrides.node_feature_discovery.helm_timeout, null), var.default_helm_timeout != 0 ? var.default_helm_timeout : local.defaults.helm_timeout_short)
      disable_webhooks = coalesce(try(var.service_overrides.node_feature_discovery.helm_disable_webhooks, null), var.default_helm_disable_webhooks)
      skip_crds        = coalesce(try(var.service_overrides.node_feature_discovery.helm_skip_crds, null), var.default_helm_skip_crds)
      replace          = coalesce(try(var.service_overrides.node_feature_discovery.helm_replace, null), var.default_helm_replace)
      force_update     = coalesce(try(var.service_overrides.node_feature_discovery.helm_force_update, null), var.default_helm_force_update)
      cleanup_on_fail  = coalesce(try(var.service_overrides.node_feature_discovery.helm_cleanup_on_fail, null), var.default_helm_cleanup_on_fail)
      wait             = coalesce(try(var.service_overrides.node_feature_discovery.helm_wait, null), var.default_helm_wait)
      wait_for_jobs    = coalesce(try(var.service_overrides.node_feature_discovery.helm_wait_for_jobs, null), var.default_helm_wait_for_jobs)
    }
    kube_state_metrics = {
      timeout          = coalesce(try(var.service_overrides.kube_state_metrics.helm_timeout, null), var.default_helm_timeout != 0 ? var.default_helm_timeout : local.defaults.helm_timeout_medium)
      disable_webhooks = coalesce(try(var.service_overrides.kube_state_metrics.helm_disable_webhooks, null), var.default_helm_disable_webhooks)
      skip_crds        = coalesce(try(var.service_overrides.kube_state_metrics.helm_skip_crds, null), var.default_helm_skip_crds)
      replace          = coalesce(try(var.service_overrides.kube_state_metrics.helm_replace, null), var.default_helm_replace)
      force_update     = coalesce(try(var.service_overrides.kube_state_metrics.helm_force_update, null), var.default_helm_force_update)
      cleanup_on_fail  = coalesce(try(var.service_overrides.kube_state_metrics.helm_cleanup_on_fail, null), var.default_helm_cleanup_on_fail)
      wait             = coalesce(try(var.service_overrides.kube_state_metrics.helm_wait, null), var.default_helm_wait)
      wait_for_jobs    = coalesce(try(var.service_overrides.kube_state_metrics.helm_wait_for_jobs, null), var.default_helm_wait_for_jobs)
    }
    metrics_server = {
      timeout          = coalesce(try(var.service_overrides.metrics_server.helm_timeout, null), var.default_helm_timeout != 0 ? var.default_helm_timeout : local.defaults.helm_timeout_short)
      disable_webhooks = coalesce(try(var.service_overrides.metrics_server.helm_disable_webhooks, null), var.default_helm_disable_webhooks)
      skip_crds        = coalesce(try(var.service_overrides.metrics_server.helm_skip_crds, null), var.default_helm_skip_crds)
      replace          = coalesce(try(var.service_overrides.metrics_server.helm_replace, null), var.default_helm_replace)
      force_update     = coalesce(try(var.service_overrides.metrics_server.helm_force_update, null), var.default_helm_force_update)
      cleanup_on_fail  = coalesce(try(var.service_overrides.metrics_server.helm_cleanup_on_fail, null), var.default_helm_cleanup_on_fail)
      wait             = coalesce(try(var.service_overrides.metrics_server.helm_wait, null), var.default_helm_wait)
      wait_for_jobs    = coalesce(try(var.service_overrides.metrics_server.helm_wait_for_jobs, null), var.default_helm_wait_for_jobs)
    }
    loki = {
      timeout          = coalesce(try(var.service_overrides.loki.helm_timeout, null), var.default_helm_timeout != 0 ? var.default_helm_timeout : local.defaults.helm_timeout_medium)
      disable_webhooks = coalesce(try(var.service_overrides.loki.helm_disable_webhooks, null), var.default_helm_disable_webhooks)
      skip_crds        = coalesce(try(var.service_overrides.loki.helm_skip_crds, null), var.default_helm_skip_crds)
      replace          = coalesce(try(var.service_overrides.loki.helm_replace, null), var.default_helm_replace)
      force_update     = coalesce(try(var.service_overrides.loki.helm_force_update, null), var.default_helm_force_update)
      cleanup_on_fail  = coalesce(try(var.service_overrides.loki.helm_cleanup_on_fail, null), var.default_helm_cleanup_on_fail)
      wait             = coalesce(try(var.service_overrides.loki.helm_wait, null), var.default_helm_wait)
      wait_for_jobs    = coalesce(try(var.service_overrides.loki.helm_wait_for_jobs, null), var.default_helm_wait_for_jobs)
    }
    promtail = {
      timeout          = coalesce(try(var.service_overrides.promtail.helm_timeout, null), var.default_helm_timeout != 0 ? var.default_helm_timeout : local.defaults.helm_timeout_short)
      disable_webhooks = coalesce(try(var.service_overrides.promtail.helm_disable_webhooks, null), var.default_helm_disable_webhooks)
      skip_crds        = coalesce(try(var.service_overrides.promtail.helm_skip_crds, null), var.default_helm_skip_crds)
      replace          = coalesce(try(var.service_overrides.promtail.helm_replace, null), var.default_helm_replace)
      force_update     = coalesce(try(var.service_overrides.promtail.helm_force_update, null), var.default_helm_force_update)
      cleanup_on_fail  = coalesce(try(var.service_overrides.promtail.helm_cleanup_on_fail, null), var.default_helm_cleanup_on_fail)
      wait             = coalesce(try(var.service_overrides.promtail.helm_wait, null), var.default_helm_wait)
      wait_for_jobs    = coalesce(try(var.service_overrides.promtail.helm_wait_for_jobs, null), var.default_helm_wait_for_jobs)
    }
    prometheus_stack_crds = {
      timeout          = coalesce(try(var.service_overrides.prometheus_crds.helm_timeout, null), var.default_helm_timeout != 0 ? var.default_helm_timeout : local.defaults.helm_timeout_medium)
      disable_webhooks = coalesce(try(var.service_overrides.prometheus_crds.helm_disable_webhooks, null), var.default_helm_disable_webhooks)
      skip_crds        = coalesce(try(var.service_overrides.prometheus_crds.helm_skip_crds, null), var.default_helm_skip_crds)
      replace          = coalesce(try(var.service_overrides.prometheus_crds.helm_replace, null), var.default_helm_replace)
      force_update     = coalesce(try(var.service_overrides.prometheus_crds.helm_force_update, null), var.default_helm_force_update)
      cleanup_on_fail  = coalesce(try(var.service_overrides.prometheus_crds.helm_cleanup_on_fail, null), var.default_helm_cleanup_on_fail)
      wait             = coalesce(try(var.service_overrides.prometheus_crds.helm_wait, null), var.default_helm_wait)
      wait_for_jobs    = coalesce(try(var.service_overrides.prometheus_crds.helm_wait_for_jobs, null), var.default_helm_wait_for_jobs)
    }
    node_red = {
      timeout          = coalesce(try(var.service_overrides.node_red.helm_timeout, null), var.default_helm_timeout != 0 ? var.default_helm_timeout : local.defaults.helm_timeout_medium)
      disable_webhooks = coalesce(try(var.service_overrides.node_red.helm_disable_webhooks, null), var.default_helm_disable_webhooks)
      skip_crds        = coalesce(try(var.service_overrides.node_red.helm_skip_crds, null), var.default_helm_skip_crds)
      replace          = coalesce(try(var.service_overrides.node_red.helm_replace, null), var.default_helm_replace)
      force_update     = coalesce(try(var.service_overrides.node_red.helm_force_update, null), var.default_helm_force_update)
      cleanup_on_fail  = coalesce(try(var.service_overrides.node_red.helm_cleanup_on_fail, null), var.default_helm_cleanup_on_fail)
      wait             = coalesce(try(var.service_overrides.node_red.helm_wait, null), var.default_helm_wait)
      wait_for_jobs    = coalesce(try(var.service_overrides.node_red.helm_wait_for_jobs, null), var.default_helm_wait_for_jobs)
    }
    n8n = {
      timeout          = coalesce(try(var.service_overrides.n8n.helm_timeout, null), var.default_helm_timeout != 0 ? var.default_helm_timeout : local.defaults.helm_timeout_medium)
      disable_webhooks = coalesce(try(var.service_overrides.n8n.helm_disable_webhooks, null), var.default_helm_disable_webhooks)
      skip_crds        = coalesce(try(var.service_overrides.n8n.helm_skip_crds, null), var.default_helm_skip_crds)
      replace          = coalesce(try(var.service_overrides.n8n.helm_replace, null), var.default_helm_replace)
      force_update     = coalesce(try(var.service_overrides.n8n.helm_force_update, null), var.default_helm_force_update)
      cleanup_on_fail  = coalesce(try(var.service_overrides.n8n.helm_cleanup_on_fail, null), var.default_helm_cleanup_on_fail)
      wait             = coalesce(try(var.service_overrides.n8n.helm_wait, null), var.default_helm_wait)
      wait_for_jobs    = coalesce(try(var.service_overrides.n8n.helm_wait_for_jobs, null), var.default_helm_wait_for_jobs)
    }
    home_assistant = {
      timeout          = coalesce(try(var.service_overrides.home_assistant.helm_timeout, null), var.default_helm_timeout != 0 ? var.default_helm_timeout : local.defaults.helm_timeout_long)
      disable_webhooks = coalesce(try(var.service_overrides.home_assistant.helm_disable_webhooks, null), var.default_helm_disable_webhooks)
      skip_crds        = coalesce(try(var.service_overrides.home_assistant.helm_skip_crds, null), var.default_helm_skip_crds)
      replace          = coalesce(try(var.service_overrides.home_assistant.helm_replace, null), var.default_helm_replace)
      force_update     = coalesce(try(var.service_overrides.home_assistant.helm_force_update, null), var.default_helm_force_update)
      cleanup_on_fail  = coalesce(try(var.service_overrides.home_assistant.helm_cleanup_on_fail, null), var.default_helm_cleanup_on_fail)
      wait             = coalesce(try(var.service_overrides.home_assistant.helm_wait, null), var.default_helm_wait)
      wait_for_jobs    = coalesce(try(var.service_overrides.home_assistant.helm_wait_for_jobs, null), var.default_helm_wait_for_jobs)
    }
    openhab = {
      timeout          = coalesce(try(var.service_overrides.openhab.helm_timeout, null), var.default_helm_timeout != 0 ? var.default_helm_timeout : local.defaults.helm_timeout_long)
      disable_webhooks = coalesce(try(var.service_overrides.openhab.helm_disable_webhooks, null), var.default_helm_disable_webhooks)
      skip_crds        = coalesce(try(var.service_overrides.openhab.helm_skip_crds, null), var.default_helm_skip_crds)
      replace          = coalesce(try(var.service_overrides.openhab.helm_replace, null), var.default_helm_replace)
      force_update     = coalesce(try(var.service_overrides.openhab.helm_force_update, null), var.default_helm_force_update)
      cleanup_on_fail  = coalesce(try(var.service_overrides.openhab.helm_cleanup_on_fail, null), var.default_helm_cleanup_on_fail)
      wait             = coalesce(try(var.service_overrides.openhab.helm_wait, null), var.default_helm_wait)
      wait_for_jobs    = coalesce(try(var.service_overrides.openhab.helm_wait_for_jobs, null), var.default_helm_wait_for_jobs)
    }
    homebridge = {
      timeout          = coalesce(try(var.service_overrides.homebridge.helm_timeout, null), var.default_helm_timeout != 0 ? var.default_helm_timeout : local.defaults.helm_timeout_medium)
      disable_webhooks = coalesce(try(var.service_overrides.homebridge.helm_disable_webhooks, null), var.default_helm_disable_webhooks)
      skip_crds        = coalesce(try(var.service_overrides.homebridge.helm_skip_crds, null), var.default_helm_skip_crds)
      replace          = coalesce(try(var.service_overrides.homebridge.helm_replace, null), var.default_helm_replace)
      force_update     = coalesce(try(var.service_overrides.homebridge.helm_force_update, null), var.default_helm_force_update)
      cleanup_on_fail  = coalesce(try(var.service_overrides.homebridge.helm_cleanup_on_fail, null), var.default_helm_cleanup_on_fail)
      wait             = coalesce(try(var.service_overrides.homebridge.helm_wait, null), var.default_helm_wait)
      wait_for_jobs    = coalesce(try(var.service_overrides.homebridge.helm_wait_for_jobs, null), var.default_helm_wait_for_jobs)
    }
    longhorn = {
      timeout          = coalesce(try(var.service_overrides.longhorn.helm_timeout, null), var.default_helm_timeout != 0 ? var.default_helm_timeout : local.defaults.helm_timeout_long)
      disable_webhooks = coalesce(try(var.service_overrides.longhorn.helm_disable_webhooks, null), var.default_helm_disable_webhooks)
      skip_crds        = coalesce(try(var.service_overrides.longhorn.helm_skip_crds, null), var.default_helm_skip_crds)
      replace          = coalesce(try(var.service_overrides.longhorn.helm_replace, null), var.default_helm_replace)
      force_update     = coalesce(try(var.service_overrides.longhorn.helm_force_update, null), var.default_helm_force_update)
      cleanup_on_fail  = coalesce(try(var.service_overrides.longhorn.helm_cleanup_on_fail, null), var.default_helm_cleanup_on_fail)
      wait             = coalesce(try(var.service_overrides.longhorn.helm_wait, null), var.default_helm_wait)
      wait_for_jobs    = coalesce(try(var.service_overrides.longhorn.helm_wait_for_jobs, null), var.default_helm_wait_for_jobs)
    }
    rook_ceph = {
      timeout          = coalesce(try(var.service_overrides.rook_ceph.helm_timeout, null), var.default_helm_timeout != 0 ? var.default_helm_timeout : local.defaults.helm_timeout_long)
      disable_webhooks = coalesce(try(var.service_overrides.rook_ceph.helm_disable_webhooks, null), var.default_helm_disable_webhooks)
      skip_crds        = coalesce(try(var.service_overrides.rook_ceph.helm_skip_crds, null), var.default_helm_skip_crds)
      replace          = coalesce(try(var.service_overrides.rook_ceph.helm_replace, null), var.default_helm_replace)
      force_update     = coalesce(try(var.service_overrides.rook_ceph.helm_force_update, null), var.default_helm_force_update)
      cleanup_on_fail  = coalesce(try(var.service_overrides.rook_ceph.helm_cleanup_on_fail, null), var.default_helm_cleanup_on_fail)
      wait             = coalesce(try(var.service_overrides.rook_ceph.helm_wait, null), var.default_helm_wait)
      wait_for_jobs    = coalesce(try(var.service_overrides.rook_ceph.helm_wait_for_jobs, null), var.default_helm_wait_for_jobs)
    }
  }
}

# Query control plane nodes - try multiple label patterns for different K8s distributions
# Skip in CI mode to prevent connection errors
data "kubernetes_nodes" "k8s_masters" {
  count = local.enable_k8s_node_queries ? 1 : 0
  metadata {
    labels = {
      "node-role.kubernetes.io/control-plane" = ""
    }
  }
}

data "kubernetes_nodes" "k8s_masters_legacy" {
  count = local.enable_k8s_node_queries ? 1 : 0
  metadata {
    labels = {
      "node-role.kubernetes.io/master" = ""
    }
  }
}

data "kubernetes_nodes" "k3s_masters" {
  count = local.enable_k8s_node_queries ? 1 : 0
  metadata {
    labels = {
      "node-role.kubernetes.io/control-plane" = "true"
    }
  }
}

data "kubernetes_nodes" "microk8s_masters" {
  count = local.enable_k8s_node_queries ? 1 : 0
  metadata {
    labels = {
      "node.kubernetes.io/microk8s-controlplane" = "microk8s-controlplane"
    }
  }
}

# Query worker nodes specifically
data "kubernetes_nodes" "k8s_workers" {
  count = local.enable_k8s_node_queries ? 1 : 0
  metadata {
    labels = {
      "node-role.kubernetes.io/worker" = ""
    }
  }
}

data "kubernetes_nodes" "k3s_workers" {
  count = local.enable_k8s_node_queries ? 1 : 0
  metadata {
    labels = {
      "node-role.kubernetes.io/worker" = "true"
    }
  }
}

# Fallback to any node if no control plane nodes found
data "kubernetes_nodes" "all_nodes" {
  count = local.enable_k8s_node_queries ? 1 : 0
  metadata {
    labels = {}
  }
}
