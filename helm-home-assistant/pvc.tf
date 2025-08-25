# ============================================================================
# PERSISTENT VOLUME CLAIM FOR HOME ASSISTANT DATA STORAGE
# ============================================================================

resource "kubernetes_persistent_volume_claim" "data_storage" {
  count = var.enable_persistence ? 1 : 0

  metadata {
    name      = local.pvc_config.name
    namespace = kubernetes_namespace.this.metadata[0].name
    labels    = local.pvc_config.pvc_labels
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

  depends_on = [kubernetes_namespace.this]
}