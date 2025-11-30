resource "kubernetes_namespace" "this" {
  metadata {
    name        = local.module_config.namespace
    labels      = local.common_labels
    annotations = local.common_labels
  }
}

# Cleanup provisioner to handle stuck deletions
resource "null_resource" "cleanup" {
  triggers = {
    namespace = local.module_config.namespace
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      echo "Cleaning up Longhorn resources..."
      kubectl delete deployment,daemonset,statefulset -n ${self.triggers.namespace} --all --force --grace-period=0 || true
      kubectl delete pods -n ${self.triggers.namespace} --all --force --grace-period=0 || true
      for resource in volumes engines replicas nodes engineimages instancemanagers sharemanagers backingimages; do
        kubectl get $resource.longhorn.io -n ${self.triggers.namespace} -o name 2>/dev/null | xargs -r kubectl patch -n ${self.triggers.namespace} -p '{"metadata":{"finalizers":[]}}' --type=merge || true
        kubectl delete $resource.longhorn.io -n ${self.triggers.namespace} --all --ignore-not-found=true || true
      done
      kubectl patch namespace ${self.triggers.namespace} -p '{"metadata":{"finalizers":[]}}' --type=merge || true
    EOT
  }
}

resource "helm_release" "this" {
  name       = local.module_config.name
  chart      = local.module_config.chart_name
  repository = local.module_config.chart_repo
  version    = local.module_config.chart_version
  namespace  = kubernetes_namespace.this.metadata[0].name

  create_namespace = false
  values = [
    templatefile("${path.module}/values.yaml.tpl", local.template_values)
  ]

  disable_webhooks = local.helm_config.disable_webhooks
  skip_crds        = local.helm_config.skip_crds
  replace          = local.helm_config.replace
  force_update     = local.helm_config.force_update
  cleanup_on_fail  = local.helm_config.cleanup_on_fail
  timeout          = local.helm_config.timeout
  wait             = local.helm_config.wait
  wait_for_jobs    = local.helm_config.wait_for_jobs

  # Prevent uninstall issues
  disable_openapi_validation = true
  atomic                     = false

  # Lifecycle configuration to handle stuck deletions
  lifecycle {
    ignore_changes = [
      metadata,
    ]
  }

  depends_on = [
    kubernetes_namespace.this,
    null_resource.cleanup
  ]
}
