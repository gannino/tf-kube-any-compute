# ============================================================================
# NATIVE KUBERNETES DEPLOYMENT FOR OPENHAB
# ============================================================================



resource "kubernetes_deployment" "this" {
  wait_for_rollout = false

  timeouts {
    create = 300 > 0 ? "${300}s" : "5m"
    update = 300 > 0 ? "${300}s" : "5m"
  }

  metadata {
    name      = local.module_config.name
    namespace = kubernetes_namespace.this.metadata[0].name
    labels    = local.common_labels
  }

  spec {
    replicas                  = 1
    progress_deadline_seconds = 300 > 0 ? 300 : 600

    strategy {
      type = "Recreate"
    }

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

        # Init container to initialize userdata from template
        init_container {
          name    = "init-userdata"
          image   = var.cpu_arch == "arm64" ? "openhab/openhab:${var.image_version}-alpine" : "openhab/openhab:${var.image_version}"
          command = ["/bin/sh", "-c", "if [ ! -f /openhab/userdata/etc/version.properties ]; then cp -r /openhab/dist/userdata/* /openhab/userdata/ && echo 'Userdata initialized'; else echo 'Userdata exists'; fi && sed -i 's/#automation = /automation = rule/' /openhab/conf/services/addons.cfg && sed -i 's/#ui = /ui = main,basic/' /openhab/conf/services/addons.cfg && echo 'Addons config updated'"]

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
              name       = "openhab-conf"
              mount_path = "/openhab/conf"
            }
          }
        }

        security_context {
          fs_group               = var.nfs_fs_group
          fs_group_change_policy = "OnRootMismatch"
        }

        container {
          name  = "openhab"
          image = var.cpu_arch == "arm64" ? "openhab/openhab:${var.image_version}-alpine" : "openhab/openhab:${var.image_version}"

          port {
            container_port = 8080
            name           = "http"
          }



          port {
            container_port = 8101
            name           = "karaf"
          }

          env {
            name  = "OPENHAB_HOME"
            value = "/openhab"
          }

          env {
            name  = "OPENHAB_CONF"
            value = "/openhab/conf"
          }

          env {
            name  = "OPENHAB_RUNTIME"
            value = "/openhab/runtime"
          }

          env {
            name  = "OPENHAB_USERDATA"
            value = "/openhab/userdata"
          }

          env {
            name  = "OPENHAB_LOGDIR"
            value = "/openhab/userdata/logs"
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
            name  = "EXTRA_JAVA_OPTS"
            value = "-Xms256m -Xmx512m"
          }

          env {
            name  = "OPENHAB_HTTP_PORT"
            value = "8080"
          }

          env {
            name  = "OPENHAB_HTTPS_PORT"
            value = "8443"
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

          # Static PV mounts (single PVC with subpaths)
          dynamic "volume_mount" {
            for_each = false ? [1] : []
            content {
              name       = "openhab-static"
              mount_path = "/openhab/userdata"
              sub_path   = "userdata"
            }
          }

          dynamic "volume_mount" {
            for_each = false ? [1] : []
            content {
              name       = "openhab-static"
              mount_path = "/openhab/addons"
              sub_path   = "addons"
            }
          }

          dynamic "volume_mount" {
            for_each = false ? [1] : []
            content {
              name       = "openhab-static"
              mount_path = "/openhab/conf"
              sub_path   = "conf"
            }
          }

          # Dynamic PVC mounts (separate PVCs)
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
            failure_threshold     = 120
          }
        }

        # Static PV volume (single PVC)
        dynamic "volume" {
          for_each = false ? [1] : []
          content {
            name = "openhab-static"
            persistent_volume_claim {
              claim_name = kubernetes_persistent_volume_claim.static_pvc[0].metadata[0].name
            }
          }
        }

        # Dynamic PV volumes (separate PVCs)
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
    kubernetes_namespace.this
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
