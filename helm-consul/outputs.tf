# ============================================================================
# HELM-CONSUL MODULE - OUTPUTS
# ============================================================================

output "namespace" {
  description = "Kubernetes namespace where Consul is deployed"
  value       = kubernetes_namespace.this.metadata[0].name
}

output "name" {
  description = "Name of the Consul deployment"
  value       = local.module_config.name
}

output "url" {
  description = "Consul server hostname (without port)"
  value       = "${local.module_config.name}-server.${kubernetes_namespace.this.metadata[0].name}.svc.cluster.local"
}

output "uri" {
  description = "Consul server URI with port (hostname:port format)"
  value       = "${local.module_config.name}-server.${kubernetes_namespace.this.metadata[0].name}.svc.cluster.local:8500"
}

output "service_host" {
  description = "Consul service hostname (for connection strings)"
  value       = "${local.module_config.name}-server.${kubernetes_namespace.this.metadata[0].name}.svc.cluster.local"
}

output "service_port" {
  description = "Consul service port"
  value       = 8500
}

output "get_acl_secret" {
  description = "Command to retrieve the ACL bootstrap token from the Kubernetes secret"
  value       = "kubectl get secret -n ${kubernetes_namespace.this.metadata[0].name} ${local.consul_config.bootstrap_acl_token_secret_name} -o jsonpath='{.data.token}' | base64 -d && echo"
}

output "token" {
  description = "Consul bootstrap token"
  sensitive   = true
  value       = data.kubernetes_secret.token.data.token
}

output "helm_release" {
  description = "Helm release information"
  value = {
    name      = helm_release.this.name
    namespace = helm_release.this.namespace
    version   = helm_release.this.version
    status    = helm_release.this.status
  }
}

output "chart_version" {
  description = "Helm chart version deployed"
  value       = local.module_config.chart_version
}

output "resource_limits" {
  description = "Resource limits applied to Consul"
  value = {
    cpu    = local.module_config.cpu_limit
    memory = local.module_config.memory_limit
  }
}

output "resource_requests" {
  description = "Resource requests applied to Consul"
  value = {
    cpu    = local.module_config.cpu_request
    memory = local.module_config.memory_request
  }
}
