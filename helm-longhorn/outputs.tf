output "namespace" {
  description = "Namespace where Longhorn is deployed"
  value       = kubernetes_namespace.this.metadata[0].name
}

output "helm_release_name" {
  description = "Name of the Helm release"
  value       = helm_release.this.name
}

output "helm_release_status" {
  description = "Status of the Helm release"
  value       = helm_release.this.status
}

output "storage_class_name" {
  description = "Name of the Longhorn storage class"
  value       = "longhorn"
}
