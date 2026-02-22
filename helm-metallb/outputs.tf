# ============================================================================
# MetalLB Module Outputs
# ============================================================================

# Basic outputs
output "namespace" {
  description = "Kubernetes namespace where MetalLB is deployed"
  value       = kubernetes_namespace.this.metadata[0].name
}

output "name" {
  description = "Name of the MetalLB deployment"
  value       = helm_release.this.name
}

# Service discovery outputs
output "ip_address_pool" {
  description = "IP address pool configured for MetalLB LoadBalancer services"
  value       = local.module_config.address_pool
}

output "ip_address_pool_name" {
  description = "Name of the IPAddressPool resource"
  value       = kubectl_manifest.metallb_ip_pool.yaml_body_parsed
}

# Integration outputs
output "helm_release" {
  description = "Helm release name for MetalLB"
  value       = helm_release.this.name
}

output "chart_version" {
  description = "Helm chart version deployed"
  value       = local.module_config.chart_version
}

# Note: MetalLB doesn't expose a typical service_host as it provides
# LoadBalancer IP addresses to other services, not a web interface.
# Use the ip_address_pool output to configure services that need LoadBalancer IPs.
