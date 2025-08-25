# ============================================================================
# TERRAFORM KUBERNETES INFRASTRUCTURE - CLOUD AGNOSTIC DEPLOYMENT
# ==============  # Gatekeeper version configuration

# This module deploys a comprehensive Kubernetes infrastructure stack
# supporting ARM64, AMD64, and mixed-architecture clusters across various
# platforms including MicroK8s, K3s, EKS, GKE, AKS, and standard Kubernetes.
#
# Architecture: Modular service deployment with automatic detection
# Storage: NFS-CSI primary, hostPath fallback
# Networking: Traefik ingress + MetalLB load balancing
# Monitoring: Prometheus + Grafana + Loki stack
# Security: Vault + Consul + Gatekeeper (optional)
# Management: Portainer container management
#
# ============================================================================

module "traefik" {
  count  = local.services_enabled.traefik ? 1 : 0
  source = "./helm-traefik"
  providers = {
    kubernetes = kubernetes
    helm       = helm
  }
  name                  = "${local.workspace_prefix}-traefik"
  namespace             = "${local.workspace_prefix}-traefik-ingress"
  domain_name           = local.domain
  enable_ingress        = local.service_configs.traefik.enable_dashboard
  traefik_cert_resolver = local.cert_resolvers.traefik
  le_email              = local.letsencrypt_email
  # traefik_dashboard_password removed - use centralized middleware
  consul_url              = local.services_enabled.consul ? module.consul[0].url : ""
  cpu_arch                = local.service_configs.traefik.cpu_arch
  disable_arch_scheduling = local.final_disable_arch_scheduling.traefik

  # DNS provider configuration
  dns_providers = try(var.service_overrides.traefik.dns_providers, {
    primary = {
      name   = "hurricane"
      config = {}
    }
    additional = []
  })

  # Middleware configuration with proper defaults
  middleware_config = local.middleware_config

  # Dashboard middleware - use new flexible middleware system
  dashboard_middleware = length(try(var.service_overrides.traefik.dashboard_middleware, [])) > 0 ? var.service_overrides.traefik.dashboard_middleware : local.service_middlewares_with_custom.traefik

  # Middleware deployment control
  enable_middleware = try(var.middleware_overrides.enabled, false)

  dns_challenge_config = try(var.service_overrides.traefik.dns_challenge_config, {})

  cert_resolvers = try(var.service_overrides.traefik.cert_resolvers, {})

  # Tracing configuration
  enable_tracing  = try(var.service_overrides.traefik.enable_tracing, false)
  tracing_backend = try(var.service_overrides.traefik.tracing_backend, "loki")
  loki_endpoint   = local.services_enabled.loki ? "${module.loki[0].loki_url}/api/traces" : ""
  jaeger_endpoint = try(var.service_overrides.traefik.jaeger_endpoint, "")

  # Storage configuration
  storage_class        = local.service_configs.traefik.storage_class
  persistent_disk_size = local.service_configs.traefik.storage_size

  # Resource limits with service overrides
  cpu_limit      = local.service_configs.traefik.cpu_limit
  memory_limit   = local.service_configs.traefik.memory_limit
  cpu_request    = local.service_configs.traefik.cpu_request
  memory_request = local.service_configs.traefik.memory_request

  # helm configuration
  helm_timeout          = local.helm_configs.traefik.timeout
  helm_disable_webhooks = local.helm_configs.traefik.disable_webhooks
  helm_skip_crds        = local.helm_configs.traefik.skip_crds
  helm_replace          = local.helm_configs.traefik.replace
  helm_force_update     = local.helm_configs.traefik.force_update
  helm_cleanup_on_fail  = local.helm_configs.traefik.cleanup_on_fail
  helm_wait             = local.helm_configs.traefik.wait
  helm_wait_for_jobs    = local.helm_configs.traefik.wait_for_jobs

  depends_on = [
    module.nfs_csi,
    module.metallb,
    module.host_path,
  ]
}


module "metallb" {
  count  = local.services_enabled.metallb ? 1 : 0
  source = "./helm-metallb"
  providers = {
    kubernetes = kubernetes
    helm       = helm
  }
  ingress_gateway_name    = "${lower(try(local.workspace[terraform.workspace], terraform.workspace))}-metallb"
  namespace               = "${lower(try(local.workspace[terraform.workspace], terraform.workspace))}-metallb-ingress"
  domain_name             = local.domain
  address_pool            = local.service_configs.metallb.address_pool
  cpu_arch                = local.service_configs.metallb.cpu_arch
  disable_arch_scheduling = local.final_disable_arch_scheduling.metallb

  # Resource limits
  cpu_limit      = local.service_configs.metallb.cpu_limit
  memory_limit   = local.service_configs.metallb.memory_limit
  cpu_request    = local.service_configs.metallb.cpu_request
  memory_request = local.service_configs.metallb.memory_request

