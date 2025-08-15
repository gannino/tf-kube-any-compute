output "namespace" {
  description = "Namespace where kube-state-metrics is deployed"
  value       = kubernetes_namespace.this.metadata[0].name
}

output "service_name" {
  description = "Service name for kube-state-metrics"
  value       = "${local.module_config.name}-kube-state-metrics"
}

output "service_port" {
  description = "Service port for kube-state-metrics"
  value       = 8080
}

output "metrics_endpoint" {
  description = "Metrics endpoint for kube-state-metrics"
  value       = "http://${local.module_config.name}-kube-state-metrics.${kubernetes_namespace.this.metadata[0].name}.svc.cluster.local:8080/metrics"
}

output "helm_release_name" {
  description = "Helm release name"
  value       = helm_release.this.name
}

output "helm_release_status" {
  description = "Helm release status"
  value       = helm_release.this.status
}
