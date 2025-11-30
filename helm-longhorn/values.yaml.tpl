defaultSettings:
  defaultReplicaCount: ${replica_count}
%{ if backup_target != "" ~}
  backupTarget: "${backup_target}"
%{ endif ~}
%{ if backup_target_credential_secret != "" ~}
  backupTargetCredentialSecret: "${backup_target_credential_secret}"
%{ endif ~}
  defaultDataPath: ${default_data_path}

csi:
  kubeletRootDir: ${kubelet_root_dir}

persistence:
  defaultClass: ${set_as_default_storage_class}
  defaultClassReplicaCount: ${replica_count}

%{ if !disable_arch_scheduling ~}
nodeSelector:
  kubernetes.io/arch: ${cpu_arch}
%{ endif ~}

longhornManager:
  resources:
    requests:
      cpu: ${cpu_request}
      memory: ${memory_request}
    limits:
      cpu: ${cpu_limit}
      memory: ${memory_limit}

longhornDriver:
  resources:
    requests:
      cpu: ${cpu_request}
      memory: ${memory_request}
    limits:
      cpu: ${cpu_limit}
      memory: ${memory_limit}

longhornUI:
  resources:
    requests:
      cpu: ${cpu_request}
      memory: ${memory_request}
    limits:
      cpu: ${cpu_limit}
      memory: ${memory_limit}

# Uninstall configuration
uninstall:
  force: true
  deleteNamespace: false
  jobTTLSecondsAfterFinished: 300
