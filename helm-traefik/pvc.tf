resource "kubernetes_persistent_volume_claim" "traefik" {
  count = var.storage_class != "" ? 1 : 0

  metadata {
    name      = "${var.name}-certs"
    namespace = kubernetes_namespace.this.metadata[0].name
    annotations = {
      "helm.sh/resource-policy" = "keep"
    }
    labels = {
      "app.kubernetes.io/name"     = var.name
      "app.kubernetes.io/instance" = var.name
    }
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

  depends_on = [
    kubernetes_namespace.this
  ]
}
