resource "kubernetes_namespace" "this" {
  metadata {
    name = "${var.name}-system"
    labels = {
      "app.kubernetes.io/name"       = var.name
      "app.kubernetes.io/instance"   = var.environment
      "app.kubernetes.io/version"    = var.chart_version
      "app.kubernetes.io/component"  = "metrics"
      "app.kubernetes.io/part-of"    = "tf-kube-any-compute"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}
