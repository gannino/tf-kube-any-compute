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

# https://traefik.io/blog/secure-web-applications-with-traefik-proxy-cert-manager-and-lets-encrypt
module "traefik" {
  count  = local.services_enabled.traefik ? 1 : 0
  source = "./helm-traefik"
  providers = {
    kubernetes = kubernetes
    helm       = helm
  }
  name                       = "${local.workspace_prefix}-traefik"
  namespace                  = "${local.workspace_prefix}-traefik-ingress"
  domain_name                = local.domain
  enable_ingress             = local.service_configs.traefik.enable_dashboard
  traefik_cert_resolver      = local.cert_resolvers.traefik
  le_email                   = local.letsencrypt_email
  traefik_dashboard_password = var.traefik_dashboard_password
  consul_url                 = local.services_enabled.consul ? module.consul[0].url : ""
  cpu_arch                   = local.service_configs.traefik.cpu_arch
  disable_arch_scheduling    = local.final_disable_arch_scheduling.traefik
  load_balancer_class        = local.service_configs.traefik.load_balancer_class
  enable_load_balancer_class = local.service_configs.traefik.enable_load_balancer_class

  # Storage configuration
  storage_class        = local.service_configs.traefik.storage_class
  persistent_disk_size = local.storage_sizes.traefik

  # Resource limits with service overrides
  cpu_limit      = coalesce(try(var.service_overrides.traefik.cpu_limit, null), "200m")
  memory_limit   = coalesce(try(var.service_overrides.traefik.memory_limit, null), "128Mi")
  cpu_request    = coalesce(try(var.service_overrides.traefik.cpu_request, null), "50m")
  memory_request = coalesce(try(var.service_overrides.traefik.memory_request, null), "64Mi")

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
    module.consul,
    module.host_path
  ]
}


module "metallb" {
  count  = local.services_enabled.metallb ? 1 : 0
  source = "./helm-metallb"
  providers = {
    kubernetes = kubernetes
    helm       = helm
  }
  ingress_gateway_name       = "${local.workspace_prefix}-metallb"
  namespace                  = "${local.workspace_prefix}-metallb-ingress"
  domain_name                = local.domain
  address_pool               = local.service_configs.metallb.address_pool
  cpu_arch                   = local.cpu_architectures.metallb
  disable_arch_scheduling    = local.final_disable_arch_scheduling.metallb
  load_balancer_class        = local.service_configs.metallb.load_balancer_class
  enable_load_balancer_class = local.service_configs.metallb.enable_load_balancer_class
  address_pool_name          = local.service_configs.metallb.address_pool_name
  enable_prometheus_metrics  = local.service_configs.metallb.enable_prometheus_metrics
  controller_replica_count   = local.service_configs.metallb.controller_replica_count
  speaker_replica_count      = local.service_configs.metallb.speaker_replica_count
  enable_bgp                 = local.service_configs.metallb.enable_bgp
  enable_frr                 = local.service_configs.metallb.enable_frr
  log_level                  = local.service_configs.metallb.log_level
  service_monitor_enabled    = local.service_configs.metallb.service_monitor_enabled
  additional_ip_pools        = coalesce(try(var.service_overrides.metallb.additional_ip_pools, null), [])
  bgp_peers                  = coalesce(try(var.service_overrides.metallb.bgp_peers, null), [])

  # Resource limits
  cpu_limit      = var.enable_resource_limits ? var.default_cpu_limit : "100m"
  memory_limit   = var.enable_resource_limits ? var.default_memory_limit : "64Mi"
  cpu_request    = "25m"
  memory_request = "32Mi"

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
  name                    = "${local.workspace_prefix}-nfs-csi"
  namespace               = "${local.workspace_prefix}-nfs-csi-system"
  cpu_arch                = local.cpu_architectures.nfs_csi
  disable_arch_scheduling = local.final_disable_arch_scheduling.nfs_csi
  nfs_server              = local.nfs_server
  nfs_path                = local.nfs_path
  # Set as default when NFS storage is preferred
  set_as_default_storage_class = var.use_nfs_storage && local.services_enabled.nfs_csi
  create_fast_storage_class    = true
  create_safe_storage_class    = true

