# ============================================================================
# NAMESPACE AND RELEASE OUTPUTS
# ============================================================================

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

# ============================================================================
# SERVICE DISCOVERY OUTPUTS
# ============================================================================

output "service_host" {
  description = "Rook-Ceph service hostname for service discovery (format: name.namespace.svc.cluster.local)"
  value       = "${helm_release.this.name}.${kubernetes_namespace.this.metadata[0].name}.svc.cluster.local"
}

# ============================================================================
# STORAGE CLASS OUTPUTS (Conditional on CephCluster)
# ============================================================================

output "storage_class_rbd" {
  description = "RBD (block) storage class name (when CephCluster is enabled)"
  value       = local.enable_ceph_cluster ? "ceph-rbd" : null
}

output "storage_class_cephfs" {
  description = "CephFS (file) storage class name (when CephCluster is enabled)"
  value       = local.enable_ceph_cluster ? "ceph-cephfs" : null
}

output "storage_classes" {
  description = "Map of available storage classes (when CephCluster is enabled)"
  value = local.enable_ceph_cluster ? {
    rbd    = "ceph-rbd"
    cephfs = "ceph-cephfs"
  } : {}
}

# ============================================================================
# DASHBOARD OUTPUTS (Conditional on Dashboard + Ingress)
# ============================================================================

output "dashboard_url" {
  description = "Ceph Dashboard URL (when dashboard and ingress are enabled)"
  value       = local.enable_dashboard && local.enable_ingress ? "https://${local.ingress_config.host}" : null
}

output "dashboard_secret_name" {
  description = "Name of Kubernetes secret containing dashboard password (when dashboard is enabled)"
  value       = local.enable_dashboard ? "rook-ceph-dashboard-password" : null
}

output "dashboard_secret_namespace" {
  description = "Namespace containing the dashboard password secret"
  value       = local.enable_dashboard ? kubernetes_namespace.this.metadata[0].name : null
}

# ============================================================================
# HEALTH AND DEBUG OUTPUTS
# ============================================================================

output "health_check_command" {
  description = "Command to check Ceph cluster health status"
  value       = local.enable_ceph_cluster ? "kubectl get cephcluster -n ${kubernetes_namespace.this.metadata[0].name}" : null
}

output "toolbox_command" {
  description = "Command to run the Ceph toolbox for advanced diagnostics"
  value       = local.enable_ceph_cluster ? "kubectl -n ${kubernetes_namespace.this.metadata[0].name} exec -it deploy/rook-ceph-tools -- ceph status" : null
}

# ============================================================================
# CONFIGURATION OUTPUTS (for debugging and reference)
# ============================================================================

output "ceph_cluster_enabled" {
  description = "Whether CephCluster resource is deployed"
  value       = local.enable_ceph_cluster
}

output "monitor_count" {
  description = "Number of Ceph monitors configured"
  value       = local.monitor_count
}

output "ceph_image_version" {
  description = "Ceph image version in use"
  value       = local.ceph_image_version
}

output "csi_kubelet_dir_path" {
  description = "CSI kubelet directory path configured"
  value       = local.csi_kubelet_dir_path
}
