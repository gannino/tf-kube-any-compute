resources:
  limits:
    cpu: ${cpu_limit}
    memory: ${memory_limit}
  requests:
    cpu: ${cpu_request}
    memory: ${memory_request}

csi:
  enableCSIHostNetwork: true
  provisionerReplicas: ${csi_provisioner_replicas}
  # Kubelet directory path - different for each Kubernetes distribution
  kubeletDirPath: ${csi_kubelet_dir_path}

  csiRBDProvisionerResource: |
    - name: csi-provisioner
      resource:
        requests:
          memory: 128Mi
          cpu: 100m
        limits:
          memory: ${csi_rbd_provisioner_memory_limit}
          cpu: ${csi_rbd_provisioner_cpu_limit}
    - name: csi-attacher
      resource:
        requests:
          memory: 128Mi
          cpu: 100m
        limits:
          memory: ${csi_rbd_provisioner_memory_limit}
          cpu: ${csi_rbd_provisioner_cpu_limit}

  csiRBDPluginResource: |
    - name: driver-registrar
      resource:
        requests:
          memory: 128Mi
          cpu: 50m
        limits:
          memory: 256Mi
          cpu: 100m
    - name: csi-rbdplugin
      resource:
        requests:
          memory: 256Mi
          cpu: 100m
        limits:
          memory: ${csi_rbd_plugin_memory_limit}
          cpu: ${csi_rbd_plugin_cpu_limit}

  csiCephFSProvisionerResource: |
    - name: csi-provisioner
      resource:
        requests:
          memory: 128Mi
          cpu: 100m
        limits:
          memory: ${csi_rbd_provisioner_memory_limit}
          cpu: ${csi_rbd_provisioner_cpu_limit}

  csiCephFSPluginResource: |
    - name: driver-registrar
      resource:
        requests:
          memory: 128Mi
          cpu: 50m
        limits:
          memory: 256Mi
          cpu: 100m
    - name: csi-cephfsplugin
      resource:
        requests:
          memory: 256Mi
          cpu: 100m
        limits:
          memory: ${csi_rbd_plugin_memory_limit}
          cpu: ${csi_rbd_plugin_cpu_limit}

monitoring:
  enabled: true

pspEnable: false

# Enable Ceph Dashboard
dashboard:
  enabled: true
  ssl: ${dashboard_ssl}
