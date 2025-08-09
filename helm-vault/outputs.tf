# Standard outputs for HashiCorp Vault module

# Service connectivity outputs
output "service_name" {
  description = "Vault service name"
  value       = local.module_config.name
}

output "namespace" {
  description = "Vault namespace"
  value       = kubernetes_namespace.this.metadata[0].name
}

output "service_url" {
  description = "Internal service URL for Vault (cluster-local)"
  value       = "http://${local.module_config.name}.${kubernetes_namespace.this.metadata[0].name}.svc.cluster.local:${var.vault_port}"
}

output "vault_address" {
  description = "Vault server address (hostname:port format for client configuration)"
  value       = "${local.module_config.name}.${kubernetes_namespace.this.metadata[0].name}.svc.cluster.local:${var.vault_port}"
}

# External access outputs
output "ingress_url" {
  description = "External ingress URL for Vault web UI"
  value       = local.module_config.enable_ingress || local.module_config.enable_traefik_ingress ? "https://vault.${local.module_config.domain_name}" : "Not configured"
}

output "web_ui_url" {
  description = "Vault web UI URL"
  value       = local.module_config.enable_ingress || local.module_config.enable_traefik_ingress ? "https://vault.${local.module_config.domain_name}/ui" : "http://${local.module_config.name}.${kubernetes_namespace.this.metadata[0].name}.svc.cluster.local:${var.vault_port}/ui"
}

# Configuration outputs
output "vault_port" {
  description = "Vault server port"
  value       = var.vault_port
}

output "consul_backend_address" {
  description = "Consul backend address used by Vault"
  value       = var.consul_address
}

output "consul_port" {
  description = "Consul port used by Vault backend"
  value       = var.consul_port
}

# Health check configuration outputs
output "health_check_endpoint" {
  description = "Vault health check endpoint"
  value       = "/v1/sys/health?standbyok=true&sealedcode=200&uninitcode=200"
}

output "health_check_url" {
  description = "Full health check URL"
  value       = "http://${local.module_config.name}.${kubernetes_namespace.this.metadata[0].name}.svc.cluster.local:${var.vault_port}/v1/sys/health?standbyok=true&sealedcode=200&uninitcode=200"
}

# Operational outputs
output "kubectl_commands" {
  description = "Useful kubectl commands for Vault operations"
  value = {
    get_pods     = "kubectl get pods -n ${kubernetes_namespace.this.metadata[0].name} -l app.kubernetes.io/name=${local.module_config.name}"
    get_logs     = "kubectl logs -n ${kubernetes_namespace.this.metadata[0].name} -l app.kubernetes.io/name=${local.module_config.name} -f"
    port_forward = "kubectl port-forward -n ${kubernetes_namespace.this.metadata[0].name} svc/${local.module_config.name} ${var.vault_port}:${var.vault_port}"
    exec_vault   = "kubectl exec -n ${kubernetes_namespace.this.metadata[0].name} -it deploy/${local.module_config.name} -- vault"
    status       = "kubectl exec -n ${kubernetes_namespace.this.metadata[0].name} deploy/${local.module_config.name} -- vault status"
    get_secret   = "kubectl get secret -n ${kubernetes_namespace.this.metadata[0].name} ${local.module_config.name}-token -o jsonpath='{.data.root_token}' | base64 -d"
  }
}

# Storage and resource outputs
output "storage_class" {
  description = "Storage class used for Vault persistence"
  value       = var.storage_class
}

output "storage_size" {
  description = "Storage size allocated for Vault"
  value       = var.storage_size
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
  value       = local.helm_config.chart_name
}

output "common_labels" {
  description = "Common labels applied to all resources"
  value       = local.common_labels
}

# Environment-specific outputs
output "environment_config" {
  description = "Environment configuration summary"
  value = {
    cpu_arch                = var.cpu_arch
    vault_init_timeout      = var.vault_init_timeout
    vault_readiness_timeout = var.vault_readiness_timeout
    healthcheck_interval    = var.healthcheck_interval
    healthcheck_timeout     = var.healthcheck_timeout
    ingress_enabled         = local.module_config.enable_ingress
    traefik_ingress_enabled = local.module_config.enable_traefik_ingress
    ingress_selector        = local.ingress_selector
  }
}
