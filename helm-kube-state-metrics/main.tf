resource "kubernetes_namespace" "this" {
  metadata {
    annotations = merge(local.common_labels, {
      name = local.module_config.namespace
    })
    labels = local.common_labels
    name   = local.module_config.namespace
  }
}

# Kube-state-metrics values template using standardized template values
locals {
  kube_state_metrics_values = templatefile("${path.module}/templates/kube-state-metrics-values.yaml.tpl", local.template_values)
}

# Install helm release kube-state-metrics
resource "helm_release" "this" {
  name       = local.helm_config.name
  chart      = local.helm_config.chart
  repository = local.helm_config.repository
  version    = local.helm_config.version
  namespace  = kubernetes_namespace.this.metadata[0].name

  values = [
    local.kube_state_metrics_values
  ]

  # Helm deployment configuration using locals
  disable_webhooks = local.helm_config.disable_webhooks
  skip_crds        = local.helm_config.skip_crds
  replace          = local.helm_config.replace
  force_update     = local.helm_config.force_update
  cleanup_on_fail  = local.helm_config.cleanup_on_fail
  timeout          = local.helm_config.timeout
  wait             = local.helm_config.wait
  wait_for_jobs    = local.helm_config.wait_for_jobs

  depends_on = [
    kubernetes_namespace.this
  ]
}
