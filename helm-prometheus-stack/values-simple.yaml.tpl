# Simplified Prometheus configuration for ARM64
server:
  enabled: true
  image:
    repository: prom/prometheus
    tag: v2.45.0
  %{ if enable_node_selector }nodeSelector:
    kubernetes.io/arch: ${cpu_arch}
  %{ endif }
  resources:
    requests:
      cpu: 100m
      memory: 256Mi
    limits:
      cpu: 500m
      memory: 512Mi
  persistentVolume:
    enabled: true
    size: ${prometheus_size}
    %{ if prometheus_storage_class != "" }storageClassName: ${prometheus_storage_class}%{ endif }
  service:
    type: ClusterIP
    servicePort: 9090

# Node exporter for system metrics
nodeExporter:
  enabled: true
  %{ if enable_node_selector }nodeSelector:
    kubernetes.io/arch: ${cpu_arch}
  %{ endif }
  resources:
    requests:
      cpu: 50m
      memory: 32Mi
    limits:
      cpu: 100m
      memory: 64Mi

# Disable components that require operator
alertmanager:
  enabled: false

pushgateway:
  enabled: false

# Kube-state-metrics for Kubernetes metrics
kube-state-metrics:
  enabled: true
  %{ if enable_node_selector }nodeSelector:
    kubernetes.io/arch: ${cpu_arch}
  %{ endif }
  resources:
    requests:
      cpu: 50m
      memory: 64Mi
    limits:
      cpu: 100m
      memory: 128Mi
