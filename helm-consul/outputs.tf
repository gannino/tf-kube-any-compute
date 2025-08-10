output "url" {
  value       = "${local.module_config.name}-server.${kubernetes_namespace.this.metadata[0].name}.svc.cluster.local"
  description = "Consul server hostname (without port)"
}

output "uri" {
  value       = "${local.module_config.name}-server.${kubernetes_namespace.this.metadata[0].name}.svc.cluster.local:8500"
  description = "Consul server URI with port (hostname:port format)"
}
# Command to retrieve the ACL bootstrap token from Kubernetes secret
output "get_acl_secret" {
  value       = "kubectl get secret -n ${kubernetes_namespace.this.metadata[0].name} ${local.consul_config.bootstrap_acl_token_secret_name} -o jsonpath='{.data.token}' | base64 -d && echo"
  description = "Command to retrieve the ACL bootstrap token from the Kubernetes secret."
}
output "token" {
  sensitive = true
  value     = data.kubernetes_secret.token.data.token
}
