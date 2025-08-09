output "namespace" {
  description = "Namespace where Promtail is deployed"
  value       = kubernetes_namespace.this.metadata[0].name
}

output "release_name" {
  description = "Name of the Helm release"
  value       = helm_release.this.name
}

output "release_namespace" {
  description = "Namespace of the Promtail deployment"
  value       = helm_release.this.namespace
}

output "release_version" {
  description = "Version of the deployed Helm chart"
  value       = helm_release.this.version
}

output "release_status" {
  description = "Status of the Helm release"
  value       = helm_release.this.status
}

output "app_version" {
  description = "App version of the deployed Promtail (if available)"
  value       = try(helm_release.this.metadata[0].app_version, "unknown")
}

output "chart_metadata" {
  description = "Metadata of the deployed chart"
  value = {
    chart     = helm_release.this.chart
    version   = helm_release.this.version
    namespace = helm_release.this.namespace
    name      = helm_release.this.name
    status    = helm_release.this.status
  }
}

output "service_account_name" {
  description = "Name of the created ServiceAccount"
  value       = kubernetes_service_account.this.metadata[0].name
}

output "cluster_role_name" {
  description = "Name of the created ClusterRole"
  value       = kubernetes_cluster_role.this.metadata[0].name
}

output "loki_endpoint" {
  description = "Configured Loki endpoint"
  value       = var.loki_url
  sensitive   = true
}

output "monitoring_labels" {
  description = "Labels used for monitoring and service discovery"
  value       = local.common_labels
}