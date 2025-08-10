# Promtail Configuration
serviceAccount:
  create: false  # We manage this externally
  name: ${name}

# Image configuration
image:
  pullPolicy: IfNotPresent

# Resource configuration
resources:
  requests:
    cpu: ${cpu_request}
    memory: ${memory_request}
  limits:
    cpu: ${cpu_limit}
    memory: ${memory_limit}

# DaemonSet configuration
daemonset:
  enabled: true

# Update strategy
updateStrategy:
  type: RollingUpdate
  rollingUpdate:
    maxUnavailable: 1

# Security context
securityContext:
  readOnlyRootFilesystem: ${read_only_root_filesystem}
  runAsNonRoot: ${run_as_non_root}
  runAsUser: ${run_as_user}
  runAsGroup: ${run_as_group}
  privileged: ${privileged}

%{ if cpu_arch != "" ~}
# Node selector for architecture
nodeSelector:
  kubernetes.io/arch: ${cpu_arch}
%{ endif ~}

# Promtail configuration
config:
  # Global configuration
  server:
    http_listen_port: 3101
    grpc_listen_port: 0
    log_level: ${log_level}

  # Position tracking
  positions:
    filename: /tmp/positions.yaml

  # Loki client configuration
  clients:
    - url: ${loki_url}/loki/api/v1/push
      tenant_id: ""

  # Basic scrape configuration for Kubernetes pods
  scrape_configs:
    - job_name: kubernetes-pods
      kubernetes_sd_configs:
        - role: pod
      pipeline_stages:
        - cri: {}
      relabel_configs:
        - source_labels: [__meta_kubernetes_pod_name]
          target_label: pod
        - source_labels: [__meta_kubernetes_pod_namespace]
          target_label: namespace
        - source_labels: [__meta_kubernetes_pod_container_name]
          target_label: container
        - source_labels: [__meta_kubernetes_pod_node_name]
          target_label: node

# Pod annotations
podAnnotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "3101"
  prometheus.io/path: "/metrics"
