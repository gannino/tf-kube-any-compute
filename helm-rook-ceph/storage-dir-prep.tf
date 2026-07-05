# ============================================================================
# STORAGE DIRECTORY PREPARATION
# ============================================================================

# DaemonSet to create storage directories on all nodes before OSD creation
# This runs once per node to ensure /opt/local-path-provisioner/rook-storage exists for OSDs
resource "kubernetes_daemonset" "storage_prep" {
  count = var.enable_ceph_cluster ? 1 : 0

  metadata {
    name      = "${var.name}-storage-prep"
    namespace = kubernetes_namespace.this.metadata[0].name
    labels = {
      app        = "${var.name}-storage-prep"
      managed-by = "terraform"
      component  = "storage-orchestrator"
    }
  }

  spec {
    selector {
      match_labels = {
        app = "${var.name}-storage-prep"
      }
    }

    template {
      metadata {
        labels = {
          app = "${var.name}-storage-prep"
        }
      }

      spec {
        # Run on all nodes including control plane
        toleration {
          operator = "Exists"
        }

        # Init container to create directories with proper permissions
        container {
          name  = "prep-storage"
          image = var.cleanup_image

          command = ["/bin/sh", "-c"]
          args = [
            "set -e; STORAGE_DIR='${var.storage_prep_host_path}/${var.osd_storage_subdir}'; echo 'Checking Rook-Ceph storage directory...'; if [ ! -d \"$STORAGE_DIR\" ]; then echo \"Creating $STORAGE_DIR...\"; mkdir -p \"$STORAGE_DIR\"; chmod 777 \"$STORAGE_DIR\"; echo \"✓ Created $STORAGE_DIR\"; else echo \"✓ Directory $STORAGE_DIR already exists\"; fi; if [ -w \"$STORAGE_DIR\" ]; then echo '✓ Directory is writable, keeping pod alive'; echo 'Sleeping indefinitely to maintain DaemonSet pod...'; sleep infinity; else echo '✗ ERROR: Directory is not writable'; exit 1; fi"
          ]

          # Mount host filesystem to create directories
          volume_mount {
            name       = "rootfs"
            mount_path = var.storage_prep_host_path
          }

          security_context {
            privileged = true
          }

          resources {
            limits = {
              cpu    = var.storage_prep_cpu_limit
              memory = var.storage_prep_memory_limit
            }
            requests = {
              cpu    = var.storage_prep_cpu_request
              memory = var.storage_prep_memory_request
            }
          }
        }

        # DaemonSet requires Always restart policy
        # Script checks if directory exists and exits successfully if already done
        restart_policy = "Always"

        volume {
          name = "rootfs"
          host_path {
            path = var.storage_prep_host_path
            type = "DirectoryOrCreate"
          }
        }
      }
    }
  }

  # Ensure this runs before the CephCluster is created
  depends_on = [
    helm_release.this
  ]
}
