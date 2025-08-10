crds:
  enabled: false  # CRDs managed separately by prometheus_crds module

alertmanager:
  enabled: true
  alertmanagerSpec:
    # Remove or fix node selector - check your actual node labels
    %{ if enable_node_selector }nodeSelector:
      kubernetes.io/arch: ${cpu_arch}
    %{ endif }
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 200m
        memory: 256Mi
    storage:
      volumeClaimTemplate:
        spec:
          accessModes: ["ReadWriteOnce"]
          %{ if alertmanager_storage_class != "" }storageClassName: "${alertmanager_storage_class}"%{ endif }
          resources:
            requests:
              storage: "${alertmanager_size}"
    ingress:
      enabled: false  # Using separate traefik-ingress.tf

prometheus:
  enabled: true
  prometheusSpec:
    scrapeInterval: 30s
    evaluationInterval: 30s
    # Remove or fix node selector
    %{ if enable_node_selector }nodeSelector:
      kubernetes.io/arch: ${cpu_arch}
    %{ endif }
    resources:
      requests:
        cpu: 200m
        memory: 512Mi
      limits:
        cpu: 1000m
        memory: 1Gi
    storageSpec:
      volumeClaimTemplate:
        spec:
          accessModes: ["ReadWriteOnce"]
          %{ if prometheus_storage_class != "" }storageClassName: "${prometheus_storage_class}"%{ endif }
          resources:
            requests:
              storage: "${prometheus_size}"
    ingress:
      enabled: false  # Using separate traefik-ingress.tf

grafana:
  enabled: false  # Using standalone Grafana module

prometheusOperator:
  enabled: true
  admissionWebhooks:
    enabled: false
    patch:
      enabled: false
    certManager:
      enabled: false
  tls:
    enabled: false
  hostNetwork: false
  %{ if enable_node_selector }nodeSelector:
    kubernetes.io/arch: ${cpu_arch}
  %{ endif }

# Disable other webhook configurations
defaultRules:
  create: true
  rules:
    alertmanager: true
    etcd: false
    general: true
    k8s: true
    kubeApiserver: true
    kubeApiserverAvailability: true
    kubeApiserverError: true
    kubeApiserverSlos: true
    kubelet: true

kubelet:
  enabled: true
  namespace: ${namespace}  # Keep kubelet service in Prometheus namespace
  serviceMonitor:
    namespace: ${namespace}
    kubePrometheusGeneral: true
    kubePrometheusNodeAlerting: true
    kubePrometheusNodeRecording: true
    kubernetesAbsent: true
    kubernetesApps: true
    kubernetesResources: true
    kubernetesStorage: true
    kubernetesSystem: true
    kubeScheduler: false
    kubeStateMetrics: true
    network: true
    node: true
    prometheus: true
    prometheusOperator: true
    time: true

prometheus-node-exporter:
  # Node exporters should run on all nodes - remove node selector
  # Or make it conditional
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

kube-state-metrics:
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
