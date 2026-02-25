resource "kubernetes_config_map" "plugin_installer" {
  count = length(local.enabled_plugins) > 0 ? 1 : 0

  metadata {
    name      = "${var.name}-plugin-installer"
    namespace = kubernetes_namespace.this.metadata[0].name
    labels    = local.common_labels
  }

  data = {
    "install-plugins.sh" = <<-EOT
      #!/bin/sh
      set -e
      PLUGIN_DIR="/headlamp/plugins"
      mkdir -p "$PLUGIN_DIR"

      # Install KubeVirt plugin from buttahtoast/headlamp-plugins (latest)
      if [ ! -d "$PLUGIN_DIR/kubevirt" ]; then
        echo "Downloading KubeVirt plugin..."
        cd "$PLUGIN_DIR"
        LATEST_URL=$(wget -qO- https://api.github.com/repos/buttahtoast/headlamp-plugins/releases/latest | grep 'browser_download_url.*kubevirt.*tar.gz' | cut -d '"' -f 4)
        wget -O kubevirt.tar.gz "$LATEST_URL"
        tar -xzf kubevirt.tar.gz
        rm kubevirt.tar.gz
        echo "KubeVirt plugin installed successfully"
      else
        echo "KubeVirt plugin already installed"
      fi

      # Install OpenCost plugin from main branch
      if [ ! -d "$PLUGIN_DIR/opencost" ]; then
        echo "Installing OpenCost plugin..."
        cd "$PLUGIN_DIR"
        wget -O plugins.tar.gz https://github.com/headlamp-k8s/plugins/archive/refs/heads/main.tar.gz
        tar -xzf plugins.tar.gz plugins-main/opencost --strip-components=1
        rm plugins.tar.gz
        echo "OpenCost plugin installed successfully"
      else
        echo "OpenCost plugin already installed"
      fi
    EOT
  }
}

resource "kubernetes_job" "plugin_installer" {
  count = length(local.enabled_plugins) > 0 ? 1 : 0

  metadata {
    name      = "${var.name}-plugin-installer"
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

        init_container {
          name    = "install-plugins"
          image   = "node:18-alpine"
          command = ["/bin/sh", "-c", "apk add --no-cache wget git && /scripts/install-plugins.sh"]

          volume_mount {
            name       = "plugin-dir"
            mount_path = "/headlamp/plugins"
          }

          volume_mount {
            name       = "installer-script"
            mount_path = "/scripts"
          }
        }

        container {
          name    = "complete"
          image   = "busybox:latest"
          command = ["sh", "-c", "echo 'Plugin installation complete'"]
        }

        volume {
          name = "plugin-dir"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.plugins[0].metadata[0].name
          }
        }

        volume {
          name = "installer-script"
          config_map {
            name         = kubernetes_config_map.plugin_installer[0].metadata[0].name
            default_mode = "0755"
          }
        }
      }
    }
  }

  wait_for_completion = false

  depends_on = [
    kubernetes_config_map.plugin_installer,
    kubernetes_persistent_volume_claim.plugins
  ]
}

resource "kubernetes_persistent_volume_claim" "plugins" {
  count = local.plugins_volume_enabled ? 1 : 0

  metadata {
    name      = "${var.name}-plugins"
    namespace = kubernetes_namespace.this.metadata[0].name
    labels    = local.common_labels
  }

  spec {
    access_modes       = ["ReadWriteMany"]
    storage_class_name = var.storage_class

    resources {
      requests = {
        storage = "1Gi"
      }
    }
  }
}
