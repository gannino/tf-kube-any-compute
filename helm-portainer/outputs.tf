output "portainer" {
  value = {
    namespace      = kubernetes_namespace.this.metadata[0].name
    service_name   = data.kubernetes_service.this.metadata[0].name
    url            = var.enable_portainer_ingress_route ? "https://portainer.${var.domain_name}" : null
    helm_release   = helm_release.this.name
    admin_username = "admin"
    admin_password = local.admin_password
  }
}
