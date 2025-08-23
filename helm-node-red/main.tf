# ============================================================================
# HELM-NODE-RED MODULE - VISUAL PROGRAMMING FOR IOT AND AUTOMATION
# ============================================================================

# Create Node-RED namespace
resource "kubernetes_namespace" "this" {
  metadata {
    annotations = merge(
      {
        name = local.module_config.namespace
      },
      local.common_labels
    )
    labels = local.common_labels
    name   = local.module_config.namespace
  }
}

# Deploy Node-RED
resource "helm_release" "this" {
  name       = local.module_config.name
  chart      = local.module_config.chart_name
  repository = local.module_config.chart_repo
  version    = local.module_config.chart_version
  namespace  = kubernetes_namespace.this.metadata[0].name

  # Helm configuration using locals
  timeout          = local.helm_config.timeout
  disable_webhooks = local.helm_config.disable_webhooks
  skip_crds        = local.helm_config.skip_crds
  replace          = local.helm_config.replace
  force_update     = local.helm_config.force_update
  cleanup_on_fail  = local.helm_config.cleanup_on_fail
  wait             = local.helm_config.wait
  wait_for_jobs    = local.helm_config.wait_for_jobs

  values = [
    templatefile("${path.module}/templates/node-red-values.yaml.tpl", local.template_values)
  ]

  depends_on = [
    kubernetes_namespace.this,
    kubernetes_persistent_volume_claim.data_storage
  ]
}

# Wait for Node-RED deployment to be ready
resource "null_resource" "wait_for_deployment" {
  depends_on = [helm_release.this]

  provisioner "local-exec" {
    command     = <<EOT
      echo "Waiting for Node-RED deployment to be ready..."
      kubectl wait --for=condition=available --timeout=${local.module_config.deployment_wait_timeout}s deployment/${var.name} -n ${kubernetes_namespace.this.metadata[0].name}
    EOT
    interpreter = ["/bin/bash", "-c"]
  }
}

# Get service information
data "kubernetes_service" "this" {
  metadata {
    name      = var.name
    namespace = kubernetes_namespace.this.metadata[0].name
  }
  depends_on = [helm_release.this]
}