  # helm configuration
  helm_timeout          = local.helm_configs.metallb.timeout
  helm_disable_webhooks = local.helm_configs.metallb.disable_webhooks
  helm_skip_crds        = local.helm_configs.metallb.skip_crds
  helm_replace          = local.helm_configs.metallb.replace
  helm_force_update     = local.helm_configs.metallb.force_update
  helm_cleanup_on_fail  = local.helm_configs.metallb.cleanup_on_fail
  helm_wait             = local.helm_configs.metallb.wait
  helm_wait_for_jobs    = local.helm_configs.metallb.wait_for_jobs
}

module "nfs_csi" {
  count  = local.services_enabled.nfs_csi ? 1 : 0
  source = "./helm-nfs-csi"
  providers = {
    kubernetes = kubernetes
    helm       = helm
  }
  name                    = "${lower(try(local.workspace[terraform.workspace], terraform.workspace))}-nfs-csi"
  namespace               = "${lower(try(local.workspace[terraform.workspace], terraform.workspace))}-nfs-csi-system"
  cpu_arch                = local.cpu_architectures.nfs_csi
  disable_arch_scheduling = local.final_disable_arch_scheduling.nfs_csi
  nfs_server              = coalesce(try(var.service_overrides.nfs_csi.nfs_server_address, null), local.nfs_server)
  nfs_path                = coalesce(try(var.service_overrides.nfs_csi.nfs_server_path, null), local.nfs_path)
  # Set as default when NFS storage is preferred
  set_as_default_storage_class = var.use_nfs_storage && local.services_enabled.nfs_csi
  create_fast_storage_class    = true
  create_safe_storage_class    = true

  # Resource limits
  cpu_limit      = coalesce(try(var.service_overrides.nfs_csi.cpu_limit, null), local.defaults.cpu_limit_light)
  memory_limit   = coalesce(try(var.service_overrides.nfs_csi.memory_limit, null), local.defaults.memory_limit_light)
  cpu_request    = coalesce(try(var.service_overrides.nfs_csi.cpu_request, null), local.defaults.cpu_request_light)
  memory_request = coalesce(try(var.service_overrides.nfs_csi.memory_request, null), local.defaults.memory_request_light)

  # helm configuration
  helm_timeout          = local.helm_configs.nfs_csi.timeout
  helm_disable_webhooks = local.helm_configs.nfs_csi.disable_webhooks
  helm_skip_crds        = local.helm_configs.nfs_csi.skip_crds
  helm_replace          = local.helm_configs.nfs_csi.replace
  helm_force_update     = local.helm_configs.nfs_csi.force_update
  helm_cleanup_on_fail  = local.helm_configs.nfs_csi.cleanup_on_fail
  helm_wait             = local.helm_configs.nfs_csi.wait
  helm_wait_for_jobs    = local.helm_configs.nfs_csi.wait_for_jobs
}

module "host_path" {
  count  = local.services_enabled.host_path ? 1 : 0
  source = "./helm-host-path"
  providers = {
    kubernetes = kubernetes
    helm       = helm
  }
  name                    = "${lower(try(local.workspace[terraform.workspace], terraform.workspace))}-host-path-csi"
  namespace               = "${lower(try(local.workspace[terraform.workspace], terraform.workspace))}-host-path-csi-system"
  domain_name             = local.domain
  cpu_arch                = local.cpu_architectures.host_path
  disable_arch_scheduling = local.final_disable_arch_scheduling.host_path
  # Only set as default if NFS is not enabled or not preferred
  set_as_default_storage_class = !var.use_nfs_storage || !local.services_enabled.nfs_csi

  # helm configuration
  helm_timeout          = local.helm_configs.host_path.timeout
  helm_disable_webhooks = local.helm_configs.host_path.disable_webhooks
  helm_skip_crds        = local.helm_configs.host_path.skip_crds
  helm_replace          = local.helm_configs.host_path.replace
  helm_force_update     = local.helm_configs.host_path.force_update
  helm_cleanup_on_fail  = local.helm_configs.host_path.cleanup_on_fail
  helm_wait             = local.helm_configs.host_path.wait
  helm_wait_for_jobs    = local.helm_configs.host_path.wait_for_jobs
}

module "gatekeeper" {
  count  = local.services_enabled.gatekeeper ? 1 : 0
  source = "./helm-gatekeeper"
  providers = {
    kubernetes = kubernetes
    helm       = helm
  }
  name      = "${lower(try(local.workspace[terraform.workspace], terraform.workspace))}-gatekeeper"
  namespace = "${lower(try(local.workspace[terraform.workspace], terraform.workspace))}-gatekeeper-system"

