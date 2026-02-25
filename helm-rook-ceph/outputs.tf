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

output "service_host" {
  description = "Rook-Ceph service hostname for service discovery (format: name.namespace.svc.cluster.local)"
  value       = "${helm_release.this.name}.${kubernetes_namespace.this.metadata[0].name}.svc.cluster.local"
}

output "storage_class_rbd" {
  description = "RBD storage class name (when enabled)"
  value       = "ceph-rbd"
}

output "storage_class_cephfs" {
  description = "CephFS storage class name (when enabled)"
  value       = "ceph-cephfs"
}
