# ============================================================================
# PERSISTENT VOLUME CLAIMS FOR OPENHAB DATA STORAGE
# ============================================================================

# Main data storage (userdata)
resource "kubernetes_persistent_volume_claim" "data_storage" {
  count = var.enable_persistence ? 1 : 0

  metadata {
    name      = local.pvc_configs.data.name
    namespace = kubernetes_namespace.this.metadata[0].name
    labels    = local.pvc_labels
  }

  spec {
    access_modes       = local.pvc_configs.data.access_modes
    storage_class_name = local.pvc_configs.data.storage_class

    resources {
      requests = {
        storage = local.pvc_configs.data.persistent_size
      }
    }
  }

  depends_on = [kubernetes_namespace.this]
}

# Addons storage
resource "kubernetes_persistent_volume_claim" "addons_storage" {
  count = var.enable_persistence ? 1 : 0

  metadata {
    name      = local.pvc_configs.addons.name
    namespace = kubernetes_namespace.this.metadata[0].name
    labels    = local.pvc_labels
  }

  spec {
    access_modes       = local.pvc_configs.addons.access_modes
    storage_class_name = local.pvc_configs.addons.storage_class

    resources {
      requests = {
        storage = local.pvc_configs.addons.persistent_size
      }
    }
  }

  depends_on = [kubernetes_namespace.this]
}

# Configuration storage
resource "kubernetes_persistent_volume_claim" "conf_storage" {
  count = var.enable_persistence ? 1 : 0

  metadata {
    name      = local.pvc_configs.conf.name
    namespace = kubernetes_namespace.this.metadata[0].name
    labels    = local.pvc_labels
  }

  spec {
    access_modes       = local.pvc_configs.conf.access_modes
    storage_class_name = local.pvc_configs.conf.storage_class

    resources {
      requests = {
        storage = local.pvc_configs.conf.persistent_size
      }
    }
  }

  depends_on = [kubernetes_namespace.this]
}