  # Resource limits
  cpu_limit      = var.enable_resource_limits ? "100m" : "100m"
  memory_limit   = var.enable_resource_limits ? "64Mi" : "64Mi"
  cpu_request    = "25m"
  memory_request = "32Mi"

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
  name                    = "${local.workspace_prefix}-host-path-csi"
  namespace               = "${local.workspace_prefix}-host-path-csi-system"
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
  name      = "${local.workspace_prefix}-gatekeeper"
  namespace = "${local.workspace_prefix}-gatekeeper-system"

  # Security policy configuration - PRODUCTION HARDENING
  enable_policies          = true
  enable_security_policies = true   # Enforce security contexts, no privileged containers
  enable_resource_policies = true   # Enforce CPU/memory limits
  enable_hostpath_policy   = true   # Limit PVC sizes
  hostpath_max_size        = "10Gi" # Strict storage limits
  hostpath_storage_class   = "hostpath"

  cpu_arch = local.cpu_architectures.gatekeeper

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
  name                    = "${local.workspace_prefix}-node-feature-discovery"
  namespace               = "${local.workspace_prefix}-node-feature-discovery-system"
  cpu_arch                = local.cpu_architectures.node_feature_discovery
  disable_arch_scheduling = local.final_disable_arch_scheduling.node_feature_discovery

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
  name                           = "${local.workspace_prefix}-portainer"
  namespace                      = "${local.workspace_prefix}-portainer-system"
  domain_name                    = local.domain
  enable_portainer_ingress_route = true
  traefik_cert_resolver          = local.cert_resolvers.portainer
  cpu_arch                       = local.service_configs.portainer.cpu_arch
  disable_arch_scheduling        = local.final_disable_arch_scheduling.portainer

  # Storage configuration
  storage_class        = local.service_configs.portainer.storage_class
  persistent_disk_size = local.storage_sizes.portainer

  # Resource limits
  cpu_limit      = var.enable_resource_limits ? var.default_cpu_limit : "500m"
  memory_limit   = var.enable_resource_limits ? var.default_memory_limit : "512Mi"
  cpu_request    = "100m"
  memory_request = "128Mi"

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
  name                        = "${local.workspace_prefix}-prometh-alert"
  namespace                   = "${local.workspace_prefix}-monitoring-stack"
  domain_name                 = local.domain
  traefik_cert_resolver       = local.cert_resolvers.prometheus
  cpu_arch                    = local.service_configs.prometheus.cpu_arch
  monitoring_admin_password   = local.service_configs.prometheus.monitoring_admin_password
  enable_prometheus_ingress   = local.service_configs.prometheus.enable_ingress
  enable_alertmanager_ingress = local.service_configs.prometheus.enable_alertmanager_ingress
  enable_monitoring_auth      = coalesce(try(var.service_overrides.prometheus.enable_monitoring_auth, null), false)
  # Grafana handled by standalone module

  # Storage configuration - Grafana handled by standalone module
  prometheus_storage_class   = local.service_configs.prometheus.storage_class
  alertmanager_storage_class = coalesce(var.storage_class_override.alertmanager, local.storage_classes.default, "hostpath")
  prometheus_storage_size    = local.storage_sizes.prometheus
  alertmanager_storage_size  = local.storage_sizes.alertmanager

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
  name        = "${local.workspace_prefix}-prometheus-operator-crds"
  namespace   = "${local.workspace_prefix}-premon-stack"
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
  name                   = "${local.workspace_prefix}-grafana"
  namespace              = "${local.workspace_prefix}-grafana-system"
  domain_name            = local.domain
  traefik_cert_resolver  = local.cert_resolvers.grafana
  prometheus_url         = local.services_enabled.prometheus ? module.prometheus[0].prometheus_url : "http://localhost:9090"
  prometheus_namespace   = local.services_enabled.prometheus ? module.prometheus[0].namespace : "default"
  alertmanager_url       = local.services_enabled.prometheus ? module.prometheus[0].alertmanager_url : "http://localhost:9093"
  loki_url               = local.services_enabled.loki ? module.loki[0].loki_url : "http://localhost:3100"
  cpu_arch               = local.service_configs.grafana.cpu_arch
  grafana_node_name      = local.service_configs.grafana.node_name
  grafana_admin_password = var.grafana_admin_password

