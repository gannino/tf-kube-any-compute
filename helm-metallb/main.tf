# Create metallb namespace
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

# Deploy MetalLB via Helm
resource "helm_release" "this" {
  name       = local.module_config.name
  chart      = local.module_config.chart_name
  repository = local.module_config.chart_repo
  version    = local.module_config.chart_version
  namespace  = kubernetes_namespace.this.metadata[0].name

  values = [local.metallb_values]

  # Helm configuration from locals
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

# Use kubectl_manifest provider instead of kubernetes_manifest
# This requires adding the kubectl provider to your terraform configuration
resource "kubectl_manifest" "metallb_ip_pool" {
  yaml_body = <<-YAML
    apiVersion: metallb.io/v1beta1
    kind: IPAddressPool
    metadata:
      name: default-pool
      namespace: ${kubernetes_namespace.this.metadata[0].name}
    spec:
      addresses:
      - ${local.module_config.address_pool}
  YAML

  depends_on = [helm_release.this]
}

resource "kubectl_manifest" "metallb_l2_advert" {
  yaml_body = <<-YAML
    apiVersion: metallb.io/v1beta1
    kind: L2Advertisement
    metadata:
      name: l2
      namespace: ${kubernetes_namespace.this.metadata[0].name}
    spec: {}
  YAML

  depends_on = [helm_release.this]
}
