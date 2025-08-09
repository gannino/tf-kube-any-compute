# Standard outputs for Prometheus Stack module

# Service connectivity outputs
output "prometheus_service_name" {
  description = "Prometheus service name"
  value       = local.service_names.prometheus
}

output "alertmanager_service_name" {
  description = "AlertManager service name"
  value       = local.service_names.alertmanager
}

output "namespace" {
  description = "Prometheus stack namespace"
  value       = kubernetes_namespace.this.metadata[0].name
}

output "prometheus_url" {
  description = "Internal service URL for Prometheus (cluster-local)"
  value       = "http://${local.service_names.prometheus}.${kubernetes_namespace.this.metadata[0].name}.svc.cluster.local:${local.ports.prometheus}"
}

output "alertmanager_url" {
  description = "Internal service URL for AlertManager (cluster-local)"
  value       = "http://${local.service_names.alertmanager}.${kubernetes_namespace.this.metadata[0].name}.svc.cluster.local:${local.ports.alertmanager}"
}

# External access outputs
output "prometheus_ingress_url" {
  description = "External ingress URL for Prometheus web UI"
  value       = var.enable_prometheus_ingress ? "https://${local.ingress_config.prometheus_host}" : "Not configured"
}

output "alertmanager_ingress_url" {
  description = "External ingress URL for AlertManager web UI"
  value       = var.enable_alertmanager_ingress ? "https://${local.ingress_config.alertmanager_host}" : "Not configured"
}

# Authentication outputs
output "monitoring_admin_password" {
  description = "Admin password for Prometheus and AlertManager basic auth"
  value       = local.monitoring_password
  sensitive   = true
}

output "monitoring_admin_username" {
  description = "Admin username for Prometheus and AlertManager basic auth"
  value       = "admin"
}

# Configuration outputs
output "prometheus_port" {
  description = "Prometheus server port"
  value       = local.ports.prometheus
}

output "alertmanager_port" {
  description = "AlertManager server port"
  value       = local.ports.alertmanager
}

# Operational outputs
output "kubectl_commands" {
  description = "Useful kubectl commands for Prometheus stack operations"
  value = {
    get_pods_prometheus       = "kubectl get pods -n ${kubernetes_namespace.this.metadata[0].name} -l app.kubernetes.io/name=prometheus"
    get_pods_alertmanager     = "kubectl get pods -n ${kubernetes_namespace.this.metadata[0].name} -l app.kubernetes.io/name=alertmanager"
    get_logs_prometheus       = "kubectl logs -n ${kubernetes_namespace.this.metadata[0].name} -l app.kubernetes.io/name=prometheus -f"
    get_logs_alertmanager     = "kubectl logs -n ${kubernetes_namespace.this.metadata[0].name} -l app.kubernetes.io/name=alertmanager -f"
    port_forward_prometheus   = "kubectl port-forward -n ${kubernetes_namespace.this.metadata[0].name} svc/${local.service_names.prometheus} ${local.ports.prometheus}:${local.ports.prometheus}"
    port_forward_alertmanager = "kubectl port-forward -n ${kubernetes_namespace.this.metadata[0].name} svc/${local.service_names.alertmanager} ${local.ports.alertmanager}:${local.ports.alertmanager}"
  }
}

# Storage and resource outputs
output "prometheus_storage_class" {
  description = "Storage class used for Prometheus persistence"
  value       = local.module_config.prometheus_storage_class
}

output "prometheus_storage_size" {
  description = "Storage size allocated for Prometheus"
  value       = local.module_config.prometheus_storage_size
}

output "alertmanager_storage_class" {
  description = "Storage class used for AlertManager persistence"
  value       = local.module_config.alertmanager_storage_class
}

output "alertmanager_storage_size" {
  description = "Storage size allocated for AlertManager"
  value       = local.module_config.alertmanager_storage_size
}

# Deployment metadata
output "helm_release_name" {
  description = "Helm release name"
  value       = helm_release.this.name
}

output "helm_chart_version" {
  description = "Helm chart version deployed"
  value       = helm_release.this.version
}

output "helm_chart_name" {
  description = "Helm chart name"
  value       = local.helm_config.chart
}

output "common_labels" {
  description = "Common labels applied to all resources"
  value       = local.common_labels
}

# Environment-specific outputs
output "environment_config" {
  description = "Environment configuration summary"
  value = {
    cpu_arch                        = local.module_config.cpu_arch
    enable_prometheus_ingress       = local.module_config.enable_prometheus_ingress
    enable_alertmanager_ingress     = local.module_config.enable_alertmanager_ingress
    traefik_cert_resolver           = local.module_config.traefik_cert_resolver
    domain_name                     = local.module_config.domain_name
    prometheus_storage_configured   = local.module_config.prometheus_storage_class != ""
    alertmanager_storage_configured = local.module_config.alertmanager_storage_class != ""
  }
}