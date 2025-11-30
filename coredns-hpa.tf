# CoreDNS HorizontalPodAutoscaler to prevent scaling to 0 replicas
resource "kubernetes_horizontal_pod_autoscaler_v2" "coredns" {
  count = var.enable_coredns_hpa ? 1 : 0

  metadata {
    name      = "coredns-hpa"
    namespace = "kube-system"
  }

  spec {
    min_replicas = var.coredns_min_replicas
    max_replicas = var.coredns_max_replicas

    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = "coredns"
    }

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = var.coredns_cpu_target
        }
      }
    }

    metric {
      type = "Resource"
      resource {
        name = "memory"
        target {
          type                = "Utilization"
          average_utilization = var.coredns_memory_target
        }
      }
    }

    behavior {
      scale_down {
        stabilization_window_seconds = 300
        select_policy                = "Min"
        policy {
          type           = "Percent"
          value          = 50
          period_seconds = 60
        }
      }
      scale_up {
        stabilization_window_seconds = 60
        select_policy                = "Max"
        policy {
          type           = "Percent"
          value          = 100
          period_seconds = 30
        }
      }
    }
  }
}
