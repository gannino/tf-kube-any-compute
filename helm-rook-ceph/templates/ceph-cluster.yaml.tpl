apiVersion: ceph.rook.io/v1
kind: CephCluster
metadata:
  name: rook-ceph
  namespace: ${namespace}
spec:
  cephVersion:
    image: quay.io/ceph/ceph:${ceph_image_version}
    allowUnsupported: false
  dataDirHostPath: /opt/rook
  mon:
    count: ${monitor_count}
    allowMultiplePerNode: false
  network:
    hostNetwork: false
  mgr:
    count: 1
    modules:
    - name: pg_autoscaler
      enabled: true
  dashboard:
    enabled: ${enable_dashboard}
    ssl: ${dashboard_ssl}
    port: 8443
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
        cpu: "500m"
        memory: "512Mi"
      requests:
        cpu: "250m"
        memory: "256Mi"
    osd:
      limits:
        cpu: "200m"
        memory: "256Mi"
      requests:
        cpu: "100m"
        memory: "128Mi"
  storage:
    storageClassDeviceSets:
    - name: "local-devices"
      count: ${osd_per_node}
      portable: false
      volumeClaimTemplates:
      - metadata:
          name: data
        spec:
          resources:
            requests:
              storage: ${osd_data_size}
          storageClassName: ${storage_class}
          volumeMode: Block
          accessModes:
          - ReadWriteOnce