  # Security policy configuration - PRODUCTION HARDENING
  enable_policies          = coalesce(try(var.service_overrides.gatekeeper.enable_policies, null), true)
  enable_security_policies = coalesce(try(var.service_overrides.gatekeeper.enable_security_policies, null), true)
  enable_resource_policies = coalesce(try(var.service_overrides.gatekeeper.enable_resource_policies, null), true)
  enable_hostpath_policy   = coalesce(try(var.service_overrides.gatekeeper.enable_hostpath_policy, null), true)
  hostpath_max_size        = coalesce(try(var.service_overrides.gatekeeper.hostpath_max_size, null), "10Gi")
  hostpath_storage_class   = coalesce(try(var.service_overrides.gatekeeper.hostpath_storage_class, null), "hostpath")

  cpu_arch = coalesce(try(var.service_overrides.gatekeeper.cpu_arch, null), try(var.cpu_arch_override.gatekeeper, null), local.cpu_arch)

  # Resource limits
  cpu_limit      = coalesce(try(var.service_overrides.gatekeeper.cpu_limit, null), local.defaults.cpu_limit_default)
  memory_limit   = coalesce(try(var.service_overrides.gatekeeper.memory_limit, null), local.defaults.memory_limit_default)
  cpu_request    = coalesce(try(var.service_overrides.gatekeeper.cpu_request, null), local.defaults.cpu_request_default)
  memory_request = coalesce(try(var.service_overrides.gatekeeper.memory_request, null), local.defaults.memory_request_default)

  # helm configuration
  helm_timeout          = local.helm_configs.gatekeeper.timeout
  helm_disable_webhooks = local.helm_configs.gatekeeper.disable_webhooks
  helm_skip_crds        = local.helm_configs.gatekeeper.skip_crds
  helm_replace          = local.helm_configs.gatekeeper.replace
  helm_force_update     = local.helm_configs.gatekeeper.force_update
  helm_cleanup_on_fail  = local.helm_configs.gatekeeper.cleanup_on_fail
  helm_wait             = local.helm_configs.gatekeeper.wait
  helm_wait_for_jobs    = local.helm_configs.gatekeeper.wait_for_jobs
}

module "node_feature_discovery" {
  count  = local.services_enabled.node_feature_discovery ? 1 : 0
  source = "./helm-node-feature-discovery"
  providers = {
    kubernetes = kubernetes
    helm       = helm
  }
  name                    = "${lower(try(local.workspace[terraform.workspace], terraform.workspace))}-node-feature-discovery"
  namespace               = "${lower(try(local.workspace[terraform.workspace], terraform.workspace))}-node-feature-discovery-system"
  cpu_arch                = coalesce(try(var.service_overrides.node_feature_discovery.cpu_arch, null), try(var.cpu_arch_override.node_feature_discovery, null), local.cpu_arch)
  disable_arch_scheduling = local.final_disable_arch_scheduling.node_feature_discovery

  # Resource limits
  cpu_limit      = coalesce(try(var.service_overrides.node_feature_discovery.cpu_limit, null), local.defaults.cpu_limit_light)
  memory_limit   = coalesce(try(var.service_overrides.node_feature_discovery.memory_limit, null), local.defaults.memory_limit_light)
  cpu_request    = coalesce(try(var.service_overrides.node_feature_discovery.cpu_request, null), local.defaults.cpu_request_light)
  memory_request = coalesce(try(var.service_overrides.node_feature_discovery.memory_request, null), local.defaults.memory_request_light)

  # helm configuration
  helm_timeout          = local.helm_configs.node_feature_discovery.timeout
  helm_disable_webhooks = local.helm_configs.node_feature_discovery.disable_webhooks
  helm_skip_crds        = local.helm_configs.node_feature_discovery.skip_crds
  helm_replace          = local.helm_configs.node_feature_discovery.replace
  helm_force_update     = local.helm_configs.node_feature_discovery.force_update
  helm_cleanup_on_fail  = local.helm_configs.node_feature_discovery.cleanup_on_fail
  helm_wait             = local.helm_configs.node_feature_discovery.wait
  helm_wait_for_jobs    = local.helm_configs.node_feature_discovery.wait_for_jobs
}

module "portainer" {
  count  = local.services_enabled.portainer ? 1 : 0
  source = "./helm-portainer"
  providers = {
    kubernetes = kubernetes
    helm       = helm
  }
  name                           = "${lower(try(local.workspace[terraform.workspace], terraform.workspace))}-portainer"
  namespace                      = "${lower(try(local.workspace[terraform.workspace], terraform.workspace))}-portainer-system"
  domain_name                    = local.domain
  enable_portainer_ingress_route = true
  traefik_cert_resolver          = local.cert_resolvers.portainer
  cpu_arch                       = local.service_configs.portainer.cpu_arch
  disable_arch_scheduling        = local.final_disable_arch_scheduling.portainer

  # Storage configuration
  storage_class        = local.service_configs.portainer.storage_class
  persistent_disk_size = local.service_configs.portainer.storage_size

  # Resource limits
  cpu_limit      = local.service_configs.portainer.cpu_limit
  memory_limit   = local.service_configs.portainer.memory_limit
  cpu_request    = local.service_configs.portainer.cpu_request
  memory_request = local.service_configs.portainer.memory_request

