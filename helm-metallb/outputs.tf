# ============================================================================
# HELM-METALLB MODULE - OUTPUTS
# ============================================================================

output "namespace" {
  description = "MetalLB namespace"
  value       = kubernetes_namespace.this.metadata[0].name
}

output "helm_release_name" {
  description = "MetalLB Helm release name"
  value       = helm_release.this.name
}

output "helm_release_status" {
  description = "MetalLB Helm release status"
  value       = helm_release.this.status
}

output "address_pool" {
  description = "MetalLB IP address pool configuration"
  value       = local.module_config.address_pool
}

output "controller_replica_count" {
  description = "Number of MetalLB controller replicas"
  value       = local.module_config.controller_replica_count
}

output "speaker_replica_count" {
  description = "Number of MetalLB speaker replicas"
  value       = local.module_config.speaker_replica_count
}

output "load_balancer_class" {
  description = "MetalLB load balancer class"
  value       = "metallb"
}

output "module_config" {
  description = "Complete module configuration for debugging"
  value       = local.module_config
  sensitive   = false
}
