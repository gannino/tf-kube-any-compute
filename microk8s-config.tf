# MicroK8s-specific configuration
locals {
  # Auto-detect or use provided architecture
  # cpu_arch = var.cpu_arch != "" ? var.cpu_arch : "amd64"

  # MicroK8s storage class mapping
  storage_class = var.use_hostpath_storage ? "hostpath" : "nfs-csi"

  # Resource limits for constrained environments
  microk8s_limits = var.enable_microk8s_mode ? {
    cpu_limit    = "200m"
    memory_limit = "256Mi"
    replicas     = 1
    } : {
    cpu_limit    = "500m"
    memory_limit = "512Mi"
    replicas     = 2
  }
}
