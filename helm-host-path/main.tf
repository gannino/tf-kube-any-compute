# Generate a consistent random suffix for the namespace
resource "kubernetes_namespace" "this" {
  metadata {
    annotations = merge(var.service_overrides.annotations, {
      name                           = local.module_config.namespace
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/component"  = local.module_config.component
      "app.kubernetes.io/name"       = local.module_config.name
      "app.kubernetes.io/part-of"    = "infrastructure"
    })
    labels = local.common_labels
    name   = local.module_config.namespace
  }
}

resource "helm_release" "this" {
  name       = local.helm_config.name
  chart      = local.helm_config.chart
  repository = local.helm_config.repository
  version    = local.helm_config.version
  namespace  = local.helm_config.namespace

  create_namespace = false

  values = [
    templatefile("${path.module}/values.yaml.tpl", local.template_values)
  ]

  # Allow Helm to replace existing resources
  disable_webhooks = var.helm_disable_webhooks
  # Skip CRDs to avoid conflicts with existing ones
  skip_crds = var.helm_skip_crds
  # Allow Helm to replace existing resources
  replace = var.helm_replace
  # Force resource updates if needed
  force_update = var.helm_force_update
  # Cleanup CRDs on deletion
  cleanup_on_fail = var.helm_cleanup_on_fail
  # Allow Helm to create new namespaces
  timeout = var.helm_timeout
  # Wait for the Helm release to be fully deployed
  wait = var.helm_wait
  # Wait for the Helm release to be fully deploye
  wait_for_jobs = var.helm_wait_for_jobs

  depends_on = [
    kubernetes_namespace.this
  ]
}

# ResourceQuota limits overall resource usage *in a namespace*.
# It controls the total amount of storage requested by PersistentVolumeClaims (PVCs)
# and the maximum number of PVCs allowed at any time.
resource "kubernetes_resource_quota" "hostpath_quota" {
  metadata {
    name      = "hostpath-storage-quota"
    namespace = local.helm_config.namespace
    labels    = local.common_labels
  }

  spec {
    hard = {
      # Limits the total amount of requested storage for all PVCs combined in the namespace.
      # For example, 50Gi means the sum of all PVC requests cannot exceed 50 GiB.
      "requests.storage" = local.limit_range_config.hostpath_max_storage

      # Limits how many PVCs can exist simultaneously in this namespace.
      "persistentvolumeclaims" = "10"
    }
  }

  depends_on = [
    helm_release.this
  ]
}

# LimitRange enforces size limits on individual PVCs in the namespace.
# It can also set default requests so users don’t have to specify size manually.
resource "kubernetes_limit_range" "hostpath_pvc_limit" {
  metadata {
    name      = "hostpath-pvc-limit"
    namespace = local.helm_config.namespace
    labels    = local.common_labels
  }

  spec {
    limit {
      # Applies limits to PersistentVolumeClaim resource types
      type = "PersistentVolumeClaim"

      max = {
        # Maximum allowed storage size per PVC.
        # This prevents any single PVC from reserving too much space.
        storage = local.limit_range_config.pvc_max_storage
      }

      default_request = {
        # Default storage request size when user doesn't specify.
        storage = local.limit_range_config.pvc_min_storage
      }
    }
  }

  depends_on = [
    helm_release.this
  ]
}

# output "storage_classes" {
#   value = {
#     default = try(kubernetes_storage_class.this[0].metadata[0].name, null)
#   }
# }