  # Storage configuration - Enable persistence to fix SQLite locking issues
  enable_persistence = local.service_configs.grafana.enable_persistence
  storage_class      = local.service_configs.grafana.storage_class
  storage_size       = local.storage_sizes.grafana

  # Resource limits - Optimized for ARM64 with persistent storage
  cpu_limit      = var.enable_resource_limits ? "300m" : "500m"
  memory_limit   = var.enable_resource_limits ? "256Mi" : "512Mi"
  cpu_request    = "100m"
  memory_request = "128Mi"

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

module "loki" {
  count  = local.services_enabled.loki ? 1 : 0
  source = "./helm-loki"
  providers = {
    kubernetes = kubernetes
    helm       = helm
  }
  name                  = "${local.workspace_prefix}-loki"
  namespace             = "${local.workspace_prefix}-loki-system"
  domain_name           = local.domain
  traefik_cert_resolver = local.cert_resolvers.default
  enable_ingress        = false # Loki ingress disabled by default
  cpu_arch              = local.service_configs.loki.cpu_arch
  storage_class         = local.service_configs.loki.storage_class
  storage_size          = "5Gi"

  # Resource limits optimized for ARM64
  cpu_limit      = var.enable_resource_limits ? "200m" : "500m"
  memory_limit   = var.enable_resource_limits ? "256Mi" : "512Mi"
  cpu_request    = "50m"
  memory_request = "64Mi"

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
  name      = "${local.workspace_prefix}-promtail"
  namespace = "${local.workspace_prefix}-promtail-system"
  loki_url  = local.services_enabled.loki ? module.loki[0].loki_url : "http://loki:3100"
  cpu_arch  = local.cpu_architectures.promtail

  # Resource limits optimized for ARM64 DaemonSet
  cpu_limit      = var.enable_resource_limits ? "100m" : "200m"
  memory_limit   = var.enable_resource_limits ? "128Mi" : "256Mi"
  cpu_request    = "50m"
  memory_request = "64Mi"

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
  name                  = "${local.workspace_prefix}-consul"
  namespace             = "${local.workspace_prefix}-consul-stack"
  traefik_cert_resolver = local.cert_resolvers.consul
  domain_name           = local.domain
  cpu_arch              = local.service_configs.consul.cpu_arch

  # Storage configuration
  storage_class        = local.service_configs.consul.storage_class
  persistent_disk_size = local.storage_sizes.consul

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
  name                  = "${local.workspace_prefix}-vault"
  namespace             = "${local.workspace_prefix}-vault-stack"
  traefik_cert_resolver = local.cert_resolvers.vault
  domain_name           = local.domain
  consul_address        = local.services_enabled.consul ? module.consul[0].uri : ""
  consul_token          = local.services_enabled.consul ? module.consul[0].token : ""
  cpu_arch              = local.service_configs.vault.cpu_arch

  # Storage configuration  
  storage_class = local.service_configs.vault.storage_class
  storage_size  = local.storage_sizes.vault

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
# FUTURE SERVICES (Currently Disabled)
# ============================================================================

# module "n8n" {
#   source = "./n8n"
#   providers = {
#     kubernetes  = kubernetes
#     kubernetes-alpha = kubernetes-alpha
#   }
#   deployment = "${local.workspace_prefix}-n8n"
#   namespace = "${local.workspace_prefix}-n8n-system"
#   service = "${local.workspace_prefix}-n8n-server"

#   domain_name = local.domain
#   depends_on = [
#       module.traefik
#   ]
# }




