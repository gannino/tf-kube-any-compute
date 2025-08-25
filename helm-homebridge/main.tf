# Create namespace
resource "kubernetes_namespace" "this" {
  metadata {
    name   = var.namespace
    labels = local.common_labels
  }
}

# Helm release for Homebridge
resource "helm_release" "this" {
  name       = var.name
  repository = var.chart_repo
  chart      = var.chart_name
  version    = var.chart_version
  namespace  = kubernetes_namespace.this.metadata[0].name

  wait          = var.helm_wait
  wait_for_jobs = var.helm_wait_for_jobs
  timeout       = var.helm_timeout

  cleanup_on_fail  = var.helm_cleanup_on_fail
  disable_webhooks = var.helm_disable_webhooks
  skip_crds        = var.helm_skip_crds
  replace          = var.helm_replace
  force_update     = var.helm_force_update

  values = [
    templatefile("${path.module}/templates/homebridge-values.yaml.tpl", {
      namespace            = kubernetes_namespace.this.metadata[0].name
      storage_class        = var.storage_class
      persistent_disk_size = var.persistent_disk_size
      enable_persistence   = var.enable_persistence
      enable_host_network  = var.enable_host_network
      cpu_arch             = var.cpu_arch
      node_selector        = local.node_selector
      plugins              = local.plugins_json
      cpu_limit            = var.cpu_limit
      memory_limit         = var.memory_limit
      cpu_request          = var.cpu_request
      memory_request       = var.memory_request
    })
  ]

  depends_on = [
    kubernetes_namespace.this,
    kubernetes_persistent_volume_claim.data_storage
  ]
}

# Wait for deployment to be ready
resource "null_resource" "wait_for_deployment" {
  count = var.helm_wait ? 0 : 1

  provisioner "local-exec" {
    command = <<-EOT
      timeout ${var.deployment_wait_timeout} bash -c '
        while ! kubectl get deployment ${var.name} -n ${var.namespace} >/dev/null 2>&1; do
          echo "Waiting for deployment ${var.name} to be created..."
          sleep 5
        done
        kubectl wait --for=condition=available --timeout=${var.deployment_wait_timeout}s deployment/${var.name} -n ${var.namespace}
      '
    EOT
  }

  depends_on = [helm_release.this]
}
