# ============================================================================
# STALE DATA CLEANUP - Prevents keyring mismatch on redeployment
# ============================================================================
# Rook Ceph stores data on host paths (e.g., /opt/rook/mon-a). If a cluster
# is destroyed and redeployed without cleaning this data, the new deployment
# will fail with "cephx server client.admin: unexpected key" errors because
# the old mon database has different credentials.
#
# This resource cleans up stale data BEFORE the CephCluster is created.
# Uses a parallel Job approach that completes and doesn't block scheduling.

locals {
  # Get node names for cleanup jobs
  cleanup_node_names = data.kubernetes_nodes.this.nodes[*].metadata[0].name
}

# Get cluster nodes for cleanup
data "kubernetes_nodes" "this" {}

# Pre-deployment cleanup - creates a Job per node that runs cleanup and exits
# This avoids the DaemonSet scheduling conflict issue
resource "kubernetes_job" "cleanup_stale_data" {
  for_each = var.enable_ceph_cluster && var.cleanup_stale_data_on_deploy ? toset(local.cleanup_node_names) : []

  metadata {
    name      = "${var.name}-cleanup-${substr(each.value, -6, 6)}"
    namespace = kubernetes_namespace.this.metadata[0].name
    labels = {
      app         = "${var.name}-cleanup"
      managed-by  = "terraform"
      component   = "cleanup"
      cleanup-for = "rook-ceph"
    }
  }

  spec {
    # Don't use TTL - let Terraform manage job lifecycle
    # ttl_seconds_after_finished causes jobs to be deleted, then Terraform recreates them on every apply
    backoff_limit = 1
    completions   = 1
    parallelism   = 1

    template {
      metadata {
        labels = {
          app         = "${var.name}-cleanup"
          cleanup-for = "rook-ceph"
        }
      }

      spec {
        # Run on specific node
        node_selector = {
          "kubernetes.io/hostname" = each.value
        }

        # Tolerate all taints to reach all nodes
        toleration {
          operator = "Exists"
        }

        # Don't restart on failure - just fail and let TTL clean up
        restart_policy = "Never"

        container {
          name  = "cleanup"
          image = var.cleanup_image

          command = ["/bin/sh", "-c"]
          args = [
            <<-EOT
              set -e
              echo "=== Rook-Ceph Stale Data Cleanup ==="
              echo "Node: $(hostname)"
              echo "Timestamp: $(date)"
              echo ""

              ROOK_BASE="/host${var.rook_data_dir_host_path}"

              # Clean up stale mon data (causes keyring mismatch)
              if [ -d "$ROOK_BASE" ]; then
                echo "Found existing Rook data directory:"
                ls -la "$ROOK_BASE" 2>/dev/null || true
                echo ""

                # Remove stale mon directories (mon-a, mon-b, etc.)
                for mon_dir in "$ROOK_BASE"/mon-*; do
                  if [ -d "$mon_dir" ]; then
                    echo "Removing stale mon data: $mon_dir"
                    rm -rf "$mon_dir"
                  fi
                done

                # Remove namespace-specific stale data
                if [ -d "$ROOK_BASE/${var.namespace}" ]; then
                  echo "Removing stale namespace data: $ROOK_BASE/${var.namespace}"
                  rm -rf "$ROOK_BASE/${var.namespace}"
                fi

                # Remove any cluster-specific stale data
                for cluster_dir in "$ROOK_BASE"/*-rook-ceph*; do
                  if [ -d "$cluster_dir" ]; then
                    echo "Removing stale cluster data: $cluster_dir"
                    rm -rf "$cluster_dir"
                  fi
                done

                echo ""
                echo "Cleanup complete. Remaining files:"
                ls -la "$ROOK_BASE" 2>/dev/null || echo "  (directory empty or removed)"
              else
                echo "No existing Rook data directory found at $ROOK_BASE"
              fi

              echo ""
              echo "=== Cleanup finished successfully ==="
            EOT
          ]

          # Mount host filesystem to access Rook data
          volume_mount {
            name       = "host-opt"
            mount_path = "/host/opt"
          }

          security_context {
            privileged = true
          }

          resources {
            limits = {
              cpu    = var.cleanup_cpu_limit
              memory = var.cleanup_memory_limit
            }
            requests = {
              cpu    = var.cleanup_cpu_request
              memory = var.cleanup_memory_request
            }
          }
        }

        volume {
          name = "host-opt"
          host_path {
            path = "/opt"
            type = "DirectoryOrCreate"
          }
        }
      }
    }
  }

  # Wait for job to complete
  wait_for_completion = true
  timeouts {
    create = "5m"
    update = "5m"
  }
}

# Wait for all cleanup jobs to complete before allowing CephCluster creation
resource "null_resource" "wait_for_cleanup" {
  count = var.enable_ceph_cluster && var.cleanup_stale_data_on_deploy ? 1 : 0

  depends_on = [kubernetes_job.cleanup_stale_data]

  provisioner "local-exec" {
    command = <<-EOT
      echo "=== Verifying cleanup jobs completed ==="

      # Show logs from all cleanup jobs
      for pod in $(kubectl get pods -n ${kubernetes_namespace.this.metadata[0].name} \
        -l app=${var.name}-cleanup,component=cleanup \
        -o jsonpath='{.items[*].metadata.name}' 2>/dev/null); do
        echo "--- Logs from $pod ---"
        kubectl logs -n ${kubernetes_namespace.this.metadata[0].name} "$pod" 2>/dev/null || true
        echo ""
      done

      echo "=== Stale data cleanup completed on all nodes ==="
    EOT
  }

  triggers = {
    # Trigger on node or namespace changes (not timestamp)
    nodes     = join(",", local.cleanup_node_names)
    namespace = kubernetes_namespace.this.metadata[0].name
  }
}
