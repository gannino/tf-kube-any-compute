# ============================================================================
# HELM-HOME-ASSISTANT MODULE - OPEN-SOURCE HOME AUTOMATION PLATFORM
# ============================================================================

# Create Home Assistant namespace
resource "kubernetes_namespace" "this" {
  metadata {
    annotations = merge(
      {
        name = local.module_config.namespace
      },
      local.common_labels
    )
    labels = local.common_labels
    name   = local.module_config.namespace
  }
}

# Deploy Home Assistant
resource "kubernetes_deployment" "this" {
  wait_for_rollout = false

  timeouts {
    create = "10m"
    update = "10m"
  }

  metadata {
    name      = local.module_config.name
    namespace = kubernetes_namespace.this.metadata[0].name
    labels    = local.common_labels
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = local.module_config.name
      }
    }

    template {
      metadata {
        labels = merge(local.common_labels, {
          app = local.module_config.name
        })
      }

      spec {
        node_selector = local.node_selector

        security_context {
          fs_group = var.nfs_fs_group
        }

        container {
          name  = "home-assistant"
          image = "homeassistant/home-assistant:${var.image_version}"

          port {
            container_port = 8123
            name           = "http"
          }

          env {
            name  = "TZ"
            value = var.timezone
          }

          volume_mount {
            name       = "http-config"
            mount_path = "/config/configuration.yaml"
            sub_path   = "configuration.yaml"
            read_only  = true
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
              name       = "home-assistant-config"
              mount_path = "/config"
            }
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 8123
            }
            initial_delay_seconds = 120
            period_seconds        = 30
            timeout_seconds       = 10
            failure_threshold     = 5
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 8123
            }
            initial_delay_seconds = 60
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 5
          }

          startup_probe {
            http_get {
              path = "/"
              port = 8123
            }
            initial_delay_seconds = 0
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 60
          }

          dynamic "security_context" {
            for_each = var.enable_privileged ? [1] : []
            content {
              privileged = true
            }
          }
        }

        dynamic "volume" {
          for_each = var.enable_persistence ? [1] : []
          content {
            name = "home-assistant-config"
            persistent_volume_claim {
              claim_name = kubernetes_persistent_volume_claim.data_storage[0].metadata[0].name
            }
          }
        }

        volume {
          name = "http-config"
          config_map {
            name = kubernetes_config_map.http_config.metadata[0].name
          }
        }

        host_network = var.enable_host_network
        dns_policy   = var.enable_host_network ? "ClusterFirstWithHostNet" : "ClusterFirst"
      }
    }
  }

  depends_on = [
    kubernetes_namespace.this,
    kubernetes_persistent_volume_claim.data_storage
  ]
}

# Service for Home Assistant
resource "kubernetes_service" "this" {
  metadata {
    name      = local.module_config.name
    namespace = kubernetes_namespace.this.metadata[0].name
    labels    = local.common_labels
  }

  spec {
    selector = {
      app = local.module_config.name
    }

    port {
      name        = "http"
      port        = 8123
      target_port = 8123
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }

  depends_on = [kubernetes_deployment.this]
}
