resource "kubernetes_job_v1" "portainer_init" {
  count = var.portainer_admin_password != null && var.portainer_admin_password != "" ? 1 : 1

  metadata {
    name      = "${var.name}-init"
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

        container {
          name  = "portainer-init"
          image = "curlimages/curl:latest"

          command = ["/bin/sh", "-c"]
          args = [<<-EOT
            echo "Waiting for Portainer to be ready..."

            # Use internal cluster service endpoint
            PORTAINER_URL="http://${var.name}.${kubernetes_namespace.this.metadata[0].name}.svc.cluster.local:9000"

            # Wait for Portainer API to be ready
            until curl -f $PORTAINER_URL/api/status > /dev/null 2>&1; do
              echo "Waiting for Portainer API at $PORTAINER_URL..."
              sleep 10
            done

            # Check if already initialized
            STATUS=$(curl -s $PORTAINER_URL/api/status)
            if echo "$STATUS" | grep -q '"InitialSetup":false'; then
              echo "Portainer already initialized"
              exit 0
            fi

            # Initialize admin user
            echo "Initializing Portainer admin user..."
            ADMIN_PASSWORD=$(cat /etc/portainer-secret/admin-password)

            RESPONSE=$(curl -s -X POST $PORTAINER_URL/api/users/admin/init \
              -H "Content-Type: application/json" \
              -d "{\"Username\":\"admin\",\"Password\":\"$ADMIN_PASSWORD\"}")

            if echo "$RESPONSE" | grep -q '"Id"'; then
              echo "Admin user created successfully"
              exit 0
            else
              echo "Failed to create admin user: $RESPONSE"
              exit 1
            fi
          EOT
          ]

          volume_mount {
            name       = "portainer-secret"
            mount_path = "/etc/portainer-secret"
            read_only  = true
          }

          resources {
            limits = {
              cpu    = "100m"
              memory = "128Mi"
            }
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
          }
        }

        volume {
          name = "portainer-secret"
          secret {
            secret_name = kubernetes_secret.portainer_admin_password.metadata[0].name
          }
        }

        node_selector = !var.disable_arch_scheduling && var.cpu_arch != "" ? {
          "kubernetes.io/arch" = var.cpu_arch
        } : null
      }
    }

    backoff_limit = 3
  }

  wait_for_completion = false

  depends_on = [
    helm_release.this,
    kubernetes_secret.portainer_admin_password
  ]
}
