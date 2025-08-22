# ============================================================================
# KUBERNETES JOB FOR NODE-RED PALETTE INSTALLATION
# ============================================================================

resource "kubernetes_job_v1" "palette_installer" {
  count = var.enable_persistence && length(var.palette_packages) > 0 ? 1 : 0

  wait_for_completion = false

  timeouts {
    create = "2m"
    delete = "5m"
  }

  metadata {
    name      = "${var.name}-palette-installer"
    namespace = kubernetes_namespace.this.metadata[0].name
    labels    = local.common_labels
  }

  spec {
    template {
      metadata {
        labels = local.common_labels
      }
      spec {
        restart_policy = "OnFailure"

        # Node selector for architecture
        node_selector = var.disable_arch_scheduling ? {} : {
          "kubernetes.io/arch" = var.cpu_arch
        }

        container {
          name              = "palette-installer"
          image             = "nodered/node-red:latest"
          image_pull_policy = "IfNotPresent"
          working_dir       = "/data"

          command = ["/bin/sh", "/scripts/install-palette.sh"]

          resources {
            limits = {
              cpu    = "1000m"
              memory = "1Gi"
            }
            requests = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }

          volume_mount {
            name       = "data"
            mount_path = "/data"
          }

          volume_mount {
            name       = "script"
            mount_path = "/scripts"
            read_only  = true
          }
        }

        volume {
          name = "data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.data_storage[0].metadata[0].name
          }
        }

        volume {
          name = "script"
          config_map {
            name         = kubernetes_config_map.palette_installer_script[0].metadata[0].name
            default_mode = "0755"
          }
        }
      }
    }

    backoff_limit              = 3
    ttl_seconds_after_finished = 300 # Clean up after 5 minutes
  }

  depends_on = [
    helm_release.this,
    kubernetes_persistent_volume_claim.data_storage
  ]
}
