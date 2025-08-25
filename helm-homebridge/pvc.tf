# Persistent Volume Claim for Homebridge data
resource "kubernetes_persistent_volume_claim" "data_storage" {
  count = var.enable_persistence ? 1 : 0

  metadata {
    name      = "${var.name}-data"
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

  depends_on = [kubernetes_namespace.this]
}