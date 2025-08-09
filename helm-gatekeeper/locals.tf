locals {
  # Module configuration
  module_config = {
    component = "policy-engine"
  }

  # Helm configuration
  helm_config = {
    name          = var.name
    namespace     = var.namespace
    chart         = var.chart_name
    repository    = var.chart_repo
    version       = var.chart_version
    timeout       = var.helm_timeout
    wait          = var.helm_wait
    wait_for_jobs = var.helm_wait_for_jobs
    values_template = templatefile("${path.module}/values.yaml.tpl", {
      cpu_limit               = local.resource_config.limits.cpu
      memory_limit            = local.resource_config.limits.memory
      cpu_request             = local.resource_config.requests.cpu
      memory_request          = local.resource_config.requests.memory
      cpu_arch                = var.cpu_arch
      disable_arch_scheduling = var.disable_arch_scheduling
    })
  }

  # Standardized labels
  common_labels = {
    "app.kubernetes.io/name"       = var.name
    "app.kubernetes.io/component"  = local.module_config.component
    "app.kubernetes.io/part-of"    = "infrastructure"
    "app.kubernetes.io/managed-by" = "terraform"
  }

  # Resource configuration
  resource_config = {
    limits = {
      cpu    = var.cpu_limit
      memory = var.memory_limit
    }
    requests = {
      cpu    = var.cpu_request
      memory = var.memory_request
    }
  }

  # Limit range configuration
  limit_range_config = {
    enabled              = var.limit_range_enabled
    container_max_cpu    = var.container_max_cpu
    container_max_memory = var.container_max_memory
    pvc_max_storage      = var.pvc_max_storage
    pvc_min_storage      = var.pvc_min_storage
  }

  # Gatekeeper-specific configuration
  gatekeeper_config = {
    version          = var.gatekeeper_version
    enable_policies  = var.enable_policies
    crd_wait_timeout = var.crd_wait_timeout
    api_version      = var.crd_api_version
    critical_crds = [
      "constrainttemplates.templates.gatekeeper.sh",
      "k8srequiredlabels.templates.gatekeeper.sh",
      "k8sallowedrepos.templates.gatekeeper.sh"
    ]
  }

  # Policy configuration
  policy_config = {
    enable_hostpath_policy   = var.enable_hostpath_policy
    hostpath_max_size        = var.hostpath_max_size
    hostpath_storage_class   = var.hostpath_storage_class
    enable_security_policies = var.enable_security_policies
    enable_resource_policies = var.enable_resource_policies
  }

  # Helm configuration options
  helm_options = merge(var.service_overrides, {
    disable_webhooks = var.helm_disable_webhooks
    skip_crds        = true # Always skip CRDs in main chart since we handle them separately
    replace          = var.helm_replace
    force_update     = var.helm_force_update
    cleanup_on_fail  = var.helm_cleanup_on_fail
  })

  # CRD readiness check
  crds_ready = var.enable_policies && length(data.kubernetes_resources.gatekeeper_crds) > 0 && length(data.kubernetes_resources.gatekeeper_crds[0].objects) > 0
}
