resource "kubernetes_namespace" "this" {
  metadata {
    name = "${var.name}-system"
    labels = {
      "app.kubernetes.io/name"       = var.name
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}
