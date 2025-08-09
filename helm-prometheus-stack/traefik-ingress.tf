# data "kubernetes_service" "this" {
#   metadata {
#     name      = "${var.name}-server"
#     namespace = kubernetes_namespace.this.metadata[0].name
#   }
#   depends_on = [helm_release.this]
# }

# resource "kubernetes_ingress" "this" {
#   count = var.enable_prometheus_ingress == true ? 1 : 0
#   metadata {
#     name      = "${var.name}-ingress"
#     namespace = kubernetes_namespace.this.metadata[0].name
#     annotations = {
#       "kubernetes.io/ingress.class" = "traefik"
#     }
#   }

#   spec {
#     rule {
#       host = "prometheus.${var.domain_name}"
#       http {
#         path {
#           backend {
#             service_name = data.kubernetes_service.this.metadata[0].name
#             service_port = 80
#           }
#           #path = "/"
#         }
#       }
#     }
#   }
#   depends_on = [data.kubernetes_service.this]

# }


# data "kubernetes_service" "this_alertmanager" {
#   metadata {
#     name      = "${var.name}-alertmanager"
#     namespace = kubernetes_namespace.this.metadata[0].name
#   }
#   depends_on = [helm_release.this]
# }

# resource "kubernetes_ingress" "this_alertmanager" {
#   count = var.enable_alertmanager_ingress == true ? 1 : 0
#   metadata {
#     name      = "${var.name}-alertmanager-ingress"
#     namespace = kubernetes_namespace.this.metadata[0].name
#     annotations = {
#       "kubernetes.io/ingress.class" = "traefik"
#     }
#   }

#   spec {
#     rule {
#       host = "alertmanager.${var.domain_name}"
#       http {
#         path {
#           backend {
#             service_name = data.kubernetes_service.this_alertmanager.metadata[0].name
#             service_port = 80
#           }
#           #path = "/"
#         }
#       }
#     }
#   }
#   depends_on = [data.kubernetes_service.this_alertmanager]

#   #   timeouts {
#   #     create = "15m"
#   #     delete = "15m"
#   #   }

# }
