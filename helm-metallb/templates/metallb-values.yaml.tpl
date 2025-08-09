controller:
  replicaCount: ${controller_replica_count}
%{ if !disable_arch_scheduling && cpu_arch != "" ~}
  nodeSelector:
    kubernetes.io/arch: ${cpu_arch}
%{ endif ~}

speaker:
  replicaCount: ${speaker_replica_count}
  frr:
    enabled: false
%{ if !disable_arch_scheduling && cpu_arch != "" ~}
  nodeSelector:
    kubernetes.io/arch: ${cpu_arch}
%{ endif ~}

resources:
  limits:
    cpu: ${cpu_limit}
    memory: ${memory_limit}
  requests:
    cpu: ${cpu_request}
    memory: ${memory_request}