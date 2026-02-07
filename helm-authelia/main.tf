resource "kubernetes_namespace" "this" {
  metadata {
    annotations = merge(local.common_labels, {
      name = local.module_config.namespace
    })
    labels = local.common_labels
    name   = local.module_config.namespace
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      metadata[0].annotations["kubectl.kubernetes.io/last-applied-configuration"],
      metadata[0].labels
    ]
  }

  timeouts {
    delete = var.cleanup_timeout
  }
}

# Create Kubernetes secret for Authelia secrets
resource "kubernetes_secret" "authelia_secrets" {
  metadata {
    name      = "${var.name}-secrets"
    namespace = kubernetes_namespace.this.metadata[0].name
    labels    = local.common_labels
  }

  type = "Opaque"
  data = {
    JWT_TOKEN              = local.jwt_secret
    SESSION_SECRET         = local.session_secret
    STORAGE_ENCRYPTION_KEY = local.storage_encryption_key
  }
}

# Create dedicated PVC for Authelia storage
resource "kubernetes_persistent_volume_claim" "authelia" {
  metadata {
    name      = "${var.name}-storage"
    namespace = kubernetes_namespace.this.metadata[0].name
    labels    = local.common_labels
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = var.storage_class
    resources {
      requests = {
        storage = var.persistent_disk_size
      }
    }
  }
}

resource "helm_release" "this" {
  name       = local.helm_config.name
  chart      = local.helm_config.chart
  repository = local.helm_config.repository
  version    = local.helm_config.version
  namespace  = kubernetes_namespace.this.metadata[0].name

  values = [
    templatefile("${path.module}/templates/values.yaml.tpl", local.template_values)
  ]

  disable_webhooks = local.helm_config.disable_webhooks
  skip_crds        = local.helm_config.skip_crds
  replace          = local.helm_config.replace
  force_update     = local.helm_config.force_update
  cleanup_on_fail  = local.helm_config.cleanup_on_fail
  timeout          = local.helm_config.timeout
  wait             = local.helm_config.wait
  wait_for_jobs    = local.helm_config.wait_for_jobs

  depends_on = [
    kubernetes_namespace.this,
    kubernetes_secret.authelia_secrets,
    kubernetes_persistent_volume_claim.authelia
  ]
}

# Force cleanup resource for stuck namespaces
resource "null_resource" "force_namespace_cleanup" {
  count = var.force_namespace_cleanup ? 1 : 0

  triggers = {
    namespace       = var.namespace
    cleanup_timeout = var.cleanup_timeout
    kubeconfig_path = local.kubeconfig_path
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<EOT
      # Set KUBECONFIG from trigger
      export KUBECONFIG="$${KUBECONFIG_PATH}"

      # Wait for namespace to enter terminating state
      echo "Waiting for namespace to enter terminating phase..."
      timeout 300 bash -c "until kubectl get namespace $$NAMESPACE -o jsonpath='{.status.phase}' | grep -q 'Terminating'; do sleep 2; done"

      # Force remove namespace finalizers
      echo "Force removing namespace finalizers..."
      kubectl get namespace $$NAMESPACE -o json | \
        jq 'del(.spec.finalizers)' | \
        kubectl replace --raw "/api/v1/namespaces/$$NAMESPACE/finalize" -f - --timeout=$$CLEANUP_TIMEOUT

      # Verify namespace is deleted
      echo "Verifying namespace deletion..."
      timeout 300 bash -c "until ! kubectl get namespace $$NAMESPACE 2>/dev/null; do sleep 2; done"
      echo "Namespace $$NAMESPACE successfully cleaned up."
    EOT

    environment = {
      KUBECONFIG_PATH = self.triggers.kubeconfig_path
      NAMESPACE       = self.triggers.namespace
      CLEANUP_TIMEOUT = self.triggers.cleanup_timeout
    }
  }

  depends_on = [
    helm_release.this
  ]
}
