# ============================================================================
# HELM-METRICS-SERVER MODULE OUTPUTS
# ============================================================================

output "namespace" {
  description = "Kubernetes namespace where metrics-server is deployed"
  value       = kubernetes_namespace.this.metadata[0].name
}

output "helm_release_name" {
  description = "Name of the Helm release"
  value       = helm_release.this.name
}

output "helm_release_status" {
  description = "Status of the Helm release"
  value       = helm_release.this.status
}

output "service_name" {
  description = "Name of the metrics-server service"
  value       = var.name
}

output "service_port" {
  description = "Port of the metrics-server service"
  value       = var.service_port
}

output "chart_version" {
  description = "Version of the metrics-server Helm chart"
  value       = var.chart_version
}
