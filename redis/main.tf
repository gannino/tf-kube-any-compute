# ============================================================================
# Redis Deployment Module - Native Kubernetes Redis (Alpine)
# ============================================================================

resource "kubernetes_namespace" "this" {
  metadata {
    annotations = merge(local.common_labels, {
      name = var.namespace
    })
    labels = local.common_labels
    name   = var.namespace
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ConfigMap for Redis configuration
resource "kubernetes_config_map" "redis_config" {
  metadata {
    name      = "${var.name}-config"
    namespace = kubernetes_namespace.this.metadata[0].name
    labels    = local.common_labels
  }

  data = {
    "redis.conf" = <<-EOF
      # Redis configuration for Alpine
      bind 0.0.0.0
      port 6379
      maxmemory-policy allkeys-lru
      save 900 1
      save 300 10
      save 60 10000
      appendonly yes
      appendfsync everysec
      dir /data
    EOF
  }
}

# PVC for Redis data
resource "kubernetes_persistent_volume_claim" "redis_data" {
  count = var.enable_persistence ? 1 : 0

  metadata {
    name      = "${var.name}-data"
    namespace = kubernetes_namespace.this.metadata[0].name
    labels    = local.common_labels
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.storage_size
      }
    }
    storage_class_name = var.storage_class != "" ? var.storage_class : null
  }
}

# Redis Deployment
resource "kubernetes_deployment" "redis" {
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
        node_selector = var.disable_arch_scheduling || var.cpu_arch == "" ? {} : {
          "kubernetes.io/arch" = var.cpu_arch
        }

        container {
          name  = "redis"
          image = "redis:7.2-alpine"

          port {
            container_port = 6379
            name           = "redis"
          }

          # Use Redis Alpine-compatible command
          command = ["redis-server"]
          args    = ["/etc/redis/redis.conf"]

          # Resource limits
          resources {
            limits = {
              cpu    = local.resources_config.limits.cpu
              memory = local.resources_config.limits.memory
            }
            requests = {
              cpu    = local.resources_config.requests.cpu
              memory = local.resources_config.requests.memory
            }
          }

          # Health checks
          liveness_probe {
            exec {
              command = ["redis-cli", "ping"]
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            exec {
              command = ["redis-cli", "ping"]
            }
            initial_delay_seconds = 5
            period_seconds        = 5
            timeout_seconds       = 1
            failure_threshold     = 3
          }

          # Volume mounts
          volume_mount {
            name       = "config"
            mount_path = "/etc/redis"
            read_only  = true
          }

          dynamic "volume_mount" {
            for_each = var.enable_persistence ? [1] : []
            content {
              name       = "data"
              mount_path = "/data"
            }
          }

          # Security context
          security_context {
            run_as_user                = 999
            run_as_non_root            = true
            allow_privilege_escalation = false
            read_only_root_filesystem  = false
          }
        }

        # Volumes
        volume {
          name = "config"
          config_map {
            name = kubernetes_config_map.redis_config.metadata[0].name
          }
        }

        dynamic "volume" {
          for_each = var.enable_persistence ? [1] : []
          content {
            name = "data"
            persistent_volume_claim {
              claim_name = kubernetes_persistent_volume_claim.redis_data[0].metadata[0].name
            }
          }
        }

        # Pod security context
        security_context {
          fs_group = 999
        }
      }
    }
  }

  depends_on = [kubernetes_namespace.this]
}

# Redis Service
resource "kubernetes_service" "redis" {
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
      name        = "redis"
      port        = 6379
      target_port = 6379
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }

  depends_on = [kubernetes_deployment.redis]
}

# Optional ServiceMonitor for Prometheus integration
resource "kubernetes_manifest" "servicemonitor" {
  count = var.enable_servicemonitor ? 1 : 0

  manifest = yamlencode({
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "${var.name}-redis"
      namespace = kubernetes_namespace.this.metadata[0].name
      labels = {
        "app.kubernetes.io/name"       = "redis"
        "app.kubernetes.io/managed-by" = "terraform"
        "app.kubernetes.io/component"  = "caching"
      }
    }
    spec = {
      selector = {
        matchLabels = local.common_labels
      }
      endpoints = [
        {
          port     = "redis"
          interval = "30s"
          path     = "/metrics"
        }
      ]
    }
  })

  depends_on = [kubernetes_service.redis]
}
