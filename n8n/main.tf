# ============================================================================
# NATIVE TERRAFORM N8N MODULE - WORKFLOW AUTOMATION PLATFORM
# ============================================================================

# Create n8n namespace
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

# Generate encryption key for n8n
resource "random_password" "encryption_key" {
  length  = 32
  special = true
}

# n8n ConfigMap for configuration
resource "kubernetes_config_map" "n8n_config" {
  metadata {
    name      = "${var.name}-config"
    namespace = kubernetes_namespace.this.metadata[0].name
    labels    = local.common_labels
  }

  data = {
    "N8N_HOST"                            = local.n8n_host
    "N8N_PORT"                            = "5678"
    "N8N_PROTOCOL"                        = "http"
    "WEBHOOK_URL"                         = "https://${local.n8n_host}"
    "N8N_EDITOR_BASE_URL"                 = "https://${local.n8n_host}"
    "N8N_SECURE_COOKIE"                   = "false"
    "N8N_METRICS"                         = "true"
    "N8N_LOG_LEVEL"                       = "info"
    "N8N_LOG_OUTPUT"                      = "console"
    "N8N_USER_FOLDER"                     = "/home/node/.n8n"
    "N8N_DISABLE_PRODUCTION_MAIN_PROCESS" = "true"
    "EXECUTIONS_PROCESS"                  = "main"
    "EXECUTIONS_MODE"                     = "regular"
    "N8N_DIAGNOSTICS_ENABLED"             = "false"
    "N8N_VERSION_NOTIFICATIONS_ENABLED"   = "false"
    "N8N_TEMPLATES_ENABLED"               = "true"
    "N8N_ONBOARDING_FLOW_DISABLED"        = "true"
    "N8N_PERSONALIZATION_ENABLED"         = "false"
  }
}

# n8n Secret for sensitive configuration
resource "kubernetes_secret" "n8n_secret" {
  metadata {
    name      = "${var.name}-secret"
    namespace = kubernetes_namespace.this.metadata[0].name
    labels    = local.common_labels
  }

  type = "Opaque"
  data = {
    "N8N_ENCRYPTION_KEY" = base64encode(random_password.encryption_key.result)
  }
}

# n8n Deployment
resource "kubernetes_deployment" "n8n" {
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
        # Architecture-based node selection
        node_selector = var.disable_arch_scheduling ? {} : {
          "kubernetes.io/arch" = var.cpu_arch
        }

        security_context {
          run_as_non_root = true
          run_as_user     = 1000
          run_as_group    = 1000
          fs_group        = 1000
        }

        container {
          name  = "n8n"
          image = "n8nio/n8n:${local.n8n_version}"

          port {
            container_port = 5678
            name           = "http"
            protocol       = "TCP"
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.n8n_config.metadata[0].name
            }
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.n8n_secret.metadata[0].name
            }
          }

          # Resource limits
          resources {
            limits = {
              cpu    = var.cpu_limit
              memory = var.memory_limit
            }
            requests = {
              cpu    = var.cpu_request
              memory = var.memory_request
            }
          }

          # Health checks
          liveness_probe {
            http_get {
              path = "/healthz"
              port = 5678
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path = "/healthz"
              port = 5678
            }
            initial_delay_seconds = 10
            period_seconds        = 5
            timeout_seconds       = 3
            failure_threshold     = 3
          }

          # Persistent storage mount
          dynamic "volume_mount" {
            for_each = var.enable_persistence ? [1] : []
            content {
              name       = "n8n-data"
              mount_path = "/home/node/.n8n"
            }
          }

          security_context {
            allow_privilege_escalation = false
            read_only_root_filesystem  = false
            run_as_non_root            = true
            capabilities {
              drop = ["ALL"]
            }
          }
        }

        # Persistent volume
        dynamic "volume" {
          for_each = var.enable_persistence ? [1] : []
          content {
            name = "n8n-data"
            persistent_volume_claim {
              claim_name = kubernetes_persistent_volume_claim.data_storage[0].metadata[0].name
            }
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_namespace.this,
    kubernetes_config_map.n8n_config,
    kubernetes_secret.n8n_secret
  ]
}

# n8n Service
resource "kubernetes_service" "n8n" {
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
      port        = 5678
      target_port = 5678
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }

  depends_on = [kubernetes_deployment.n8n]
}
