locals {
  module_config = {
    name          = var.name
    namespace     = var.namespace
    chart_name    = var.chart_name
    chart_repo    = var.chart_repo
    chart_version = var.chart_version
    component     = "storage-provisioner"
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

  # Auto-detect kubelet root directory based on k8s distribution
  kubelet_root_dir = var.kubelet_root_dir != "" ? var.kubelet_root_dir : (
    var.k8s_distribution == "k3s" ? "/var/lib/rancher/k3s/agent/kubelet" :
    var.k8s_distribution == "microk8s" ? "/var/snap/microk8s/common/var/lib/kubelet" :
    "/var/lib/kubelet" # Standard Kubernetes
  )

  template_values = {
    cpu_arch                        = var.cpu_arch
    disable_arch_scheduling         = var.disable_arch_scheduling
    set_as_default_storage_class    = var.set_as_default_storage_class
    replica_count                   = var.replica_count
    kubelet_root_dir                = local.kubelet_root_dir
    backup_target                   = var.backup_target
    backup_target_credential_secret = var.backup_target_credential_secret
    default_data_path               = var.default_data_path
    cpu_limit                       = local.resource_config.limits.cpu
    memory_limit                    = local.resource_config.limits.memory
    cpu_request                     = local.resource_config.requests.cpu
    memory_request                  = local.resource_config.requests.memory
  }

  # Ingress configuration
  ingress_config = {
    host         = "longhorn.${var.domain_name}"
    service_name = "longhorn-frontend"
    service_port = 80
    path         = "/"

    # TLS configuration based on cert resolver type
    tls_annotations = var.traefik_cert_resolver == "wildcard" ? {
      "traefik.ingress.kubernetes.io/router.tls.domains.0.main" = var.domain_name
      "traefik.ingress.kubernetes.io/router.tls.domains.0.sans" = "*.${var.domain_name}"
      } : {
      "traefik.ingress.kubernetes.io/router.tls.domains.0.main" = "longhorn.${var.domain_name}"
    }

    # Base annotations for ingress
    base_annotations = {
      "traefik.ingress.kubernetes.io/router.entrypoints"      = "websecure"
      "traefik.ingress.kubernetes.io/router.tls"              = "true"
      "traefik.ingress.kubernetes.io/router.tls.certresolver" = var.traefik_cert_resolver
    }
  }
}