  # helm configuration
  helm_timeout          = local.helm_configs.portainer.timeout
  helm_disable_webhooks = local.helm_configs.portainer.disable_webhooks
  helm_skip_crds        = local.helm_configs.portainer.skip_crds
  helm_replace          = local.helm_configs.portainer.replace
  helm_force_update     = local.helm_configs.portainer.force_update
  helm_cleanup_on_fail  = local.helm_configs.portainer.cleanup_on_fail
  helm_wait             = local.helm_configs.portainer.wait
  helm_wait_for_jobs    = local.helm_configs.portainer.wait_for_jobs

  depends_on = [
    module.traefik,
    module.nfs_csi,
    module.metallb,
    module.host_path
  ]
}

module "prometheus" {
  count  = local.services_enabled.prometheus ? 1 : 0
  source = "./helm-prometheus-stack"
  providers = {
    kubernetes = kubernetes
    helm       = helm
  }
  name                        = "${lower(try(local.workspace[terraform.workspace], terraform.workspace))}-prometh-alert"
  namespace                   = "${lower(try(local.workspace[terraform.workspace], terraform.workspace))}-monitoring-stack"
  domain_name                 = local.domain
  traefik_cert_resolver       = local.cert_resolvers.prometheus
  cpu_arch                    = local.service_configs.prometheus.cpu_arch
  monitoring_admin_password   = local.service_configs.prometheus.monitoring_admin_password
  enable_prometheus_ingress   = local.service_configs.prometheus.enable_ingress
  enable_alertmanager_ingress = local.service_configs.prometheus.enable_alertmanager_ingress
  enable_monitoring_auth      = coalesce(try(var.service_overrides.prometheus.enable_monitoring_auth, null), true) # Enable by default when middleware available
  # Grafana handled by standalone module

  # Middleware integration - use new flexible middleware system
  traefik_middleware_namespace  = local.services_enabled.traefik ? module.traefik[0].namespace : ""
  traefik_security_middlewares  = local.services_enabled.traefik ? local.service_middlewares_with_custom.prometheus : []
  traefik_basic_auth_middleware = null # Managed by service_middlewares system

  # Storage configuration - Grafana handled by standalone module
  prometheus_storage_class   = local.service_configs.prometheus.storage_class
  alertmanager_storage_class = coalesce(try(var.service_overrides.prometheus.alertmanager_storage_class, null), var.storage_class_override.alertmanager, "hostpath")
  prometheus_storage_size    = local.service_configs.prometheus.storage_size
  alertmanager_storage_size  = local.storage_sizes.alertmanager

  # Resource limits
  cpu_limit      = local.service_configs.prometheus.cpu_limit
  memory_limit   = local.service_configs.prometheus.memory_limit
  cpu_request    = local.service_configs.prometheus.cpu_request
  memory_request = local.service_configs.prometheus.memory_request

  # helm configuration
  helm_timeout          = local.helm_configs.prometheus_stack.timeout
  helm_disable_webhooks = local.helm_configs.prometheus_stack.disable_webhooks
  helm_skip_crds        = local.helm_configs.prometheus_stack.skip_crds
  helm_replace          = local.helm_configs.prometheus_stack.replace
  helm_force_update     = local.helm_configs.prometheus_stack.force_update
  helm_cleanup_on_fail  = local.helm_configs.prometheus_stack.cleanup_on_fail
  helm_wait             = local.helm_configs.prometheus_stack.wait
  helm_wait_for_jobs    = local.helm_configs.prometheus_stack.wait_for_jobs



  depends_on = [
    module.prometheus_crds,
    module.traefik,
    module.nfs_csi,
    module.host_path
  ]
}

module "prometheus_crds" {
  count  = local.services_enabled.prometheus_crds ? 1 : 0
  source = "./helm-prometheus-stack-crds"
  providers = {
    kubernetes = kubernetes
    helm       = helm
  }
  name        = "${lower(try(local.workspace[terraform.workspace], terraform.workspace))}-prometheus-operator-crds"
  namespace   = "${lower(try(local.workspace[terraform.workspace], terraform.workspace))}-premon-stack"
  domain_name = local.domain
  cpu_arch    = local.cpu_architectures.prometheus_stack_crds

  # helm configuration
  helm_timeout          = local.helm_configs.prometheus_stack_crds.timeout
  helm_disable_webhooks = local.helm_configs.prometheus_stack_crds.disable_webhooks
  helm_skip_crds        = local.helm_configs.prometheus_stack_crds.skip_crds
  helm_replace          = local.helm_configs.prometheus_stack_crds.replace
  helm_force_update     = local.helm_configs.prometheus_stack_crds.force_update
  helm_cleanup_on_fail  = local.helm_configs.prometheus_stack_crds.cleanup_on_fail
  helm_wait             = local.helm_configs.prometheus_stack_crds.wait
  helm_wait_for_jobs    = local.helm_configs.prometheus_stack_crds.wait_for_jobs
}

