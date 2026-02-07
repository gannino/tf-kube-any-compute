output "namespace" {
  description = "KubeVirt namespace"
  value       = kubernetes_namespace.this.metadata[0].name
}

output "status" {
  description = "KubeVirt deployment status"
  value       = "deployed"
  depends_on  = [kubectl_manifest.kubevirt_cr]
}
