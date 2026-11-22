defaultSettings:
  defaultReplicaCount: ${replica_count}
  defaultDataPath: ${default_data_path}

csi:
  kubeletRootDir: ${kubelet_root_dir}

persistence:
  defaultClass: ${set_as_default_storage_class}
  defaultClassReplicaCount: ${replica_count}
  # Explicit backup target reference: "default" when backups are configured,
  # empty when not (chart default injects "default" unconditionally, which
  # deadlocks volume creation if no BackupTarget CR named default exists)
  backupTargetName: ${backup_target_name}

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

# Backup target configuration (creates BackupTarget CRD instance)
%{ if backup_target != "" ~}
defaultBackupStore:
  backupTarget: "${backup_target}"
%{ if backup_target_credential_secret != "" ~}
  backupTargetCredentialSecret: "${backup_target_credential_secret}"
%{ endif ~}
  pollInterval: 30
%{ endif ~}

# Uninstall configuration
uninstall:
  force: true
  deleteNamespace: false
  jobTTLSecondsAfterFinished: 300
# Disable webhook validation during uninstall to avoid errors when CRDs are deleted
disableValidationWebhook: true