# https://artifacthub.io/packages/helm/grafana/grafana
module "grafana" {
  count  = local.services_enabled.grafana ? 1 : 0
  source = "./helm-grafana"
  providers = {
    kubernetes = kubernetes
    helm       = helm
  }
  name                   = "${lower(try(local.workspace[terraform.workspace], terraform.workspace))}-grafana"
  namespace              = "${lower(try(local.workspace[terraform.workspace], terraform.workspace))}-grafana-system"
  domain_name            = local.domain
  traefik_cert_resolver  = local.cert_resolvers.grafana
  prometheus_url         = local.services_enabled.prometheus ? module.prometheus[0].prometheus_url : "http://localhost:9090"
  prometheus_namespace   = local.services_enabled.prometheus ? module.prometheus[0].namespace : "default"
  alertmanager_url       = local.services_enabled.prometheus ? module.prometheus[0].alertmanager_url : "http://localhost:9093"
  loki_url               = local.services_enabled.loki ? module.loki[0].loki_url : "http://localhost:3100"
  cpu_arch               = local.service_configs.grafana.cpu_arch
  grafana_node_name      = local.service_configs.grafana.node_name
  grafana_admin_password = local.service_configs.grafana.admin_password

  # Storage configuration - Enable persistence to fix SQLite locking issues
  enable_persistence = local.service_configs.grafana.enable_persistence
  storage_class      = local.service_configs.grafana.storage_class
  storage_size       = local.service_configs.grafana.storage_size

  # Resource limits - Optimized for ARM64 with persistent storage
  cpu_limit      = local.service_configs.grafana.cpu_limit
  memory_limit   = local.service_configs.grafana.memory_limit
  cpu_request    = local.service_configs.grafana.cpu_request
  memory_request = local.service_configs.grafana.memory_request

  # helm configuration
  helm_timeout          = local.helm_configs.grafana.timeout
  helm_disable_webhooks = local.helm_configs.grafana.disable_webhooks
  helm_skip_crds        = local.helm_configs.grafana.skip_crds
  helm_replace          = local.helm_configs.grafana.replace
  helm_force_update     = local.helm_configs.grafana.force_update
  helm_cleanup_on_fail  = local.helm_configs.grafana.cleanup_on_fail
  helm_wait             = local.helm_configs.grafana.wait
  helm_wait_for_jobs    = local.helm_configs.grafana.wait_for_jobs

  depends_on = [
    module.prometheus,
    module.traefik,
    module.nfs_csi,
    module.host_path
  ]
}

module "kube_state_metrics" {
  count  = local.services_enabled.kube_state_metrics ? 1 : 0
  source = "./helm-kube-state-metrics"
  providers = {
    kubernetes = kubernetes
    helm       = helm
  }
  name                    = "${lower(try(local.workspace[terraform.workspace], terraform.workspace))}-kube-state-metrics"
  namespace               = "${lower(try(local.workspace[terraform.workspace], terraform.workspace))}-kube-state-metrics-system"
  cpu_arch                = local.service_configs.kube_state_metrics.cpu_arch
  disable_arch_scheduling = local.final_disable_arch_scheduling.kube_state_metrics

  # Resource limits - Optimized for Kubernetes metrics collection
  cpu_limit      = local.service_configs.kube_state_metrics.cpu_limit
  memory_limit   = local.service_configs.kube_state_metrics.memory_limit
  cpu_request    = local.service_configs.kube_state_metrics.cpu_request
  memory_request = local.service_configs.kube_state_metrics.memory_request

  # helm configuration
  helm_timeout          = local.helm_configs.kube_state_metrics.timeout
  helm_disable_webhooks = local.helm_configs.kube_state_metrics.disable_webhooks
  helm_skip_crds        = local.helm_configs.kube_state_metrics.skip_crds
  helm_replace          = local.helm_configs.kube_state_metrics.replace
  helm_force_update     = local.helm_configs.kube_state_metrics.force_update
  helm_cleanup_on_fail  = local.helm_configs.kube_state_metrics.cleanup_on_fail
  helm_wait             = local.helm_configs.kube_state_metrics.wait
  helm_wait_for_jobs    = local.helm_configs.kube_state_metrics.wait_for_jobs

  depends_on = [
    module.prometheus_crds
  ]
}

module "loki" {
  count  = local.services_enabled.loki ? 1 : 0
  source = "./helm-loki"
  providers = {
    kubernetes = kubernetes
    helm       = helm
  }
  name                  = "${lower(try(local.workspace[terraform.workspace], terraform.workspace))}-loki"
  namespace             = "${lower(try(local.workspace[terraform.workspace], terraform.workspace))}-loki-system"
  domain_name           = local.domain
  traefik_cert_resolver = local.cert_resolvers.default
  enable_ingress        = false # Loki ingress disabled by default
  cpu_arch              = local.service_configs.loki.cpu_arch
  storage_class         = local.service_configs.loki.storage_class
  storage_size          = local.service_configs.loki.storage_size

