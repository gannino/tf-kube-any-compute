controller:
  replicaCount: ${controller_replica_count}
  logLevel: ${log_level}
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
%{ if enable_prometheus_metrics ~}
  serviceMonitor:
    enabled: ${service_monitor_enabled}
%{ endif ~}

speaker:
  replicaCount: ${speaker_replica_count}
  logLevel: ${log_level}
  frr:
    enabled: ${enable_frr}
  resources:
    limits:
      cpu: ${cpu_limit}
      memory: ${memory_limit}
    requests:
      cpu: ${cpu_request}
      memory: ${memory_request}
%{ if enable_prometheus_metrics ~}
  serviceMonitor:
    enabled: ${service_monitor_enabled}
%{ endif ~}
%{ if !disable_arch_scheduling && cpu_arch != "" ~}
  nodeSelector:
    kubernetes.io/arch: ${cpu_arch}
%{ endif ~}

# Prometheus metrics configuration
prometheus:
  serviceAccount: metallb-controller
  namespace: ${namespace}
  podMonitor:
    enabled: ${enable_prometheus_metrics}
  serviceMonitor:
    enabled: ${service_monitor_enabled}

# Load balancer class configuration
%{ if enable_load_balancer_class ~}
loadBalancerClass: ${load_balancer_class}
%{ endif ~}