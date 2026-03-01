# ============================================================================
# S3 CSI DRIVER - Outputs
# ============================================================================

output "namespace" {
  description = "Namespace where S3 CSI driver is deployed"
  value       = kubernetes_namespace.this.metadata[0].name
}

output "storage_class_name" {
  description = "Name of the S3 CSI storage class"
  value       = local.storage_config.name
}

output "helm_release_name" {
  description = "Name of the Helm release"
  value       = helm_release.this.name
}

output "helm_release_status" {
  description = "Status of the Helm release"
  value       = helm_release.this.status
}

output "s3_endpoint" {
  description = "S3 endpoint used by the CSI driver"
  value       = local.s3_config.endpoint
  sensitive   = true
}

output "s3_bucket" {
  description = "S3 bucket used for storage"
  value       = local.s3_config.bucket
}

output "secret_name" {
  description = "Name of the Kubernetes Secret containing S3 credentials"
  value       = local.secret_config.name
  sensitive   = true
}

output "mounter" {
  description = "S3 mounter type (geesefs, rclone, s3backer)"
  value       = local.storage_config.mounter
}

output "service_discovery_host" {
  description = "Service hostname for external service discovery"
  value       = "${local.module_config.name}.${kubernetes_namespace.this.metadata[0].name}.svc.cluster.local"
}
