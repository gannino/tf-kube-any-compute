output "admin_password" {
  sensitive = true
  value     = local.admin_password
}

output "grafana_service_name" {
  value = var.name
}

output "namespace" {
  value = kubernetes_namespace.this.metadata[0].name
}

output "service_url" {
  value = "http://${var.name}.${kubernetes_namespace.this.metadata[0].name}.svc.cluster.local"
}

output "ingress_url" {
  value = "https://grafana.${var.domain_name}"
}

output "admin_user" {
  value = var.grafana_admin_user
}
