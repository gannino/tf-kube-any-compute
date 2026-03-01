# ============================================================================
# CEPH MONITOR DNS SERVICE
# ============================================================================

# Headless service for Ceph monitor DNS-based discovery
# This service enables monitors to discover each other via DNS SRV records
# Required for monitor quorum formation in distributed deployments
resource "kubernetes_service" "ceph_mon_dns" {
  count = var.enable_ceph_cluster ? 1 : 0

  metadata {
    name      = "ceph-mon"
    namespace = kubernetes_namespace.this.metadata[0].name
    labels = {
      app                            = "rook-ceph-mon"
      "app.kubernetes.io/component"  = "monitor"
      "app.kubernetes.io/managed-by" = "rook-ceph-operator"
      "app.kubernetes.io/part-of"    = "infrastructure"
      "rook_cluster"                 = kubernetes_namespace.this.metadata[0].name
    }
  }

  spec {
    type                        = "ClusterIP"
    cluster_ip                  = "None"
    publish_not_ready_addresses = true
    session_affinity            = "None"

    port {
      name        = "tcp-msgr1"
      port        = 6789
      protocol    = "TCP"
      target_port = 6789
    }

    port {
      name        = "tcp-msgr2"
      port        = 3300
      protocol    = "TCP"
      target_port = 3300
    }

    selector = {
      app = "rook-ceph-mon"
    }
  }

  # Wait for Helm release to create monitors first
  depends_on = [
    kubectl_manifest.ceph_cluster
  ]
}
