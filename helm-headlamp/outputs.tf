output "namespace" {
  description = "Namespace where Headlamp is deployed."
  value       = kubernetes_namespace.this.metadata[0].name
}

output "name" {
  description = "Name of the Headlamp Helm release."
  value       = helm_release.this.name
}

output "url" {
  description = "URL to access the Headlamp UI."
  value       = local.ingress_enabled ? "https://${var.name}.${var.domain_name}" : null
}

output "cluster_ip" {
  description = "Cluster IP of Headlamp service (for LoadBalancer or NodePort)."
  value       = "${var.name}.${kubernetes_namespace.this.metadata[0].name}.svc.cluster.local"
}

output "helm_status" {
  description = "Status information from Helm release."
  value = {
    name      = helm_release.this.name
    namespace = helm_release.this.namespace
    status    = helm_release.this.status
    version   = helm_release.this.version
  }
}

output "enabled_plugins" {
  description = "List of enabled Headlamp plugins."
  value       = local.enabled_plugins
}

output "storage_enabled" {
  description = "Whether persistent storage is enabled for Headlamp."
  value       = local.storage_config.enabled
}

output "storage_class" {
  description = "Storage class used for Headlamp persistence."
  value       = local.storage_config.storage_class
}

output "cpu_arch" {
  description = "CPU architecture used for Headlamp deployment."
  value       = var.cpu_arch
}

output "resource_limits" {
  description = "Resource limits applied to Headlamp containers."
  value = {
    cpu    = var.cpu_limit
    memory = var.memory_limit
  }
}

output "resource_requests" {
  description = "Resource requests applied to Headlamp containers."
  value = {
    cpu    = var.cpu_request
    memory = var.memory_request
  }
}

output "ingress_enabled" {
  description = "Whether ingress is enabled for Headlamp."
  value       = local.ingress_enabled
}

output "traefik_middleware_applied" {
  description = "Traefik middleware applied to Headlamp ingress."
  value       = var.traefik_middleware
}

output "service_account_name" {
  description = "Name of the Headlamp service account."
  value       = "headlamp-admin"
}

output "service_account_token_command" {
  description = "Command to generate a temporary service account token for Headlamp authentication."
  value       = "kubectl create token headlamp-admin -n ${kubernetes_namespace.this.metadata[0].name}"
}