  # Resource limits optimized for ARM64
  cpu_limit      = local.service_configs.loki.cpu_limit
  memory_limit   = local.service_configs.loki.memory_limit
  cpu_request    = local.service_configs.loki.cpu_request
  memory_request = local.service_configs.loki.memory_request

  helm_timeout          = local.helm_configs.loki.timeout
  helm_disable_webhooks = local.helm_configs.loki.disable_webhooks
  helm_skip_crds        = local.helm_configs.loki.skip_crds
  helm_replace          = local.helm_configs.loki.replace
  helm_force_update     = local.helm_configs.loki.force_update
  helm_cleanup_on_fail  = local.helm_configs.loki.cleanup_on_fail
  helm_wait             = local.helm_configs.loki.wait
  helm_wait_for_jobs    = local.helm_configs.loki.wait_for_jobs

  depends_on = [
    module.nfs_csi,
    module.host_path
  ]
}

module "promtail" {
  count  = local.services_enabled.promtail && local.services_enabled.loki ? 1 : 0
  source = "./helm-promtail"
  providers = {
    kubernetes = kubernetes
    helm       = helm
  }
  name      = "${lower(try(local.workspace[terraform.workspace], terraform.workspace))}-promtail"
  namespace = "${lower(try(local.workspace[terraform.workspace], terraform.workspace))}-promtail-system"
  loki_url  = local.services_enabled.loki ? module.loki[0].loki_url : "http://loki:3100"
  cpu_arch  = local.service_configs.promtail.cpu_arch

  # Resource limits optimized for ARM64 DaemonSet
  cpu_limit      = local.service_configs.promtail.cpu_limit
  memory_limit   = local.service_configs.promtail.memory_limit
  cpu_request    = local.service_configs.promtail.cpu_request
  memory_request = local.service_configs.promtail.memory_request

  # Limit range configuration
  container_default_cpu    = local.service_configs.promtail.container_default_cpu
  container_default_memory = local.service_configs.promtail.container_default_memory
  container_request_cpu    = local.service_configs.promtail.container_request_cpu
  container_request_memory = local.service_configs.promtail.container_request_memory
  container_max_cpu        = local.service_configs.promtail.container_max_cpu
  container_max_memory     = local.service_configs.promtail.container_max_memory
  pvc_max_storage          = local.service_configs.promtail.pvc_max_storage
  pvc_min_storage          = local.service_configs.promtail.pvc_min_storage

  helm_timeout          = local.helm_configs.promtail.timeout
  helm_disable_webhooks = local.helm_configs.promtail.disable_webhooks
  helm_skip_crds        = local.helm_configs.promtail.skip_crds
  helm_replace          = local.helm_configs.promtail.replace
  helm_force_update     = local.helm_configs.promtail.force_update
  helm_cleanup_on_fail  = local.helm_configs.promtail.cleanup_on_fail
  helm_wait             = local.helm_configs.promtail.wait
  helm_wait_for_jobs    = local.helm_configs.promtail.wait_for_jobs

  depends_on = [
    module.loki
  ]
}

module "consul" {
  count  = local.services_enabled.consul ? 1 : 0
  source = "./helm-consul"
  providers = {
    kubernetes = kubernetes
    helm       = helm
  }
  name                  = "${lower(try(local.workspace[terraform.workspace], terraform.workspace))}-consul"
  namespace             = "${lower(try(local.workspace[terraform.workspace], terraform.workspace))}-consul-stack"
  traefik_cert_resolver = local.cert_resolvers.consul
  domain_name           = local.domain
  cpu_arch              = local.service_configs.consul.cpu_arch

  # Replica configuration
  server_replicas = local.service_configs.consul.server_replicas
  client_replicas = local.service_configs.consul.client_replicas

  # Anti-affinity configuration
  enable_pod_anti_affinity = local.service_configs.consul.enable_pod_anti_affinity

  # Storage configuration
  storage_class        = local.service_configs.consul.storage_class
  persistent_disk_size = local.service_configs.consul.storage_size

  # Resource limits
  cpu_limit      = local.service_configs.consul.cpu_limit
  memory_limit   = local.service_configs.consul.memory_limit
  cpu_request    = local.service_configs.consul.cpu_request
  memory_request = local.service_configs.consul.memory_request

  # helm configuration
  helm_timeout          = local.helm_configs.consul.timeout
  helm_disable_webhooks = local.helm_configs.consul.disable_webhooks
  helm_skip_crds        = local.helm_configs.consul.skip_crds
  helm_replace          = local.helm_configs.consul.replace
  helm_force_update     = local.helm_configs.consul.force_update
  helm_cleanup_on_fail  = local.helm_configs.consul.cleanup_on_fail
  helm_wait             = local.helm_configs.consul.wait
  helm_wait_for_jobs    = local.helm_configs.consul.wait_for_jobs

