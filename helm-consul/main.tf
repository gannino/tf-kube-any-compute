resource "kubernetes_namespace" "this" {
  metadata {
    annotations = local.common_labels
    labels      = local.common_labels
    name        = local.module_config.namespace
  }
}

resource "helm_release" "this" {
  name       = local.module_config.name
  chart      = local.module_config.chart_name
  repository = local.module_config.chart_repo
  version    = local.module_config.chart_version
  namespace  = kubernetes_namespace.this.metadata[0].name
  values = [
    templatefile("${path.module}/templates/consul-values.yaml.tpl", local.template_values)
  ]

  # Helm deployment settings
  disable_webhooks = local.helm_config.disable_webhooks
  skip_crds        = local.helm_config.skip_crds
  replace          = local.helm_config.replace
  force_update     = local.helm_config.force_update
  cleanup_on_fail  = local.helm_config.cleanup_on_fail
  timeout          = local.helm_config.timeout
  wait             = local.helm_config.wait
  wait_for_jobs    = local.helm_config.wait_for_jobs

  depends_on = [kubernetes_secret.this, kubernetes_limit_range.namespace_limits, kubernetes_namespace.this]
}


# Generate a proper Consul gossip encryption key (32 bytes base64 encoded)
resource "random_bytes" "gossip_encryption_key" {
  length = 16
}

resource "kubernetes_secret" "this" {
  metadata {
    name      = local.consul_config.gossip_encryption_key_secret_name
    namespace = kubernetes_namespace.this.metadata[0].name
    labels    = local.common_labels
  }

  data = {
    key = random_bytes.gossip_encryption_key.base64
  }

  type       = "Opaque"
  depends_on = [kubernetes_namespace.this]
}

data "kubernetes_secret" "token" {
  metadata {
    name      = local.consul_config.bootstrap_acl_token_secret_name
    namespace = kubernetes_namespace.this.metadata[0].name
  }
  depends_on = [kubernetes_namespace.this, helm_release.this]
}
