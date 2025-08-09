output "namespace" {
  description = "Namespace where NFS CSI is deployed"
  value       = kubernetes_namespace.this.metadata[0].name
}

output "storage_classes" {
  description = "Created storage classes"
  value = {
    default = try(kubernetes_storage_class.this[0].metadata[0].name, null)
    fast    = try(kubernetes_storage_class.nfs_fast[0].metadata[0].name, null)
    safe    = try(kubernetes_storage_class.nfs_safe[0].metadata[0].name, null)
  }
}

output "helm_release_name" {
  description = "Name of the Helm release"
  value       = helm_release.this.name
}

output "helm_release_status" {
  description = "Status of the Helm release"
  value       = helm_release.this.status
}

output "service_name" {
  description = "Name of the NFS CSI frontend service"
  value       = data.kubernetes_service.this.metadata[0].name
}

output "nfs_server" {
  description = "NFS server used by the CSI driver"
  value       = local.storage_config.nfs_server
}

output "nfs_path" {
  description = "NFS path used by the CSI driver"
  value       = local.storage_config.nfs_path
}