  depends_on = [
    module.nfs_csi,
    module.host_path,
    module.metallb,
  ]
}

module "vault" {
  count  = local.services_enabled.vault ? 1 : 0
  source = "./helm-vault"
  providers = {
    kubernetes = kubernetes
    helm       = helm
  }
  name                  = "${lower(try(local.workspace[terraform.workspace], terraform.workspace))}-vault"
  namespace             = "${lower(try(local.workspace[terraform.workspace], terraform.workspace))}-vault-stack"
  traefik_cert_resolver = local.cert_resolvers.vault
  domain_name           = local.domain
  consul_address        = local.services_enabled.consul ? module.consul[0].uri : ""
  consul_token          = local.services_enabled.consul ? module.consul[0].token : ""
  cpu_arch              = local.service_configs.vault.cpu_arch

  # Replica configuration
  ha_replicas = local.service_configs.vault.ha_replicas

  # Storage configuration
  storage_class = local.service_configs.vault.storage_class
  storage_size  = local.service_configs.vault.storage_size

  # Resource limits
  cpu_limit      = local.service_configs.vault.cpu_limit
  memory_limit   = local.service_configs.vault.memory_limit
  cpu_request    = local.service_configs.vault.cpu_request
  memory_request = local.service_configs.vault.memory_request

  # helm configuration
  helm_timeout          = local.helm_configs.vault.timeout
  helm_disable_webhooks = local.helm_configs.vault.disable_webhooks
  helm_skip_crds        = local.helm_configs.vault.skip_crds
  helm_replace          = local.helm_configs.vault.replace
  helm_force_update     = local.helm_configs.vault.force_update
  helm_cleanup_on_fail  = local.helm_configs.vault.cleanup_on_fail
  helm_wait             = local.helm_configs.vault.wait
  helm_wait_for_jobs    = local.helm_configs.vault.wait_for_jobs

  depends_on = [
    module.consul,
    module.nfs_csi,
    module.host_path,
    module.metallb
  ]
}

# ============================================================================
# AUTOMATION AND WORKFLOW SERVICES
# ============================================================================

module "home_assistant" {
  count  = local.services_enabled.home_assistant ? 1 : 0
  source = "./helm-home-assistant"
  providers = {
    kubernetes = kubernetes
    helm       = helm
  }
  name                    = "${local.workspace_prefix}-home-assistant"
  namespace               = "${local.workspace_prefix}-home-assistant-system"
  domain_name             = local.domain
  traefik_cert_resolver   = local.cert_resolvers.home_assistant
  cpu_arch                = local.service_configs.home_assistant.cpu_arch
  disable_arch_scheduling = local.final_disable_arch_scheduling.home_assistant

  # Storage configuration
  enable_persistence   = local.service_configs.home_assistant.enable_persistence
  storage_class        = local.service_configs.home_assistant.storage_class
  persistent_disk_size = local.service_configs.home_assistant.storage_size

  # Feature configuration
  enable_privileged   = local.service_configs.home_assistant.enable_privileged
  enable_host_network = local.service_configs.home_assistant.enable_host_network

  # Ingress configuration
  enable_ingress = local.service_configs.home_assistant.enable_ingress

  # Resource limits
  cpu_limit      = local.service_configs.home_assistant.cpu_limit
  memory_limit   = local.service_configs.home_assistant.memory_limit
  cpu_request    = local.service_configs.home_assistant.cpu_request
  memory_request = local.service_configs.home_assistant.memory_request

  # helm configuration
  helm_timeout          = local.helm_configs.home_assistant.timeout
  helm_disable_webhooks = local.helm_configs.home_assistant.disable_webhooks
  helm_skip_crds        = local.helm_configs.home_assistant.skip_crds
  helm_replace          = local.helm_configs.home_assistant.replace
  helm_force_update     = local.helm_configs.home_assistant.force_update
  helm_cleanup_on_fail  = local.helm_configs.home_assistant.cleanup_on_fail
  helm_wait             = local.helm_configs.home_assistant.wait
  helm_wait_for_jobs    = local.helm_configs.home_assistant.wait_for_jobs

  depends_on = [
    module.traefik,
    module.nfs_csi,
    module.host_path
  ]
}

module "openhab" {
  count  = local.services_enabled.openhab ? 1 : 0
  source = "./helm-openhab"
  providers = {
    kubernetes = kubernetes
    helm       = helm
  }
  name                    = "${local.workspace_prefix}-openhab"
  namespace               = "${local.workspace_prefix}-openhab-system"
  domain_name             = local.domain
  traefik_cert_resolver   = local.cert_resolvers.openhab
  cpu_arch                = local.service_configs.openhab.cpu_arch
  disable_arch_scheduling = local.final_disable_arch_scheduling.openhab

