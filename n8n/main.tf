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

# Generate shared authentication token for task runners
# This token is used to authenticate communication between n8n and task runners
resource "random_password" "task_runner_auth_token" {
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

  data = merge(
    {
      "N8N_HOST"                            = local.n8n_host
      "N8N_PORT"                            = "5678"
      "N8N_PROTOCOL"                        = "http"
      "WEBHOOK_URL"                         = "https://${local.n8n_host}/webhook"
      "N8N_EDITOR_BASE_URL"                 = "https://${local.n8n_host}"
      "N8N_SECURE_COOKIE"                   = "false"
      "N8N_METRICS"                         = "true"
      "N8N_LOG_LEVEL"                       = "info"
      "N8N_LOG_OUTPUT"                      = "console"
      "N8N_USER_FOLDER"                     = "/home/node/.n8n"
      "N8N_DISABLE_PRODUCTION_MAIN_PROCESS" = "true"
      "EXECUTIONS_MODE"                     = "regular"
      "N8N_DIAGNOSTICS_ENABLED"             = "false"
      "N8N_VERSION_NOTIFICATIONS_ENABLED"   = "false"
      "N8N_TEMPLATES_ENABLED"               = "true"
      "N8N_ONBOARDING_FLOW_DISABLED"        = "true"
      "N8N_PERSONALIZATION_ENABLED"         = "false"

      # Network binding - force IPv4 to fix health check connection issues
      # n8n binds to :: (IPv6) by default but Kubernetes probes use IPv4
      "N8N_LISTEN_ADDRESS" = "0.0.0.0"
    },
    # Conditionally include task runner configuration
    # When disabled: n8n runs without task broker (internal/default mode)
    # When enabled: n8n runs task broker for external task runners
    local.task_runner_config
  )
  # removed the below as deprecated.
  #     "EXECUTIONS_PROCESS"                  = "main"

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
    "N8N_ENCRYPTION_KEY"     = base64encode(random_password.encryption_key.result)
    "N8N_RUNNERS_AUTH_TOKEN" = base64encode(random_password.task_runner_auth_token.result)
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

  wait_for_rollout = false

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

    # Task broker port for external task runners (conditional)
    dynamic "port" {
      for_each = var.enable_task_runners ? [1] : []
      content {
        name        = "task-broker"
        port        = 5679
        target_port = 5679
        protocol    = "TCP"
      }
    }

    type = "ClusterIP"
  }

  depends_on = [kubernetes_deployment.n8n]
}

# ============================================================================
# TASK RUNNERS DEPLOYMENT - Separate deployment for code execution
# ============================================================================
# Task runners execute JavaScript and Python code from n8n Code nodes
# Running as separate deployment enables independent scaling and fault isolation
# Task runners connect to n8n's task broker via Kubernetes Service (port 5679)

resource "kubernetes_deployment" "task_runners" {
  count = local.task_runner_enabled ? 1 : 0

  metadata {
    name      = local.task_runner_name
    namespace = kubernetes_namespace.this.metadata[0].name
    labels = merge(local.common_labels, {
      "app.kubernetes.io/component" = "task-runners"
    })
  }

  spec {
    replicas = var.task_runner_replicas

    selector {
      match_labels = {
        app = local.task_runner_name
      }
    }

    template {
      metadata {
        labels = merge(local.common_labels, {
          app = local.task_runner_name
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
          name  = "task-runners"
          image = "n8nio/runners:${local.task_runner_version}"

          # Task runners only expose health check port (5680)
          # They connect to n8n's task broker on port 5679 (not listening)
          port {
            container_port = 5680
            name           = "health-check"
            protocol       = "TCP"
          }

          # Environment variables for task runners
          env {
            name = "N8N_RUNNERS_AUTH_TOKEN"

            value_from {
              secret_key_ref {
                name = kubernetes_secret.n8n_secret.metadata[0].name
                key  = "N8N_RUNNERS_AUTH_TOKEN"
              }
            }
          }

          # Task runner connection configuration
          # Task runners connect TO n8n's task broker via Kubernetes Service
          env {
            name  = "N8N_RUNNERS_TASK_BROKER_URI"
            value = "http://${var.name}.${var.namespace}.svc.cluster.local:5679"
          }

          # Auto-shutdown timeout (0 = disabled, task runners stay alive)
          env {
            name  = "N8N_RUNNERS_AUTO_SHUTDOWN_TIMEOUT"
            value = "0"
          }

          # Resource limits for task runners
          resources {
            limits = {
              cpu    = var.task_runner_cpu_limit
              memory = var.task_runner_memory_limit
            }
            requests = {
              cpu    = var.task_runner_cpu_request
              memory = var.task_runner_memory_request
            }
          }

          # Health checks for task runners
          # Task runners expose health check server on port 5680
          # Using TCP probe instead of HTTP to avoid 404 errors
          liveness_probe {
            tcp_socket {
              port = 5680
            }
            initial_delay_seconds = 10
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            tcp_socket {
              port = 5680
            }
            initial_delay_seconds = 5
            period_seconds        = 5
            timeout_seconds       = 3
            failure_threshold     = 3
          }

          security_context {
            allow_privilege_escalation = false
            run_as_non_root            = true
            capabilities {
              drop = ["ALL"]
            }
          }
        }
      }
    }
  }

  depends_on = [kubernetes_namespace.this]
}

# Task runners service - health check endpoint and service discovery
# Note: Task runners connect TO n8n's task broker (outbound), not the other way
# This service is for health checks, monitoring, and potential future features
resource "kubernetes_service" "task_runners" {
  count = local.task_runner_enabled ? 1 : 0

  metadata {
    name      = local.task_runner_name
    namespace = kubernetes_namespace.this.metadata[0].name
    labels = merge(local.common_labels, {
      "app.kubernetes.io/component" = "task-runners"
    })
  }

  spec {
    selector = {
      app = local.task_runner_name
    }

    port {
      name        = "health-check"
      port        = 5680
      target_port = 5680
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }

  depends_on = [kubernetes_deployment.task_runners]
}
