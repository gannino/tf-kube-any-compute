resource "kubernetes_persistent_volume_claim" "portainer" {
  metadata {
    name      = local.pvc_config.name
    namespace = kubernetes_namespace.this.metadata[0].name
    annotations = {
      "helm.sh/resource-policy" = "keep"
    }
    labels = local.pvc_config.pvc_labels
  }

  spec {
    access_modes       = local.pvc_config.access_modes
    storage_class_name = local.pvc_config.storage_class

    resources {
      requests = {
        storage = local.pvc_config.persistent_size
      }
    }
  }
}