  # Storage configuration
  enable_persistence   = local.service_configs.openhab.enable_persistence
  storage_class        = local.service_configs.openhab.storage_class
  persistent_disk_size = local.service_configs.openhab.storage_size
  addons_disk_size     = local.service_configs.openhab.addons_disk_size
  conf_disk_size       = local.service_configs.openhab.conf_disk_size

  # Feature configuration
  enable_privileged    = local.service_configs.openhab.enable_privileged
  enable_host_network  = local.service_configs.openhab.enable_host_network
  enable_karaf_console = local.service_configs.openhab.enable_karaf_console

  # Ingress configuration
  enable_ingress = local.service_configs.openhab.enable_ingress

  # Resource limits
  cpu_limit      = local.service_configs.openhab.cpu_limit
  memory_limit   = local.service_configs.openhab.memory_limit
  cpu_request    = local.service_configs.openhab.cpu_request
  memory_request = local.service_configs.openhab.memory_request

  # helm configuration
  helm_timeout          = local.helm_configs.openhab.timeout
  helm_disable_webhooks = local.helm_configs.openhab.disable_webhooks
  helm_skip_crds        = local.helm_configs.openhab.skip_crds
  helm_replace          = local.helm_configs.openhab.replace
  helm_force_update     = local.helm_configs.openhab.force_update
  helm_cleanup_on_fail  = local.helm_configs.openhab.cleanup_on_fail
  helm_wait             = local.helm_configs.openhab.wait
  helm_wait_for_jobs    = local.helm_configs.openhab.wait_for_jobs

  depends_on = [
    module.traefik,
    module.nfs_csi,
    module.host_path
  ]
}

module "node_red" {
  count  = local.services_enabled.node_red ? 1 : 0
  source = "./helm-node-red"
  providers = {
    kubernetes = kubernetes
    helm       = helm
  }
  name                    = "${local.workspace_prefix}-node-red"
  namespace               = "${local.workspace_prefix}-node-red-system"
  domain_name             = local.domain
  traefik_cert_resolver   = local.cert_resolvers.node_red
  cpu_arch                = local.service_configs.node_red.cpu_arch
  disable_arch_scheduling = local.final_disable_arch_scheduling.node_red

  # Storage configuration
  enable_persistence   = local.service_configs.node_red.enable_persistence
  storage_class        = local.service_configs.node_red.storage_class
  persistent_disk_size = local.service_configs.node_red.storage_size

  # Ingress configuration
  enable_ingress = local.service_configs.node_red.enable_ingress

  # Palette packages
  palette_packages = local.service_configs.node_red.palette_packages

  # Resource limits
  cpu_limit      = local.service_configs.node_red.cpu_limit
  memory_limit   = local.service_configs.node_red.memory_limit
  cpu_request    = local.service_configs.node_red.cpu_request
  memory_request = local.service_configs.node_red.memory_request

  # helm configuration
  helm_timeout          = local.helm_configs.node_red.timeout
  helm_disable_webhooks = local.helm_configs.node_red.disable_webhooks
  helm_skip_crds        = local.helm_configs.node_red.skip_crds
  helm_replace          = local.helm_configs.node_red.replace
  helm_force_update     = local.helm_configs.node_red.force_update
  helm_cleanup_on_fail  = local.helm_configs.node_red.cleanup_on_fail
  helm_wait             = local.helm_configs.node_red.wait
  helm_wait_for_jobs    = local.helm_configs.node_red.wait_for_jobs

  depends_on = [
    module.traefik,
    module.nfs_csi,
    module.host_path
  ]
}

module "n8n" {
  count  = local.services_enabled.n8n ? 1 : 0
  source = "./n8n"
  providers = {
    kubernetes = kubernetes
  }
  name                    = "${local.workspace_prefix}-n8n"
  namespace               = "${local.workspace_prefix}-n8n-system"
  domain_name             = local.domain
  traefik_cert_resolver   = local.cert_resolvers.n8n
  cpu_arch                = local.service_configs.n8n.cpu_arch
  disable_arch_scheduling = local.final_disable_arch_scheduling.n8n

  # Storage configuration
  enable_persistence   = local.service_configs.n8n.enable_persistence
  storage_class        = local.service_configs.n8n.storage_class
  persistent_disk_size = local.service_configs.n8n.storage_size

  # Database configuration
  enable_database = local.service_configs.n8n.enable_database

  # Ingress configuration
  enable_ingress = local.service_configs.n8n.enable_ingress

  # Resource limits
  cpu_limit      = local.service_configs.n8n.cpu_limit
  memory_limit   = local.service_configs.n8n.memory_limit
  cpu_request    = local.service_configs.n8n.cpu_request
  memory_request = local.service_configs.n8n.memory_request

  # Native Terraform deployment - no Helm configuration needed

  depends_on = [
    module.traefik,
    module.nfs_csi,
    module.host_path
  ]
}
