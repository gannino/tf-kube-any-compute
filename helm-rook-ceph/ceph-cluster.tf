resource "kubectl_manifest" "ceph_cluster" {
  count = var.enable_ceph_cluster ? 1 : 0

  yaml_body = templatefile("${path.module}/templates/ceph-cluster.yaml.tpl", {
    namespace          = kubernetes_namespace.this.metadata[0].name
    ceph_image_version = local.ceph_image_version
    monitor_count      = local.monitor_count
    enable_dashboard   = local.enable_dashboard
    dashboard_ssl      = local.dashboard_ssl
    osd_per_node       = local.osd_per_node
    osd_data_size      = local.osd_data_size
    storage_class      = local.storage_class_name
  })

  depends_on = [
    helm_release.this,
    kubernetes_daemonset.storage_prep,
    null_resource.wait_for_cleanup,
    kubernetes_secret.dashboard_cert
  ]
}
