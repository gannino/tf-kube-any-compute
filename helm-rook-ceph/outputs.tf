output "namespace" {
  description = "Namespace where Rook Ceph is deployed"
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

output "chart_version" {
  description = "Deployed chart version"
  value       = helm_release.this.metadata.version
}
