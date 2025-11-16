# ============================================================================
# NATIVE KUBERNETES DEPLOYMENT FOR OPENHAB
# ============================================================================

resource "kubernetes_deployment" "this" {
  wait_for_rollout = var.deployment_wait_timeout > 0

  timeouts {
    create = var.deployment_wait_timeout > 0 ? "${var.deployment_wait_timeout}s" : "5m"
    update = var.deployment_wait_timeout > 0 ? "${var.deployment_wait_timeout}s" : "5m"
  }

  metadata {
    name      = local.module_config.name
    namespace = kubernetes_namespace.this.metadata[0].name
    labels    = local.common_labels
  }

  spec {
    replicas                  = 1
    progress_deadline_seconds = var.deployment_wait_timeout > 0 ? var.deployment_wait_timeout : 600

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

        # Init container to set up permissions quickly
        init_container {
          name    = "setup-permissions"
          image   = "busybox:1.35"
          command = ["/bin/sh", "-c", "mkdir -p /openhab/userdata /openhab/conf /openhab/addons && chmod 777 /openhab /openhab/userdata /openhab/conf /openhab/addons && echo 'Permissions set'"]

          dynamic "volume_mount" {
            for_each = var.enable_persistence ? [1] : []
            content {
              name       = "openhab-data"
              mount_path = "/openhab/userdata"
            }
          }

          dynamic "volume_mount" {
            for_each = var.enable_persistence ? [1] : []
            content {
              name       = "openhab-addons"
              mount_path = "/openhab/addons"
            }
          }

          dynamic "volume_mount" {
            for_each = var.enable_persistence ? [1] : []
            content {
              name       = "openhab-conf"
              mount_path = "/openhab/conf"
            }
          }
        }

        security_context {
          fs_group = var.nfs_fs_group
        }

        container {
          name  = "openhab"
          image = var.cpu_arch == "arm64" ? "openhab/openhab:latest-alpine" : "openhab/openhab:latest"

          port {
            container_port = 8080
            name           = "http"
          }

          port {
            container_port = 8443
            name           = "https"
          }

          port {
            container_port = 8101
            name           = "karaf"
          }

          env {
            name  = "OPENHAB_HTTP_PORT"
            value = "8080"
          }

          env {
            name  = "OPENHAB_HTTPS_PORT"
            value = "8443"
          }

          env {
            name  = "EXTRA_JAVA_OPTS"
            value = "-Duser.timezone=UTC -XX:+TieredCompilation -XX:TieredStopAtLevel=1"
          }

          env {
            name  = "USER_ID"
            value = tostring(var.nfs_fs_group)
          }

          env {
            name  = "GROUP_ID"
            value = tostring(var.nfs_fs_group)
          }

          env {
            name  = "DISABLE_CHOWN"
            value = "true"
          }

          env {
            name  = "OPENHAB_BACKUPS"
            value = "/openhab/userdata/backup"
          }

          env {
            name  = "KARAF_OPTS"
            value = "-Xms256m -Xmx512m"
          }

          dynamic "env" {
            for_each = var.enable_karaf_console ? [1] : []
            content {
              name  = "KARAF_CONSOLE_ENABLED"
              value = "true"
            }
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
              name       = "openhab-data"
              mount_path = "/openhab/userdata"
            }
          }

          dynamic "volume_mount" {
            for_each = var.enable_persistence ? [1] : []
            content {
              name       = "openhab-addons"
              mount_path = "/openhab/addons"
            }
          }

          dynamic "volume_mount" {
            for_each = var.enable_persistence ? [1] : []
            content {
              name       = "openhab-conf"
              mount_path = "/openhab/conf"
            }
          }

          liveness_probe {
            tcp_socket {
              port = 8080
            }
            initial_delay_seconds = 180
            period_seconds        = 30
            timeout_seconds       = 10
            failure_threshold     = 5
          }

          readiness_probe {
            tcp_socket {
              port = 8080
            }
            initial_delay_seconds = 120
            period_seconds        = 20
            timeout_seconds       = 10
            failure_threshold     = 10
          }

          startup_probe {
            tcp_socket {
              port = 8080
            }
            initial_delay_seconds = 60
            period_seconds        = 20
            timeout_seconds       = 10
            failure_threshold     = 90
          }
        }

        dynamic "volume" {
          for_each = var.enable_persistence ? [1] : []
          content {
            name = "openhab-data"
            persistent_volume_claim {
              claim_name = kubernetes_persistent_volume_claim.data_storage[0].metadata[0].name
            }
          }
        }

        dynamic "volume" {
          for_each = var.enable_persistence ? [1] : []
          content {
            name = "openhab-addons"
            persistent_volume_claim {
              claim_name = kubernetes_persistent_volume_claim.addons_storage[0].metadata[0].name
            }
          }
        }

        dynamic "volume" {
          for_each = var.enable_persistence ? [1] : []
          content {
            name = "openhab-conf"
            persistent_volume_claim {
              claim_name = kubernetes_persistent_volume_claim.conf_storage[0].metadata[0].name
            }
          }
        }

        host_network = var.enable_host_network
      }
    }
  }

  depends_on = [
    kubernetes_namespace.this,
    kubernetes_persistent_volume_claim.data_storage,
    kubernetes_persistent_volume_claim.addons_storage,
    kubernetes_persistent_volume_claim.conf_storage
  ]
}

# Service for openHAB
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
      port        = 8080
      target_port = 8080
      protocol    = "TCP"
    }

    port {
      name        = "https"
      port        = 8443
      target_port = 8443
      protocol    = "TCP"
    }

    dynamic "port" {
      for_each = var.enable_karaf_console ? [1] : []
      content {
        name        = "karaf"
        port        = 8101
        target_port = 8101
        protocol    = "TCP"
      }
    }

    type = "ClusterIP"
  }

  depends_on = [kubernetes_deployment.this]
}
