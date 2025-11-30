resource "kubectl_manifest" "ceph_cluster" {
  count = var.enable_ceph_cluster ? 1 : 0

  yaml_body = <<-YAML
    apiVersion: ceph.rook.io/v1
    kind: CephCluster
    metadata:
      name: rook-ceph
      namespace: ${kubernetes_namespace.this.metadata[0].name}
    spec:
      cephVersion:
        image: quay.io/ceph/ceph:v18.2.4
        allowUnsupported: false
      dataDirHostPath: /opt/rook
      mon:
        count: 3
        allowMultiplePerNode: false
      mgr:
        count: 1
        modules:
        - name: pg_autoscaler
          enabled: true
      dashboard:
        enabled: ${var.enable_dashboard}
        ssl: false
      monitoring:
        enabled: true
      resources:
        mon:
          limits:
            cpu: "200m"
            memory: "256Mi"
          requests:
            cpu: "100m"
            memory: "128Mi"
        mgr:
          limits:
            cpu: "200m"
            memory: "256Mi"
          requests:
            cpu: "100m"
            memory: "128Mi"
        osd:
          limits:
            cpu: "200m"
            memory: "256Mi"
          requests:
            cpu: "100m"
            memory: "128Mi"
      storage:
        useAllNodes: true
        useAllDevices: false
        directories:
        - path: /opt/rook/storage
  YAML

  depends_on = [
    helm_release.this
  ]
}
