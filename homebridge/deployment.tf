# ============================================================================
# NATIVE KUBERNETES DEPLOYMENT FOR HOMEBRIDGE
# ============================================================================

resource "kubernetes_deployment" "this" {
  wait_for_rollout = false

  timeouts {
    create = "10m"
    update = "10m"
  }

  metadata {
    name      = var.name
    namespace = kubernetes_namespace.this.metadata[0].name
    labels    = local.common_labels
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = var.name
      }
    }

    template {
      metadata {
        labels = merge(local.common_labels, {
          app = var.name
        })
      }

      spec {
        node_selector = local.node_selector

        security_context {
          run_as_user  = 0
          run_as_group = 0
          fs_group     = var.nfs_fs_group
        }

        container {
          name  = "homebridge"
          image = "homebridge/homebridge:${var.image_version}"

          port {
            container_port = 8581
            name           = "http"
          }

          env {
            name  = "HOMEBRIDGE_CONFIG_UI"
            value = "1"
          }

          env {
            name  = "HOMEBRIDGE_CONFIG_UI_PORT"
            value = "8581"
          }

          env {
            name  = "PUID"
            value = "1000"
          }

          env {
            name  = "PGID"
            value = "1000"
          }

          env {
            name  = "TZ"
            value = "UTC"
          }

          env {
            name  = "HOMEBRIDGE_INSECURE"
            value = "1"
          }

          env {
            name  = "HOMEBRIDGE_CONFIG_UI_THEME"
            value = "auto"
          }

          resources {
            requests = {
              cpu    = var.cpu_request
              memory = var.memory_request
            }
            limits = {
              cpu    = var.cpu_limit
              memory = var.memory_limit
            }
          }

          dynamic "volume_mount" {
            for_each = var.enable_persistence ? [1] : []
            content {
              name       = "homebridge-data"
              mount_path = "/homebridge"
            }
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 8581
            }
            initial_delay_seconds = 120
            period_seconds        = 30
            timeout_seconds       = 10
            failure_threshold     = 5
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 8581
            }
            initial_delay_seconds = 60
            period_seconds        = 15
            timeout_seconds       = 5
            failure_threshold     = 5
          }

          startup_probe {
            tcp_socket {
              port = 8581
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 60
          }
        }

        dynamic "volume" {
          for_each = var.enable_persistence ? [1] : []
          content {
            name = "homebridge-data"
            persistent_volume_claim {
              claim_name = kubernetes_persistent_volume_claim.data_storage[0].metadata[0].name
            }
          }
        }

        host_network = var.enable_host_network
      }
    }
  }

  depends_on = [
    kubernetes_namespace.this
  ]
}

# Service for Homebridge
resource "kubernetes_service" "this" {
  metadata {
    name      = var.name
    namespace = kubernetes_namespace.this.metadata[0].name
    labels    = local.common_labels
  }

  spec {
    selector = {
      app = var.name
    }

    port {
      name        = "http"
      port        = 8581
      target_port = 8581
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }

  depends_on = [kubernetes_deployment.this]
}
