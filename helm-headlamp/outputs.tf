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
  description = "Command to generate a temporary service account token for Headlamp authentication. This is the RECOMMENDED authentication method due to OIDC token refresh limitations (see README)."
  value       = "kubectl create token headlamp-admin -n ${kubernetes_namespace.this.metadata[0].name} --duration=24h"
}

output "authentication_methods" {
  description = "Available authentication methods for Headlamp and their status."
  value = {
    oidc = {
      enabled     = try(var.oidc_config.enabled, false)
      status      = "Known limitation: Token refresh fails after ~2 minutes causing 'lost connection to cluster' errors. See: https://github.com/kubernetes-sigs/headlamp/issues/4481"
      recommended = false
      description = "Use for initial login, but expect disconnections after 2 minutes"
    }
    service_account_token = {
      enabled     = true
      status      = "Fully supported"
      recommended = true
      description = "Generate token using the 'service_account_token_command' output - stable authentication without token refresh issues"
    }
  }
}

output "prometheus_service_address" {
  description = "Prometheus service address for Headlamp UI (format: namespace/service:port). Configure this in Headlamp Settings > Prometheus."
  value = var.prometheus_enabled && var.prometheus_url != "" ? (
    length(regexall("^https?://([^.]+)\\.([^.]+)\\.svc[^:]*:(\\d+)$", var.prometheus_url)) > 0 ? (
      join("/", [regex("^https?://([^.]+)\\.([^.]+)\\.svc[^:]*:(\\d+)$", var.prometheus_url)[1], "${regex("^https?://([^.]+)\\.([^.]+)\\.svc[^:]*:(\\d+)$", var.prometheus_url)[0]}:${regex("^https?://([^.]+)\\.([^.]+)\\.svc[^:]*:(\\d+)$", var.prometheus_url)[2]}"])
    ) : var.prometheus_url
  ) : "Prometheus not enabled"
}
