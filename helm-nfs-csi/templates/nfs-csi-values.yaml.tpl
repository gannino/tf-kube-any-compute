storageClass:
  create: ${let_helm_create_storage_class}
  name: ${storage_class}

nfs:
  server: ${nfs_server}
  path: ${nfs_path}

rbac:
  create: true

serviceAccount:
  create: true

resources:
  limits:
    cpu: ${cpu_limit}
    memory: ${memory_limit}
  requests:
    cpu: ${cpu_request}
    memory: ${memory_request}

%{ if !disable_arch_scheduling && cpu_arch != "" ~}
nodeSelector:
  kubernetes.io/arch: ${cpu_arch}
%{ endif ~}