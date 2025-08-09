# Gatekeeper CRDs Module Outputs

output "crds_ready" {
  value       = time_sleep.wait_for_crds.id
  description = "Indicates when Gatekeeper CRDs are ready for use"
}

output "crd_names" {
  value       = [for crd in kubernetes_manifest.gatekeeper_crds : crd.manifest.metadata.name]
  description = "Names of the deployed Gatekeeper CRDs"
}

output "crd_namespace" {
  value       = var.namespace
  description = "Namespace where Gatekeeper CRDs are deployed"
}
