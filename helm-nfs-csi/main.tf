# Generate a consistent random suffix for the namespace
resource "kubernetes_namespace" "this" {
  metadata {
    annotations = local.common_labels
    labels      = local.common_labels
    name        = local.module_config.namespace
  }
}

# Improved storage class with better configuration
resource "kubernetes_storage_class" "this" {
  count = local.storage_config.let_helm_create_storage_class ? 0 : 1
  metadata {
    name = "nfs-csi"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = tostring(local.storage_config.set_as_default_storage_class)
    }
    labels = merge(local.storage_class_labels, {
      "performance-tier" = "standard"
    })
  }

  # Use the correct provisioner name for NFS CSI driver
  storage_provisioner = "cluster.local/${local.module_config.name}-nfs-subdir-external-provisioner" # Correct provisioner for nfs-subdir-external-provisioner

  parameters = {
    server = local.storage_config.nfs_server
    share  = local.storage_config.nfs_path

    archiveOnDelete = "true"
    # Optional: Add subdirectory creation
    # subDir = "k8s-volumes"

    # Optional: Set permissions for created directories
    # onDelete = "retain"  # or "delete"
  }

  # Optimized mount options for better performance and reliability
  mount_options = [
    # NFS version - use v4.1 for better performance if supported
    "vers=4",

    # Performance tuning
    "rsize=131072", # 128K read size for better throughput
    "wsize=131072", # 128K write size for better throughput
    "hard",         # Hard mount (recommended for data integrity)

    # Caching and performance
    "noatime",    # Don't update access times (better performance)
    "nodiratime", # Don't update directory access times
    # "sync",              # Synchronous writes for data safety

    # Timeouts and retries
    "timeo=${var.nfs_timeout_default}",   # Configurable timeout in deciseconds
    "retrans=${var.nfs_retrans_default}", # Configurable number of retries
  ]

  # Volume expansion capability
  allow_volume_expansion = true

  # Retain volumes when PVC is deleted (safer default)
  reclaim_policy = "Retain"

  # Immediate binding for NFS (no topology constraints)
  volume_binding_mode = "Immediate"
}

# Optional: Create a high-performance storage class variant
resource "kubernetes_storage_class" "nfs_fast" {
  count = local.storage_config.create_fast_storage_class ? 1 : 0

  metadata {
    name = "nfs-csi-fast"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "false"
    }
    labels = merge(local.storage_class_labels, {
      "performance-tier" = "fast"
    })
  }

  storage_provisioner = "cluster.local/${local.module_config.name}-nfs-subdir-external-provisioner" # Correct provisioner for nfs-subdir-external-provisioner

  parameters = {
    server          = local.storage_config.nfs_server
    share           = local.storage_config.nfs_path
    archiveOnDelete = "true"
  }

  # Optimized for performance over safety
  mount_options = [
    "vers=4.1",
    "rsize=1048576",
    "wsize=1048576",
    "hard",
    "noatime",
    "nodiratime",
    "async",                         # Async writes for better performance (less safe)
    "timeo=${var.nfs_timeout_fast}", # Configurable shorter timeout for faster failover
    "retrans=${var.nfs_retrans_fast}",
  ]

  allow_volume_expansion = true
  reclaim_policy         = "Delete" # Auto-cleanup for temporary volumes
  volume_binding_mode    = "Immediate"
}

# Optional: Create a safety-focused storage class
resource "kubernetes_storage_class" "nfs_safe" {
  count = local.storage_config.create_safe_storage_class ? 1 : 0

  metadata {
    name = "nfs-csi-safe"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "false"
    }
    labels = merge(local.storage_class_labels, {
      "performance-tier" = "safe"
    })
  }

  storage_provisioner = "cluster.local/${local.module_config.name}-nfs-subdir-external-provisioner" # Correct provisioner for nfs-subdir-external-provisioner

  parameters = {
    server          = local.storage_config.nfs_server
    share           = local.storage_config.nfs_path
    archiveOnDelete = "true"
  }

  # Optimized for data safety and consistency
  mount_options = [
    "vers=4.1",
    "rsize=65536", # Smaller chunks for stability
    "wsize=65536",
    "hard",
    "sync",                            # Synchronous writes for data safety
    "timeo=${var.nfs_timeout_safe}",   # Configurable longer timeout for stability
    "retrans=${var.nfs_retrans_safe}", # Configurable more retries
  ]

  allow_volume_expansion = true
  reclaim_policy         = "Retain"
  volume_binding_mode    = "Immediate"
}

resource "helm_release" "this" {
  name       = local.module_config.name
  chart      = local.module_config.chart_name
  repository = local.module_config.chart_repo
  version    = local.module_config.chart_version
  namespace  = kubernetes_namespace.this.metadata[0].name

  create_namespace = false
  values = [
    templatefile("${path.module}/templates/nfs-csi-values.yaml.tpl", local.template_values)
  ]

  # Helm deployment settings
  disable_webhooks = local.helm_config.disable_webhooks
  skip_crds        = local.helm_config.skip_crds
  replace          = local.helm_config.replace
  force_update     = local.helm_config.force_update
  cleanup_on_fail  = local.helm_config.cleanup_on_fail
  timeout          = local.helm_config.timeout
  wait             = local.helm_config.wait
  wait_for_jobs    = local.helm_config.wait_for_jobs

  depends_on = [
    kubernetes_namespace.this,
    kubernetes_storage_class.this,
    kubernetes_limit_range.namespace_limits
  ]
}

data "kubernetes_service" "this" {
  metadata {
    name      = "nfs-csi-frontend"
    namespace = kubernetes_namespace.this.metadata[0].name
  }
  depends_on = [helm_release.this]
}