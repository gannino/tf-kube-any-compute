resource "kubernetes_namespace" "this" {
  metadata {
    annotations = merge(local.common_labels, {
      name = local.module_config.namespace
    })
    labels = local.common_labels
    name   = local.module_config.namespace
  }
}

resource "helm_release" "this" {
  name       = local.module_config.name
  chart      = local.helm_config.chart_name
  repository = local.helm_config.chart_repo
  version    = local.helm_config.chart_version
  namespace  = kubernetes_namespace.this.metadata[0].name

  values = [
    templatefile("${path.module}/values.yaml.tpl", local.template_values)
  ]

  # Helm deployment configuration
  disable_webhooks = local.helm_config.disable_webhooks
  skip_crds        = local.helm_config.skip_crds
  replace          = local.helm_config.replace
  force_update     = local.helm_config.force_update
  cleanup_on_fail  = local.helm_config.cleanup_on_fail
  timeout          = local.helm_config.timeout
  wait             = local.helm_config.wait
  wait_for_jobs    = local.helm_config.wait_for_jobs

  depends_on = [kubernetes_namespace.this]
}
