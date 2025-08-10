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

# Use the dedicated CRDs chart instead of manual installation
resource "helm_release" "prometheus_crds" {
  name       = local.helm_config.name
  chart      = local.helm_config.chart
  repository = local.helm_config.repository
  version    = local.helm_config.version
  namespace  = kubernetes_namespace.this.metadata[0].name

  values = [local.helm_config.values_template]

  # CRDs should be installed first and rarely updated
  lifecycle {
    ignore_changes = all
  }

  # Allow Helm to replace existing resources
  disable_webhooks = local.helm_options.disable_webhooks
  # Skip CRDs to avoid conflicts with existing ones
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

  depends_on = [kubernetes_namespace.this]
}

resource "null_resource" "wait_for_crds" {
  depends_on = [helm_release.prometheus_crds]

  provisioner "local-exec" {
    command     = <<EOT
      echo "Waiting for Prometheus CRDs to be registered..."

      # List of critical CRDs to wait for
      CRDS=(${join(" ", [for crd in local.crd_config.critical_crds : "\"${crd}\""])})

      for crd in "$${CRDS[@]}"; do
        echo "Waiting for CRD: $crd"
        for i in {1..${local.crd_config.wait_timeout_minutes * 20}}; do
          if kubectl get crd "$crd" >/dev/null 2>&1; then
            echo "CRD $crd is ready"
            break
          fi
          echo "Waiting for CRD $crd... ($i/${local.crd_config.wait_timeout_minutes * 20})"
          sleep 3
        done

        if ! kubectl get crd "$crd" >/dev/null 2>&1; then
          echo "Error: CRD $crd was not registered after waiting."
          exit 1
        fi
      done

      echo "All Prometheus CRDs are ready!"
    EOT
    interpreter = ["/bin/bash", "-c"]
  }
}
