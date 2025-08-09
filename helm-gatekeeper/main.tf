# Deploy Gatekeeper CRDs first
module "crds" {
  count  = local.gatekeeper_config.enable_policies ? 1 : 0
  source = "./crds"

  name               = "${local.helm_config.name}-crds"
  namespace          = local.helm_config.namespace
  chart_name         = local.helm_config.chart
  chart_repo         = local.helm_config.repository
  chart_version      = local.helm_config.version
  gatekeeper_version = local.gatekeeper_config.version
  helm_timeout       = local.helm_config.timeout
}

# Check if CRDs are available in the cluster
data "kubernetes_resources" "gatekeeper_crds" {
  count = local.gatekeeper_config.enable_policies ? 1 : 0

  api_version    = local.gatekeeper_config.api_version
  kind           = "CustomResourceDefinition"
  field_selector = "metadata.name=constrainttemplates.templates.gatekeeper.sh"
}

# Generate a consistent random suffix for the namespace
resource "kubernetes_namespace" "this" {
  metadata {
    annotations = merge(
      {
        name = local.helm_config.namespace
      },
      local.common_labels
    )
    labels = local.common_labels
    name   = local.helm_config.namespace
  }
}

# Only deploy Helm release if CRDs are ready in the cluster
resource "helm_release" "this" {
  count = local.crds_ready ? 1 : 0

  name       = local.helm_config.name
  chart      = local.helm_config.chart
  repository = local.helm_config.repository
  version    = local.helm_config.version
  namespace  = kubernetes_namespace.this.metadata[0].name

  create_namespace = false

  values = [local.helm_config.values_template]

  # Allow Helm to replace existing resources
  disable_webhooks = local.helm_options.disable_webhooks
  # Skip CRDs since they're handled by the CRDs module
  skip_crds = local.helm_options.skip_crds
  # Allow Helm to replace existing resources
  replace = local.helm_options.replace
  # Force resource updates if needed
  force_update = local.helm_options.force_update
  # Cleanup CRDs on deletion
  cleanup_on_fail = local.helm_options.cleanup_on_fail
  # Allow Helm to create new namespaces
  timeout = local.helm_config.timeout
  # Wait for the Helm release to be fully deployed
  wait = local.helm_config.wait
  # Wait for the Helm release to be fully deploye
  wait_for_jobs = local.helm_config.wait_for_jobs

  depends_on = [
    kubernetes_namespace.this,
    module.crds # Ensure CRDs are deployed first
  ]
}

module "policies" {
  count  = local.gatekeeper_config.enable_policies && local.crds_ready && length(helm_release.this) > 0 ? 1 : 0
  source = "./policies"

  depends_on = [helm_release.this] # This will work since we check length > 0

  namespace                = local.helm_config.namespace
  enable_hostpath_policy   = local.policy_config.enable_hostpath_policy
  hostpath_max_size        = local.policy_config.hostpath_max_size
  hostpath_storage_class   = local.policy_config.hostpath_storage_class
  enable_security_policies = local.policy_config.enable_security_policies
  enable_resource_policies = local.policy_config.enable_resource_policies
}