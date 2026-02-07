resource "kubernetes_namespace" "this" {
  metadata {
    annotations = merge(local.common_labels, {
      name = var.namespace
    })
    labels = local.common_labels
    name   = var.namespace
  }
}

# Headlamp values template using standardized template values
locals {
  headlamp_values = templatefile("${path.module}/templates/headlamp-values.yaml.tpl", local.template_values)
}

# Install helm release Headlamp
resource "helm_release" "this" {
  name       = var.name
  chart      = local.helm_config.chart
  repository = local.helm_config.repository
  version    = local.helm_config.version
  namespace  = kubernetes_namespace.this.metadata[0].name

  values = [
    local.headlamp_values
  ]

  # Helm deployment configuration using locals
  disable_webhooks = var.helm_disable_webhooks
  skip_crds        = var.helm_skip_crds
  replace          = var.helm_replace
  force_update     = var.helm_force_update
  cleanup_on_fail  = var.helm_cleanup_on_fail
  timeout          = var.helm_timeout
  wait             = var.helm_wait
  wait_for_jobs    = var.helm_wait_for_jobs

  depends_on = [
    kubernetes_namespace.this
  ]
}
